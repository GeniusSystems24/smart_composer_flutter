import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_composer_flutter/smart_composer_flutter.dart';

/// Controller-level tests that don't require pumping the widget tree — they
/// exercise the editing model directly.
void main() {
  setUpAll(ReferenceRegistry.ensureDefaults);

  ComposerController make([ComposerMode? mode]) =>
      ComposerController(mode: mode ?? ComposerModes.aiPrompt);

  test('seeded segments produce encodedText and references', () {
    final c = make();
    c.setSegments([
      ComposerSegment.text('Hi '),
      ComposerSegment.ref(ComposerReference(type: 'user', title: 'Ahmed')),
    ]);
    final v = c.getValue();
    expect(v.references.length, 1);
    expect(v.references.first.type, 'user');
    expect(v.encodedText.contains('[@user:Ahmed]'), isTrue);
    expect(v.plainText.startsWith('Hi Ahmed'), isTrue);
    c.dispose();
  });

  test('setEncodedText round-trips through the editor', () {
    final c = make();
    const src = 'Pay [#invoice:INV-1](invoice://INV-1) now';
    c.setEncodedText(src);
    expect(c.getEncodedText(), src);
    c.dispose();
  });

  test('insertReference adds a token and fires onReferenceSelected', () {
    ComposerReference? selected;
    final c = ComposerController(
      mode: ComposerModes.aiPrompt,
      callbacks: ComposerCallbacks(onReferenceSelected: (r) => selected = r),
    );
    c.insertReference(ComposerReference(type: 'task', title: 'Prepare Report'));
    expect(selected, isNotNull);
    expect(c.getValue().references.length, 1);
    c.dispose();
  });

  test('command mode validation requires a command reference', () {
    final c = make(ComposerModes.command);
    c.insertText('do something');
    expect(c.validation.valid, isFalse);
    c.insertReference(ComposerReference(type: 'command', title: 'assign'));
    expect(c.validation.valid, isTrue);
    c.dispose();
  });

  test('access + model setters fire their callbacks', () {
    String? access;
    final c = ComposerController(
      mode: ComposerModes.aiPrompt,
      callbacks: ComposerCallbacks(onAccessModeChanged: (a) => access = a),
    );
    c.setAccessMode('readOnly');
    expect(access, 'readOnly');
    expect(c.accessMode, 'readOnly');
    c.setModel('opus');
    expect(c.modelName, 'opus');
    c.dispose();
  });

  test('attachments add/remove fire callbacks', () {
    final added = <String>[];
    final removed = <String>[];
    final c = ComposerController(
      mode: ComposerModes.note,
      callbacks: ComposerCallbacks(
        onAttachmentAdded: (a) => added.add(a.title),
        onAttachmentRemoved: (a) => removed.add(a.title),
      ),
    );
    final att = ComposerAttachment(type: 'file', title: 'a.pdf');
    c.addAttachment(att);
    expect(added, ['a.pdf']);
    c.removeAttachment(att.id);
    expect(removed, ['a.pdf']);
    c.dispose();
  });

  test('handleDrop inserts tokens and rejects invalid items', () {
    final inserted = <String>[];
    final rejected = <String>[];
    final c = ComposerController(
      mode: ComposerModes.message,
      dropCallbacks: DropCallbacks(
        onDroppedTokenInserted: (t, r, i) => inserted.add(t.displayText),
        onDropRejected: (rej) => rejected.addAll(rej.map((e) => e.item?.name ?? '')),
      ),
    );
    c.handleDrop([
      ComposerDnd.makeDropItem({'name': 'photo.png', 'mimeType': 'image/png', 'size': 1000}),
      ComposerDnd.makeDropItem({'name': 'installer.exe', 'size': 10}),
    ]);
    expect(inserted, contains('photo.png'));
    expect(rejected, contains('installer.exe'));
    c.dispose();
  });

  test('submit only fires onSubmitted when valid', () {
    var submits = 0;
    final c = ComposerController(
      mode: ComposerModes.comment, // requireText
      callbacks: ComposerCallbacks(onSubmitted: (_) => submits++),
    );
    c.submit();
    expect(submits, 0); // empty → invalid
    c.insertText('looks good');
    c.submit();
    expect(submits, 1);
    c.dispose();
  });
}
