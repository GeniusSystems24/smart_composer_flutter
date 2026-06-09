import 'package:flutter/material.dart';
import 'package:smart_composer_flutter/smart_composer_flutter.dart';

import '../ui.dart';

/// The Docs / API tab — architecture, models, encoding, drag & drop, extension
/// points, callbacks, modes and drop-in usage. Mirrors `Docs` in docs.jsx, with
/// Flutter/Dart code snippets in place of the React/JS ones.
class DocsTab extends StatelessWidget {
  const DocsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ComposerThemeScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sec(theme, 'layers', 'Architecture — MVC', [
          _p(theme, 'Layered like the React original: a pure Model (data + functions, no widgets), a ChangeNotifier Controller that owns the editing surface, and a thin Widget layer. Only the widgets are Flutter-specific; the Model and Controller contracts match the React source one-to-one.'),
          _arch(theme),
          _flow(theme),
        ]),
        _sec(theme, 'box', 'Core models', [
          _p(theme, 'Every reference is a ComposerReference. The full shape (most fields optional):'),
          _code(theme, '''ComposerReference(
  id, type, title, subtitle, description,
  icon, accent, source, metadata,
  displayText, value, url, path,
  permissions, isRemote, isLocal, isEnabled,
  state, // ready | loading | error | disabled
);

ComposerAttachment(id, type, title, subtitle, icon,
  meta, url, path, preview, state, progress);

ComposerEditorValue(text, segments, references, attachments,
  encodedText, plainText);
ComposerValidationResult(valid, errors[ValidationError(code, message, refId)]);'''),
          _p(theme, 'The editor never reads type directly — it resolves icon / accent / group from ReferenceRegistry, so a new type needs zero core changes.'),
        ]),
        _sec(theme, 'braces', 'Encoded text — the source of truth', [
          _p(theme, 'Composer content stores as human-readable encoded text (not JSON). plainText is derived; the editor restores from encodedText alone. The format is byte-for-byte identical to the React version.'),
          _code(theme, '''[<prefix><tagType>:<displayText>](valueText)

[@user:Ahmed](user://user_123)
[#invoice:INV-2026-001](invoice://INV-2026-001)
[\$tool:Browser Use](skill://openai-bundled/browser-use/0.1.0-alpha1/browser)
[@file:client-a.pdf](file:///C:/Users/Al-saiary/contracts/client-a.pdf)'''),
          _p(theme, 'prefix = category · tagType = real entity type (authoritative) · displayText = label only · valueText = system value to resolve/open. Never act on displayText.'),
          _code(theme, '''SmartComposerParser.parse(encodedText);   // -> ParseResult(segments, tokens, errors, plainText)
SmartComposerValue.fromEncodedText(s);    // -> toEncodedText / toPlainText / toTokenIndex / toStorage
SmartComposerPlainTextConverter.convert(s);
SmartComposerTokenIndex.extract(s);

controller.getEncodedText();              // round-trip
controller.setEncodedText(s);

// remote resolution (per-token shimmer; app owns navigation)
SmartComposerPreview(
  encodedText: s,
  resolver: (t) async => ResolveResult(state: ResolveState.resolved, subtitle: '…'),
  onTokenTap: (t) => router.open(t),
);'''),
          _p(theme, 'Reserved characters ([ ] ( ) \\ newline) are backslash-escaped inside displayText/valueText; URIs keep their : and / raw. Invalid tokens degrade to plain text and never throw.'),
        ]),
        _sec(theme, 'mouse-pointer-2', 'Drag & drop', [
          _p(theme, 'Dropped files, images, videos, documents, URLs and custom in-app resources become typed smart tokens at the drop point. The editor never uploads — it builds tokens and fires callbacks; the app decides what to do with the value.'),
          _code(theme, '''SmartComposer(
  mode: ComposerModes.message,
  dnd: DropConfig(
    allowMultiple: true,
    maxFileSize: 25 * 1024 * 1024,
    allowedExtensions: ['pdf', 'png', 'xlsx'], // null = any
    blockedExtensions: ['exe', 'bat'],
    insertAtDropPosition: true,
    generateTokenFromDropItem: (item) => ComposerDnd.dropItemToToken(item),
    customValidator: (item) => DropValidationResult(
      valid: item.size < 10000000, errors: const [],
    ),
  ),
  dropCallbacks: DropCallbacks(
    onFilesDropped: (items) {},
    onDroppedTokenInserted: (token, ref, item) => upload(item),
    onDropRejected: (rejections) => warn(rejections),
  ),
);'''),
          _p(theme, 'Extension/MIME map (ComposerDnd.mapExtToType): images, video, document, else generic file. URLs → link; Windows paths → file:///C:/…. Make a UI element draggable by wrapping it in a Draggable<List<DropItem>>. Programmatic inserts: insertTokenAtCursor / insertDroppedItemsAtCursor / replaceSelectionWithToken / insertTokenAtOffset.'),
        ]),
        _sec(theme, 'plus-circle', 'Add a reference type', [
          _p(theme, 'One registry call. The token, suggestion menu, toolbar and validation all pick it up automatically.'),
          _code(theme, '''ReferenceRegistry.register(const ReferenceType(
  type: 'contract',
  label: 'Contract',
  icon: 'file-text',   // any ComposerIcons name
  accent: 'orange',    // blue | green | orange | violet | red | neutral
  group: 'Legal',      // suggestion-menu section
  mono: true,          // monospace label (ids / paths)
));

// supply data for the default provider (or use a custom one, below)
SampleData.data['contract'] = [
  {'title': 'MSA-2026-04', 'subtitle': 'Client A · signed', 'mono': true},
];'''),
        ]),
        _sec(theme, 'at-sign', 'Add a trigger', [
          _p(theme, 'Triggers are data. Single-char or word (file:) triggers both work; add the key to a mode\u2019s triggers list to enable it there.'),
          _code(theme, '''Triggers.all['&'] = TriggerConfig(
  symbol: '&', label: 'Contract', hint: 'legal docs',
  types: ['contract'],
  // optional per-trigger provider — overrides ComposerSearch.search:
  searchProvider: (query, types, opts) async => myApi.find(query, types),
  // optional: customise the inserted token
  tokenBuilder: (ref) => ref.copyWith(displayText: '§ \${ref.title}'),
);'''),
        ]),
        _sec(theme, 'search', 'Custom suggestion provider', [
          _p(theme, 'Return grouped results. Anything async (an API) works — the menu shows loading / empty states.'),
          _code(theme, '''FutureOr<List<SuggestionGroup>> myProvider(
    String query, List<String> types, Map<String, dynamic> opts) {
  return [
    SuggestionGroup(group: 'Recent', items: [ComposerReference(type: 'user', title: 'Ahmed')]),
    SuggestionGroup(group: 'Users', items: results.map((r) => ComposerReference(type: 'user', title: r.name)).toList()),
  ];
}

SmartComposer(mode: ComposerModes.aiPrompt, searchProvider: myProvider);'''),
        ]),
        _sec(theme, 'paintbrush', 'Custom token & theme', [
          _p(theme, 'Tokens render from the registry def + accent. Override per-instance theme by wrapping in a ComposerThemeScope — nothing is hardcoded.'),
          _code(theme, '''// per-instance theme (override any ComposerTheme field)
ComposerThemeScope(
  theme: ComposerTheme.dark().copyWith /* or build your own */,
  child: SmartComposer(mode: ComposerModes.aiPrompt),
);

// token colors come from the accent registry
ComposerAccents.all['brand'] = ComposerAccent.fromHex(0x7C3AED);'''),
        ]),
        _sec(theme, 'webhook', 'Callbacks — the app owns navigation', [
          _p(theme, 'The component never navigates. It calls you; you decide. Generic + typed convenience callbacks both fire.'),
          _chips(theme, const [
            'onChanged', 'onSubmitted', 'onReferenceSelected', 'onReferenceRemoved', 'onReferenceTap',
            'onAttachmentAdded', 'onAttachmentRemoved', 'onAttachmentTap', 'onSuggestionSearch',
            'onCommandSelected', 'onAccessModeChanged', 'onValidationChanged', 'onTokenTap',
            'onFilePathTap', 'onUserTap', 'onInvoiceTap', 'onTaskTap', 'onFinancialAccountTap', 'onCommandTap',
          ]),
        ]),
        _sec(theme, 'shapes', 'Modes, access & state', [
          _p(theme, 'A mode only configures placeholder, live triggers, toolbar, access options and validation. The core editor is identical across all of them.'),
          _threeCols(theme),
        ]),
        _sec(theme, 'code', 'Drop-in usage', [
          _code(theme, '''SmartComposer(
  mode: ComposerModes.aiPrompt,          // or any custom preset
  seed: const [ /* ComposerSegment list */ ],
  readOnly: false,
  callbacks: ComposerCallbacks(
    onSubmitted: (value) => send(value),
    onReferenceTap: (ref) => router.open(ref),   // app decides
    onSuggestionSearch: (q, types) => track(q),
  ),
);'''),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text('© 2026 GENIUSLINK · SMARTCOMPOSER v$kSmartComposerVersion · MODEL · CONTROLLER · VIEW',
                style: TextStyle(color: theme.fg3, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          ),
        ]),
      ],
    );
  }

  Widget _sec(ComposerTheme theme, String icon, String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: theme.accent.withOpacity(0.14), borderRadius: BorderRadius.circular(7)),
                child: Icon(ComposerIcons.resolve(icon), size: 16, color: theme.accent),
              ),
              const SizedBox(width: 10),
              Text(title, style: TextStyle(color: theme.fg1, fontSize: 18, fontWeight: FontWeight.w700, fontFamily: theme.displayFont)),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _p(ComposerTheme theme, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(text, style: TextStyle(color: theme.fg2, fontSize: 13.5, height: 1.6)),
      );

  Widget _code(ComposerTheme theme, String code) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.bg2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.borderSoft),
        ),
        child: SelectableText(code, style: TextStyle(fontFamily: theme.monoFont, fontSize: 12, height: 1.55, color: theme.fg2)),
      );

  Widget _arch(ComposerTheme theme) {
    const arch = [
      ['Model', 'database', 'lib/src/model/', 'Pure data + pure functions — no widgets. Registry, modes, triggers, access modes, sample providers, validation. Ports from the React model.js 1:1.'],
      ['Controller', 'cpu', 'composer_controller.dart', 'ComposerController (ChangeNotifier). Owns one TextField surface: typing, trigger detection, token insert/remove, caret & backspace, suggestion state, submit. Emits a view-state + the spec callbacks.'],
      ['Widgets', 'layout-template', 'lib/src/widgets/', 'Flutter layer: SmartComposer wrapper, SuggestionMenu, token chips, ComposerToolbar, AttachmentBar, Banner. The Model & Controller contracts match the React source.'],
    ];
    return Column(
      children: arch.map((a) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: theme.bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: theme.borderSoft)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(ComposerIcons.resolve(a[1]), size: 15, color: theme.accent),
                const SizedBox(width: 8),
                Text(a[0], style: TextStyle(color: theme.fg1, fontSize: 13.5, fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: theme.bg2, borderRadius: BorderRadius.circular(5)),
                  child: Text(a[2], style: TextStyle(fontFamily: theme.monoFont, fontSize: 11, color: theme.fg3)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(a[3], style: TextStyle(color: theme.fg3, fontSize: 12.5, height: 1.45)),
          ],
        ),
      )).toList(),
    );
  }

  Widget _flow(ComposerTheme theme) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: theme.bg2, borderRadius: BorderRadius.circular(8), border: Border.all(color: theme.borderSoft)),
      child: Text.rich(
        TextSpan(
          style: TextStyle(color: theme.fg3, fontSize: 12.5, height: 1.6),
          children: [
            const TextSpan(text: 'types '),
            _b(theme, 'register()'),
            const TextSpan(text: ' → mode '),
            _b(theme, 'preset'),
            const TextSpan(text: ' → controller detects '),
            _b(theme, 'trigger'),
            const TextSpan(text: ' → provider '),
            _b(theme, 'search()'),
            const TextSpan(text: ' → '),
            _b(theme, 'token'),
            const TextSpan(text: ' inserted → '),
            _b(theme, 'validate()'),
            const TextSpan(text: ' → '),
            _b(theme, 'onSubmitted'),
          ],
        ),
      ),
    );
  }

  TextSpan _b(ComposerTheme theme, String s) =>
      TextSpan(text: s, style: TextStyle(color: theme.fg1, fontWeight: FontWeight.w700, fontFamily: theme.monoFont, fontSize: 12));

  Widget _chips(ComposerTheme theme, List<String> items) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: items.map((c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: theme.bg2, borderRadius: BorderRadius.circular(5), border: Border.all(color: theme.borderSoft)),
        child: Text(c, style: TextStyle(fontFamily: theme.monoFont, fontSize: 11.5, color: theme.fg2)),
      )).toList(),
    );
  }

  Widget _threeCols(ComposerTheme theme) {
    Widget col(String title, List<String> items) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(title, style: TextStyle(color: theme.fg2, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
            _chips(theme, items),
          ],
        );
    return Wrap(
      spacing: 24,
      runSpacing: 20,
      children: [
        SizedBox(width: 220, child: col('Modes', ComposerModes.byId.keys.toList())),
        SizedBox(width: 220, child: col('Access modes', AccessModes.all.map((a) => a.id).toList())),
        SizedBox(width: 260, child: col('States', const [
          'idle', 'focused', 'typing', 'suggestionOpen', 'referenceSelected', 'attachmentAdded',
          'validating', 'invalid', 'loading', 'submitting', 'submitted', 'disabled', 'readOnly', 'error',
        ])),
      ],
    );
  }
}
