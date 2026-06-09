import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_composer_flutter/smart_composer_flutter.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: ComposerThemeScope(
        theme: ComposerTheme.dark(),
        child: Scaffold(body: Padding(padding: const EdgeInsets.all(24), child: child)),
      ),
    );

void main() {
  setUpAll(ReferenceRegistry.ensureDefaults);

  testWidgets('renders a seeded token chip', (tester) async {
    await tester.pumpWidget(_wrap(SmartComposer(
      mode: ComposerModes.aiPrompt,
      seed: [
        ComposerSegment.text('Hi '),
        ComposerSegment.ref(ComposerReference(type: 'user', title: 'Ahmed')),
      ],
    )));
    await tester.pumpAndSettle();
    expect(find.text('Ahmed'), findsOneWidget);
  });

  testWidgets('shows placeholder text', (tester) async {
    await tester.pumpWidget(_wrap(const SmartComposer(mode: ComposerModes.comment)));
    await tester.pump();
    expect(find.textContaining('Add a comment'), findsOneWidget);
  });

  testWidgets('toolbar renders the send button label', (tester) async {
    await tester.pumpWidget(_wrap(const SmartComposer(mode: ComposerModes.search)));
    await tester.pump();
    expect(find.text('Search'), findsWidgets);
  });

  testWidgets('tapping a token fires onReferenceTap', (tester) async {
    ComposerReference? tapped;
    await tester.pumpWidget(_wrap(SmartComposer(
      mode: ComposerModes.aiPrompt,
      seed: [ComposerSegment.ref(ComposerReference(type: 'task', title: 'Prepare Report'))],
      callbacks: ComposerCallbacks(onReferenceTap: (r) => tapped = r),
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Prepare Report'));
    await tester.pump();
    expect(tapped, isNotNull);
    expect(tapped!.title, 'Prepare Report');
  });

  testWidgets('SmartComposerPreview renders tokens from encoded text', (tester) async {
    await tester.pumpWidget(_wrap(const SmartComposerPreview(
      encodedText: 'Pay [#invoice:INV-2026-001](invoice://INV-2026-001) now',
    )));
    await tester.pumpAndSettle();
    expect(find.text('INV-2026-001'), findsOneWidget);
    expect(find.textContaining('Pay'), findsWidgets);
  });

  testWidgets('readOnly composer hides the toolbar', (tester) async {
    await tester.pumpWidget(_wrap(const SmartComposer(mode: ComposerModes.aiPrompt, readOnly: true)));
    await tester.pump();
    expect(find.text('Run'), findsNothing);
  });
}
