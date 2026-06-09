---
name: smart_composer_flutter
description: >-
  How to use the smart_composer_flutter package — an entity-aware rich composer
  for Flutter (a port of the GeniusLink SmartComposer React component). Mixes
  plain text with inline reference tokens, with a React-compatible encoded-text
  format, a parser, a read-only preview with remote resolution, drag & drop,
  modes, triggers, access postures, validation and theming. Use this when
  building a Flutter chat box, AI prompt input, comment field, task description,
  invoice note, financial entry, or any input that must reference entities
  (users, files, invoices, accounts, tasks, tools, commands, …).
---

# SmartComposer for Flutter

`smart_composer_flutter` is a reusable Flutter widget for composing text that
contains **typed inline references** ("tokens"). It is a faithful port of the
GeniusLink **SmartComposer** React component — same encoded format, same models,
same behaviour.

The golden rule: **the component never navigates.** It mixes text + tokens,
parses/serializes the encoded format, validates, and fires callbacks. Your app
decides what tapping a token, submitting, or dropping a file means.

---

## 1. Package overview

```
import 'package:smart_composer_flutter/smart_composer_flutter.dart';
```

Layers (all exported from the single barrel above):

- **Model** — `ReferenceRegistry`, `ReferenceType`, `ComposerReference`,
  `ComposerAttachment`, `ComposerSegment`, `Triggers`, `TriggerConfig`,
  `AccessModes`, `ComposerModes`/`ComposerMode`, `SampleData`, `ComposerSearch`,
  `ComposerValidator`, `ComposerSeed`, `ComposerAccents`.
- **Encoding (React-compatible)** — `SmartComposerParser`,
  `SmartComposerSerializer`, `SmartComposerValue`,
  `SmartComposerPlainTextConverter`, `SmartComposerTokenIndex`,
  `ComposerBridge`, `EncodingUtil`, `SmartComposerToken`, `ResolveState`.
- **Drag & drop** — `ComposerDnd`, `DropConfig`, `DropItem`,
  `SmartComposerDropValidator`, `DropValidationResult`.
- **Controller** — `ComposerController` (`ChangeNotifier`), `ComposerCallbacks`,
  `DropCallbacks`, `ComposerEditorValue`.
- **Widgets** — `SmartComposer`, `SmartComposerPreview`, `ComposerToolbar`,
  `SuggestionMenu`, `AttachmentBar`, `ComposerTokenChip`, `ComposerIcons`.
- **Preview** — `SmartComposerPreview`, `PreviewResolverModel`,
  `TokenResolver`, `ResolveResult`, `makeDemoResolver`, `kPreviewStyles`.
- **Theme** — `ComposerTheme`, `ComposerThemeScope`.
- **Testing** — `runComposerTests()` returns a `TestRun`.

Call once at startup to install the default entity types:

```dart
ReferenceRegistry.ensureDefaults();
```

---

## 2. The main components

### `SmartComposer` — the editable composer

```dart
SmartComposer(
  mode: ComposerModes.aiPrompt,        // any preset or custom ComposerMode
  seed: const [],                      // optional List<ComposerSegment>
  readOnly: false,
  attachments: const [],               // optional List<ComposerAttachment>
  searchProvider: null,                // optional custom provider
  callbacks: ComposerCallbacks(
    onChanged: (v) {},
    onSubmitted: (v) => send(v.encodedText),
    onReferenceTap: (ref) => router.open(ref),
  ),
  dropCallbacks: const DropCallbacks(),
  dnd: const DropConfig(),
  onReady: (controller) => _api = controller, // grab the controller
);
```

`onReady` hands you the `ComposerController` for programmatic control
(`setEncodedText`, `getEncodedText`, `clear`, `openTrigger`, `insertReference`,
`insertTokenAtCursor`, `submit`, …). You may also create the controller yourself
and pass it via `controller:`.

### `SmartComposerPreview` — read-only render

```dart
SmartComposerPreview(
  encodedText: '[@user:Ahmed](user://user_123) shipped it',
  resolver: makeDemoResolver(),   // optional remote resolution
  onTokenTap: (token) => router.open(token),
);
```

### Theming

```dart
ComposerThemeScope(
  theme: ComposerTheme.dark(),    // or ComposerTheme.light()
  child: SmartComposer(mode: ComposerModes.message),
);
```

`ComposerThemeScope.of(context)` returns the active `ComposerTheme` (defaults to
dark when none is provided).

---

## 3. The encoded text format (the source of truth)

```
[<prefix><tagType>:<displayText>](valueText)
```

