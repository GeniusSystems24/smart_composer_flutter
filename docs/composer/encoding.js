/* =============================================================================
   SmartComposer — ENCODING  (framework-agnostic; no DOM, no React)
   -----------------------------------------------------------------------------
   The single source of truth is a human-readable encoded string:

       [<prefix><tagType>:<displayText>](valueText)

   e.g.  [$tool:Browser Use](skill://openai-bundled/browser-use/0.1.0-alpha1/browser)
         [@user:Ahmed](user://user_123)
         [#invoice:INV-2026-001](invoice://INV-2026-001)

   plainText is DERIVED from encodedText (tokens → displayText). JSON is never
   required to rebuild the composer — encodedText alone restores it.

   Exposes under window.SC:
     SC.SmartComposerParser.parse(encodedText) -> SmartComposerParseResult
     SC.SmartComposerSerializer.serialize(value)
     SC.SmartComposerValue.fromEncodedText(encodedText)
     SC.SmartComposerPlainTextConverter.convert(encodedText)
     SC.SmartComposerTokenIndex.extract(encodedText)
============================================================================= */
(function () {
  const SC = (window.SC = window.SC || {});

  /* ---- resolve states (remote token resolution lifecycle) ---- */
  SC.RESOLVE_STATE = Object.freeze({
    idle: 'idle', loading: 'loading', resolved: 'resolved', error: 'error',
    notFound: 'notFound', permissionDenied: 'permissionDenied', deleted: 'deleted', disabled: 'disabled',
  });

  /* ---- prefix ⇄ category. tagType is always authoritative for the entity ---- */
  SC.PREFIX_BY_TYPE = {
    '@': ['user', 'member', 'team', 'club', 'file', 'folder', 'document', 'image', 'video', 'source', 'link'],
    '#': ['task', 'project', 'invoice', 'report'],
    '$': ['tool', 'skill', 'plugin', 'financialAccount', 'bankAccount', 'payment', 'transaction'],
    '/': ['command'],
  };
  SC.prefixForType = function (type) {
    for (const p in SC.PREFIX_BY_TYPE) if (SC.PREFIX_BY_TYPE[p].includes(type)) return p;
    return '@';
  };
  // URI scheme for a given tagType (kebab-cased entity name)
  SC.schemeForType = function (type) {
    return ({
      financialAccount: 'financial-account', bankAccount: 'bank-account',
    }[type]) || type.replace(/([a-z])([A-Z])/g, '$1-$2').toLowerCase();
  };

  /* ---- escaping. Reserved: [ ] ( ) < > : \ and newline.
         displayText terminates at ']'; valueText terminates at ')'. We only
         MUST escape the terminator + backslash + newline; ':' '/' stay raw so
         URIs read naturally (matches the spec examples). ---- */
  function escDisplay(s) {
    return String(s).replace(/\\/g, '\\\\').replace(/\]/g, '\\]').replace(/\n/g, '\\n');
  }
  function escValue(s) {
    return String(s).replace(/\\/g, '\\\\').replace(/\)/g, '\\)').replace(/\n/g, '\\n');
  }
  SC.encEscape = { display: escDisplay, value: escValue };

  /* =========================================================================
     PARSER
     Scans encodedText into ordered SmartComposerSegments. Invalid tokens are
     left as plain text (never throws); errors are collected for debugging.
  ========================================================================= */
  const WORD = /[A-Za-z0-9_-]/;

  function parseTokenAt(s, i) {
    // s[i] === '['
    let j = i + 1;
    let prefix = '';
    // prefix = leading symbol chars (non-word, not ':' or ']')
    while (j < s.length && !WORD.test(s[j]) && s[j] !== ':' && s[j] !== ']' && s[j] !== '[') { prefix += s[j]; j++; }
    // tagType = word chars
    let tagType = '';
    while (j < s.length && WORD.test(s[j])) { tagType += s[j]; j++; }
    if (s[j] !== ':') return { ok: false, reason: 'missing-colon', at: j };
    j++; // skip ':'
    // displayText until unescaped ']'
    let displayText = '';
    while (j < s.length && s[j] !== ']') {
      if (s[j] === '\\' && j + 1 < s.length) { displayText += s[j + 1] === 'n' ? '\n' : s[j + 1]; j += 2; continue; }
      if (s[j] === '\n') return { ok: false, reason: 'newline-in-token', at: j };
      displayText += s[j]; j++;
    }
    if (s[j] !== ']') return { ok: false, reason: 'unterminated-display', at: j };
    j++; // skip ']'
    if (s[j] !== '(') return { ok: false, reason: 'missing-paren', at: j };
    j++; // skip '('
    // valueText until unescaped ')'
    let valueText = '';
    while (j < s.length && s[j] !== ')') {
      if (s[j] === '\\' && j + 1 < s.length) { valueText += s[j + 1] === 'n' ? '\n' : s[j + 1]; j += 2; continue; }
      if (s[j] === '\n') return { ok: false, reason: 'newline-in-token', at: j };
      valueText += s[j]; j++;
    }
    if (s[j] !== ')') return { ok: false, reason: 'unterminated-value', at: j };
    j++; // skip ')'
    // ---- validate ----
    if (!tagType) return { ok: false, reason: 'empty-tagType', at: i };
    if (!valueText) return { ok: false, reason: 'empty-valueText', at: i };
    const token = {
      prefix, tagType,
      displayText: displayText || valueText, // empty displayText → fallback to valueText
      valueText,
      rawText: s.slice(i, j),
      startOffset: i, endOffset: j,
      metadata: {},
      resolveState: SC.RESOLVE_STATE.idle,
    };
    return { ok: true, token, end: j };
  }

  const Parser = (SC.SmartComposerParser = {
    parse(encodedText) {
      encodedText = encodedText == null ? '' : String(encodedText);
      const segments = [];
      const tokens = [];
      const errors = [];
      let i = 0, textStart = 0;
      const flush = (end) => {
        if (end > textStart) segments.push({ kind: 'text', text: encodedText.slice(textStart, end) });
      };
      while (i < encodedText.length) {
        if (encodedText[i] === '\\' && encodedText[i + 1] === '[') { i += 2; continue; } // escaped bracket → literal text
        if (encodedText[i] === '[') {
          const r = parseTokenAt(encodedText, i);
          if (r.ok) {
            flush(i);
            segments.push({ kind: 'token', token: r.token });
            tokens.push(r.token);
            i = r.end; textStart = i;
            continue;
          } else {
            errors.push({ index: i, reason: r.reason });
            i++; // treat '[' as ordinary text and keep scanning
            continue;
          }
        }
        i++;
      }
      flush(encodedText.length);
      const plainText = segments.map((s) => (s.kind === 'text' ? s.text : s.token.displayText)).join('');
      return { encodedText, segments, tokens, errors, plainText };
    },
  });

  /* =========================================================================
     SERIALIZER
  ========================================================================= */
  SC.tokenToEncoded = function (t) {
    const prefix = t.prefix != null ? t.prefix : SC.prefixForType(t.tagType);
    const display = escDisplay(t.displayText || t.valueText || '');
    return `[${prefix}${t.tagType}:${display}](${escValue(t.valueText || '')})`;
  };

  const Serializer = (SC.SmartComposerSerializer = {
    // value: { segments:[{kind:'text',text}|{kind:'token',token}] }  OR  { encodedText }
    serialize(value) {
      if (value && value.segments) {
        return value.segments.map((s) => (s.kind === 'text' ? s.text : SC.tokenToEncoded(s.token))).join('');
      }
      return value && value.encodedText ? value.encodedText : '';
    },
  });

  /* =========================================================================
     PLAIN-TEXT CONVERTER  &  TOKEN INDEX
  ========================================================================= */
  SC.SmartComposerPlainTextConverter = {
    convert(encodedText) { return Parser.parse(encodedText).plainText; },
  };
  SC.SmartComposerTokenIndex = {
    extract(encodedText) {
      return Parser.parse(encodedText).tokens.map((t) => ({
        prefix: t.prefix, tagType: t.tagType, displayText: t.displayText, valueText: t.valueText,
      }));
    },
  };

  /* =========================================================================
     VALUE  (the storable object)
  ========================================================================= */
  function makeValue(encodedText) {
    const res = Parser.parse(encodedText);
    return {
      encodedText: res.encodedText,
      plainText: res.plainText,
      segments: res.segments,
      tokens: res.tokens,
      errors: res.errors,
      metadata: {},
      toEncodedText() { return this.encodedText; },
      toPlainText() { return this.plainText; },
      toSegments() { return this.segments; },
      toTokens() { return this.tokens; },
      toTokenIndex() { return this.tokens.map((t) => ({ prefix: t.prefix, tagType: t.tagType, displayText: t.displayText, valueText: t.valueText })); },
      toStorage() { return { encodedText: this.encodedText, plainText: this.plainText, tokensIndex: this.toTokenIndex() }; },
    };
  }
  SC.SmartComposerValue = {
    fromEncodedText(encodedText) { return makeValue(encodedText); },
    fromSegments(segments) { return makeValue(Serializer.serialize({ segments })); },
  };

  /* =========================================================================
     REFERENCE ⇄ TOKEN bridge  (connects the editor's ComposerReference world
     to the encoded SmartComposerToken world)
  ========================================================================= */
  function slug(s) { return String(s || '').trim().toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, ''); }
  const FILE_TYPES = ['file', 'folder', 'document', 'image', 'video'];

  SC.valueTextForRef = function (ref) {
    if (ref.value && /^[a-z][\w+.-]*:\/\//i.test(ref.value)) return ref.value;
    if (ref.url) return ref.url;
    if (FILE_TYPES.includes(ref.type)) {
      const p = ref.path || ref.value || ref.title || '';
      if (/^[a-z][\w+.-]*:\/\//i.test(p)) return p;
      if (/^[a-zA-Z]:[\\/]/.test(p)) return 'file:///' + p.replace(/\\/g, '/');     // windows path → file URI
      return 'file:///' + p.replace(/^\/+/, '');
    }
    const id = ref.value || ref.id || slug(ref.title);
    return `${SC.schemeForType(ref.type)}://${id}`;
  };

  SC.refToToken = function (ref) {
    return {
      prefix: SC.prefixForType(ref.type),
      tagType: ref.type,
      displayText: ref.displayText || ref.title || ref.value || '',
      valueText: SC.valueTextForRef(ref),
      rawText: '',
      metadata: ref.metadata || {},
      resolveState: ref.state === 'error' ? SC.RESOLVE_STATE.error
        : ref.state === 'loading' ? SC.RESOLVE_STATE.loading
        : ref.state === 'disabled' ? SC.RESOLVE_STATE.disabled : SC.RESOLVE_STATE.idle,
    };
  };

  SC.tokenToRef = function (token) {
    const def = SC.ReferenceRegistry.get(token.tagType);
    const isFile = FILE_TYPES.includes(token.tagType);
    let path = '';
    if (isFile) {
      const m = /^file:\/\/\/(.*)$/i.exec(token.valueText);
      path = m ? m[1] : token.valueText;
    }
    return SC.createReference({
      type: token.tagType,
      title: token.displayText,
      displayText: token.displayText,
      value: token.valueText,
      path,
      icon: def.icon,
      accent: def.accent,
      // surface resolve states onto the ref's transient state
      state: token.resolveState === SC.RESOLVE_STATE.error || token.resolveState === SC.RESOLVE_STATE.notFound ? 'error'
        : token.resolveState === SC.RESOLVE_STATE.loading ? 'loading'
        : token.resolveState === SC.RESOLVE_STATE.disabled || token.resolveState === SC.RESOLVE_STATE.deleted ? 'disabled' : 'ready',
      metadata: token.metadata || {},
    });
  };

  // Encoded string -> editor segments ({kind:'text'} | {kind:'ref', ref})
  SC.encodedToSegments = function (encodedText) {
    return Parser.parse(encodedText).segments.map((s) =>
      s.kind === 'text' ? { kind: 'text', text: s.text } : { kind: 'ref', ref: SC.tokenToRef(s.token) }
    );
  };
  // editor segments -> encoded string
  SC.segmentsToEncoded = function (segments) {
    return segments.map((s) => (s.kind === 'text' ? s.text : SC.tokenToEncoded(SC.refToToken(s.ref)))).join('');
  };
})();
