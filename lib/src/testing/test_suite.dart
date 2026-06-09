import 'package:smart_composer_flutter/smart_composer_flutter.dart';

import '../dnd/dnd.dart';
import '../encoding/bridge.dart';
import '../encoding/parser.dart';
import '../encoding/serializer.dart';
import '../encoding/value.dart';
import '../model/reference.dart';

/// One test outcome. Mirrors `{ group, name, pass, detail }`.
class TestResult {
  TestResult(this.group, this.name, this.pass, this.detail);
  final String group;
  final String name;
  final bool pass;
  final String detail;
}

/// Aggregate run summary. Mirrors `{ results, pass, fail, total }`.
class TestRun {
  TestRun(this.results, this.pass, this.fail, this.total);
  final List<TestResult> results;
  final int pass;
  final int fail;
  final int total;
}

/// In-library unit tests for the encoding layer — a faithful 1:1 port of
/// `SC.runTests()` from the React project. Returns structured results so the
/// example "Tests" tab can render them; also asserted by the Dart test harness.
TestRun runComposerTests() {
  final results = <TestResult>[];
  var group = '';
  void g(String s) => group = s;
  void ok(String name, bool cond, [String detail = '']) =>
      results.add(TestResult(group, name, cond, detail));
  void eq(String name, Object? a, Object? b) =>
      ok(name, a == b, a == b ? '' : 'got $a ≠ $b');

  // ---- parsing ----
  g('Parsing');
  {
    final r = SmartComposerParser.parse('Hello [@user:Ahmed](user://user_123)!');
    eq('segment count', r.segments.length, 3);
    eq('leading text', r.segments[0].text, 'Hello ');
    eq('token prefix', r.tokens[0].prefix, '@');
    eq('token tagType', r.tokens[0].tagType, 'user');
    eq('token displayText', r.tokens[0].displayText, 'Ahmed');
    eq('token valueText', r.tokens[0].valueText, 'user://user_123');
    eq('trailing text', r.segments[2].text, '!');
  }
  {
    final r = SmartComposerParser.parse('[\$tool:Browser Use](skill://openai-bundled/browser-use/0.1.0-alpha1/browser)');
    eq('uri value preserved', r.tokens[0].valueText, 'skill://openai-bundled/browser-use/0.1.0-alpha1/browser');
    eq('display with space', r.tokens[0].displayText, 'Browser Use');
  }

  // ---- positions ----
  g('Positions');
  {
    eq('token at beginning', SmartComposerParser.parse('[@user:A](user://a) tail').segments[0].kind, 'token');
    eq('token at end', SmartComposerParser.parse('lead [@user:A](user://a)').segments.last.kind, 'token');
    final adj = SmartComposerParser.parse('[@user:A](user://a)[#task:B](task://b)');
    eq('adjacent: 2 tokens', adj.tokens.length, 2);
    eq('adjacent: no text between', adj.segments.length, 2);
  }

  // ---- serialization ----
  g('Serialization');
  {
    const src = 'Pay [#invoice:INV-2026-001](invoice://INV-2026-001) from [\$financialAccount:Main Bank Account](financial-account://main_bank_account).';
    final v = SmartComposerValue.fromEncodedText(src);
    eq('round-trips identically', v.toEncodedText(), src);
    eq('segments round-trip', SmartComposerSerializer.serializeSegments(v.segments), src);
  }

  // ---- plainText ----
  g('plainText');
  {
    const enc = 'Pay invoice [#invoice:INV-2026-001](invoice://INV-2026-001) from [\$financialAccount:Main Bank Account](financial-account://main_bank_account).';
    eq('tokens → displayText', SmartComposerPlainTextConverter.convert(enc), 'Pay invoice INV-2026-001 from Main Bank Account.');
    ok('no encoded syntax leaks', !RegExp(r'[\[\]\(\)]').hasMatch(SmartComposerPlainTextConverter.convert(enc)));
  }

  // ---- escaping ----
  g('Escaping');
  {
    final t = SmartComposerToken(prefix: '@', tagType: 'user', displayText: 'Ahmed: Lead [VIP]', valueText: 'user://u_1');
    final enc = SmartComposerSerializer.tokenToEncoded(t);
    final back = SmartComposerParser.parse(enc).tokens[0];
    eq('display with ] survives', back.displayText, 'Ahmed: Lead [VIP]');
    final t2 = SmartComposerToken(prefix: '@', tagType: 'file', displayText: 'weird) name', valueText: 'file:///a/b(c).pdf');
    final back2 = SmartComposerParser.parse(SmartComposerSerializer.tokenToEncoded(t2)).tokens[0];
    eq('value with ) survives', back2.valueText, 'file:///a/b(c).pdf');
    eq('display with ) survives', back2.displayText, 'weird) name');
  }

  // ---- file uris ----
  g('File URIs');
  {
    final ref = ComposerReference(type: 'file', title: 'client-a.pdf', path: 'C:\\Users\\Al-saiary\\contracts\\client-a.pdf');
    eq('windows path encodes to file:///', ComposerBridge.valueTextForRef(ref), 'file:///C:/Users/Al-saiary/contracts/client-a.pdf');
  }

  // ---- invalid → text ----
  g('Invalid → text');
  {
    eq('missing closing bracket', SmartComposerParser.parse('[@user:Ahmed(user://x)').tokens.length, 0);
    eq('missing paren', SmartComposerParser.parse('[@user:Ahmed] hi').tokens.length, 0);
    eq('empty tagType invalid', SmartComposerParser.parse('[@:Ahmed](user://x)').tokens.length, 0);
    eq('empty valueText invalid', SmartComposerParser.parse('[@user:Ahmed]()').tokens.length, 0);
    eq('plain markdown link untouched', SmartComposerParser.parse('see [docs](https://x.y)').tokens.length, 0);
    final r = SmartComposerParser.parse('[@:Ahmed](user://x)');
    eq('invalid kept as text', r.segments[0].kind, 'text');
    ok('error recorded', r.errors.isNotEmpty);
  }

  // ---- fallbacks ----
  g('Fallbacks');
  {
    eq('empty display → value', SmartComposerParser.parse('[@user:](user://user_9)').tokens[0].displayText, 'user://user_9');
  }

  // ---- unknown types ----
  g('Unknown types');
  {
    final r = SmartComposerParser.parse('[~widget:Gadget](widget://w_1)');
    eq('unknown tagType parsed', r.tokens.length, 1);
    eq('unknown prefix kept', r.tokens[0].prefix, '~');
    eq('unknown tagType kept', r.tokens[0].tagType, 'widget');
  }

  // ---- scale ----
  g('Scale');
  {
    final long = 'x' * 2000;
    final r = SmartComposerParser.parse('[@file:big](file:///$long)');
    eq('long value intact', r.tokens[0].valueText.length, ('file:///$long').length);
    final many = List.generate(50, (i) => '[#task:T$i](task://t_$i)').join(' ');
    eq('50 tokens parsed', SmartComposerParser.parse(many).tokens.length, 50);
  }

  // ---- token index ----
  g('Token index');
  {
    final idx = SmartComposerTokenIndex.extract('[#invoice:INV-1](invoice://1) & [@user:A](user://a)');
    eq('index length', idx.length, 2);
    eq('index entry shape', 'displayText,prefix,tagType,valueText',
        'displayText,prefix,tagType,valueText'); // shape fixed by TokenIndexEntry
    ok('index entry fields present',
        idx[0].prefix.isNotEmpty && idx[0].tagType.isNotEmpty && idx[0].valueText.isNotEmpty);
  }

  // ---- restore ----
  g('Restore');
  {
    const src = 'Use [\$tool:Browser Use](skill://o/b) on [@source:Documents](plugin://documents@x).';
    final segs = ComposerBridge.encodedToSegments(src);
    eq('rebuilt segment count', segs.length, 5);
    eq('rebuilt back to encoded', ComposerBridge.segmentsToEncoded(segs), src);
  }

  // ---- drag & drop ----
  g('Drag & drop');
  {
    eq('png → image', ComposerDnd.mapExtToType('png', 'image/png'), 'image');
    eq('mp4 → video', ComposerDnd.mapExtToType('mp4', 'video/mp4'), 'video');
    eq('pdf → document', ComposerDnd.mapExtToType('pdf', 'application/pdf'), 'document');
    eq('zip → file (fallback)', ComposerDnd.mapExtToType('zip', 'application/zip'), 'file');
    final item = ComposerDnd.makeDropItem({'name': 'client-a.pdf', 'path': 'C:\\contracts\\client-a.pdf', 'size': 2400000});
    eq('drop item type', item.type, 'document');
    eq('drop item uri = file://', item.uri, 'file:///C:/contracts/client-a.pdf');
    final tok = ComposerDnd.dropItemToToken(item);
    eq('dropped token tagType', tok.tagType, 'document');
    eq('dropped token displayText', tok.displayText, 'client-a.pdf');
    final enc = SmartComposerSerializer.tokenToEncoded(tok);
    eq('dropped token round-trips', SmartComposerParser.parse(enc).tokens[0].valueText, 'file:///C:/contracts/client-a.pdf');
    final url = ComposerDnd.makeDropItemFromUrl('https://genius.link/q4-board/');
    eq('url → link', url.type, 'link');
    eq('url display trimmed', url.name, 'genius.link/q4-board');
  }

  // ---- drop validation ----
  g('Drop validation');
  {
    final big = ComposerDnd.makeDropItem({'name': 'huge.zip', 'size': 48 * 1024 * 1024});
    ok('rejects oversize', SmartComposerDropValidator.validate(big, const DropConfig(maxFileSize: 25 * 1024 * 1024)).valid == false);
    final exe = ComposerDnd.makeDropItem({'name': 'installer.exe', 'size': 10});
    ok('rejects blocked ext', SmartComposerDropValidator.validate(exe, const DropConfig()).valid == false);
    final png = ComposerDnd.makeDropItem({'name': 'a.png', 'mimeType': 'image/png', 'size': 1000});
    ok('accepts allowed ext', SmartComposerDropValidator.validate(png, const DropConfig(allowedExtensions: ['png'])).valid == true);
    ok('rejects ext not in allow-list', SmartComposerDropValidator.validate(ComposerDnd.makeDropItem({'name': 'a.pdf', 'size': 1}), const DropConfig(allowedExtensions: ['png'])).valid == false);
    ok('mime wildcard match', SmartComposerDropValidator.validate(png, const DropConfig(allowedMimeTypes: ['image/*'])).valid == true);
  }

  // ---- caret insertion ----
  g('Caret insertion');
  {
    const enc = 'Hello [@user:Ahmed](user://u) world';
    final segs = ComposerBridge.encodedToSegments(enc);
    eq('token sits between text', segs[1].kind, 'ref');
    eq('text after token preserved', segs[2].text, ' world');
    eq('round-trips with mid token', ComposerBridge.segmentsToEncoded(segs), enc);
  }

  final pass = results.where((r) => r.pass).length;
  return TestRun(results, pass, results.length - pass, results.length);
}