| Part | Meaning |
|---|---|
| `prefix` | category / trigger style (`@ # / $`) — presentation only |
| `tagType` | the **authoritative** entity type (`user`, `invoice`, …) |
| `displayText` | the human label — **never act on it** |
| `valueText` | the system value to resolve / open (a URI) |

Examples:

```
[@user:Ahmed](user://user_123)
[#invoice:INV-2026-001](invoice://INV-2026-001)
[$financialAccount:Main Bank Account](financial-account://main_bank_account)
[$tool:Browser Use](skill://openai-bundled/browser-use/0.1.0-alpha1/browser)
[@file:client-a.pdf](file:///C:/Users/Al-saiary/contracts/client-a.pdf)
```

Reserved characters (`[ ] ( ) \` and newline) are backslash-escaped inside
`displayText` / `valueText`. URIs keep `:` and `/` raw. **Invalid tokens degrade
to plain text and never throw.** This format is byte-for-byte identical to the
React version, so encoded strings move freely between the two.

---

## 4. Parser & preview

```dart
// parse
final result = SmartComposerParser.parse(encoded);
result.segments;  // List<ParsedSegment> (text | token), in order
result.tokens;    // List<SmartComposerToken>
result.errors;    // List<ParseError> (collected, never thrown)
result.plainText; // tokens flattened to their displayText

// value object — restores the editor from encodedText alone, no JSON
final value = SmartComposerValue.fromEncodedText(encoded);
value.toEncodedText();
value.toPlainText();
value.toTokenIndex();   // List<TokenIndexEntry>
value.toStorage();      // { encodedText, plainText, tokensIndex }

// helpers
SmartComposerPlainTextConverter.convert(encoded);
SmartComposerTokenIndex.extract(encoded);

// serialize back
SmartComposerSerializer.tokenToEncoded(token);
SmartComposerSerializer.serializeSegments(result.segments);
```

### Remote resolution in the preview

A `TokenResolver` is `(SmartComposerToken) => FutureOr<ResolveResult>`:

```dart
SmartComposerPreview(
  encodedText: encoded,
  resolver: (token) async {
    final row = await api.lookup(token.valueText);
    if (row == null) return const ResolveResult(state: ResolveState.notFound);
    if (!row.allowed) return const ResolveResult(state: ResolveState.permissionDenied);
    return ResolveResult(
      state: ResolveState.resolved,
      displayText: row.name,   // optional enrich
      subtitle: row.status,
    );
  },
  onTokenTap: (token) => router.open(token),
);
```

`ResolveState`: `idle`, `loading`, `resolved`, `error`, `notFound`,
`permissionDenied`, `deleted`, `disabled`. The preview reflects each inline
(shimmer / lock / strike-through / retry) without blocking the surrounding text.

---

## 5. Themes

`ComposerTheme.dark()` and `ComposerTheme.light()` reproduce the GeniusLink
tokens (electric royal-blue accent `#4A7CFF`, near-black surfaces, Manrope /
Inter / JetBrains Mono). Override fields by constructing a `ComposerTheme`
directly, then provide it via `ComposerThemeScope`. Token colours come from
`ComposerAccents` (`blue green orange violet red neutral`); add your own:

```dart
ComposerAccents.all['brand'] = ComposerAccent.fromHex(0x7C3AED);
```

Icons are resolved by name through `ComposerIcons` (Lucide-style names mapped to
Material glyphs). Plug a different icon set with
`ComposerIcons.resolver = (name) => myIconData(name);`.

---

## 6. Tokens, resolving, drag/drop & errors

### Add a reference type (one call — token, menu, toolbar, validation all update)

```dart
ReferenceRegistry.register(const ReferenceType(
  type: 'contract',
  label: 'Contract',
  icon: 'file-text',
  accent: 'orange',
  group: 'Legal',
  mono: true,
));
SampleData.data['contract'] = [
  {'title': 'MSA-2026-04', 'subtitle': 'Client A · signed', 'mono': true},
];
```

### Add a trigger

```dart
Triggers.all['&'] = TriggerConfig(
  symbol: '&', label: 'Contract', hint: 'legal docs',
  types: ['contract'],
  searchProvider: (q, types, opts) async => myApi.find(q, types), // optional
  tokenBuilder: (ref) => ref.copyWith(displayText: '§ ${ref.title}'), // optional
);
```

### Custom suggestion provider

```dart
FutureOr<List<SuggestionGroup>> myProvider(
    String query, List<String> types, Map<String, dynamic> opts) async {
  final rows = await api.search(query, types);
  return [
    SuggestionGroup(group: 'Users', items: rows.map((r) =>
      ComposerReference(type: 'user', title: r.name, subtitle: r.role)).toList()),
  ];
}

SmartComposer(mode: ComposerModes.aiPrompt, searchProvider: myProvider);
```

