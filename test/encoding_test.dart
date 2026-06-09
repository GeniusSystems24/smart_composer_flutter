import 'package:flutter_test/flutter_test.dart';
import 'package:smart_composer_flutter/smart_composer_flutter.dart';

/// Encoding-layer unit tests. These mirror the React `SC.runTests()` suite
/// case-for-case and assert React ⇄ Flutter parser compatibility.
void main() {
  setUpAll(ReferenceRegistry.ensureDefaults);

  group('In-library suite parity (runComposerTests)', () {
    test('every ported test passes', () {
      final run = runComposerTests();
      final failed = run.results.where((r) => !r.pass).map((r) => '${r.group} · ${r.name}: ${r.detail}').toList();
      expect(failed, isEmpty, reason: failed.join('\n'));
      expect(run.fail, 0);
      expect(run.total, greaterThan(40));
    });
  });

  group('Parsing', () {
    test('text + token + text', () {
      final r = SmartComposerParser.parse('Hello [@user:Ahmed](user://user_123)!');
      expect(r.segments.length, 3);
      expect(r.segments[0].text, 'Hello ');
      expect(r.tokens[0].prefix, '@');
      expect(r.tokens[0].tagType, 'user');
      expect(r.tokens[0].displayText, 'Ahmed');
      expect(r.tokens[0].valueText, 'user://user_123');
      expect(r.segments[2].text, '!');
    });

    test('uri value with slashes and dots preserved', () {
      final r = SmartComposerParser.parse('[\$tool:Browser Use](skill://openai-bundled/browser-use/0.1.0-alpha1/browser)');
      expect(r.tokens[0].valueText, 'skill://openai-bundled/browser-use/0.1.0-alpha1/browser');
      expect(r.tokens[0].displayText, 'Browser Use');
    });

    test('adjacent tokens, no text between', () {
      final adj = SmartComposerParser.parse('[@user:A](user://a)[#task:B](task://b)');
      expect(adj.tokens.length, 2);
      expect(adj.segments.length, 2);
    });
  });

  group('Serialization round-trip', () {
    const src = 'Pay [#invoice:INV-2026-001](invoice://INV-2026-001) from [\$financialAccount:Main Bank Account](financial-account://main_bank_account).';
    test('value round-trips identically', () {
      final v = SmartComposerValue.fromEncodedText(src);
      expect(v.toEncodedText(), src);
      expect(SmartComposerSerializer.serializeSegments(v.segments), src);
    });
  });

  group('plainText', () {
    test('tokens become displayText, no syntax leaks', () {
      const enc = 'Pay invoice [#invoice:INV-2026-001](invoice://INV-2026-001) from [\$financialAccount:Main Bank Account](financial-account://main_bank_account).';
      expect(SmartComposerPlainTextConverter.convert(enc), 'Pay invoice INV-2026-001 from Main Bank Account.');
      expect(RegExp(r'[\[\]\(\)]').hasMatch(SmartComposerPlainTextConverter.convert(enc)), isFalse);
    });
  });

  group('Escaping', () {
    test('] in display and ) in value survive a round-trip', () {
      final t = SmartComposerToken(prefix: '@', tagType: 'user', displayText: 'Ahmed: Lead [VIP]', valueText: 'user://u_1');
      final back = SmartComposerParser.parse(SmartComposerSerializer.tokenToEncoded(t)).tokens[0];
      expect(back.displayText, 'Ahmed: Lead [VIP]');

      final t2 = SmartComposerToken(prefix: '@', tagType: 'file', displayText: 'weird) name', valueText: 'file:///a/b(c).pdf');
      final back2 = SmartComposerParser.parse(SmartComposerSerializer.tokenToEncoded(t2)).tokens[0];
      expect(back2.valueText, 'file:///a/b(c).pdf');
      expect(back2.displayText, 'weird) name');
    });
  });

  group('File URIs', () {
    test('windows path encodes to file:///', () {
      final ref = ComposerReference(type: 'file', title: 'client-a.pdf', path: 'C:\\Users\\Al-saiary\\contracts\\client-a.pdf');
      expect(ComposerBridge.valueTextForRef(ref), 'file:///C:/Users/Al-saiary/contracts/client-a.pdf');
    });
  });

  group('Invalid tokens degrade to text (never throw)', () {
    test('various malformed inputs yield zero tokens', () {
      expect(SmartComposerParser.parse('[@user:Ahmed(user://x)').tokens.length, 0);
      expect(SmartComposerParser.parse('[@user:Ahmed] hi').tokens.length, 0);
      expect(SmartComposerParser.parse('[@:Ahmed](user://x)').tokens.length, 0);
      expect(SmartComposerParser.parse('[@user:Ahmed]()').tokens.length, 0);
      expect(SmartComposerParser.parse('see [docs](https://x.y)').tokens.length, 0);
      final r = SmartComposerParser.parse('[@:Ahmed](user://x)');
      expect(r.segments[0].kind, 'text');
      expect(r.errors, isNotEmpty);
    });
  });

  group('Fallbacks & unknown types', () {
    test('empty display falls back to valueText', () {
      expect(SmartComposerParser.parse('[@user:](user://user_9)').tokens[0].displayText, 'user://user_9');
    });
    test('unknown tagType still parses with prefix kept', () {
      final r = SmartComposerParser.parse('[~widget:Gadget](widget://w_1)');
      expect(r.tokens.length, 1);
      expect(r.tokens[0].prefix, '~');
      expect(r.tokens[0].tagType, 'widget');
    });
  });

  group('Scale', () {
    test('2000-char value and 50 tokens', () {
      final long = 'x' * 2000;
      final r = SmartComposerParser.parse('[@file:big](file:///$long)');
      expect(r.tokens[0].valueText.length, ('file:///$long').length);
      final many = List.generate(50, (i) => '[#task:T$i](task://t_$i)').join(' ');
      expect(SmartComposerParser.parse(many).tokens.length, 50);
    });
  });

  group('Token index & restore', () {
    test('index extracts entries', () {
      final idx = SmartComposerTokenIndex.extract('[#invoice:INV-1](invoice://1) & [@user:A](user://a)');
      expect(idx.length, 2);
      expect(idx[0].tagType, 'invoice');
    });
    test('restore from encoded alone', () {
      const src = 'Use [\$tool:Browser Use](skill://o/b) on [@source:Documents](plugin://documents@x).';
      final segs = ComposerBridge.encodedToSegments(src);
      expect(segs.length, 5);
      expect(ComposerBridge.segmentsToEncoded(segs), src);
    });
  });

  group('Drag & drop mapping', () {
    test('extension/mime → type', () {
      expect(ComposerDnd.mapExtToType('png', 'image/png'), 'image');
      expect(ComposerDnd.mapExtToType('mp4', 'video/mp4'), 'video');
      expect(ComposerDnd.mapExtToType('pdf', 'application/pdf'), 'document');
      expect(ComposerDnd.mapExtToType('zip', 'application/zip'), 'file');
    });
    test('drop item + token round-trip', () {
      final item = ComposerDnd.makeDropItem({'name': 'client-a.pdf', 'path': 'C:\\contracts\\client-a.pdf', 'size': 2400000});
      expect(item.type, 'document');
      expect(item.uri, 'file:///C:/contracts/client-a.pdf');
      final tok = ComposerDnd.dropItemToToken(item);
      expect(tok.tagType, 'document');
      expect(tok.displayText, 'client-a.pdf');
      expect(SmartComposerParser.parse(SmartComposerSerializer.tokenToEncoded(tok)).tokens[0].valueText, 'file:///C:/contracts/client-a.pdf');
    });
    test('url → link', () {
      final url = ComposerDnd.makeDropItemFromUrl('https://genius.link/q4-board/');
      expect(url.type, 'link');
      expect(url.name, 'genius.link/q4-board');
    });
  });

  group('Drop validation', () {
    test('oversize / blocked / allow-list / wildcard', () {
      final big = ComposerDnd.makeDropItem({'name': 'huge.zip', 'size': 48 * 1024 * 1024});
      expect(SmartComposerDropValidator.validate(big, const DropConfig(maxFileSize: 25 * 1024 * 1024)).valid, isFalse);
      final exe = ComposerDnd.makeDropItem({'name': 'installer.exe', 'size': 10});
      expect(SmartComposerDropValidator.validate(exe, const DropConfig()).valid, isFalse);
      final png = ComposerDnd.makeDropItem({'name': 'a.png', 'mimeType': 'image/png', 'size': 1000});
      expect(SmartComposerDropValidator.validate(png, const DropConfig(allowedExtensions: ['png'])).valid, isTrue);
      expect(SmartComposerDropValidator.validate(ComposerDnd.makeDropItem({'name': 'a.pdf', 'size': 1}), const DropConfig(allowedExtensions: ['png'])).valid, isFalse);
      expect(SmartComposerDropValidator.validate(png, const DropConfig(allowedMimeTypes: ['image/*'])).valid, isTrue);
    });
  });

  group('Validation rules', () {
    test('requireReferenceType for command mode', () {
      final rules = ComposerModes.command.validation;
      final empty = ComposerValidator.validate(text: 'do it', references: const [], attachments: const [], rules: rules);
      expect(empty.valid, isFalse);
      final withCmd = ComposerValidator.validate(
        text: '',
        references: [ComposerReference(type: 'command', title: 'assign')],
        attachments: const [],
        rules: rules,
      );
      expect(withCmd.valid, isTrue);
    });

    test('entity error/disabled state surfaces as invalid', () {
      final res = ComposerValidator.validate(
        text: 'x',
        references: [ComposerReference(type: 'invoice', title: 'INV-022', state: 'error')],
        attachments: const [],
        rules: const ValidationRules(),
      );
      expect(res.valid, isFalse);
      expect(res.errors.first.code, 'invalidReference');
    });
  });

  group('Value storage', () {
    test('toStorage carries encoded, plain and token index', () {
      final v = SmartComposerValue.fromEncodedText('Hi [@user:A](user://a)');
      final s = v.toStorage();
      expect(s['encodedText'], 'Hi [@user:A](user://a)');
      expect(s['plainText'], 'Hi A');
      expect((s['tokensIndex'] as List).length, 1);
    });
  });
}
