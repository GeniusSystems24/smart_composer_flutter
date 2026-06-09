# Changelog

All notable changes to **smart_composer_flutter** are documented here. The
format is based on [Keep a Changelog](https://keepachangelog.com/) and this
project adheres to [Semantic Versioning](https://semver.org/).

## [1.0.0] — 2026-06-09

Initial release — a faithful Flutter port of the GeniusLink SmartComposer React
component. Visual and behavioural parity with the React source.

### Added

- **Model layer** (`lib/src/model/`)
  - `ComposerAccents` — the disciplined 6-hue accent registry.
  - `ReferenceRegistry` / `ReferenceType` with the default GeniusLink entity types.
  - `ComposerReference`, `ComposerAttachment`, `ComposerSegment`.
  - `Triggers` (`@ # / $ :` + word triggers `file:` / `path:`).
  - `AccessModes` (full / limited / ask-first / no-external / read-only).
  - `ComposerModes` — 9 presets (aiPrompt, search, command, note, comment,
    taskDescription, invoiceNote, financialEntry, message).
  - `SampleData` + `ComposerSearch` default suggestion provider.
  - `ComposerValidator` with entity-state validation.
  - `ComposerSeed` (`seedSegments` / `guessType`).
- **Encoding layer** (`lib/src/encoding/`) — React-compatible
  - `SmartComposerParser` (parser), `SmartComposerSerializer`,
    `SmartComposerValue`, `SmartComposerPlainTextConverter`,
    `SmartComposerTokenIndex`, `ComposerBridge`, `EncodingUtil`.
  - Same encoded text format as React: `[<prefix><tagType>:<displayText>](valueText)`.
- **Drag & drop** (`lib/src/dnd/`) — `ComposerDnd`, `DropConfig`, `DropItem`,
  `SmartComposerDropValidator`, extension/MIME mapping, URL & path handling.
- **Controller** (`lib/src/controller/`) — `ComposerController` (`ChangeNotifier`),
  `ComposerCallbacks`, `DropCallbacks`, `ComposerEditorValue`.
- **Widgets** (`lib/src/widgets/`) — `SmartComposer`, `SuggestionMenu`,
  `ComposerToolbar`, `AttachmentBar`, `ComposerBanner`, `ComposerTokenChip`,
  `ComposerIcons`.
- **Preview** (`lib/src/preview/`) — `SmartComposerPreview`,
  `PreviewResolverModel`, `TokenResolver`, `ResolveResult`, `makeDemoResolver`.
- **Theme** — `ComposerTheme` (GeniusLink dark + light), `ComposerThemeScope`.
- **Testing utility** — `runComposerTests()` (mirrors React `SC.runTests()`).
- **Example app** (`example/`) — six-tab showcase matching the React example:
  Playground, Examples, Encoding, Drag & Drop, Tests, Docs / API.
- **Tests** — encoding, controller and widget tests.
- **AI skill** — `skills/smart_composer_flutter.md`.
