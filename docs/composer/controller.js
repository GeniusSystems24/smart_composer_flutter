/* =============================================================================
   SmartComposer — CONTROLLER  (vanilla class, owns the editing surface)
   -----------------------------------------------------------------------------
   Frameworks bind to this; it never imports React. It manages a single
   contentEditable element: plain-text typing, trigger detection, token
   insert/remove, caret + backspace behaviour around tokens, suggestion state,
   validation and submit. It pushes an immutable "view state" to a subscriber
   (the React view) and emits the spec callbacks.

   const c = new SC.Editor(el, {
     mode, triggers, accessMode, searchProvider, callbacks,
     submitOnEnter, readOnly
   });
   c.onState = (state) => render(state);
============================================================================= */
(function () {
  const SC = (window.SC = window.SC || {});

  function escapeRe(s) { return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'); }
  function lucide(root) { if (window.lucide) try { window.lucide.createIcons({ root }); } catch (e) {} }

  class Editor {
    constructor(el, opts) {
      this.el = el;
      this.opts = opts || {};
      this.callbacks = this.opts.callbacks || {};
      this.refs = new Map();          // id -> ComposerReference (for live tokens)
      this.attachments = [];          // ComposerAttachment[]
      this.selectedToken = null;      // token element pending delete
      this.sug = { open: false };     // suggestion view-state
      this.accessMode = this.opts.accessMode || null;
      this.modelName = this.opts.modelName || null;
      this.readOnly = !!this.opts.readOnly;
      this.onState = () => {};
      this.lastValue = null;
      this._bind();
      el.contentEditable = this.readOnly ? 'false' : 'true';
    }

    /* ---- lifecycle ---- */
    _bind() {
      const el = this.el;
      this._onInput = this._onInput.bind(this);
      this._onKey = this._onKey.bind(this);
      this._onClick = this._onClick.bind(this);
      this._onFocus = this._onFocus.bind(this);
      this._onBlur = this._onBlur.bind(this);
      this._onSelect = this._onSelect.bind(this);
      el.addEventListener('input', this._onInput);
      el.addEventListener('keydown', this._onKey);
      el.addEventListener('click', this._onClick);
      el.addEventListener('focus', this._onFocus);
      el.addEventListener('blur', this._onBlur);
      document.addEventListener('selectionchange', this._onSelect);
      // ---- drag & drop ----
      this.dropConfig = Object.assign({}, SC.DEFAULT_DROP_CONFIG, this.opts.dnd || {});
      this.dropCallbacks = this.opts.dropCallbacks || {};
      this.drag = { state: SC.DROP_STATE.idle, count: 0 };
      this._onDragEnter = this._onDragEnter.bind(this);
      this._onDragOver = this._onDragOver.bind(this);
      this._onDragLeave = this._onDragLeave.bind(this);
      this._onDrop = this._onDrop.bind(this);
      el.addEventListener('dragenter', this._onDragEnter);
      el.addEventListener('dragover', this._onDragOver);
      el.addEventListener('dragleave', this._onDragLeave);
      el.addEventListener('drop', this._onDrop);
    }
    destroy() {
      const el = this.el;
      el.removeEventListener('input', this._onInput);
      el.removeEventListener('keydown', this._onKey);
      el.removeEventListener('click', this._onClick);
      el.removeEventListener('focus', this._onFocus);
      el.removeEventListener('blur', this._onBlur);
      document.removeEventListener('selectionchange', this._onSelect);
      el.removeEventListener('dragenter', this._onDragEnter);
      el.removeEventListener('dragover', this._onDragOver);
      el.removeEventListener('dragleave', this._onDragLeave);
      el.removeEventListener('drop', this._onDrop);
    }

    setMode(mode) { this.opts.mode = mode; this._emit(); }
    setReadOnly(ro) { this.readOnly = ro; this.el.contentEditable = ro ? 'false' : 'true'; this._emit(); }
    setAccessMode(id) { this.accessMode = id; this.callbacks.onAccessModeChanged && this.callbacks.onAccessModeChanged(id); this._emit(); }
    setModel(id) { this.modelName = id; this._emit(); }
    focus() { this.el.focus(); this._placeCaretEnd(); }

    /* ---- public: live caret/trigger rect in viewport coords (for the menu to
           re-anchor on scroll / resize / keyboard without a stale rect) ---- */
    getCaretRect() {
      if (document.activeElement !== this.el && !this.el.contains(document.activeElement)) {
        // editor not focused — fall back to the editor box so the menu still anchors
        return this.el.getBoundingClientRect();
      }
      return this._caretRect();
    }

    /* ---- value ---- */
    getValue() {
      const segments = [];
      let text = '';
      const references = [];
      this.el.childNodes.forEach((n) => {
        if (n.nodeType === 3) { segments.push({ kind: 'text', text: n.data }); text += n.data; }
        else if (n.nodeType === 1 && n.dataset && n.dataset.refId) {
          const ref = this.refs.get(n.dataset.refId);
          if (ref) { segments.push({ kind: 'ref', ref }); references.push(ref); text += `[${ref.displayText || ref.title}]`; }
        } else if (n.nodeName === 'BR') { segments.push({ kind: 'text', text: '\n' }); text += '\n'; }
      });
      return { text, segments, references, attachments: this.attachments.slice(),
        encodedText: SC.segmentsToEncoded(segments),
        plainText: segments.map((s) => (s.kind === 'text' ? s.text : (s.ref.displayText || s.ref.title))).join('') };
    }

    /* ---- encoded-text source of truth ---- */
    getEncodedText() { return SC.segmentsToEncoded(this.getValue().segments); }
    getPlainText() { return SC.SmartComposerPlainTextConverter.convert(this.getEncodedText()); }
    getTokenIndex() { return SC.SmartComposerTokenIndex.extract(this.getEncodedText()); }
    setEncodedText(str) { this.setSegments(SC.encodedToSegments(str || '')); }

    validation() {
      const rules = (this.opts.mode && this.opts.mode.validation) || {};
      return SC.validate(this.getValue(), rules);
    }

    /* ---- seeding (demo / setValue) ---- */
    setSegments(segs) {
      this.el.innerHTML = '';
      this.refs.clear();
      segs.forEach((s) => {
        if (s.kind === 'text') this.el.appendChild(document.createTextNode(s.text));
        else { const t = this._makeToken(s.ref); this.el.appendChild(t); this.el.appendChild(document.createTextNode(' ')); }
      });
      lucide(this.el);
      this._afterChange();
    }
    setAttachments(list) { this.attachments = list.slice(); this._emit(); }
    addAttachment(att) {
      this.attachments.push(att);
      this.callbacks.onAttachmentAdded && this.callbacks.onAttachmentAdded(att);
      this._afterChange();
    }
    removeAttachment(id) {
      const i = this.attachments.findIndex((a) => a.id === id); if (i < 0) return;
      const [a] = this.attachments.splice(i, 1);
      this.callbacks.onAttachmentRemoved && this.callbacks.onAttachmentRemoved(a);
      this._afterChange();
    }

    /* ---- token DOM ---- */
    _makeToken(ref) {
      const def = SC.ReferenceRegistry.get(ref.type);
      const accent = SC.ACCENTS[ref.accent || def.accent] || SC.ACCENTS.neutral;
      const span = document.createElement('span');
      span.className = 'sc-token' + (ref.mono || def.mono ? ' sc-token--mono' : '') +
        (ref.state === 'error' ? ' sc-token--error' : '') +
        (ref.state === 'loading' ? ' sc-token--loading' : '') +
        (ref.state === 'disabled' || ref.isEnabled === false ? ' sc-token--disabled' : '');
      span.contentEditable = 'false';
      span.dataset.refId = ref.id;
      span.dataset.type = ref.type;
      span.style.setProperty('--tk', accent.fg);
      span.style.setProperty('--tk-bg', accent.bg);
      span.style.setProperty('--tk-bd', accent.border);
      const label = ref.displayText || ref.title || ref.value || '';
      span.innerHTML =
        `<i class="sc-token__ic" data-lucide="${ref.icon || def.icon}"></i>` +
        `<span class="sc-token__t">${escapeHtml(label)}</span>` +
        (ref.subtitle ? `<span class="sc-token__sub">${escapeHtml(ref.subtitle)}</span>` : '') +
        (this.readOnly ? '' : `<button class="sc-token__x" data-remove title="Remove" tabindex="-1"><i data-lucide="x"></i></button>`);
      this.refs.set(ref.id, ref);
      return span;
    }

    /* ---- low-level: insert a token node at the current selection (replacing
           any selected range), leave caret after the trailing space ---- */
    _insertRefNode(ref) {
      const sel = window.getSelection();
      let range;
      if (sel.rangeCount && this.el.contains(sel.focusNode)) range = sel.getRangeAt(0);
      else { range = document.createRange(); range.selectNodeContents(this.el); range.collapse(false); }
      range.deleteContents();
      const token = this._makeToken(ref);
      range.insertNode(token);
      const space = document.createTextNode(' ');
      token.after(space);
      const r2 = document.createRange(); r2.setStart(space, 1); r2.collapse(true);
      sel.removeAllRanges(); sel.addRange(r2);
      this.savedRange = r2.cloneRange();
      lucide(token);
      return token;
    }

    /* ---- insert a reference at the current caret (used by toolbar pickers) ---- */
    insertReference(ref) {
      this._restoreRange();
      this._insertRefNode(ref);
      this.callbacks.onReferenceSelected && this.callbacks.onReferenceSelected(ref);
      this._closeMenu();
      this._afterChange();
    }

    /* ========================================================================
       PUBLIC INSERTION API (tokens / encoded / dropped items)
    ======================================================================== */
    insertTokenAtCursor(token) {
      this._restoreRange();
      this._ensureLeadingSpace();
      const ref = SC.tokenToRef(token);
      this._insertRefNode(ref);
      this._afterChange();
      return ref;
    }
    insertEncodedTokenAtCursor(encodedToken) {
      const r = SC.SmartComposerParser.parse(encodedToken);
      if (!r.tokens.length) return null;
      return this.insertTokenAtCursor(r.tokens[0]);
    }
    replaceSelectionWithToken(token) {
      // selection (if any) is deleted by _insertRefNode's range.deleteContents()
      this._restoreRange();
      const ref = SC.tokenToRef(token);
      this._insertRefNode(ref);
      this._afterChange();
      return ref;
    }
    insertTokenAtOffset(token, offset) {
      this.el.focus();
      this._setCaretAtTextOffset(offset);
      const ref = SC.tokenToRef(token);
      this._insertRefNode(ref);
      this._afterChange();
      return ref;
    }
    insertDroppedItemAtCursor(item) { return this.insertTokenAtCursor(SC.dropItemToToken(item)); }
    insertDroppedItemsAtCursor(items) {
      this.el.focus();
      const refs = [];
      (items || []).forEach((item) => { refs.push(this.insertTokenAtCursor(SC.dropItemToToken(item))); });
      return refs;
    }

    _ensureLeadingSpace() {
      const sel = window.getSelection();
      if (!sel.rangeCount || !this.el.contains(sel.focusNode)) return;
      const n = sel.focusNode, o = sel.focusOffset;
      if (n.nodeType === 3 && o > 0) {
        const ch = n.data[o - 1];
        if (ch && !/\s/.test(ch)) this.insertText(' ');
      } else if (n === this.el && o > 0) {
        const prev = this.el.childNodes[o - 1];
        if (prev && prev.nodeType === 1 && prev.dataset && prev.dataset.refId) this.insertText(' ');
      }
    }
    _setCaretAtTextOffset(offset) {
      let n = Math.max(0, offset | 0);
      const sel = window.getSelection();
      const place = (node, off) => { const r = document.createRange(); r.setStart(node, off); r.collapse(true); sel.removeAllRanges(); sel.addRange(r); };
      for (const node of this.el.childNodes) {
        if (node.nodeType === 3) {
          if (n <= node.data.length) return place(node, n);
          n -= node.data.length;
        } else if (node.nodeType === 1 && node.dataset && node.dataset.refId) {
          const len = (node.textContent || '').length || 1;
          if (n <= 0) { const r = document.createRange(); r.setStartBefore(node); r.collapse(true); sel.removeAllRanges(); sel.addRange(r); return; }
          n -= len;
        }
      }
      this._placeCaretEnd();
    }
    _setCaretFromPoint(x, y) {
      let range = null;
      if (document.caretRangeFromPoint) range = document.caretRangeFromPoint(x, y);
      else if (document.caretPositionFromPoint) {
        const p = document.caretPositionFromPoint(x, y);
        if (p) { range = document.createRange(); range.setStart(p.offsetNode, p.offset); }
      }
      if (range && this.el.contains(range.startContainer)) {
        range.collapse(true);
        const sel = window.getSelection(); sel.removeAllRanges(); sel.addRange(range);
        return true;
      }
      return false;
    }

    /* ========================================================================
       DRAG & DROP
    ======================================================================== */
    _dropEnabled() { return this.dropConfig.enabled && !this.readOnly; }
    _dtHasDrop(e) {
      const t = e.dataTransfer && e.dataTransfer.types;
      if (!t) return false;
      return Array.prototype.some.call(t, (x) => x === 'Files' || x === 'application/x-smartcomposer' || x === 'text/uri-list');
    }
    _onDragEnter(e) {
      if (!this._dtHasDrop(e)) return;
      e.preventDefault();
      this.drag.count++;
      this.drag.state = this._dropEnabled() ? SC.DROP_STATE.dragOver : SC.DROP_STATE.rejected;
      this.dropCallbacks.onDragEnter && this.dropCallbacks.onDragEnter(e);
      this._emit();
    }
    _onDragOver(e) {
      if (!this._dtHasDrop(e)) return;
      e.preventDefault();
      try { e.dataTransfer.dropEffect = this._dropEnabled() ? 'copy' : 'none'; } catch (_) {}
      this.dropCallbacks.onDragOver && this.dropCallbacks.onDragOver(e);
    }
    _onDragLeave(e) {
      if (!this._dtHasDrop(e)) return;
      this.drag.count = Math.max(0, this.drag.count - 1);
      if (this.drag.count === 0 && this.drag.state !== SC.DROP_STATE.idle) { this.drag.state = SC.DROP_STATE.idle; this._emit(); }
      this.dropCallbacks.onDragLeave && this.dropCallbacks.onDragLeave(e);
    }
    _onDrop(e) {
      if (!this._dtHasDrop(e)) return;
      e.preventDefault();
      this.drag = { state: SC.DROP_STATE.idle, count: 0 };
      if (!this._dropEnabled()) { this._emit(); return; }
      const items = SC.dropItemsFromDataTransfer(e.dataTransfer);
      if (!items.length) { this._emit(); return; }
      this.dropCallbacks.onFilesDropped && this.dropCallbacks.onFilesDropped(items);

      // place caret at the drop point (or fall back to end)
      if (this.dropConfig.insertAtDropPosition) {
        const ok = this._setCaretFromPoint(e.clientX, e.clientY);
        if (!ok && this.dropConfig.fallbackInsertAtEnd) this.focus();
      } else if (this.dropConfig.fallbackInsertAtEnd) this.focus();

      let list = this.dropConfig.allowMultiple ? items.slice() : items.slice(0, 1);
      const rejected = [];
      if (this.dropConfig.maxFilesCount && list.length > this.dropConfig.maxFilesCount) {
        list.slice(this.dropConfig.maxFilesCount).forEach((it) => rejected.push({ item: it, errors: [{ code: 'tooManyFiles', message: `At most ${this.dropConfig.maxFilesCount} files.` }] }));
        list = list.slice(0, this.dropConfig.maxFilesCount);
      }
      const inserted = [];
      list.forEach((item) => {
        const v = SC.SmartComposerDropValidator.validate(item, this.dropConfig);
        if (!v.valid) {
          rejected.push(v);
          this.dropCallbacks.onDropValidationError && this.dropCallbacks.onDropValidationError(v);
          return;
        }
        const token = (this.dropConfig.generateTokenFromDropItem || SC.dropItemToToken)(item);
        this._ensureLeadingSpace();
        const ref = SC.tokenToRef(token);
        this._insertRefNode(ref);
        inserted.push({ token, ref, item });
        this.dropCallbacks.onDroppedTokenInserted && this.dropCallbacks.onDroppedTokenInserted(token, ref, item);
      });
      if (rejected.length) this.dropCallbacks.onDropRejected && this.dropCallbacks.onDropRejected(rejected);
      this.dropCallbacks.onDrop && this.dropCallbacks.onDrop({ inserted, rejected, items });
      this._afterChange();
    }

    /* ---- programmatic text / trigger insertion (toolbar pickers) ---- */
    insertText(str) {
      this._restoreRange();
      const sel = window.getSelection();
      let range;
      if (sel.rangeCount && this.el.contains(sel.focusNode)) range = sel.getRangeAt(0);
      else { range = document.createRange(); range.selectNodeContents(this.el); range.collapse(false); }
      range.deleteContents();
      const t = document.createTextNode(str);
      range.insertNode(t);
      const r2 = document.createRange(); r2.setStart(t, t.data.length); r2.collapse(true);
      sel.removeAllRanges(); sel.addRange(r2);
      this.savedRange = r2.cloneRange();
      this._refreshSuggestions();
      this._afterChange();
    }
    openTrigger(sym) {
      this._restoreRange();
      const sel = window.getSelection();
      const node = sel.focusNode;
      let needSpace = false;
      if (node && node.nodeType === 3 && sel.focusOffset > 0) {
        const ch = node.data[sel.focusOffset - 1];
        if (ch && !/\s/.test(ch)) needSpace = true;
      }
      this.insertText((needSpace ? ' ' : '') + sym);
    }

    /* ---- suggestion lifecycle ---- */
    _activeTriggerKeys() {
      const mode = this.opts.mode || {};
      const allowed = mode.triggers || SC.TRIGGER_KEYS;
      return SC.TRIGGER_KEYS.filter((k) => allowed.includes(k));
    }

    _detectTrigger() {
      const sel = window.getSelection();
      if (!sel.rangeCount || !sel.isCollapsed) return null;
      const node = sel.focusNode;
      if (!node || node.nodeType !== 3 || !this.el.contains(node)) return null;
      const before = node.data.slice(0, sel.focusOffset);
      for (const key of this._activeTriggerKeys()) {
        const trig = SC.TRIGGERS[key];
        const sym = trig.symbol;
        const re = new RegExp(`(^|\\s)(${escapeRe(sym)})([^\\s${escapeRe(sym[0])}]*)$`);
        const m = before.match(re);
        if (m) {
          const query = m[3];
          const start = sel.focusOffset - (sym.length + query.length);
          return { key, trig, query, node, start, end: sel.focusOffset };
        }
      }
      return null;
    }

    _refreshSuggestions() {
      if (this.readOnly) return this._closeMenu();
      const ctx = this._detectTrigger();
      if (!ctx) return this._closeMenu();
      this._ctx = ctx;
      const provider = (ctx.trig.searchProvider) || this.opts.searchProvider || SC.search;
      const groups = provider(ctx.query, ctx.trig.types, { trigger: ctx.key });
      const flat = [];
      groups.forEach((g) => g.items.forEach((it) => flat.push(it)));
      const rect = this._caretRect();
      this.callbacks.onSuggestionSearch && this.callbacks.onSuggestionSearch(ctx.query, ctx.trig.types);
      this.sug = {
        open: true, key: ctx.key, trig: ctx.trig, query: ctx.query,
        groups, flat, active: 0, rect,
        empty: flat.length === 0,
      };
      this._emit();
    }

    _closeMenu() {
      if (this.sug.open) { this.sug = { open: false }; this._emit(); }
      else this.sug = { open: false };
    }

    moveActive(dir) {
      if (!this.sug.open || !this.sug.flat.length) return;
      const n = this.sug.flat.length;
      this.sug.active = (this.sug.active + dir + n) % n;
      this._emit();
    }
    setActive(i) { if (this.sug.open) { this.sug.active = i; this._emit(); } }

    confirmActive(i) {
      if (!this.sug.open) return;
      const idx = i != null ? i : this.sug.active;
      const ref = this.sug.flat[idx];
      if (!ref) return;
      // replace trigger text with token
      const ctx = this._detectTrigger() || this._ctx;
      if (ctx && ctx.node && this.el.contains(ctx.node)) {
        const range = document.createRange();
        range.setStart(ctx.node, ctx.start);
        range.setEnd(ctx.node, Math.min(ctx.end, ctx.node.data.length));
        range.deleteContents();
        const token = this._makeToken(ref);
        range.insertNode(token);
        const space = document.createTextNode(' ');
        token.after(space);
        const sel = window.getSelection();
        const r2 = document.createRange(); r2.setStart(space, 1); r2.collapse(true);
        sel.removeAllRanges(); sel.addRange(r2);
        lucide(token);
      } else {
        this.insertReference(ref); return;
      }
      // command trigger fires a dedicated callback
      if (ref.type === 'command') this.callbacks.onCommandSelected && this.callbacks.onCommandSelected(ref);
      this.callbacks.onReferenceSelected && this.callbacks.onReferenceSelected(ref);
      this._closeMenu();
      this._afterChange();
    }

    /* ---- token removal ---- */
    _removeToken(tokenEl, viaUser) {
      const id = tokenEl.dataset.refId;
      const ref = this.refs.get(id);
      const next = tokenEl.nextSibling;
      tokenEl.remove();
      if (next && next.nodeType === 3 && next.data.startsWith(' ')) next.data = next.data.slice(1);
      this.refs.delete(id);
      if (this.selectedToken === tokenEl) this.selectedToken = null;
      if (ref) this.callbacks.onReferenceRemoved && this.callbacks.onReferenceRemoved(ref);
      this._afterChange();
    }

    /* ---- events ---- */
    _onInput() {
      // normalize an "empty" editor so the CSS placeholder shows
      if (this.el.childNodes.length === 1 && this.el.firstChild.nodeName === 'BR') this.el.innerHTML = '';
      this.selectedToken && this._clearTokenSel();
      this._saveRange();
      this._refreshSuggestions();
      this._afterChange();
    }

    _onSelect() {
      if (document.activeElement !== this.el) return;
      this._saveRange();
      // keep menu in sync as caret moves; cheap because detect is bounded
      if (!this.readOnly) this._refreshSuggestions();
    }

    /* ---- caret persistence: remember the last in-editor range so toolbar
           buttons / drops can insert exactly where the user left off, even
           though clicking a button blurs the editor and loses the live
           selection. ---- */
    _saveRange() {
      const sel = window.getSelection();
      if (sel.rangeCount && this.el.contains(sel.focusNode)) {
        this.savedRange = sel.getRangeAt(0).cloneRange();
      }
    }
    _restoreRange() {
      // focusing the editor blurs the button; restore the remembered caret
      this.el.focus();
      const sel = window.getSelection();
      const inEditor = sel.rangeCount && this.el.contains(sel.focusNode);
      if (this.savedRange && this.el.contains(this.savedRange.startContainer)) {
        sel.removeAllRanges();
        sel.addRange(this.savedRange);
      } else if (!inEditor) {
        this._placeCaretEnd();
      }
    }

    _onKey(e) {
      // menu navigation takes priority
      if (this.sug.open) {
        if (e.key === 'ArrowDown') { e.preventDefault(); return this.moveActive(1); }
        if (e.key === 'ArrowUp') { e.preventDefault(); return this.moveActive(-1); }
        if (e.key === 'Enter' || e.key === 'Tab') { e.preventDefault(); return this.confirmActive(); }
        if (e.key === 'Escape') { e.preventDefault(); return this._closeMenu(); }
      }
      if (e.key === 'Backspace') return this._onBackspace(e);
      if (this.selectedToken && e.key !== 'Backspace') this._clearTokenSel();
      if (e.key === 'Enter' && !e.shiftKey && this.opts.submitOnEnter !== false && !this.sug.open) {
        e.preventDefault(); this.submit();
      }
    }

    _onBackspace(e) {
      const sel = window.getSelection();
      if (!sel.rangeCount || !sel.isCollapsed) return;
      // second backspace removes the highlighted token
      if (this.selectedToken) { e.preventDefault(); this._removeToken(this.selectedToken); return; }
      const node = sel.focusNode, off = sel.focusOffset;
      let token = null;
      if (node.nodeType === 3 && off === 0) {
        const prev = node.previousSibling;
        if (prev && prev.nodeType === 1 && prev.dataset && prev.dataset.refId) token = prev;
      } else if (node === this.el && off > 0) {
        const prev = this.el.childNodes[off - 1];
        if (prev && prev.nodeType === 1 && prev.dataset && prev.dataset.refId) token = prev;
      } else if (node.nodeType === 3 && off === 1 && node.data[0] === ' ') {
        // caret after the auto space that follows a token -> let normal delete remove space
        return;
      }
      if (token) { e.preventDefault(); this._selectToken(token); }
    }

    _selectToken(t) { this.selectedToken = t; t.classList.add('sc-token--sel'); this._emit(); }
    _clearTokenSel() { if (this.selectedToken) { this.selectedToken.classList.remove('sc-token--sel'); this.selectedToken = null; } }

    _onClick(e) {
      const x = e.target.closest('[data-remove]');
      if (x) { e.preventDefault(); const t = x.closest('.sc-token'); if (t) this._removeToken(t, true); return; }
      const tok = e.target.closest('.sc-token');
      if (tok && tok.dataset.refId) {
        const ref = this.refs.get(tok.dataset.refId);
        if (ref) {
          this.callbacks.onTokenTap && this.callbacks.onTokenTap(ref);
          this.callbacks.onReferenceTap && this.callbacks.onReferenceTap(ref);
          // typed convenience callbacks
          const map = {
            file: 'onFilePathTap', folder: 'onFilePathTap', user: 'onUserTap', member: 'onUserTap',
            invoice: 'onInvoiceTap', task: 'onTaskTap', financialAccount: 'onFinancialAccountTap',
            bankAccount: 'onFinancialAccountTap', command: 'onCommandTap',
          };
          const cb = map[ref.type];
          cb && this.callbacks[cb] && this.callbacks[cb](ref);
        }
      }
    }

    _onFocus() { this.focused = true; this._emit(); }
    _onBlur() {
      this.focused = false;
      // delay so a menu click can land before the menu closes
      setTimeout(() => { if (document.activeElement !== this.el) { this._closeMenu(); this._emit(); } }, 120);
    }

    /* ---- submit ---- */
    submit() {
      const value = this.getValue();
      const result = this.validation();
      if (!result.valid) { this.callbacks.onValidationChanged && this.callbacks.onValidationChanged(result); this._emit(); return result; }
      this.callbacks.onSubmitted && this.callbacks.onSubmitted(value);
      return result;
    }
    clear() { this.el.innerHTML = ''; this.refs.clear(); this.attachments = []; this._afterChange(); }

    /* ---- helpers ---- */
    _caretRect() {
      const sel = window.getSelection();
      if (!sel.rangeCount) return this.el.getBoundingClientRect();
      const r = sel.getRangeAt(0).cloneRange();
      let rect = r.getBoundingClientRect();
      if (!rect || (rect.width === 0 && rect.height === 0)) {
        // collapsed at an element boundary; use a temp marker
        const span = document.createElement('span'); span.textContent = '\u200b';
        r.insertNode(span); rect = span.getBoundingClientRect(); span.remove();
      }
      return rect;
    }
    _placeCaretEnd() {
      const sel = window.getSelection(); const r = document.createRange();
      r.selectNodeContents(this.el); r.collapse(false); sel.removeAllRanges(); sel.addRange(r);
    }
    _afterChange() {
      const value = this.getValue();
      const result = this.validation();
      this.callbacks.onChanged && this.callbacks.onChanged(value);
      if (this.lastValid !== result.valid) { this.lastValid = result.valid; this.callbacks.onValidationChanged && this.callbacks.onValidationChanged(result); }
      this._emit(result, value);
    }

    /* ---- state push to view ---- */
    _emit(result, value) {
      value = value || this.getValue();
      result = result || this.validation();
      const empty = !value.text.trim() && value.references.length === 0;
      let state = 'idle';
      if (this.readOnly) state = 'readOnly';
      else if (this.sug.open) state = 'suggestionOpen';
      else if (this.drag && this.drag.state === SC.DROP_STATE.dragOver) state = 'dragOver';
      else if (this.focused) state = empty ? 'focused' : 'typing';
      this.onState({
        suggestion: this.sug,
        value,
        validation: result,
        attachments: this.attachments,
        accessMode: this.accessMode,
        modelName: this.modelName,
        focused: this.focused,
        empty,
        readOnly: this.readOnly,
        state,
        drag: this.drag || { state: 'idle' },
        selectedTokenId: this.selectedToken ? this.selectedToken.dataset.refId : null,
      });
    }
  }

  function escapeHtml(s) {
    return String(s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  }

  SC.Editor = Editor;
  SC.escapeHtml = escapeHtml;
})();
