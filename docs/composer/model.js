/* =============================================================================
   SmartComposer — MODEL  (framework-agnostic, no DOM, no React)
   -----------------------------------------------------------------------------
   This is the portable core. Everything here is plain data + pure functions so
   the same shapes can be reproduced 1:1 in a Flutter/Dart model layer.

   Exposes a single namespace:  window.SC
   -----------------------------------------------------------------------------
   Key shapes
     SC.ReferenceType        a registered entity kind (icon, accent, group)
     SC.createReference()    -> ComposerReference
     SC.createAttachment()   -> ComposerAttachment
     SC.MODES                mode presets (placeholder, triggers, toolbar, rules)
     SC.TRIGGERS             trigger registry (@ # / $ : file: path:)
     SC.ACCESS_MODES         access/permission presets
     SC.search()             default suggestion provider over SC.DATA
     SC.validate()           default validation -> ComposerValidationResult
============================================================================= */
(function () {
  const SC = (window.SC = window.SC || {});

  /* ---------------------------------------------------------------------------
     COLOR — accent tokens. The GeniusLink palette is one blue + semantic
     green/orange/red. We extend with a single brand violet (the cube logo's
     accent face) for "work" items, keeping the whole system to 5 disciplined
     hues. Each accent yields fg / a tinted bg / a tinted border.
  --------------------------------------------------------------------------- */
  function hexToRgb(hex) {
    const h = hex.replace('#', '');
    return [0, 2, 4].map((i) => parseInt(h.slice(i, i + 2), 16));
  }
  function tint(hex, a) {
    const [r, g, b] = hexToRgb(hex);
    return `rgba(${r},${g},${b},${a})`;
  }
  function makeAccent(hex) {
    return { fg: hex, bg: tint(hex, 0.14), bgHover: tint(hex, 0.22), border: tint(hex, 0.42) };
  }
  const ACCENTS = (SC.ACCENTS = {
    blue: makeAccent('#4A7CFF'),
    green: makeAccent('#1DB88A'),
    orange: makeAccent('#F97316'),
    violet: makeAccent('#8B7CF6'),
    red: makeAccent('#EF4444'),
    neutral: makeAccent('#8D90A0'),
  });

  /* ---------------------------------------------------------------------------
     REFERENCE TYPE REGISTRY
     Adding a new entity type is a single register() call — the core editor,
     tokens, suggestion menu and toolbar all read from here. Nothing else
     needs to change to support a brand-new entity.
  --------------------------------------------------------------------------- */
  const _types = new Map();
  const ReferenceRegistry = (SC.ReferenceRegistry = {
    register(def) {
      // def: { type, label, icon, accent, group, mono?, openLabel? }
      _types.set(def.type, Object.assign({ accent: 'neutral', group: 'Other', mono: false }, def));
      return def;
    },
    get(type) {
      return _types.get(type) || { type, label: type, icon: 'box', accent: 'neutral', group: 'Other' };
    },
    all() {
      return [..._types.values()];
    },
    has(type) {
      return _types.has(type);
    },
  });

  // ---- Default entity types (icon names are Lucide) ------------------------
  [
    // People  — blue
    { type: 'user',           label: 'User',            icon: 'user',            accent: 'blue',   group: 'People' },
    { type: 'member',         label: 'Member',          icon: 'user-round',      accent: 'blue',   group: 'People' },
    { type: 'team',           label: 'Team',            icon: 'users',           accent: 'blue',   group: 'People' },
    { type: 'club',           label: 'Club',            icon: 'shield',          accent: 'blue',   group: 'People' },
    // Files & media — orange
    { type: 'file',           label: 'File',            icon: 'file',            accent: 'orange', group: 'Files', mono: true },
    { type: 'folder',         label: 'Folder',          icon: 'folder',          accent: 'orange', group: 'Files', mono: true },
    { type: 'document',       label: 'Document',        icon: 'file-text',       accent: 'orange', group: 'Files' },
    { type: 'image',          label: 'Image',           icon: 'image',           accent: 'orange', group: 'Files' },
    { type: 'video',          label: 'Video',           icon: 'video',           accent: 'orange', group: 'Files' },
    // Financial — green
    { type: 'invoice',        label: 'Invoice',         icon: 'receipt',         accent: 'green',  group: 'Financial', mono: true },
    { type: 'payment',        label: 'Payment',         icon: 'credit-card',     accent: 'green',  group: 'Financial', mono: true },
    { type: 'financialAccount', label: 'Account',       icon: 'wallet',          accent: 'green',  group: 'Financial' },
    { type: 'bankAccount',    label: 'Bank Account',    icon: 'landmark',        accent: 'green',  group: 'Financial' },
    { type: 'transaction',    label: 'Transaction',     icon: 'arrow-left-right',accent: 'green',  group: 'Financial', mono: true },
    { type: 'report',         label: 'Report',          icon: 'chart-column',    accent: 'green',  group: 'Financial' },
    // Work — violet
    { type: 'task',           label: 'Task',            icon: 'square-check-big',accent: 'violet', group: 'Work' },
    { type: 'project',        label: 'Project',         icon: 'layers',          accent: 'violet', group: 'Work' },
    // System / AI — blue
    { type: 'tool',           label: 'Tool',            icon: 'wrench',          accent: 'blue',   group: 'AI Tools' },
    { type: 'skill',          label: 'Skill',           icon: 'sparkles',        accent: 'blue',   group: 'AI Tools' },
    { type: 'command',        label: 'Command',         icon: 'terminal',        accent: 'blue',   group: 'Commands' },
    { type: 'link',           label: 'Link',            icon: 'link',            accent: 'blue',   group: 'Links', mono: true },
    { type: 'custom',         label: 'Custom',          icon: 'box',             accent: 'neutral',group: 'Other' },
  ].forEach((d) => ReferenceRegistry.register(d));

  /* ---------------------------------------------------------------------------
     FACTORIES — ComposerReference & ComposerAttachment
     Full shape per spec; most fields optional. accent/icon/group are resolved
     from the registry when omitted.
  --------------------------------------------------------------------------- */
  let _id = 0;
  const uid = (p) => `${p}_${(++_id).toString(36)}_${Date.now().toString(36).slice(-3)}`;

  SC.createReference = function (r) {
    const def = ReferenceRegistry.get(r.type);
    return {
      id: r.id || uid('ref'),
      type: r.type,
      title: r.title || '',
      subtitle: r.subtitle || '',
      description: r.description || '',
      icon: r.icon || def.icon,
      accent: r.accent || def.accent,
      source: r.source || 'local',
      metadata: r.metadata || {},
      displayText: r.displayText || r.title || '',
      value: r.value != null ? r.value : r.title,
      url: r.url || '',
      path: r.path || '',
      permissions: r.permissions || [],
      isRemote: !!r.isRemote,
      isLocal: r.isLocal !== false,
      isEnabled: r.isEnabled !== false,
      // transient UI state a token can reflect:
      state: r.state || 'ready', // ready | loading | error | disabled
      error: r.error || '',
    };
  };

  SC.createAttachment = function (a) {
    const def = ReferenceRegistry.get(a.type || 'file');
    return {
      id: a.id || uid('att'),
      type: a.type || 'file',
      title: a.title || '',
      subtitle: a.subtitle || '',
      icon: a.icon || def.icon,
      accent: a.accent || def.accent,
      meta: a.meta || '',
      url: a.url || '',
      path: a.path || '',
      preview: a.preview || '',
      state: a.state || 'ready', // ready | uploading | error
      progress: a.progress != null ? a.progress : 1,
    };
  };

  /* ---------------------------------------------------------------------------
     TRIGGERS — configurable. Each maps a symbol to the reference types it
     searches, plus menu copy. Word triggers (file:, path:) are supported.
  --------------------------------------------------------------------------- */
  SC.TRIGGERS = {
    '@': { symbol: '@', label: 'Mention',  hint: 'people & teams',         types: ['user', 'member', 'team', 'club'] },
    '#': { symbol: '#', label: 'Reference', hint: 'tasks, invoices, reports', types: ['task', 'project', 'invoice', 'report'] },
    '/': { symbol: '/', label: 'Command',  hint: 'commands & actions',      types: ['command'] },
    '$': { symbol: '$', label: 'Financial', hint: 'accounts, payments, txns', types: ['financialAccount', 'bankAccount', 'payment', 'invoice', 'transaction'] },
    ':': { symbol: ':', label: 'Tools',    hint: 'AI tools & skills',       types: ['tool', 'skill'] },
    'file:': { symbol: 'file:', word: true, label: 'File path', hint: 'files',  types: ['file', 'document', 'image', 'video'] },
    'path:': { symbol: 'path:', word: true, label: 'Path',      hint: 'folders & files', types: ['folder', 'file'] },
  };
  // longest-first so multi-char word triggers win the prefix match
  SC.TRIGGER_KEYS = Object.keys(SC.TRIGGERS).sort((a, b) => b.length - a.length);

  /* ---------------------------------------------------------------------------
     ACCESS MODES — optional permission posture (AI / automation / finance).
  --------------------------------------------------------------------------- */
  SC.ACCESS_MODES = [
    { id: 'fullAccess',      label: 'Full access',       icon: 'shield-check',  accent: 'green',  desc: 'May read and act on every reference.' },
    { id: 'limitedAccess',   label: 'Limited access',    icon: 'shield',        accent: 'blue',   desc: 'Acts only within the current context.' },
    { id: 'askBeforeAction', label: 'Ask first',         icon: 'shield-question',accent: 'orange', desc: 'Requests confirmation before any action.' },
    { id: 'noExternalAccess',label: 'No external access', icon: 'shield-off',    accent: 'orange', desc: 'Local references only — no network.' },
    { id: 'readOnly',        label: 'Read only',         icon: 'eye',           accent: 'neutral',desc: 'Views references, takes no action.' },
  ];

  /* ---------------------------------------------------------------------------
     MODES — presets. A mode only configures: placeholder, which triggers are
     live, which toolbar buttons show, access options, and validation. The core
     editor is identical across all of them.
  --------------------------------------------------------------------------- */
  const T_ALL = ['@', '#', '/', '$', ':', 'file:', 'path:'];
  SC.MODES = {
    aiPrompt: {
      id: 'aiPrompt', label: 'AI Prompt', icon: 'sparkles',
      placeholder: 'Ask anything — type @ to mention, : for tools, / for commands, # to reference…',
      triggers: T_ALL,
      toolbar: ['attach', 'reference', 'command', 'model', 'access', 'spacer', 'send'],
      access: true, defaultAccess: 'askBeforeAction', submitLabel: 'Run', submitIcon: 'arrow-up',
      validation: { maxLength: 4000 },
    },
    search: {
      id: 'search', label: 'Search', icon: 'search',
      placeholder: 'Search across everything — @ people, # records, $ accounts…',
      triggers: ['@', '#', '$', ':'],
      toolbar: ['reference', 'spacer', 'send'],
      submitLabel: 'Search', submitIcon: 'search',
      validation: {},
    },
    command: {
      id: 'command', label: 'Command', icon: 'terminal',
      placeholder: 'Type / to run a command…',
      triggers: ['/'],
      toolbar: ['command', 'spacer', 'send'],
      submitLabel: 'Execute', submitIcon: 'corner-down-left',
      validation: { requireReferenceType: ['command'] },
    },
    note: {
      id: 'note', label: 'Note', icon: 'notebook-pen',
      placeholder: 'Write a note — @ to mention, file: to attach a path…',
      triggers: ['@', '#', 'file:', 'path:'],
      toolbar: ['attach', 'reference', 'spacer', 'send'],
      submitLabel: 'Save Note', submitIcon: 'check',
      validation: { requireText: true, maxLength: 2000 },
    },
    comment: {
      id: 'comment', label: 'Comment', icon: 'message-square',
      placeholder: 'Add a comment — @ to mention someone…',
      triggers: ['@'],
      toolbar: ['attach', 'spacer', 'send'],
      submitLabel: 'Comment', submitIcon: 'arrow-up',
      validation: { requireText: true, maxLength: 1000 },
    },
    taskDescription: {
      id: 'taskDescription', label: 'Task', icon: 'square-check-big',
      placeholder: 'Describe the task — @ to assign, /due to set a date, # to link…',
      triggers: ['@', '#', '/'],
      toolbar: ['attach', 'reference', 'assignee', 'spacer', 'send'],
      submitLabel: 'Create Task', submitIcon: 'plus',
      validation: { requireText: true, maxAttachments: 10 },
    },
    invoiceNote: {
      id: 'invoiceNote', label: 'Invoice Note', icon: 'receipt',
      placeholder: 'Add a note to this invoice — $ for accounts, # to link records…',
      triggers: ['$', '#', '@'],
      toolbar: ['reference', 'access', 'spacer', 'send'],
      access: true, defaultAccess: 'limitedAccess',
      submitLabel: 'Attach Note', submitIcon: 'check',
      validation: { allowedReferenceTypes: ['invoice', 'payment', 'financialAccount', 'bankAccount', 'transaction', 'report', 'user'] },
    },
    financialEntry: {
      id: 'financialEntry', label: 'Financial Entry', icon: 'wallet',
      placeholder: 'Reference accounts and transactions — type $ to begin…',
      triggers: ['$', '#'],
      toolbar: ['reference', 'access', 'spacer', 'send'],
      access: true, defaultAccess: 'askBeforeAction',
      submitLabel: 'Post Entry', submitIcon: 'corner-down-left',
      validation: { requireReferenceType: ['financialAccount', 'bankAccount'], allowedReferenceTypes: ['financialAccount', 'bankAccount', 'payment', 'invoice', 'transaction', 'report'] },
    },
    message: {
      id: 'message', label: 'Message', icon: 'send',
      placeholder: 'Message — @ to mention, : for tools, file: to share a path…',
      triggers: ['@', ':', 'file:'],
      toolbar: ['attach', 'reference', 'spacer', 'send'],
      submitLabel: 'Send', submitIcon: 'arrow-up',
      validation: { maxAttachments: 6 },
    },
  };

  /* ---------------------------------------------------------------------------
     SAMPLE DATA — backs the default search provider for the demo. In a real
     app this is replaced by per-trigger custom search providers hitting your
     API. Shape returned by search() is generic ComposerSuggestionItem-like.
  --------------------------------------------------------------------------- */
  SC.DATA = {
    user: [
      { title: 'Ahmed Al-Rashid', subtitle: 'Finance Lead · Riyadh', metadata: { initials: 'AR' } },
      { title: 'Sara Khan', subtitle: 'Accountant', metadata: { initials: 'SK' } },
      { title: 'Mohammed Nasser', subtitle: 'Store Manager', metadata: { initials: 'MN' } },
      { title: 'Layla Hassan', subtitle: 'Auditor', metadata: { initials: 'LH' } },
      { title: 'Omar Farouk', subtitle: 'Operations', metadata: { initials: 'OF' } },
    ],
    member: [
      { title: 'Yusuf Idris', subtitle: 'Member · #4821' },
      { title: 'Noura Saleh', subtitle: 'Member · #4822' },
    ],
    team: [
      { title: 'Finance Team', subtitle: '8 members' },
      { title: 'Audit & Compliance', subtitle: '4 members' },
      { title: 'Procurement', subtitle: '6 members' },
    ],
    club: [{ title: 'Riyadh Operations Club', subtitle: 'Regional group' }],
    file: [
      { title: 'client-a.pdf', subtitle: '2.4 MB · PDF', path: 'contracts/client-a.pdf', mono: true },
      { title: 'q4-reconciliation.xlsx', subtitle: '880 KB · Sheet', path: 'finance/q4-reconciliation.xlsx', mono: true },
      { title: 'audit-log-2026.csv', subtitle: '1.1 MB · CSV', path: 'exports/audit-log-2026.csv', mono: true },
    ],
    folder: [
      { title: 'contracts', subtitle: '24 files', path: 'contracts/', mono: true },
      { title: 'finance', subtitle: '58 files', path: 'finance/', mono: true },
      { title: 'exports', subtitle: '12 files', path: 'exports/', mono: true },
    ],
    document: [
      { title: 'Vendor Agreement', subtitle: 'DOCX · 6 pages' },
      { title: 'Q4 Audit Memo', subtitle: 'PDF · 3 pages' },
    ],
    image: [{ title: 'storefront-render.png', subtitle: '1.2 MB · PNG', mono: true }],
    video: [{ title: 'walkthrough.mp4', subtitle: '18.4 MB · MP4', mono: true }],
    invoice: [
      { title: 'INV-2026-001', subtitle: 'Client A · $5,240.00', mono: true, metadata: { amount: '$5,240.00' } },
      { title: 'INV-2026-014', subtitle: 'Vendor X · $1,180.00', mono: true, metadata: { amount: '$1,180.00' } },
      { title: 'INV-2026-022', subtitle: 'Overdue · $920.00', mono: true, state: 'error', metadata: { amount: '$920.00' } },
    ],
    payment: [
      { title: 'PAY-9042', subtitle: 'Settled · $5,240.00', mono: true },
      { title: 'PAY-9051', subtitle: 'Pending · $1,180.00', mono: true },
    ],
    financialAccount: [
      { title: 'Main Bank Account', subtitle: 'SAR · $284,120.00' },
      { title: 'Petty Cash', subtitle: 'SAR · $4,200.00' },
      { title: 'Current Assets', subtitle: 'Ledger group' },
      { title: 'Accounts Receivable', subtitle: 'Ledger group' },
    ],
    bankAccount: [
      { title: 'Al-Rajhi · ****6612', subtitle: 'Operating' },
      { title: 'SNB · ****0048', subtitle: 'Reserve' },
    ],
    transaction: [
      { title: 'TR-9042', subtitle: 'Inter-account · $5,000.00', mono: true },
      { title: 'TR-9061', subtitle: 'Deposit · +$12,400.00', mono: true },
    ],
    report: [
      { title: 'Q4 P&L', subtitle: 'Generated · 2026-01-04' },
      { title: 'Trial Balance', subtitle: 'Live' },
      { title: 'Cash Flow 2026', subtitle: 'Draft' },
    ],
    task: [
      { title: 'Prepare Report', subtitle: 'Due Fri · High' },
      { title: 'Reconcile Q4', subtitle: 'In progress' },
      { title: 'Vendor onboarding', subtitle: 'Archived', state: 'disabled' },
    ],
    project: [
      { title: 'Year-End Close', subtitle: '12 tasks' },
      { title: 'ERP Migration', subtitle: '34 tasks' },
    ],
    tool: [
      { title: 'Web Search', subtitle: 'Fetch live results' },
      { title: 'Code Interpreter', subtitle: 'Run & analyze' },
      { title: 'Ledger Query', subtitle: 'Read the books' },
    ],
    skill: [
      { title: 'Summarize', subtitle: 'Condense long text' },
      { title: 'Translate', subtitle: 'EN ⇄ AR' },
      { title: 'Reconciliation', subtitle: 'Match transactions' },
    ],
    command: [
      { title: 'due', subtitle: 'Set a due date', metadata: { args: '/due tomorrow' } },
      { title: 'status', subtitle: 'Change status', metadata: { args: '/status done' } },
      { title: 'assign', subtitle: 'Assign to user', metadata: { args: '/assign @ahmed' } },
      { title: 'summarize', subtitle: 'Summarize thread' },
      { title: 'export', subtitle: 'Export as…' },
    ],
    link: [
      { title: 'genius.link/q4-board', subtitle: 'External · dashboard', mono: true },
    ],
  };

  /* ---------------------------------------------------------------------------
     SEARCH — default suggestion provider. Filters SC.DATA across the trigger's
     types, groups by registry group, returns generic suggestion items.
     A custom provider can replace this per-trigger (see ComposerTriggerConfig).
  --------------------------------------------------------------------------- */
  function score(query, item) {
    if (!query) return 1;
    const q = query.toLowerCase();
    const t = (item.title + ' ' + (item.subtitle || '')).toLowerCase();
    const i = t.indexOf(q);
    if (i === -1) return 0;
    return i === 0 ? 3 : t[i - 1] === ' ' ? 2 : 1; // prefix > word-start > substring
  }

  SC.search = function (query, types, opts) {
    opts = opts || {};
    const groups = new Map();
    types.forEach((type) => {
      const def = ReferenceRegistry.get(type);
      (SC.DATA[type] || []).forEach((row) => {
        const s = score(query, row);
        if (s <= 0) return;
        const g = def.group;
        if (!groups.has(g)) groups.set(g, []);
        groups.get(g).push({
          score: s,
          item: SC.createReference(Object.assign({ type }, row)),
        });
      });
    });
    const out = [];
    for (const [group, rows] of groups) {
      rows.sort((a, b) => b.score - a.score || a.item.title.localeCompare(b.item.title));
      out.push({ group, items: rows.map((r) => r.item).slice(0, opts.perGroup || 6) });
    }
    // stable group ordering: by best score
    return out;
  };

  /* ---------------------------------------------------------------------------
     VALIDATION — pure. Returns ComposerValidationResult.
  --------------------------------------------------------------------------- */
  SC.validate = function (value, rules) {
    rules = rules || {};
    const refs = value.references || [];
    const atts = value.attachments || [];
    const text = (value.text || '').trim();
    const errors = [];

    if (rules.requireText && !text && refs.length === 0)
      errors.push({ code: 'requiredText', message: 'Enter some text or add a reference.' });
    if (rules.maxLength && (value.text || '').length > rules.maxLength)
      errors.push({ code: 'maxTextLength', message: `Exceeds ${rules.maxLength} characters.` });
    if (rules.maxAttachments && atts.length > rules.maxAttachments)
      errors.push({ code: 'maxAttachments', message: `At most ${rules.maxAttachments} attachments.` });
    if (rules.requireReferenceType) {
      const need = rules.requireReferenceType;
      const ok = refs.some((r) => need.includes(r.type));
      if (!ok) {
        const labels = need.map((t) => ReferenceRegistry.get(t).label).join(' or ');
        errors.push({ code: 'requiredReferenceType', message: `Add at least one ${labels}.` });
      }
    }
    if (rules.allowedReferenceTypes) {
      refs.forEach((r) => {
        if (!rules.allowedReferenceTypes.includes(r.type))
          errors.push({ code: 'forbiddenReferenceType', message: `${ReferenceRegistry.get(r.type).label} not allowed here.`, refId: r.id });
      });
    }
    // entity-state validation (deleted user, archived task, unavailable account…)
    refs.forEach((r) => {
      if (r.state === 'error')
        errors.push({ code: 'invalidReference', message: `${r.title} is unavailable.`, refId: r.id });
      if (r.state === 'disabled')
        errors.push({ code: 'archivedReference', message: `${r.title} is archived.`, refId: r.id });
    });

    return { valid: errors.length === 0, errors };
  };

  /* ---------------------------------------------------------------------------
     SEEDING — parse a "[bracket]" string into segments for demos. Maps a label
     to a best-guess type so the example text renders as real tokens.
  --------------------------------------------------------------------------- */
  SC.guessType = function (label) {
    const l = label.toLowerCase();
    if (/^inv[-\s]/i.test(label)) return 'invoice';
    if (/^pay[-\s]/i.test(label)) return 'payment';
    if (/^tr[-\s]/i.test(label)) return 'transaction';
    if (/account|cash|assets|receivable/.test(l)) return 'financialAccount';
    if (/\.(pdf|xlsx|csv|docx|png|mp4)$/.test(l) || l.includes('/')) return 'file';
    if (/prepare|task|reconcile|assign|onboard/.test(l)) return 'task';
    if (/report|p&l|balance/.test(l)) return 'report';
    if (/task|prepare|reconcile/.test(l)) return 'task';
    if (/team/.test(l)) return 'team';
    return 'user';
  };

  SC.seedSegments = function (str) {
    // returns array of { kind:'text', text } | { kind:'ref', ref }
    const segs = [];
    const re = /\[([^\]]+)\]/g;
    let last = 0, m;
    while ((m = re.exec(str))) {
      if (m.index > last) segs.push({ kind: 'text', text: str.slice(last, m.index) });
      const label = m[1];
      const type = SC.guessType(label);
      segs.push({ kind: 'ref', ref: SC.createReference({ type, title: label, displayText: label, path: type === 'file' ? label : '' }) });
      last = re.lastIndex;
    }
    if (last < str.length) segs.push({ kind: 'text', text: str.slice(last) });
    return segs;
  };

  /* DEFAULT THEME tokens (the View maps these to CSS vars). Kept here so a
     ComposerTheme is data, swappable per instance. */
  SC.THEME = {
    radius: 12,
    tokenRadius: 6,
    font: 'var(--gl-font-body)',
    mono: 'var(--gl-font-mono)',
  };

  SC.version = '1.0.0';
})();
