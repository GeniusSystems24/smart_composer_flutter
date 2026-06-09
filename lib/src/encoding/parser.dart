import 'token.dart';

/// The parser. Scans encoded text into ordered segments. Invalid tokens are
/// left as plain text (never throws); errors are collected for debugging.
/// This is a faithful port of `SC.SmartComposerParser` — byte-for-byte
/// compatible with the React encoded-text format.
class SmartComposerParser {
  SmartComposerParser._();

  static final RegExp _word = RegExp(r'[A-Za-z0-9_-]');

  static bool _isWord(String? ch) => ch != null && _word.hasMatch(ch);

  /// Returns the char at [j] or null when out of range (mirrors JS `s[j]`
  /// returning `undefined`, which never equals a delimiter).
  static String? _at(String s, int j) =>
      (j >= 0 && j < s.length) ? s[j] : null;

  static _TokenParse _parseTokenAt(String s, int i) {
    // s[i] === '['
    var j = i + 1;
    final prefix = StringBuffer();
    // prefix = leading symbol chars (non-word, not ':' ']' '[')
    while (j < s.length &&
        !_isWord(s[j]) &&
        s[j] != ':' &&
        s[j] != ']' &&
        s[j] != '[') {
      prefix.write(s[j]);
      j++;
    }
    // tagType = word chars
    final tagType = StringBuffer();
    while (j < s.length && _isWord(s[j])) {
      tagType.write(s[j]);
      j++;
    }
    if (_at(s, j) != ':') return _TokenParse.fail('missing-colon', j);
    j++; // skip ':'
    // displayText until unescaped ']'
    final display = StringBuffer();
    while (j < s.length && s[j] != ']') {
      if (s[j] == '\\' && j + 1 < s.length) {
        display.write(s[j + 1] == 'n' ? '\n' : s[j + 1]);
        j += 2;
        continue;
      }
      if (s[j] == '\n') return _TokenParse.fail('newline-in-token', j);
      display.write(s[j]);
      j++;
    }
    if (_at(s, j) != ']') return _TokenParse.fail('unterminated-display', j);
    j++; // skip ']'
    if (_at(s, j) != '(') return _TokenParse.fail('missing-paren', j);
    j++; // skip '('
    // valueText until unescaped ')'
    final value = StringBuffer();
    while (j < s.length && s[j] != ')') {
      if (s[j] == '\\' && j + 1 < s.length) {
        value.write(s[j + 1] == 'n' ? '\n' : s[j + 1]);
        j += 2;
        continue;
      }
      if (s[j] == '\n') return _TokenParse.fail('newline-in-token', j);
      value.write(s[j]);
      j++;
    }
    if (_at(s, j) != ')') return _TokenParse.fail('unterminated-value', j);
    j++; // skip ')'

    final tagTypeStr = tagType.toString();
    final valueStr = value.toString();
    final displayStr = display.toString();
    if (tagTypeStr.isEmpty) return _TokenParse.fail('empty-tagType', i);
    if (valueStr.isEmpty) return _TokenParse.fail('empty-valueText', i);

    final token = SmartComposerToken(
      prefix: prefix.toString(),
      tagType: tagTypeStr,
      displayText: displayStr.isNotEmpty ? displayStr : valueStr, // empty → fallback
      valueText: valueStr,
      rawText: s.substring(i, j),
      startOffset: i,
      endOffset: j,
      resolveState: ResolveState.idle,
    );
    return _TokenParse.success(token, j);
  }

  /// Parse [encodedText] into a [ParseResult]. Mirrors `parse(encodedText)`.
  static ParseResult parse(String? encodedText) {
    final s = encodedText ?? '';
    final segments = <ParsedSegment>[];
    final tokens = <SmartComposerToken>[];
    final errors = <ParseError>[];
    var i = 0;
    var textStart = 0;

    void flush(int end) {
      if (end > textStart) {
        segments.add(ParsedSegment.text(s.substring(textStart, end)));
      }
    }

    while (i < s.length) {
      if (s[i] == '\\' && _at(s, i + 1) == '[') {
        i += 2; // escaped bracket → literal text
        continue;
      }
      if (s[i] == '[') {
        final r = _parseTokenAt(s, i);
        if (r.ok) {
          flush(i);
          segments.add(ParsedSegment.token(r.token));
          tokens.add(r.token!);
          i = r.end;
          textStart = i;
          continue;
        } else {
          errors.add(ParseError(index: i, reason: r.reason!));
          i++; // treat '[' as ordinary text and keep scanning
          continue;
        }
      }
      i++;
    }
    flush(s.length);

    final plainText = segments
        .map((seg) => seg.isText ? seg.text : seg.token!.displayText)
        .join();

    return ParseResult(
      encodedText: s,
      segments: segments,
      tokens: tokens,
      errors: errors,
      plainText: plainText,
    );
  }
}

class _TokenParse {
  _TokenParse.success(this.token, this.end)
      : ok = true,
        reason = null;
  _TokenParse.fail(this.reason, this.end)
      : ok = false,
        token = null;
  final bool ok;
  final SmartComposerToken? token;
  final String? reason;
  final int end;
}