### Programmatic token insertion (via the controller)

```dart
controller.insertReference(ComposerReference(type: 'task', title: 'Prepare Report'));
controller.insertEncodedTokenAtCursor('[@user:Ahmed](user://user_123)');
controller.insertTokenAtCursor(token);
controller.setEncodedText('[#invoice:INV-1](invoice://INV-1) due');
final encoded = controller.getEncodedText();
```

### Drag & drop

```dart
SmartComposer(
  mode: ComposerModes.message,
  dnd: const DropConfig(
    allowMultiple: true,
    maxFileSize: 25 * 1024 * 1024,
    allowedExtensions: ['pdf', 'png', 'xlsx'], // null = any
    blockedExtensions: ['exe', 'bat'],
  ),
  dropCallbacks: DropCallbacks(
    onFilesDropped: (items) {},
    onDroppedTokenInserted: (token, ref, item) => upload(item),
    onDropRejected: (rejections) => warn(rejections),
  ),
);
```

Make any widget a drop source:

```dart
Draggable<List<DropItem>>(
  data: [ComposerDnd.makeDropItem({'name': 'a.pdf', 'path': 'C:\\docs\\a.pdf', 'size': 1200})],
  feedback: chip,
  child: chip,
);
```

`ComposerDnd.makeDropItemFromUrl(url)` turns a URL into a `link` token;
`ComposerDnd.mapExtToType(ext, mime)` resolves image/video/document/file;
Windows paths become `file:///C:/…`.

### Errors & validation

```dart
final res = controller.validation; // ComposerValidationResult
if (!res.valid) {
  for (final e in res.errors) print('${e.code}: ${e.message}');
}
```

`submit()` only fires `onSubmitted` when valid; otherwise it fires
`onValidationChanged` and the in-composer banner shows the first error. Rules
come from the mode (`maxLength`, `requireText`, `maxAttachments`,
`requireReferenceType`, `allowedReferenceTypes`) plus entity-state checks
(a token in `error` state → "unavailable", `disabled` → "archived").

### Callbacks (the app owns navigation)

`onChanged`, `onSubmitted`, `onReferenceSelected`, `onReferenceRemoved`,
`onReferenceTap`, `onAttachmentAdded`, `onAttachmentRemoved`, `onAttachmentTap`,
`onSuggestionSearch`, `onCommandSelected`, `onAccessModeChanged`,
`onValidationChanged`, `onTokenTap`, and typed convenience callbacks
`onFilePathTap`, `onUserTap`, `onInvoiceTap`, `onTaskTap`,
`onFinancialAccountTap`, `onCommandTap`.

---

## 7. All examples (copy-paste Flutter snippets)

These match the example app's **Examples** gallery one-to-one. Each is the same
core component under a different mode preset.

Helpers used below:

```dart
ComposerSegment _t(String text) => ComposerSegment.text(text);
ComposerSegment _r(String type, {String title = '', String subtitle = '', String path = ''}) =>
    ComposerSegment.ref(ComposerReference(
      type: type, title: title, displayText: title, subtitle: subtitle, path: path));
```

### AI Prompt Composer

```dart
SmartComposer(
  mode: ComposerModes.aiPrompt,
  seed: [
    _t('Use '), _r('skill', title: 'Reconciliation'),
    _t(' on '), _r('file', title: 'q4-reconciliation.xlsx', path: 'finance/q4-reconciliation.xlsx'),
    _t(' and brief '),
  ],
  callbacks: ComposerCallbacks(onSubmitted: (v) => runPrompt(v.encodedText)),
);
```

### File Path Composer

```dart
SmartComposer(
  mode: ComposerModes.note,
  seed: [
    _t('Open '), _r('file', title: 'contracts/client-a.pdf', path: 'contracts/client-a.pdf', subtitle: 'remote'),
    _t(' next to '), _r('folder', title: 'finance/', path: 'finance/'),
  ],
  callbacks: ComposerCallbacks(onFilePathTap: (r) => preview(r.path)),
);
```

### Invoice Note Composer

```dart
SmartComposer(
  mode: ComposerModes.invoiceNote,
  seed: [
    _t('Reviewed '), _r('invoice', title: 'INV-2026-001', subtitle: '\$5,240.00'),
    _t(' against '), _r('financialAccount', title: 'Main Bank Account'), _t('.'),
  ],
);
```

### Financial Account Reference

