/* =============================================================================
   SmartComposer — VIEW  (React)
   Presentational layer over SC.Editor (the controller). Renders the editor
   surface, inline tokens (via the controller's DOM), the floating suggestion
   menu, the attachment bar, validation banners and the configurable toolbar.
   Exposes window.SmartComposer + sub-components.
============================================================================= */
(function () {
  const { useRef, useEffect, useState, useLayoutEffect, useCallback } = React;
  const h = React.createElement;

  /* ---- Lucide icon as a self-managed DOM leaf (safe inside React) ---- */
  function Icon({ name, size = 16, className, style }) {
    const ref = useRef(null);
    useLayoutEffect(() => {
      const el = ref.current; if (!el) return;
      el.innerHTML = `<i data-lucide="${name}"></i>`;
      if (window.lucide) window.lucide.createIcons({ root: el });
      const svg = el.querySelector('svg');
      if (svg) { svg.setAttribute('width', size); svg.setAttribute('height', size); }
    }, [name, size]);
    return h('span', { ref, className, style: Object.assign({ display: 'inline-flex', lineHeight: 0 }, style) });
  }
  window.SCIcon = Icon;

  /* ---- bridge hook: instantiate + own one SC.Editor ---- */
  function useComposer(config) {
    const elRef = useRef(null);
    const ctrlRef = useRef(null);
    const cfgRef = useRef(config);
    cfgRef.current = config;
    const [state, setState] = useState({
      suggestion: { open: false }, value: { text: '', references: [], attachments: [], segments: [] },
      validation: { valid: true, errors: [] }, attachments: [], focused: false, empty: true,
      state: 'idle', accessMode: config.accessMode, modelName: config.modelName,
    });
    useEffect(() => {
      const c = new SC.Editor(elRef.current, cfgRef.current);
      c.onState = setState;
      ctrlRef.current = c;
      if (cfgRef.current.seed) c.setSegments(cfgRef.current.seed);
      if (cfgRef.current.attachments) c.setAttachments(cfgRef.current.attachments);
      if (cfgRef.current.apiRef) cfgRef.current.apiRef.current = c;
      if (cfgRef.current.onReady) cfgRef.current.onReady(c);
      c._emit();
      return () => c.destroy();
    }, []);
    // sync reactive bits
    useEffect(() => { const c = ctrlRef.current; if (c && config.mode) c.setMode(config.mode); }, [config.mode]);
    useEffect(() => { const c = ctrlRef.current; if (c) c.setReadOnly(!!config.readOnly); }, [config.readOnly]);
    return { elRef, ctrl: ctrlRef, state };
  }

  /* ---- floating suggestion menu (viewport-aware: flips above/below, clamps to
         the visible viewport, adapts width + max-height, scrolls when tight, and
         re-anchors on scroll / resize / orientation / keyboard) ---- */
  function SuggestionMenu({ sug, ctrl }) {
    const ref = useRef(null);
    const [pos, setPos] = useState(null);

    const reposition = useCallback(() => {
      const m = ref.current; if (!m || !sug.open) return;
      const c = ctrl.current;
      // always prefer a FRESH caret rect so scrolling/keyboard doesn't use a stale one
      const r = (c && c.getCaretRect && c.getCaretRect()) || sug.rect;
      if (!r) return;

      const PAD = 8, GAP = 6, MIN_H = 132, MAX_H = 320;
      // visualViewport tracks the area NOT covered by the mobile keyboard
      const vv = window.visualViewport;
      const vpL = vv ? vv.offsetLeft : 0;
      const vpT = vv ? vv.offsetTop : 0;
      const vpW = vv ? vv.width : window.innerWidth;
      const vpH = vv ? vv.height : window.innerHeight;
      const minL = vpL + PAD, maxR = vpL + vpW - PAD;
      const minT = vpT + PAD, maxB = vpT + vpH - PAD;

      // width adapts to the available horizontal space
      const width = Math.min(340, vpW - PAD * 2);
      m.style.width = width + 'px';

      // measure natural height at the chosen width (reset cap first)
      m.style.maxHeight = MAX_H + 'px';
      const naturalH = Math.min(MAX_H, m.scrollHeight);

      const spaceBelow = maxB - r.bottom - GAP;
      const spaceAbove = r.top - minT - GAP;

      // prefer below when it fits; else above when it fits; else the bigger side
      let placeBelow;
      if (spaceBelow >= Math.min(naturalH, MIN_H)) placeBelow = true;
      else if (spaceAbove >= Math.min(naturalH, MIN_H)) placeBelow = false;
      else placeBelow = spaceBelow >= spaceAbove;

      const avail = Math.max(0, placeBelow ? spaceBelow : spaceAbove);
      const maxH = Math.max(MIN_H, Math.min(MAX_H, avail));
      m.style.maxHeight = maxH + 'px';

      const h = Math.min(m.offsetHeight, maxH);
      let top = placeBelow ? (r.bottom + GAP) : (r.top - GAP - h);
      top = Math.max(minT, Math.min(top, maxB - h));     // clamp top & bottom

      let left = r.left;
      left = Math.max(minL, Math.min(left, maxR - width)); // clamp left & right

      m.dataset.placement = placeBelow ? 'below' : 'above';
      setPos({ top: Math.round(top), left: Math.round(left) });
    }, [sug]);

    // recompute on: open / text / cursor / suggestions change (sug identity), AND
    // scroll (any ancestor, capture) / resize / orientation / keyboard (visualViewport)
    useLayoutEffect(() => {
      if (!sug.open) return;
      reposition();
      let raf = 0;
      const onMove = () => { cancelAnimationFrame(raf); raf = requestAnimationFrame(reposition); };
      window.addEventListener('scroll', onMove, true); // capture → catches scrollable parents
      window.addEventListener('resize', onMove);
      window.addEventListener('orientationchange', onMove);
      const vv = window.visualViewport;
      if (vv) { vv.addEventListener('resize', onMove); vv.addEventListener('scroll', onMove); }
      return () => {
        cancelAnimationFrame(raf);
        window.removeEventListener('scroll', onMove, true);
        window.removeEventListener('resize', onMove);
        window.removeEventListener('orientationchange', onMove);
        if (vv) { vv.removeEventListener('resize', onMove); vv.removeEventListener('scroll', onMove); }
      };
    }, [sug, reposition]);

    if (!sug.open) return null;
    const trig = sug.trig || {};
    let flatIdx = -1;
    return h('div', { ref, className: 'sc-menu', style: pos || { visibility: 'hidden' }, onMouseDown: (e) => e.preventDefault() },
      h('div', { className: 'sc-menu__head' },
        h('span', { className: 'sc-menu__sym' }, trig.symbol),
        h('span', null, trig.label || 'Suggestions'),
        trig.hint && h('span', { style: { color: 'var(--sc-fg-3)', fontWeight: 500, textTransform: 'none', letterSpacing: 0 } }, '· ' + trig.hint)
      ),
      sug.empty
        ? h('div', { className: 'sc-menu__empty' }, h(Icon, { name: 'search-x', size: 16 }), `No matches for “${sug.query || ''}”`)
        : sug.groups.map((g) =>
          h('div', { key: g.group },
            h('div', { className: 'sc-menu__group' }, g.group),
            g.items.map((it) => {
              flatIdx++; const idx = flatIdx;
              const def = SC.ReferenceRegistry.get(it.type);
              const acc = SC.ACCENTS[it.accent || def.accent] || SC.ACCENTS.neutral;
              const meta = it.metadata && (it.metadata.amount || it.metadata.args);
              return h('div', {
                key: it.id, className: 'sc-opt' + (idx === sug.active ? ' is-active' : ''),
                style: { '--tk': acc.fg, '--tk-bg': acc.bg },
                onMouseEnter: () => ctrl.current && ctrl.current.setActive(idx),
                onMouseDown: (e) => { e.preventDefault(); ctrl.current && ctrl.current.confirmActive(idx); },
              },
                h('span', { className: 'sc-opt__ic' }, h(Icon, { name: it.icon || def.icon, size: 15 })),
                h('span', { className: 'sc-opt__body' },
                  h('div', { className: 'sc-opt__t' + (it.mono || def.mono ? ' is-mono' : '') }, it.title),
                  it.subtitle && h('div', { className: 'sc-opt__sub' }, it.subtitle)
                ),
                meta && h('span', { className: 'sc-opt__meta' }, meta),
                idx === sug.active && h('span', { className: 'sc-opt__kbd' }, '↵')
              );
            })
          )
        ),
      h('div', { className: 'sc-menu__foot' },
        h('span', null, h('kbd', null, '↑'), h('kbd', null, '↓'), ' navigate'),
        h('span', null, h('kbd', null, '↵'), ' select'),
        h('span', null, h('kbd', null, 'esc'), ' dismiss')
      )
    );
  }
  window.SCSuggestionMenu = SuggestionMenu;

  /* ---- attachment bar ---- */
  function AttachmentBar({ attachments, ctrl, onTap, display }) {
    if (!attachments.length) return null;
    return h('div', { className: 'sc-attbar' },
      attachments.map((a) => {
        const def = SC.ReferenceRegistry.get(a.type);
        const acc = SC.ACCENTS[a.accent || def.accent] || SC.ACCENTS.neutral;
        return h('div', { key: a.id, className: 'sc-att', style: { '--tk': acc.fg, '--tk-bg': acc.bg }, onClick: () => onTap && onTap(a) },
          h('span', { className: 'sc-att__thumb' }, h(Icon, { name: a.icon || def.icon, size: 16 })),
          h('span', { className: 'sc-att__body' },
            h('div', { className: 'sc-att__t' }, a.title),
            (a.meta || a.subtitle) && h('div', { className: 'sc-att__m' }, a.meta || a.subtitle),
            a.state === 'uploading' && h('div', { className: 'sc-att__bar', style: { width: (a.progress * 100) + '%' } })
          ),
          h('button', { className: 'sc-att__x', onClick: (e) => { e.stopPropagation(); ctrl.current && ctrl.current.removeAttachment(a.id); } },
            h(Icon, { name: 'x', size: 14 }))
        );
      })
    );
  }

  /* ---- small popover (model / access / attach pickers) ---- */
  function Popover({ anchorRef, onClose, children }) {
    const ref = useRef(null);
    const [pos, setPos] = useState(null);
    useLayoutEffect(() => {
      const a = anchorRef.current, m = ref.current; if (!a || !m) return;
      const ar = a.getBoundingClientRect();
      const rootRect = a.closest('.sc-root').getBoundingClientRect();
      let left = ar.left - rootRect.left;
      let top = ar.top - rootRect.top - m.offsetHeight - 8;
      if (left + m.offsetWidth > rootRect.width) left = rootRect.width - m.offsetWidth - 4;
      setPos({ left: Math.max(4, left), top });
    }, []);
    useEffect(() => {
      const onDoc = (e) => { if (ref.current && !ref.current.contains(e.target) && !anchorRef.current.contains(e.target)) onClose(); };
      document.addEventListener('mousedown', onDoc); return () => document.removeEventListener('mousedown', onDoc);
    }, []);
    return h('div', { ref, className: 'sc-pop', style: pos || { visibility: 'hidden' } }, children);
  }

  /* ---- toolbar ---- */
  const MODELS = [
    { id: 'sonnet', label: 'Claude Sonnet', desc: 'Balanced · default', icon: 'sparkles', accent: 'blue' },
    { id: 'opus', label: 'Claude Opus', desc: 'Most capable', icon: 'brain', accent: 'violet' },
    { id: 'haiku', label: 'Claude Haiku', desc: 'Fastest', icon: 'zap', accent: 'green' },
  ];
  function Toolbar({ items, ctrl, state, mode }) {
    const [open, setOpen] = useState(null);
    const modelBtn = useRef(null), accessBtn = useRef(null), attachBtn = useRef(null);
    // Responsive toolbar: collapse pill/button labels based on the toolbar's OWN
    // width (not the viewport) so it adapts in the playground, gallery cards and
    // on mobile alike. A ResizeObserver avoids CSS container queries, which would
    // add layout containment and break the fixed suggestion menu + absolute popovers.
    const tbRef = useRef(null);
    const [tbW, setTbW] = useState(9999);
    const measure = useCallback(() => { const el = tbRef.current; if (el) setTbW(el.getBoundingClientRect().width); }, []);
    useLayoutEffect(() => {
      measure();  // synchronous initial measurement (fires even without a paint cycle)
      let ro;
      if (window.ResizeObserver) { ro = new ResizeObserver(measure); ro.observe(tbRef.current); }
      window.addEventListener('resize', measure);
      return () => { if (ro) ro.disconnect(); window.removeEventListener('resize', measure); };
    }, [measure]);
    const narrow = tbW < 430;  // border-box width: hide model / access / assign text labels
    const tiny = tbW < 320;    // also hide the char counter + send label
    const v = state.value;
    const count = v.text.length;
    const maxLen = mode.validation && mode.validation.maxLength;
    const insert = (sym) => ctrl.current && ctrl.current.openTrigger(sym);
    const access = SC.ACCESS_MODES.find((a) => a.id === state.accessMode) || SC.ACCESS_MODES[0];
    const accAcc = SC.ACCENTS[access.accent] || SC.ACCENTS.neutral;
    const model = MODELS.find((m) => m.id === state.modelName) || MODELS[0];

    const sampleAtt = {
      file: { type: 'file', title: 'q4-reconciliation.xlsx', meta: '880 KB · Sheet', path: 'finance/q4-reconciliation.xlsx' },
      image: { type: 'image', title: 'storefront-render.png', meta: '1.2 MB · PNG' },
      invoice: { type: 'invoice', title: 'INV-2026-001', meta: 'Client A · $5,240.00' },
      report: { type: 'report', title: 'Q4 P&L', meta: 'PDF · generated' },
      link: { type: 'link', title: 'genius.link/q4-board', meta: 'External link' },
    };

    const btn = (key) => {
      switch (key) {
        case 'spacer': return h('span', { key, className: 'sc-tb-spacer' });
        case 'attach': return h('button', { key, ref: attachBtn, className: 'sc-tb-btn sc-tb-btn--icon', title: 'Add attachment', onClick: () => setOpen(open === 'attach' ? null : 'attach') }, h(Icon, { name: 'plus', size: 18 }));
        case 'reference': return h('button', { key, className: 'sc-tb-btn sc-tb-btn--icon', title: 'Insert reference (@)', onClick: () => insert('@') }, h(Icon, { name: 'at-sign', size: 16 }));
        case 'command': return h('button', { key, className: 'sc-tb-btn sc-tb-btn--icon', title: 'Run command (/)', onClick: () => insert('/') }, h(Icon, { name: 'slash-square', size: 16 }));
        case 'assignee': return h('button', { key, className: 'sc-tb-btn', title: 'Assign', onClick: () => insert('@') }, h(Icon, { name: 'user-plus', size: 16 }), h('span', { className: 'sc-tb-btn__lbl' }, 'Assign'));
        case 'model': return h('button', { key, ref: modelBtn, className: 'sc-tb-btn sc-tb-btn--pill', title: model.label, onClick: () => setOpen(open === 'model' ? null : 'model') }, h(Icon, { name: model.icon, size: 15 }), h('span', { className: 'sc-tb-btn__lbl' }, model.label), h(Icon, { name: 'chevron-down', size: 13 }));
        case 'access': return h('button', { key, ref: accessBtn, className: 'sc-tb-btn sc-tb-btn--pill', title: access.label, style: { color: accAcc.fg }, onClick: () => setOpen(open === 'access' ? null : 'access') }, h(Icon, { name: access.icon, size: 15 }), h('span', { className: 'sc-tb-btn__lbl' }, access.label), h(Icon, { name: 'chevron-down', size: 13 }));
        case 'send': {
          const dis = state.empty || !state.validation.valid;
          return h(React.Fragment, { key },
            maxLen && h('span', { className: 'sc-count' + (count > maxLen ? ' is-over' : '') }, `${count}/${maxLen}`),
            h('button', { className: 'sc-send', title: mode.submitLabel || 'Send', disabled: dis, onClick: () => ctrl.current && ctrl.current.submit() },
              h('span', { className: 'sc-send__lbl' }, mode.submitLabel || 'Send'), h(Icon, { name: mode.submitIcon || 'arrow-up', size: 15 }))
          );
        }
        default: return null;
      }
    };

    return h('div', { ref: tbRef, className: 'sc-toolbar' + (narrow ? ' is-narrow' : '') + (tiny ? ' is-tiny' : '') },
      items.map(btn),
      open === 'model' && h(Popover, { anchorRef: modelBtn, onClose: () => setOpen(null) },
        MODELS.map((m) => h('div', { key: m.id, className: 'sc-pop__row' + (m.id === model.id ? ' is-active' : ''), style: { '--tk': SC.ACCENTS[m.accent].fg, '--tk-bg': SC.ACCENTS[m.accent].bg }, onClick: () => { ctrl.current.setModel(m.id); setOpen(null); } },
          h('span', { className: 'sc-pop__ic' }, h(Icon, { name: m.icon, size: 15 })),
          h('span', null, h('div', { className: 'sc-pop__t' }, m.label), h('div', { className: 'sc-pop__d' }, m.desc)),
          m.id === model.id && h('span', { className: 'sc-pop__check' }, h(Icon, { name: 'check', size: 16 }))
        ))
      ),
      open === 'access' && h(Popover, { anchorRef: accessBtn, onClose: () => setOpen(null) },
        SC.ACCESS_MODES.map((a) => h('div', { key: a.id, className: 'sc-pop__row' + (a.id === access.id ? ' is-active' : ''), style: { '--tk': SC.ACCENTS[a.accent].fg, '--tk-bg': SC.ACCENTS[a.accent].bg }, onClick: () => { ctrl.current.setAccessMode(a.id); setOpen(null); } },
          h('span', { className: 'sc-pop__ic' }, h(Icon, { name: a.icon, size: 15 })),
          h('span', null, h('div', { className: 'sc-pop__t' }, a.label), h('div', { className: 'sc-pop__d' }, a.desc)),
          a.id === access.id && h('span', { className: 'sc-pop__check' }, h(Icon, { name: 'check', size: 16 }))
        ))
      ),
      open === 'attach' && h(Popover, { anchorRef: attachBtn, onClose: () => setOpen(null) },
        [['file', 'Upload file', 'file'], ['image', 'Add image', 'image'], ['invoice', 'Attach invoice', 'receipt'], ['report', 'Attach report', 'chart-column'], ['link', 'Add link', 'link']].map(([k, label, icon]) =>
          h('div', { key: k, className: 'sc-pop__row', style: { '--tk': 'var(--sc-fg-2)', '--tk-bg': 'var(--gl-input-bg)' }, onClick: () => { ctrl.current.addAttachment(SC.createAttachment(sampleAtt[k])); setOpen(null); } },
            h('span', { className: 'sc-pop__ic' }, h(Icon, { name: icon, size: 15 })),
            h('span', null, h('div', { className: 'sc-pop__t' }, label))
          ))
      )
    );
  }

  /* ---- validation / state banner ---- */
  function Banner({ validation, state }) {
    if (state.state === 'readOnly') return null;
    if (validation.valid || state.empty) return null;
    const first = validation.errors[0];
    if (!first) return null;
    return h('div', { className: 'sc-banner sc-banner--error' }, h(Icon, { name: 'alert-triangle', size: 15 }), first.message);
  }

  /* ---- the composer ---- */
  function SmartComposer(props) {
    const { mode, callbacks = {}, seed, attachments, readOnly, accessMode, modelName, style, className, dnd, dropCallbacks } = props;
    const config = {
      mode, callbacks, seed, attachments, readOnly,
      accessMode: accessMode || mode.defaultAccess, modelName: modelName || 'sonnet',
      submitOnEnter: props.submitOnEnter, apiRef: props.apiRef, onReady: props.onReady,
      dnd: dnd === false ? { enabled: false } : (dnd || {}), dropCallbacks: dropCallbacks || {},
    };
    const { elRef, ctrl, state } = useComposer(config);
    const dragOn = state.drag && state.drag.state === 'dragOver';
    const dragRej = state.drag && state.drag.state === 'rejected';
    const rootCls = ['sc-root',
      state.focused ? 'is-focused' : '',
      dragOn ? 'is-dragover' : '', dragRej ? 'is-dragreject' : '',
      !state.validation.valid && !state.empty ? 'is-invalid' : '',
      readOnly ? 'is-readonly' : '', className || ''].join(' ');

    return h('div', { className: rootCls, style },
      h('div', { className: 'sc-editor-wrap' },
        h('div', {
          ref: elRef, className: 'sc-editor', 'data-placeholder': mode.placeholder,
          spellCheck: false, role: 'textbox', 'aria-multiline': 'true',
          'aria-label': mode.placeholder + (config.dnd.enabled !== false ? '. Drop files to insert as references.' : ''),
        }),
        (dragOn || dragRej) && h('div', { className: 'sc-drop' + (dragRej ? ' sc-drop--reject' : '') },
          h('div', { className: 'sc-drop__inner' },
            h(Icon, { name: dragRej ? 'file-x' : 'file-down', size: 22 }),
            h('span', null, dragRej ? 'Drops are disabled here' : 'Drop to insert as a reference')
          )
        )
      ),
      h(Banner, { validation: state.validation, state }),
      h(AttachmentBar, { attachments: state.attachments, ctrl, onTap: callbacks.onAttachmentTap }),
      !readOnly && mode.toolbar && h(Toolbar, { items: mode.toolbar, ctrl, state, mode }),
      h(SuggestionMenu, { sug: state.suggestion, ctrl })
    );
  }

  window.SmartComposer = SmartComposer;
  window.useComposer = useComposer;
})();
