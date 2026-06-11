/* =============================================================================
   SmartComposer — PREVIEW  (React, read-only renderer of encodedText)
   -----------------------------------------------------------------------------
   <SmartComposerPreview encodedText resolver style onTokenTap … />

   - parses encodedText into segments (SC.SmartComposerParser)
   - renders text as text, tokens as inline rich chips
   - resolves remote tokens through a SmartComposerTokenResolver (per-token
     shimmer; never blocks the whole preview; keeps cached displayText)
   - supports states: idle | loading | resolved | error | notFound |
     permissionDenied | deleted | disabled
   - styles: inline | compact | card | chatBubble | detailed | minimal | debug
   - never hardcodes navigation — app decides via callbacks
============================================================================= */
(function () {
  const { useState, useEffect, useRef } = React;
  const h = React.createElement;
  const Icon = window.SCIcon;
  const RS = SC.RESOLVE_STATE;

  SC.PREVIEW_STYLES = ['inline', 'compact', 'card', 'chatBubble', 'detailed', 'minimal', 'debug'];

  /* ---- a demo SmartComposerTokenResolver ----------------------------------
     A resolver is just:  async (token) => ({ status, displayText?, subtitle?,
     icon?, metadata? }). This demo derives a state from the valueText so every
     resolve state is observable. Replace with a real API in production. */
  SC.makeDemoResolver = function (opts) {
    opts = opts || {};
    const delay = opts.delay != null ? opts.delay : 700;
    const cache = new Map();
    return function resolve(token) {
      const key = token.valueText;
      return new Promise((res) => {
        setTimeout(() => {
          const v = (token.valueText || '').toLowerCase();
          let out;
          if (/restricted|private|secret|denied/.test(v)) out = { status: RS.permissionDenied };
          else if (/missing|deleted|404|not-?found|ghost/.test(v)) out = { status: RS.notFound };
          else if (/error|fail|broken/.test(v)) out = { status: RS.error };
          else {
            // "enrich" the token from the backend
            const extra = {
              user: 'online', invoice: '$5,240.00 · paid', task: 'In progress', financialAccount: 'SAR · $284,120.00',
              file: 'synced', tool: 'ready', skill: 'v26.4', plugin: 'enabled', payment: 'settled', report: 'live',
            }[token.tagType];
            out = { status: RS.resolved, subtitle: extra, metadata: { resolvedAt: Date.now() } };
          }
          cache.set(key, out);
          res(out);
        }, /idle|cached/.test(token.tagType) ? 0 : delay + Math.round(Math.random() * 300));
      });
    };
  };

  /* ---- a single preview token, owning its own resolve lifecycle ---- */
  function PreviewToken({ token, resolver, style, onTokenTap, onTokenLongPress, onResolveRetry, onResolveError, debug }) {
    const def = SC.ReferenceRegistry.get(token.tagType);
    const [state, setState] = useState(resolver ? RS.loading : RS.idle);
    const [data, setData] = useState(null);
    const [attempt, setAttempt] = useState(0);
    const mounted = useRef(true);
    useEffect(() => () => { mounted.current = false; }, []);

    useEffect(() => {
      if (!resolver) { setState(RS.idle); return; }
      let alive = true;
      setState(RS.loading);
      Promise.resolve(resolver(token)).then((r) => {
        if (!alive || !mounted.current) return;
        r = r || { status: RS.resolved };
        setData(r);
        setState(r.status || RS.resolved);
        if (r.status === RS.error) onResolveError && onResolveError(token);
      }).catch(() => { if (alive && mounted.current) { setState(RS.error); onResolveError && onResolveError(token); } });
      return () => { alive = false; };
    }, [token.valueText, attempt]);

    const accentKey = (state === RS.notFound || state === RS.deleted) ? 'neutral'
      : state === RS.error ? 'red'
      : state === RS.permissionDenied ? 'orange'
      : (token.accent || def.accent);
    const acc = SC.ACCENTS[accentKey] || SC.ACCENTS.neutral;
    const mono = def.mono;

    // label by state
    let label = data && data.displayText ? data.displayText : token.displayText;
    let icon = (data && data.icon) || def.icon;
    let cls = 'sc-pv-tk';
    if (mono) cls += ' sc-pv-tk--mono';
    if (state === RS.loading) cls += ' sc-pv-tk--loading';
    if (state === RS.notFound || state === RS.deleted) { cls += ' sc-pv-tk--notfound'; icon = 'circle-help'; }
    if (state === RS.permissionDenied) { cls += ' sc-pv-tk--denied'; icon = 'lock'; }
    if (state === RS.error) { cls += ' sc-token--error'; icon = 'alert-triangle'; }

    const notFoundLabel = {
      user: 'User not found', invoice: 'Invoice not found', task: 'Task not found', file: 'File not found',
    }[token.tagType] || 'Reference not found';
    const deniedLabel = {
      user: 'Private user', invoice: 'Restricted invoice', file: 'Restricted file', financialAccount: 'No access',
    }[token.tagType] || 'No access';

    const tap = (e) => {
      e.preventDefault();
      if (state === RS.notFound) return onTokenTap && onTokenTap(token, state);
      if (state === RS.permissionDenied) return onTokenTap && onTokenTap(token, state);
      onTokenTap && onTokenTap(token, state);
    };
    const longPress = () => onTokenLongPress && onTokenLongPress(token);

    const sub = (style === 'detailed' && data && data.subtitle) ? data.subtitle : null;

    return h('a', {
      href: '#', className: cls,
      style: { '--tk': acc.fg, '--tk-bg': acc.bg, '--tk-bd': acc.border },
      title: debug ? `${token.prefix}${token.tagType} → ${token.valueText}` : (token.displayText + (sub ? ' · ' + sub : '')),
      onClick: tap, onContextMenu: (e) => { e.preventDefault(); longPress(); },
    },
      h('span', { className: 'sc-pv-tk__ic' }, h(Icon, { name: icon, size: 13 })),
      state === RS.loading
        ? h('span', { className: 'sc-pv-tk__t' },
            h('span', { className: 'sc-shimmer sc-pv-tk__shim', style: { width: Math.max(36, label.length * 6) + 'px' } }),
            h('span', { style: { position: 'absolute', width: 1, height: 1, overflow: 'hidden', clip: 'rect(0 0 0 0)' } }, label))
        : h('span', { className: 'sc-pv-tk__t' }, state === RS.notFound ? notFoundLabel : state === RS.permissionDenied ? deniedLabel : label),
      sub && h('span', { className: 'sc-pv-tk__sub' }, sub),
      state === RS.error && h('button', {
        className: 'sc-pv-retry', onClick: (e) => { e.preventDefault(); e.stopPropagation(); onResolveRetry && onResolveRetry(token); setAttempt((a) => a + 1); },
      }, 'retry')
    );
  }

  /* ---- debug view ---- */
  function DebugView({ result }) {
    return h('div', { className: 'sc-pv-debug' },
      h('div', { className: 'sc-pv-debug__row' }, h('div', { className: 'sc-pv-debug__k' }, 'encodedText (source of truth)'), h('div', { className: 'sc-pv-debug__v' }, result.encodedText)),
      h('div', { className: 'sc-pv-debug__row' }, h('div', { className: 'sc-pv-debug__k' }, 'plainText'), h('div', { className: 'sc-pv-debug__v' }, result.plainText)),
      h('div', { className: 'sc-pv-debug__row' }, h('div', { className: 'sc-pv-debug__k' }, `tokens · ${result.tokens.length}`),
        h('div', { className: 'sc-pv-debug__tok' }, result.tokens.flatMap((t, i) => [
          h('b', { key: 'p' + i }, t.prefix + t.tagType), h('span', { key: 'd' + i }, t.displayText), h('span', { key: 'v' + i, style: { color: 'var(--gl-fg-3)' } }, t.valueText),
        ]))),
      result.errors.length > 0 && h('div', { className: 'sc-pv-debug__row' }, h('div', { className: 'sc-pv-debug__k', style: { color: 'var(--gl-danger-500)' } }, `parse errors · ${result.errors.length}`),
        h('div', { className: 'sc-pv-debug__v' }, result.errors.map((e) => `@${e.index}: ${e.reason}`).join('\n')))
    );
  }

  /* ---- the preview ---- */
  function SmartComposerPreview(props) {
    const { encodedText = '', resolver, style = 'inline', className = '', onTokenTap, onTokenLongPress, onResolveRetry, onResolveError, debug } = props;
    const result = SC.SmartComposerParser.parse(encodedText);

    if (style === 'debug') return h('div', { className: 'sc-pv-card ' + className }, h(DebugView, { result }));

    const body = result.segments.map((s, i) =>
      s.kind === 'text'
        ? h('span', { key: i }, s.text)
        : h(PreviewToken, { key: i, token: s.token, resolver, style, onTokenTap, onTokenLongPress, onResolveRetry, onResolveError, debug })
    );

    const cls = 'sc-pv ' + (style === 'compact' ? 'sc-pv--compact ' : style === 'minimal' ? 'sc-pv--minimal ' : '') + className;
    const inner = h('div', { className: cls }, body, debug && style !== 'debug' && h('div', { style: { marginTop: 10, paddingTop: 10, borderTop: '1px solid var(--gl-border)', fontFamily: 'var(--gl-font-mono)', fontSize: 11, color: 'var(--gl-fg-3)' } }, encodedText));

    if (style === 'card' || style === 'detailed') return h('div', { className: 'sc-pv-card' }, inner);
    if (style === 'chatBubble') return h('div', { className: 'sc-pv-bubble' }, inner);
    return inner;
  }
  SmartComposerPreview.fromEncodedText = function (encodedText, opts) {
    return h(SmartComposerPreview, Object.assign({ encodedText }, opts || {}));
  };

  window.SmartComposerPreview = SmartComposerPreview;
  window.SCPreviewToken = PreviewToken;
})();