```dart
SmartComposer(
  mode: ComposerModes.financialEntry, // requires a financialAccount/bankAccount
  seed: [
    _t('Settle '), _r('transaction', title: 'TR-9042', subtitle: '\$5,000.00'),
    _t(' from '), _r('bankAccount', title: 'Al-Rajhi · ****6612'),
  ],
);
```

### Task Description Composer

```dart
SmartComposer(
  mode: ComposerModes.taskDescription,
  seed: [
    _t('Assign '), _r('task', title: 'Prepare Report'),
    _t(' to '), _r('user', title: 'Ahmed Al-Rashid', subtitle: 'Finance'), _t(' — due Friday.'),
  ],
);
```

### User Mention Composer

```dart
SmartComposer(
  mode: ComposerModes.comment, // only @, requires text
  seed: [
    _t('Great work '), _r('user', title: 'Sara Khan', subtitle: 'Accountant'),
    _t(' — can you confirm the figures?'),
  ],
);
```

### Command Composer

```dart
SmartComposer(
  mode: ComposerModes.command, // slash-only, validates a command was chosen
  seed: [_r('command', title: 'assign', subtitle: 'Assign to user'), _t(' ')],
);
```

### Mixed References Composer (every entity type)

```dart
SmartComposer(
  mode: ComposerModes.aiPrompt,
  seed: ComposerSeed.seedSegments(
    'Review invoice [INV-2026-001], compare it with account [Main Bank Account], '
    'assign task [Prepare Report] to user [Ahmed], and attach file [contracts/client-a.pdf].',
  ),
);
```

### Playground-style value inspector

```dart
SmartComposer(
  mode: ComposerModes.aiPrompt,
  callbacks: ComposerCallbacks(
    onChanged: (v) {
      print(v.encodedText);          // source of truth
      print(v.plainText);            // derived
      print(v.references.length);    // tokens index
    },
  ),
);
```

### Encoding round-trip (editor ⇄ encoded text)

```dart
late ComposerController api;
SmartComposer(
  mode: ComposerModes.aiPrompt,
  seed: ComposerBridge.encodedToSegments(encoded),
  onReady: (c) => api = c,
);
// load a new encoded string into the editor:
api.setEncodedText(encoded);
// read the editor back out:
final out = api.getEncodedText();
```

### Encoded ⇄ preview with live resolution

```dart
SmartComposerPreview(
  encodedText: encoded,
  resolver: makeDemoResolver(delay: 800),
  onTokenTap: (t) => router.open(t),
);
```

### Drag & drop demo (tray → composer)

```dart
final dropItem = ComposerDnd.makeDropItem({
  'type': 'image', 'name': 'storefront-render.png',
  'size': 1258291, 'mimeType': 'image/png',
  'uri': 'file:///assets/storefront-render.png',
});

Draggable<List<DropItem>>(
  data: [dropItem],
  feedback: const Icon(Icons.image),
  child: const Icon(Icons.image),
);

SmartComposer(
  mode: ComposerModes.message,
  dnd: const DropConfig(maxFileSize: 25 * 1024 * 1024, allowMultiple: true),
  dropCallbacks: DropCallbacks(
    onDroppedTokenInserted: (tok, ref, item) => print('${tok.prefix}${tok.tagType} · ${tok.displayText}'),
    onDropRejected: (rej) => print(rej.first.errors.first.message),
  ),
  seed: ComposerBridge.encodedToSegments('Please review these before the audit: '),
);
```

### Running the encoding test suite at runtime

```dart
final run = runComposerTests();
print('${run.pass}/${run.total} passing');
for (final r in run.results.where((r) => !r.pass)) {
  print('${r.group} · ${r.name}: ${r.detail}');
}
```

---

## 8. Mode reference

`ComposerModes.byId['…']` or the named getters:

| id | triggers | toolbar highlights | validation |
|---|---|---|---|
| `aiPrompt` | `@ # / $ : file: path:` | attach, reference, command, model, access, send | maxLength 4000 |
| `search` | `@ # $ :` | reference, send | — |
| `command` | `/` | command, send | requires a `command` |
| `note` | `@ # file: path:` | attach, reference, send | requireText, maxLength 2000 |
| `comment` | `@` | attach, send | requireText, maxLength 1000 |
| `taskDescription` | `@ # /` | attach, reference, assignee, send | requireText, ≤10 attachments |
| `invoiceNote` | `$ # @` | reference, access, send | allowed types only |
| `financialEntry` | `$ #` | reference, access, send | requires an account |
| `message` | `@ : file:` | attach, reference, send | ≤6 attachments |

A mode only configures placeholder, live triggers, toolbar, access options and
validation — the core editor is identical across all of them. Build a custom one
with `ComposerMode(...)` or `someMode.copyWith(...)`.
