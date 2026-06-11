/* =============================================================================
   SmartComposer — SHOWCASE  (playground + examples gallery)
============================================================================= */
(function () {
  const { useState, useRef, useEffect, useCallback } = React;
  const h = React.createElement;
  const Icon = window.SCIcon;

  /* seed helpers */
  const T = (text) => ({ kind: 'text', text });
  const R = (type, p) => ({ kind: 'ref', ref: SC.createReference(Object.assign({ type }, p)) });

  /* ---------- toast (shared) ---------- */
  let _toast;
  function ToastHost() {
    const [msg, setMsg] = useState(null);
    _toast = (m) => { setMsg(m); clearTimeout(_toast._t); _toast._t = setTimeout(() => setMsg(null), 2600); };
    if (!msg) return null;
    return h('div', { className: 'pg-toast' }, h(Icon, { name: msg.icon || 'mouse-pointer-click', size: 15 }), h('span', null, msg.text));
  }
  const toast = (text, icon) => _toast && _toast({ text, icon });
  window.SCtoast = toast;

  // standard callback set that logs taps as toasts (the APP decides navigation)
  const tapCallbacks = (log) => ({
    onReferenceTap: (r) => { toast(`Open ${SC.ReferenceRegistry.get(r.type).label.toLowerCase()}: ${r.title}`, r.icon); log && log('onReferenceTap', r.title); },
    onAttachmentTap: (a) => { toast(`Open attachment: ${a.title}`, a.icon); log && log('onAttachmentTap', a.title); },
    onFilePathTap: (r) => log && log('onFilePathTap', r.path || r.title),
    onUserTap: (r) => log && log('onUserTap', r.title),
    onInvoiceTap: (r) => log && log('onInvoiceTap', r.title),
    onTaskTap: (r) => log && log('onTaskTap', r.title),
    onFinancialAccountTap: (r) => log && log('onFinancialAccountTap', r.title),
    onCommandTap: (r) => log && log('onCommandTap', r.title),
  });

  /* =========================================================================
     PLAYGROUND
  ========================================================================= */
  const MODE_ORDER = ['aiPrompt', 'search', 'command', 'note', 'comment', 'taskDescription', 'invoiceNote', 'financialEntry', 'message'];

  function Playground() {
    const [modeId, setModeId] = useState('aiPrompt');
    const [readOnly, setReadOnly] = useState(false);
    // config panel starts collapsed on mobile (stacked under the composer), open on desktop
    const [cfgOpen, setCfgOpen] = useState(() => !window.matchMedia('(max-width: 940px)').matches);
    const [log, setLog] = useState([]);
    const [snap, setSnap] = useState({ text: '', references: [], attachments: [], encodedText: '', plainText: '' });
    const api = useRef(null);
    const mode = SC.MODES[modeId];

    const pushLog = useCallback((name, detail) => {
      setLog((l) => [{ id: Date.now() + Math.random(), name, detail, t: new Date().toLocaleTimeString([], { hour12: false }) }, ...l].slice(0, 7));
    }, []);

    const callbacks = {
      ...tapCallbacks(pushLog),
      onChanged: (v) => setSnap({ text: v.text, references: v.references, attachments: v.attachments, encodedText: v.encodedText, plainText: v.plainText }),
      onReferenceSelected: (r) => pushLog('onReferenceSelected', r.title),
      onReferenceRemoved: (r) => pushLog('onReferenceRemoved', r.title),
      onAttachmentAdded: (a) => pushLog('onAttachmentAdded', a.title),
      onAttachmentRemoved: (a) => pushLog('onAttachmentRemoved', a.title),
      onCommandSelected: (r) => pushLog('onCommandSelected', '/' + r.title),
      onSubmitted: (v) => { pushLog('onSubmitted', `${v.text.length} chars · ${v.references.length} refs`); toast('Submitted ✓', 'check'); },
      onSubmittedInvalid: () => {},
    };

    const seedBig = () => api.current && api.current.setSegments(
      SC.seedSegments('Review invoice [INV-2026-001], compare it with account [Main Bank Account], assign task [Prepare Report] to user [Ahmed], and attach file [contracts/client-a.pdf].')
    );
    const clear = () => api.current && api.current.clear();

    const activeTriggers = mode.triggers || [];

    return h('div', { className: 'pg-grid' },
      // ---- left: live composer ----
      h('div', { className: 'pg-main' },
        h('div', { className: 'pg-stage-head' },
          h('span', { className: 'pg-eyebrow' }, h('span', { className: 'gl-mk gl-mk--blue' }), 'Live composer · ' + mode.label),
          h('div', { className: 'pg-stage-actions' },
            h('button', { className: 'pg-mini', onClick: seedBig }, h(Icon, { name: 'wand-sparkles', size: 14 }), 'Seed example'),
            h('button', { className: 'pg-mini', onClick: clear }, h(Icon, { name: 'eraser', size: 14 }), 'Clear')
          )
        ),
        h(SmartComposer, { mode, callbacks, readOnly, apiRef: api, submitOnEnter: true }),
        h('div', { className: 'pg-hint' },
          h('span', null, 'Try a trigger:'),
          activeTriggers.map((k) => {
            const tg = SC.TRIGGERS[k];
            return h('button', { key: k, className: 'pg-trig', onClick: () => api.current && api.current.openTrigger(tg.symbol) },
              h('code', null, tg.symbol), tg.hint);
          })
        ),
        // value inspector
        h('div', { className: 'pg-inspect' },
          h('div', { className: 'pg-inspect__col', style: { gridColumn: '1 / -1' } },
            h('div', { className: 'pg-inspect__h' }, 'encodedText · source of truth'),
            h('div', { className: 'pg-code' }, snap.encodedText ? snap.encodedText : h('span', { className: 'pg-muted' }, '— empty —'))
          ),
          h('div', { className: 'pg-inspect__col' },
            h('div', { className: 'pg-inspect__h' }, 'plainText · derived'),
            h('div', { className: 'pg-code' }, snap.plainText ? snap.plainText : h('span', { className: 'pg-muted' }, '— empty —'))
          ),
          h('div', { className: 'pg-inspect__col' },
            h('div', { className: 'pg-inspect__h' }, `tokensIndex · ${snap.references.length}`),
            h('div', { className: 'pg-reflist' },
              snap.references.length === 0 && h('span', { className: 'pg-muted' }, 'none'),
              snap.references.map((r) => {
                const acc = SC.ACCENTS[r.accent] || SC.ACCENTS.neutral;
                return h('span', { key: r.id, className: 'pg-rchip', style: { '--tk': acc.fg, '--tk-bg': acc.bg } },
                  h(Icon, { name: r.icon, size: 12 }), h('code', null, SC.prefixForType(r.type) + r.type), r.title);
              })
            )
          )
        )
      ),
      // ---- right: control panel ----
      h('div', { className: 'pg-panel' + (cfgOpen ? '' : ' is-collapsed') },
        h('button', { className: 'pg-panel__h pg-panel__h--toggle', onClick: () => setCfgOpen((v) => !v), 'aria-expanded': cfgOpen },
          h(Icon, { name: 'sliders-horizontal', size: 15 }), 'Configuration',
          h(Icon, { name: 'chevron-down', size: 15, className: 'pg-panel__chev' })
        ),
        h('div', { className: 'pg-panel__body' },
        h('div', { className: 'pg-field' },
          h('label', null, 'Mode'),
          h('div', { className: 'pg-modes' },
            MODE_ORDER.map((id) => h('button', {
              key: id, className: 'pg-modebtn' + (id === modeId ? ' is-on' : ''), onClick: () => setModeId(id),
            }, h(Icon, { name: SC.MODES[id].icon, size: 14 }), SC.MODES[id].label))
          )
        ),
        h('div', { className: 'pg-field' },
          h('label', null, 'Read only'),
          h('button', { className: 'pg-switch' + (readOnly ? ' is-on' : ''), onClick: () => setReadOnly(!readOnly) }, h('span', { className: 'pg-switch__k' }))
        ),
        h('div', { className: 'pg-field' },
          h('label', null, 'Active triggers'),
          h('div', { className: 'pg-triggers' },
            activeTriggers.map((k) => h('span', { key: k, className: 'pg-tg' }, h('code', null, SC.TRIGGERS[k].symbol)))
          )
        ),
        h('div', { className: 'pg-field' },
          h('label', null, 'Toolbar'),
          h('div', { className: 'pg-tags' }, (mode.toolbar || []).filter((t) => t !== 'spacer').map((t) => h('span', { key: t, className: 'pg-tag' }, t)))
        ),
        // event log
        h('div', { className: 'pg-panel__h', style: { marginTop: 18 } }, h(Icon, { name: 'activity', size: 15 }), 'Callback log'),
        h('div', { className: 'pg-log' },
          log.length === 0 && h('div', { className: 'pg-muted', style: { padding: '8px 2px' } }, 'Interact with the composer — callbacks appear here.'),
          log.map((e) => h('div', { key: e.id, className: 'pg-logrow' },
            h('span', { className: 'pg-logt' }, e.t),
            h('code', { className: 'pg-logname' }, e.name),
            h('span', { className: 'pg-logd' }, e.detail)
          ))
        )
        )
      )
    );
  }

  /* =========================================================================
     EXAMPLES GALLERY
  ========================================================================= */
  const EXAMPLES = [
    {
      key: 'ai', title: 'AI Prompt Composer', icon: 'sparkles', accent: 'blue',
      desc: 'Tools, skills, files & context with a model picker and access posture.',
      modeId: 'aiPrompt',
      seed: [T('Use '), R('skill', { title: 'Reconciliation' }), T(' on '), R('file', { title: 'q4-reconciliation.xlsx', path: 'finance/q4-reconciliation.xlsx' }), T(' and brief ')],
    },
    {
      key: 'file', title: 'File Path Composer', icon: 'folder', accent: 'orange',
      desc: 'Local & remote paths via file: / path:, truncated and tappable to preview.',
      modeId: 'note',
      seed: [T('Open '), R('file', { title: 'contracts/client-a.pdf', path: 'contracts/client-a.pdf', subtitle: 'remote' }), T(' next to '), R('folder', { title: 'finance/', path: 'finance/' })],
    },
    {
      key: 'invoice', title: 'Invoice Note Composer', icon: 'receipt', accent: 'green',
      desc: 'Permission-aware notes linking invoices, accounts & payments.',
      modeId: 'invoiceNote',
      seed: [T('Reviewed '), R('invoice', { title: 'INV-2026-001', subtitle: '$5,240.00' }), T(' against '), R('financialAccount', { title: 'Main Bank Account' }), T('.')],
    },
    {
      key: 'finance', title: 'Financial Account Reference', icon: 'wallet', accent: 'green',
      desc: 'Sensitive workflow — requires an account, validates references.',
      modeId: 'financialEntry',
      seed: [T('Settle '), R('transaction', { title: 'TR-9042', subtitle: '$5,000.00' }), T(' from '), R('bankAccount', { title: 'Al-Rajhi · ****6612' })],
    },
    {
      key: 'task', title: 'Task Description Composer', icon: 'square-check-big', accent: 'violet',
      desc: 'Assignees, linked records, /due & /status commands, attachments.',
      modeId: 'taskDescription',
      seed: [T('Assign '), R('task', { title: 'Prepare Report' }), T(' to '), R('user', { title: 'Ahmed Al-Rashid', subtitle: 'Finance' }), T(' — due Friday.')],
    },
    {
      key: 'mention', title: 'User Mention Composer', icon: 'at-sign', accent: 'blue',
      desc: 'Minimal comment box — only @ mentions, requires text.',
      modeId: 'comment',
      seed: [T('Great work '), R('user', { title: 'Sara Khan', subtitle: 'Accountant' }), T(' — can you confirm the figures?')],
    },
    {
      key: 'command', title: 'Command Composer', icon: 'terminal', accent: 'blue',
      desc: 'Slash-only palette; validates that a command was chosen.',
      modeId: 'command',
      seed: [R('command', { title: 'assign', subtitle: 'Assign to user' }), T(' ')],
    },
    {
      key: 'mixed', title: 'Mixed References Composer', icon: 'shapes', accent: 'violet',
      desc: 'Every entity type side-by-side — the spec example, fully tokenised.',
      modeId: 'aiPrompt',
      seed: SC.seedSegments('Review invoice [INV-2026-001], compare it with account [Main Bank Account], assign task [Prepare Report] to user [Ahmed], and attach file [contracts/client-a.pdf].'),
    },
  ];

  function ExampleCard({ ex }) {
    const acc = SC.ACCENTS[ex.accent];
    const callbacks = tapCallbacks();
    return h('div', { className: 'pg-card' },
      h('div', { className: 'pg-card__h' },
        h('span', { className: 'pg-card__ic', style: { '--tk': acc.fg, '--tk-bg': acc.bg } }, h(Icon, { name: ex.icon, size: 16 })),
        h('div', null,
          h('div', { className: 'pg-card__t' }, ex.title),
          h('div', { className: 'pg-card__d' }, ex.desc)
        ),
        h('code', { className: 'pg-card__mode' }, ex.modeId)
      ),
      h(SmartComposer, { mode: SC.MODES[ex.modeId], seed: ex.seed, callbacks, submitOnEnter: true })
    );
  }

  function Gallery() {
    return h('div', null,
      h('p', { className: 'pg-section-note' }, 'Eight ready-made configurations — same core component, different mode presets. Each is fully live: type a trigger, tap a token, add an attachment.'),
      h('div', { className: 'pg-gallery' }, EXAMPLES.map((ex) => h(ExampleCard, { key: ex.key, ex })))
    );
  }

  /* =========================================================================
     APP SHELL
  ========================================================================= */
  // Compact tab dropdown shown on narrow screens (CSS hides it ≥820px).
  function TabDropdown({ tabs, tab, setTab }) {
    const [open, setOpen] = useState(false);
    const ref = useRef(null);
    const cur = tabs.find((t) => t[0] === tab) || tabs[0];
    useEffect(() => {
      if (!open) return;
      const onDown = (e) => { if (ref.current && !ref.current.contains(e.target)) setOpen(false); };
      const onKey = (e) => { if (e.key === 'Escape') setOpen(false); };
      document.addEventListener('mousedown', onDown);
      document.addEventListener('keydown', onKey);
      return () => { document.removeEventListener('mousedown', onDown); document.removeEventListener('keydown', onKey); };
    }, [open]);
    return h('div', { className: 'pg-tabsel', ref },
      h('button', { className: 'pg-tabsel__btn', onClick: () => setOpen((o) => !o), 'aria-haspopup': 'menu', 'aria-expanded': open },
        h(Icon, { name: cur[2], size: 16 }),
        h('span', { className: 'pg-tabsel__lbl' }, cur[1]),
        h(Icon, { name: 'chevron-down', size: 15, className: 'pg-tabsel__chev' + (open ? ' is-open' : '') })
      ),
      open && h('div', { className: 'pg-tabsel__menu', role: 'menu' },
        tabs.map(([id, label, icon]) => h('button', {
          key: id, role: 'menuitem', className: 'pg-tabsel__item' + (id === tab ? ' is-on' : ''),
          onClick: () => { setTab(id); setOpen(false); },
        }, h(Icon, { name: icon, size: 16 }), label, id === tab && h(Icon, { name: 'check', size: 15, className: 'pg-tabsel__chk' })))
      )
    );
  }

  function App() {
    const [theme, setTheme] = useState('dark');
    const [tab, setTab] = useState('playground');
    useEffect(() => { document.documentElement.setAttribute('data-theme', theme); }, [theme]);
    const TABS = [['playground', 'Playground', 'layout-panel-left'], ['examples', 'Examples', 'layout-grid'], ['encoding', 'Encoding', 'braces'], ['drop', 'Drag & Drop', 'mouse-pointer-2'], ['tests', 'Tests', 'flask-conical'], ['docs', 'Docs / API', 'book-open']];
    return h('div', { className: 'pg-shell' },
      h('header', { className: 'pg-head' },
        h('div', { className: 'pg-brand' },
          h('div', { className: 'pg-cube' },
            h('span', { className: 'pg-cube__f pg-cube__top' }), h('span', { className: 'pg-cube__f pg-cube__left' }), h('span', { className: 'pg-cube__f pg-cube__right' })
          ),
          h('div', null,
            h('div', { className: 'pg-brand__t' }, 'SmartComposer'),
            h('div', { className: 'pg-brand__s' }, 'GeniusLink · entity-aware editor')
          ),
          h('span', { className: 'pg-ver' }, 'v' + SC.version)
        ),
        h('div', { className: 'pg-tabs' }, TABS.map(([id, label, icon]) =>
          h('button', { key: id, className: 'pg-tab' + (tab === id ? ' is-on' : ''), onClick: () => setTab(id) }, h(Icon, { name: icon, size: 15 }), label))),
        h(TabDropdown, { tabs: TABS, tab, setTab }),
        h('button', { className: 'pg-theme', onClick: () => setTheme(theme === 'dark' ? 'light' : 'dark'), title: 'Toggle theme' },
          h(Icon, { name: theme === 'dark' ? 'sun' : 'moon', size: 16 }))
      ),
      h('main', { className: 'pg-body' },
        tab === 'playground' && h('div', null,
          h('div', { className: 'pg-intro' },
            h('span', { className: 'pg-eyebrow' }, h('span', { className: 'gl-mk gl-mk--blue' }), 'Reusable · extensible · themeable'),
            h('h1', { className: 'pg-h1' }, 'One composer. Every entity.'),
            h('p', { className: 'pg-lede' }, 'A generic rich-text editor that mixes plain text with inline reference tokens — files, users, invoices, accounts, tasks, tools, commands and any custom type. MVC core, framework-agnostic model, no module-specific behaviour hardcoded.')
          ),
          h(Playground)
        ),
        tab === 'examples' && h(Gallery),
        tab === 'encoding' && h(window.SCEncodingTab),
        tab === 'drop' && h(window.SCDropTab),
        tab === 'tests' && h(window.SCTestsTab),
        tab === 'docs' && h(window.SCDocs)
      ),
      h(ToastHost)
    );
  }

  window.SCApp = App;
})();
