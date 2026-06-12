# smart_composer_flutter

**Demo:** [geniussystems24.github.io/smart_composer_flutter](https://geniussystems24.github.io/smart_composer_flutter)

**Skill guide:** [`skills/smart_composer_flutter.md`](skills/smart_composer_flutter.md)

## Screenshots

| Simple composer | Examples |
|---|---|
| [![Simple SmartComposer example](https://raw.githubusercontent.com/GeniusSystems24/smart_composer_flutter/refs/heads/main/snapshots/simple.png)](https://geniussystems24.github.io/smart_composer_flutter) | [![SmartComposer examples screen](https://raw.githubusercontent.com/GeniusSystems24/smart_composer_flutter/refs/heads/main/snapshots/examples.png)](https://geniussystems24.github.io/smart_composer_flutter) |

| Encode / decode | Drag & drop |
|---|---|
| [![SmartComposer encode and decode screen](https://raw.githubusercontent.com/GeniusSystems24/smart_composer_flutter/refs/heads/main/snapshots/encode_decode.png)](https://geniussystems24.github.io/smart_composer_flutter) | [![SmartComposer drag and drop screen](https://raw.githubusercontent.com/GeniusSystems24/smart_composer_flutter/refs/heads/main/snapshots/drag_drop.png)](https://geniussystems24.github.io/smart_composer_flutter) |

A reusable, entity-aware **rich composer for Flutter** — a faithful port of the
GeniusLink **SmartComposer** React component.

It mixes plain text with inline **reference tokens** (users, files, invoices,
accounts, tasks, tools, commands and any custom type), backed by a
human-readable **encoded-text source of truth**, a **React-compatible parser**,
drag & drop, a read-only **preview** with remote resolution, modes, triggers,
access postures, validation and theming.

> The React project is the source of truth. This package matches it visually and
> behaviourally: same encoded text format, a parser compatible with the React
> parser, the same models, modes, triggers, examples and interactions.

---

## Features

- **One component, every entity.** Plain text interleaved with typed tokens.
  Adding a new entity type is a single `ReferenceRegistry.register(...)` call.
- **Encoded text is the source of truth.** `[<prefix><tagType>:<displayText>](valueText)`
  — human-readable, restores the editor without JSON. Byte-for-byte compatible
  with the React format.
- **Triggers** — `@` people · `#` records · `/` commands · `$` financial ·
  `:` tools · word triggers `file:` / `path:`. Triggers are data; add your own.
- **9 mode presets** — `aiPrompt`, `search`, `command`, `note`, `comment`,
  `taskDescription`, `invoiceNote`, `financialEntry`, `message`.
- **Floating suggestion menu** with grouped results, keyboard nav and a custom
  provider hook (sync or async).
- **Drag & drop** files / URLs / custom resources → typed tokens, with
  validation (size, extension, MIME, blocked types).
- **Read-only preview** (`SmartComposerPreview`) with per-token **remote
  resolution** states: loading / resolved / notFound / permissionDenied /
  deleted / error + retry.
- **Validation** — required text, max length, max attachments, required /
  allowed reference types, entity-state (archived / unavailable) checks.
- **Access postures & model picker** in the toolbar.
- **Theming** — GeniusLink dark + light themes out of the box; override any token
  via `ComposerTheme`.
- The component **never navigates** — it fires callbacks; your app decides.

---

## Install

```yaml
dependencies:
  smart_composer_flutter:
    path: ../smart_composer_flutter   # or a pub/git ref
```

```dart
import 'package:smart_composer_flutter/smart_composer_flutter.dart';

void main() {
  ReferenceRegistry.ensureDefaults(); // install the default entity types
  runApp(const MyApp());
}
```

---

## Quick start

```dart
SmartComposer(
  mode: ComposerModes.aiPrompt,
  callbacks: ComposerCallbacks(
    onSubmitted: (value) => print(value.encodedText),
    onReferenceTap: (ref) => openEntity(ref), // app decides navigation
  ),
);
```

Wrap your app (or any subtree) in a `ComposerThemeScope` to theme it:

```dart
ComposerThemeScope(
  theme: ComposerTheme.dark(), // or ComposerTheme.light()
  child: SmartComposer(mode: ComposerModes.message),
);
```

---

## Encoded text format

```
[<prefix><tagType>:<displayText>](valueText)

[@user:Ahmed](user://user_123)
[#invoice:INV-2026-001](invoice://INV-2026-001)
[$tool:Browser Use](skill://openai-bundled/browser-use/0.1.0-alpha1/browser)
[@file:client-a.pdf](file:///C:/Users/Al-saiary/contracts/client-a.pdf)
```

- `prefix` — category / trigger style
- `tagType` — the **authoritative** entity type
- `displayText` — label only (never act on it)
- `valueText` — the system value to resolve / open

```dart
final result = SmartComposerParser.parse(encoded); // segments, tokens, errors, plainText
final value  = SmartComposerValue.fromEncodedText(encoded);
value.toPlainText();
value.toTokenIndex();
value.toStorage();
SmartComposerPlainTextConverter.convert(encoded);
SmartComposerTokenIndex.extract(encoded);
```

Reserved characters (`[ ] ( ) \` and newline) are backslash-escaped inside
`displayText` / `valueText`; URIs keep their `:` and `/` raw. Invalid tokens
degrade to plain text and never throw.

---

## Preview & remote resolution

```dart
SmartComposerPreview(
  encodedText: encoded,
  resolver: (token) async {
    final r = await api.lookup(token.valueText);
    if (r == null) return const ResolveResult(state: ResolveState.notFound);
    return ResolveResult(state: ResolveState.resolved, subtitle: r.status);
  },
  onTokenTap: (token) => router.open(token),
);
```

A demo resolver is included: `makeDemoResolver(delay: 800)`.

---

## Architecture (MVC, matches the React source)

| Layer | Where | Role |
|---|---|---|
| **Model** | `lib/src/model/` | Pure data + functions — registry, modes, triggers, access modes, sample providers, validation. |
| **Encoding** | `lib/src/encoding/` | React-compatible parser, serializer, value, token, bridge. |
| **Controller** | `lib/src/controller/composer_controller.dart` | `ComposerController` (`ChangeNotifier`) owns the editing surface, triggers, tokens, suggestions, submit. |
| **Widgets** | `lib/src/widgets/` | `SmartComposer`, suggestion menu, toolbar, attachment bar, banner, token chips. |
| **Preview** | `lib/src/preview/` | `SmartComposerPreview` + resolver model + demo resolver. |

Flow: `types register()` → `mode preset` → controller detects `trigger` →
provider `search()` → `token` inserted → `validate()` → `onSubmitted`.

---

## Example app

`example/` reproduces the React showcase one-to-one — six tabs: **Playground**,
**Examples** (8 ready-made configs), **Encoding**, **Drag & Drop**, **Tests**
and **Docs / API**.

```bash
cd example
flutter run
```

---

## Tests

```bash
flutter test
```

- `test/encoding_test.dart` — the encoding suite, mirroring React `SC.runTests()`
  case-for-case (parser compatibility).
- `test/controller_test.dart` — controller behaviour (insert, validate, drop, submit).
- `test/widget_test.dart` — widget rendering & interaction.

The same suite is also available at runtime via `runComposerTests()` (rendered by
the example **Tests** tab).

---

## AI skill

A copy-paste agent skill describing how to use this package lives at
[`skills/smart_composer_flutter.md`](skills/smart_composer_flutter.md).

---

## License

MIT © GeniusLink

