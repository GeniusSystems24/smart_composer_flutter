/* =============================================================================
   SmartComposer — ENCODING & PREVIEW tab  +  TESTS tab
   exposes window.SCEncodingTab, window.SCTestsTab
============================================================================= */
(function () {
  const { useState, useRef, useEffect } = React;
  const h = React.createElement;
  const Icon = window.SCIcon;

  const FULL_EXAMPLE =
    'I want you to use [$tool:Browser Use](skill://openai-bundled/browser-use/0.1.0-alpha1/browser) to preview the page, then run [$skill:Spreadsheets](skill://openai-primary-runtime/spreadsheets/26.423.10653) on [@source:Documents](plugin://documents@openai-primary-runtime).\n\nReview invoice [#invoice:INV-2026-001](invoice://INV-2026-001), compare it with account [$financialAccount:Main Bank Account](financial-account://main_bank_account), assign task [#task:Prepare Report](task://task_prepare_report) to user [@user:Ahmed](user://user_123), and attach file [@file:contracts/client-a.pdf](file:///C:/Users/Al-saiary/contracts/client-a.pdf).';

  /* ---------- the format anatomy strip ---------- */
  function Anatomy() {
    const parts = [
      ['prefix', '$', 'blue', 'category / trigger style'],
      ['tagType', 'tool', 'violet', 'the real entity type'],
      ['displayText', 'Browser Use', 'green', 'human-readable label'],
      ['valueText', 'skill://…/browser', 'orange', 'system value to resolve / open'],
    ];
    return h('div', { className: 'enc-anat' },
      h('div', { className: 'enc-anat__fmt' },
        h('span', { className: 'enc-mut' }, '['),
        h('span', { style: { color: SC.ACCENTS.blue.fg } }, '<prefix>'),
        h('span', { style: { color: SC.ACCENTS.violet.fg } }, '<tagType>'),
        h('span', { className: 'enc-mut' }, ':'),
        h('span', { style: { color: SC.ACCENTS.green.fg } }, '<displayText>'),
        h('span', { className: 'enc-mut' }, ']('),
        h('span', { style: { color: SC.ACCENTS.orange.fg } }, '<valueText>'),
        h('span', { className: 'enc-mut' }, ')')
      ),
      h('div', { className: 'enc-anat__grid' }, parts.map(([k, v, c, d]) =>
        h('div', { key: k, className: 'enc-anat__c', style: { '--tk': SC.ACCENTS[c].fg, '--tk-bg': SC.ACCENTS[c].bg } },
          h('div', { className: 'enc-anat__k' }, k),
          h('code', { className: 'enc-anat__v' }, v),
          h('div', { className: 'enc-anat__d' }, d))))
    );
  }

  /* ---------- resolver state demo ---------- */
  const STATE_DEMOS = [
    ['Resolved', '[@user:Ahmed](user://user_123)', 'loads, then enriches from backend'],
    ['Loading → shimmer', '[#invoice:INV-2026-014](invoice://INV-2026-014)', 'per-token shimmer; text never blocked'],
    ['Not found', '[@user:Sara Khan](user://missing_user)', 'clear fallback label'],
    ['Permission denied', '[#invoice:Q4 Audit](invoice://restricted_q4)', 'no sensitive metadata exposed'],
    ['Error + retry', '[@file:ledger.xlsx](file:///vault/error/ledger.xlsx)', 'keeps layout, offers retry'],
  ];

  function EncodingTab() {
    const [enc, setEnc] = useState(FULL_EXAMPLE);
    const [style, setStyle] = useState('inline');
    const [resolve, setResolve] = useState(true);
    const resolverRef = useRef(SC.makeDemoResolver({ delay: 800 }));
    const [nonce, setNonce] = useState(0); // re-mount preview to replay resolution
    const editorApi = useRef(null);

    const result = SC.SmartComposerParser.parse(enc);
    const resolver = resolve ? resolverRef.current : null;
    const tap = (t, st) => window.SCtoast && window.SCtoast(`${t.tagType} · ${t.valueText}` + (st && st !== 'resolved' ? ` (${st})` : ''), t.tagType);

    return h('div', { className: 'enc-wrap' },
      h('p', { className: 'pg-section-note' }, 'The composer\u2019s source of truth is human-readable encoded text — Markdown-link-like, but with a typed prefix and a resolvable value. plainText is derived; JSON is never required to restore the editor.'),
      h(Anatomy),

      // live encoded <-> preview
      h('div', { className: 'enc-split' },
        h('div', { className: 'enc-pane' },
          h('div', { className: 'enc-pane__h' }, h('span', null, h(Icon, { name: 'code', size: 14 }), ' encodedText'), h('span', { className: 'enc-mut' }, 'source of truth — edit me')),
          h('textarea', { className: 'enc-ta', spellCheck: false, value: enc, onChange: (e) => setEnc(e.target.value) })
        ),
        h('div', { className: 'enc-pane' },
          h('div', { className: 'enc-pane__h' },
            h('span', null, h(Icon, { name: 'eye', size: 14 }), ' SmartComposerPreview'),
            h('div', { className: 'enc-styles' },
              SC.PREVIEW_STYLES.map((s) => h('button', { key: s, className: 'enc-style' + (s === style ? ' is-on' : ''), onClick: () => setStyle(s) }, s)))
          ),
          h('div', { className: 'enc-preview', key: nonce + style + resolve },
            h(SmartComposerPreview, { encodedText: enc, resolver, style, onTokenTap: tap, onResolveRetry: (t) => window.SCtoast && window.SCtoast('retry ' + t.valueText, 'rotate-cw') })
          ),
          h('div', { className: 'enc-controls' },
            h('button', { className: 'pg-switch' + (resolve ? ' is-on' : ''), onClick: () => setResolve(!resolve) }, h('span', { className: 'pg-switch__k' })),
            h('span', { className: 'enc-mut' }, 'remote resolver'),
            h('button', { className: 'pg-mini', onClick: () => setNonce((n) => n + 1) }, h(Icon, { name: 'rotate-cw', size: 13 }), 'Replay resolve')
          ),
          h('div', { className: 'enc-plain' }, h('span', { className: 'enc-plain__k' }, 'plainText →'), ' ', SC.SmartComposerPlainTextConverter.convert(enc).replace(/\n+/g, ' '))
        )
      ),

      // editor round-trip
      h('div', { className: 'enc-rt' },
        h('div', { className: 'pg-stage-head' },
          h('span', { className: 'pg-eyebrow' }, h('span', { className: 'gl-mk gl-mk--green' }), 'Editor \u2194 encodedText round-trip'),
          h('div', { className: 'pg-stage-actions' },
            h('button', { className: 'pg-mini', onClick: () => editorApi.current && editorApi.current.setEncodedText(enc) }, h(Icon, { name: 'download', size: 13 }), 'Load encoded into editor'),
            h('button', { className: 'pg-mini', onClick: () => { if (editorApi.current) setEnc(editorApi.current.getEncodedText()); } }, h(Icon, { name: 'upload', size: 13 }), 'Read editor → encoded'))
        ),
        h(SmartComposer, { mode: SC.MODES.aiPrompt, apiRef: editorApi, seed: SC.encodedToSegments(FULL_EXAMPLE), callbacks: { onReferenceTap: tap } })
      ),

      // resolver states
      h('div', { className: 'pg-eyebrow', style: { display: 'flex', marginTop: 28, marginBottom: 14 } }, h('span', { className: 'gl-mk gl-mk--orange' }), 'Remote resolve states'),
      h('div', { className: 'enc-states' }, STATE_DEMOS.map(([label, code, note], i) =>
        h('div', { key: label, className: 'enc-state' },
          h('div', { className: 'enc-state__t' }, label),
          h('div', { className: 'enc-state__pv', key: 'k' + nonce }, h(SmartComposerPreview, { encodedText: code, resolver: resolverRef.current, style: 'detailed', onTokenTap: tap, onResolveRetry: (t) => window.SCtoast && window.SCtoast('retrying…', 'rotate-cw') })),
          h('div', { className: 'enc-state__d' }, note),
          h('code', { className: 'enc-state__code' }, code))))
    );
  }

  /* ---------- TESTS tab ---------- */
  function TestsTab() {
    const [data, setData] = useState(null);
    useEffect(() => { setData(SC.runTests()); }, []);
    if (!data) return null;
    const groups = {};
    data.results.forEach((r) => { (groups[r.group] = groups[r.group] || []).push(r); });
    return h('div', { className: 'enc-wrap' },
      h('div', { className: 'test-summary' },
        h('span', { className: 'test-badge' + (data.fail === 0 ? ' is-pass' : ' is-fail') }, h(Icon, { name: data.fail === 0 ? 'check-check' : 'x', size: 16 }), `${data.pass}/${data.total} passing`),
        data.fail > 0 && h('span', { className: 'test-badge is-fail' }, `${data.fail} failing`),
        h('span', { className: 'pg-section-note', style: { margin: 0 } }, 'Unit tests for the encoding layer — parsing, serialization, escaping, plainText, invalid tokens, unknown types, adjacency, scale, restore.')
      ),
      Object.keys(groups).map((g) => h('div', { key: g, className: 'test-group' },
        h('div', { className: 'test-group__h' }, g, h('span', { className: 'enc-mut' }, `${groups[g].filter((r) => r.pass).length}/${groups[g].length}`)),
        groups[g].map((r, i) => h('div', { key: i, className: 'test-row' + (r.pass ? '' : ' is-fail') },
          h('span', { className: 'test-dot' }, h(Icon, { name: r.pass ? 'check' : 'x', size: 13 })),
          h('span', { className: 'test-name' }, r.name),
          !r.pass && h('span', { className: 'test-detail' }, r.detail)))))
    );
  }

  window.SCEncodingTab = EncodingTab;
  window.SCTestsTab = TestsTab;
})();
