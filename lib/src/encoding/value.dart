import 'parser.dart';
import 'serializer.dart';
import 'token.dart';

/// The storable value object. `encodedText` alone restores the composer — JSON
/// is never required. Mirrors `SC.SmartComposerValue` / `makeValue`.
class SmartComposerValue {
  SmartComposerValue._(this._result);

  final ParseResult _result;

  String get encodedText => _result.encodedText;
  String get plainText => _result.plainText;
  List<ParsedSegment> get segments => _result.segments;
  List<SmartComposerToken> get tokens => _result.tokens;
  List<ParseError> get errors => _result.errors;
  final Map<String, dynamic> metadata = {};

  /// Build a value from encoded text. Mirrors `fromEncodedText`.
  factory SmartComposerValue.fromEncodedText(String encodedText) {
    return SmartComposerValue._(SmartComposerParser.parse(encodedText));
  }

  /// Build a value from parser segments. Mirrors `fromSegments`.
  factory SmartComposerValue.fromSegments(List<ParsedSegment> segments) {
    return SmartComposerValue.fromEncodedText(
      SmartComposerSerializer.serializeSegments(segments),
    );
  }

  String toEncodedText() => encodedText;
  String toPlainText() => plainText;
  List<ParsedSegment> toSegments() => segments;
  List<SmartComposerToken> toTokens() => tokens;

  List<TokenIndexEntry> toTokenIndex() => tokens
      .map((t) => TokenIndexEntry(
            prefix: t.prefix,
            tagType: t.tagType,
            displayText: t.displayText,
            valueText: t.valueText,
          ))
      .toList();

  /// Compact storage form. Mirrors `toStorage()`.
  Map<String, dynamic> toStorage() => {
        'encodedText': encodedText,
        'plainText': plainText,
        'tokensIndex': toTokenIndex()
            .map((e) => {
                  'prefix': e.prefix,
                  'tagType': e.tagType,
                  'displayText': e.displayText,
                  'valueText': e.valueText,
                })
            .toList(),
      };
}
