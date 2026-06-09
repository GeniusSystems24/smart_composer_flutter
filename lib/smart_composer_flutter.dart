/// SmartComposer for Flutter — a reusable, entity-aware rich composer.
///
/// A faithful port of the GeniusLink SmartComposer React component. It mixes
/// plain text with inline reference tokens (users, files, invoices, accounts,
/// tasks, tools, commands and any custom type), with a human-readable encoded
/// text source of truth, a React-compatible parser, drag & drop, a read-only
/// preview with remote resolution, modes, triggers, access postures, validation
/// and theming.
///
/// ```dart
/// import 'package:smart_composer_flutter/smart_composer_flutter.dart';
///
/// SmartComposer(
///   mode: ComposerModes.aiPrompt,
///   callbacks: ComposerCallbacks(
///     onSubmitted: (v) => print(v.encodedText),
///   ),
/// );
/// ```
library smart_composer_flutter;

// ---- model ----
export 'src/model/accents.dart';
export 'src/model/reference_registry.dart';
export 'src/model/reference.dart';
export 'src/model/attachment.dart';
export 'src/model/triggers.dart';
export 'src/model/access_modes.dart';
export 'src/model/modes.dart';
export 'src/model/sample_data.dart';
export 'src/model/search.dart';
export 'src/model/validation.dart';
export 'src/model/segment.dart';
export 'src/model/seeding.dart';

// ---- encoding (React-compatible) ----
export 'src/encoding/token.dart';
export 'src/encoding/encoding_util.dart';
export 'src/encoding/parser.dart';
export 'src/encoding/serializer.dart';
export 'src/encoding/value.dart';
export 'src/encoding/bridge.dart';

// ---- drag & drop ----
export 'src/dnd/dnd.dart';

// ---- controller ----
export 'src/controller/callbacks.dart';
export 'src/controller/composer_controller.dart';

// ---- theme ----
export 'src/theme/composer_theme.dart';

// ---- widgets ----
export 'src/widgets/smart_composer.dart';
export 'src/widgets/composer_icons.dart';
export 'src/widgets/token_chip.dart';
export 'src/widgets/suggestion_menu.dart';
export 'src/widgets/toolbar.dart';
export 'src/widgets/attachment_bar.dart';

// ---- preview ----
export 'src/preview/preview_resolver.dart';
export 'src/preview/smart_composer_preview.dart';
export 'src/preview/demo_resolver.dart';

// ---- testing utilities ----
export 'src/testing/test_suite.dart';
