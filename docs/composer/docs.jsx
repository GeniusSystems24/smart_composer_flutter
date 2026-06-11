/* =============================================================================
   SmartComposer — DOCS / API tab
============================================================================= */
(function () {
  const h = React.createElement;
  const Icon = window.SCIcon;

  function Code({ children }) { return h('pre', { className: 'doc-code' }, h('code', null, children)); }
  function Sec({ id, icon, title, children }) {
    return h('section', { className: 'doc-sec', id },
      h('h2', { className: 'doc-h2' }, h('span', { className: 'doc-h2__ic' }, h(Icon, { name: icon, size: 16 })), title),
      children);
  }
  function P(props) { return h('p', { className: 'doc-p' }, props.children); }

  const ARCH = [
    ['Model', 'database', 'model.js', 'Pure data + pure functions — no DOM, no React. Registry, modes, triggers, access modes, sample providers, validation. This is what you port to Dart 1:1.'],
    ['Controller', 'cpu', 'controller.js', 'SC.Editor class. Owns one contentEditable surface: typing, trigger detection, token insert/remove, caret & backspace, suggestion state, submit. Emits a view-state + the spec callbacks.'],
    ['View', 'layout-template', 'view.jsx', 'React layer: editor wrapper, SuggestionMenu, Token DOM, Toolbar, AttachmentBar, Banner. Swap this for a Flutter widget tree; the Model & Controller contracts are identical.'],
  ];

  function Docs() {
    return h('div', { className: 'doc-wrap' },
      // architecture
      h(Sec, { id: 'arch', icon: 'layers', title: 'Architecture — MVC' },
        h(P, null, 'Three files, three roles. Only the View is framework-specific. The Model is plain data so it transcribes directly to a Flutter/Dart model layer; the Controller is a vanilla class a Flutter controller can mirror method-for-method.'),
        h('div', { className: 'doc-arch' }, ARCH.map(([t, ic, file, d]) =>
          h('div', { key: t, className: 'doc-arch__c' },
            h('div', { className: 'doc-arch__h' }, h('span', { className: 'doc-arch__ic' }, h(Icon, { name: ic, size: 15 })), t, h('code', null, file)),
            h('div', { className: 'doc-arch__d' }, d)
          ))),
        h('div', { className: 'doc-flow' },
          'types ', h('b', null, 'register()'), ' → mode ', h('b', null, 'preset'), ' → controller detects ', h('b', null, 'trigger'),
          ' → provider ', h('b', null, 'search()'), ' → ', h('b', null, 'token'), ' inserted → ', h('b', null, 'validate()'), ' → ', h('b', null, 'onSubmitted')
        )
      ),

      // models
      h(Sec, { id: 'models', icon: 'box', title: 'Core models' },
        h(P, null, 'Every reference is a ', h('code', null, 'ComposerReference'), '. The full shape (most fields optional):'),
        h(Code, null,
`ComposerReference {
  id, type, title, subtitle, description,
  icon, accent, source, metadata,
  displayText, value, url, path,
  permissions, isRemote, isLocal, isEnabled,
  state   // ready | loading | error | disabled
}

ComposerAttachment { id, type, title, subtitle, icon,
  meta, url, path, preview, state, progress }

ComposerValue { text, segments[], references[], attachments[] }
ComposerValidationResult { valid, errors[{code,message,refId}] }`),
        h(P, null, 'The editor never reads ', h('code', null, 'type'), ' directly — it resolves icon / accent / group from the registry, so a new type needs zero core changes.')
      ),

      // encoding format
      h(Sec, { id: 'encoding', icon: 'braces', title: 'Encoded text — the source of truth' },
        h(P, null, 'Composer content stores as human-readable encoded text (not JSON). plainText is derived; the editor restores from encodedText alone.'),
        h(Code, null,
`[<prefix><tagType>:<displayText>](valueText)

[@user:Ahmed](user://user_123)
[#invoice:INV-2026-001](invoice://INV-2026-001)
[$tool:Browser Use](skill://openai-bundled/browser-use/0.1.0-alpha1/browser)
[@file:client-a.pdf](file:///C:/Users/Al-saiary/contracts/client-a.pdf)`),
        h(P, null, h('code', null, 'prefix'), ' = category · ', h('code', null, 'tagType'), ' = real entity type (authoritative) · ', h('code', null, 'displayText'), ' = label only · ', h('code', null, 'valueText'), ' = system value to resolve/open. Never act on displayText.'),
        h(Code, null,
`SC.SmartComposerParser.parse(encodedText)   // -> { segments, tokens, errors, plainText }
SC.SmartComposerValue.fromEncodedText(s)    // -> { toEncodedText, toPlainText, toTokenIndex, toStorage }
SC.SmartComposerPlainTextConverter.convert(s)
SC.SmartComposerTokenIndex.extract(s)

editor.getEncodedText() / editor.setEncodedText(s)   // round-trip

// remote resolution (per-token shimmer; app owns navigation)
<SmartComposerPreview encodedText={s} resolver={async (t)=>({status,subtitle})}
   style="card" onTokenTap={(t)=>router.open(t)} />`),
        h(P, null, 'Reserved characters (', h('code', null, '[ ] ( ) \\\\'), ' newline) are backslash-escaped inside displayText/valueText; URIs keep their ', h('code', null, ':'), ' and ', h('code', null, '/'), ' raw. Invalid tokens degrade to plain text and never throw.')
      ),

      // drag & drop
      h(Sec, { id: 'dnd', icon: 'mouse-pointer-2', title: 'Drag & drop' },
        h(P, null, 'Dropped files, images, videos, documents, URLs and custom in-app resources become typed smart tokens at the drop point. The editor never uploads — it builds tokens and fires callbacks; the app decides what to do with the value.'),
        h(Code, null,
`<SmartComposer
  mode={SC.MODES.message}
  dnd={{
    allowMultiple: true,
    maxFileSize: 25 * 1024 * 1024,
    allowedExtensions: ['pdf','png','xlsx'],   // null = any
    blockedExtensions: ['exe','bat'],
    insertAtDropPosition: true,                 // caret at drop point
    generateTokenFromDropItem: (item) => SC.dropItemToToken(item),
    customValidator: (item) => ({ valid: item.size < 1e7 }),
  }}
  dropCallbacks={{
    onFilesDropped: (items) => {},
    onDroppedTokenInserted: (token, ref, item) => upload(item),
    onDropRejected: (rejections) => warn(rejections),
  }}
/>`),
        h(P, null, 'Extension/MIME map (', h('code', null, 'SC.mapExtToType'), '): images, video, document, else generic file. URLs → ', h('code', null, 'link'), '; Windows paths → ', h('code', null, 'file:///C:/…'), '. To make a UI element draggable into the composer, set ', h('code', null, "dataTransfer 'application/x-smartcomposer'"), ' to a JSON drop-item (or array). Programmatic inserts: ', h('code', null, 'insertTokenAtCursor / insertDroppedItemsAtCursor / replaceSelectionWithToken / insertTokenAtOffset'), '.')
      ),

      // add a reference type
      h(Sec, { id: 'add-type', icon: 'plus-circle', title: 'Add a reference type' },
        h(P, null, 'One registry call. The token, suggestion menu, toolbar and validation all pick it up automatically.'),
        h(Code, null,
`SC.ReferenceRegistry.register({
  type:   'contract',
  label:  'Contract',
  icon:   'file-signature',   // any Lucide name
  accent: 'orange',           // blue | green | orange | violet | red | neutral
  group:  'Legal',            // suggestion-menu section
  mono:   true                // monospace label (ids / paths)
});

// supply data for the default provider (or use a custom one, below)
SC.DATA.contract = [
  { title: 'MSA-2026-04', subtitle: 'Client A · signed', mono: true },
];`)),

      // add a trigger
      h(Sec, { id: 'add-trigger', icon: 'at-sign', title: 'Add a trigger' },
        h(P, null, 'Triggers are data. Single-char or word (', h('code', null, 'file:'), ') triggers both work; add the key to a mode\u2019s ', h('code', null, 'triggers'), ' list to enable it there.'),
        h(Code, null,
`SC.TRIGGERS['&'] = {
  symbol: '&', label: 'Contract', hint: 'legal docs',
  types: ['contract'],
  // optional per-trigger provider — overrides SC.search:
  searchProvider: async (query, types) => myApi.find(query, types),
  // optional: customise the inserted token
  tokenBuilder: (ref) => ({ ...ref, displayText: '§ ' + ref.title }),
};
SC.TRIGGER_KEYS = Object.keys(SC.TRIGGERS).sort((a,b)=>b.length-a.length);`)),

      // custom provider
      h(Sec, { id: 'provider', icon: 'search', title: 'Custom suggestion provider' },
        h(P, null, 'Return grouped results. Anything async (an API) works — the menu shows loading / empty / error states.'),
        h(Code, null,
`function myProvider(query, types) {
  return [
    { group: 'Recent', items: [ SC.createReference({type:'user', title:'Ahmed'}) ] },
    { group: 'Users',  items: results.map(r => SC.createReference({type:'user', ...r})) },
  ];
}

<SmartComposer mode={{ ...SC.MODES.aiPrompt, searchProvider: myProvider }} />`)),

      // custom token builder / theme
      h(Sec, { id: 'token', icon: 'paintbrush', title: 'Custom token & theme' },
        h(P, null, 'Tokens render from the registry def + accent. Override per-instance theme through CSS variables on ', h('code', null, '.sc-root'), ' — nothing is hardcoded.'),
        h(Code, null,
`/* per-instance theme (a ComposerTheme is just CSS vars) */
.sc-root.brand-x {
  --sc-bg: #0d1117;  --sc-accent: #7c3aed;
  --sc-radius: 16px; --sc-token-radius: 999px;  /* pill tokens */
}

/* token colors come from the accent registry */
SC.ACCENTS.brand = { fg:'#7c3aed', bg:'rgba(124,58,237,.14)',
                     bgHover:'rgba(124,58,237,.22)', border:'rgba(124,58,237,.42)' };`)),

      // callbacks
      h(Sec, { id: 'callbacks', icon: 'webhook', title: 'Callbacks — the app owns navigation' },
        h(P, null, 'The component never navigates. It calls you; you decide. Generic + typed convenience callbacks both fire.'),
        h('div', { className: 'doc-cbs' },
          ['onChanged', 'onSubmitted', 'onReferenceSelected', 'onReferenceRemoved', 'onReferenceTap', 'onAttachmentAdded', 'onAttachmentRemoved', 'onAttachmentTap', 'onSuggestionSearch', 'onCommandSelected', 'onAccessModeChanged', 'onValidationChanged', 'onTokenTap', 'onFilePathTap', 'onUserTap', 'onInvoiceTap', 'onTaskTap', 'onFinancialAccountTap', 'onCommandTap']
            .map((c) => h('code', { key: c, className: 'doc-cb' }, c))
        )
      ),

      // modes / access / states
      h(Sec, { id: 'modes', icon: 'shapes', title: 'Modes, access & state' },
        h(P, null, 'A mode only configures placeholder, live triggers, toolbar, access options and validation. The core editor is identical across all of them.'),
        h('div', { className: 'doc-cols' },
          h('div', null, h('div', { className: 'doc-coltitle' }, 'Modes'),
            h('div', { className: 'doc-chips' }, Object.keys(SC.MODES).map((m) => h('code', { key: m, className: 'doc-cb' }, m)))),
          h('div', null, h('div', { className: 'doc-coltitle' }, 'Access modes'),
            h('div', { className: 'doc-chips' }, SC.ACCESS_MODES.map((a) => h('code', { key: a.id, className: 'doc-cb' }, a.id)))),
          h('div', null, h('div', { className: 'doc-coltitle' }, 'States'),
            h('div', { className: 'doc-chips' }, ['idle', 'focused', 'typing', 'suggestionOpen', 'referenceSelected', 'attachmentAdded', 'validating', 'invalid', 'loading', 'submitting', 'submitted', 'disabled', 'readOnly', 'error'].map((s) => h('code', { key: s, className: 'doc-cb' }, s))))
        )
      ),

      // usage
      h(Sec, { id: 'usage', icon: 'code', title: 'Drop-in usage' },
        h(Code, null,
`<SmartComposer
  mode={SC.MODES.aiPrompt}          // or any custom preset
  seed={[ /* ComposerTextSegment[] */ ]}
  readOnly={false}
  callbacks={{
    onSubmitted: (value) => send(value),
    onReferenceTap: (ref) => router.open(ref),   // app decides
    onSuggestionSearch: (q, types) => track(q),
  }}
/>`),
        h('div', { className: 'doc-foot' }, '© 2026 GENIUSLINK · SMARTCOMPOSER ' + 'v' + SC.version + ' · MODEL · CONTROLLER · VIEW')
      )
    );
  }

  window.SCDocs = Docs;
})();
