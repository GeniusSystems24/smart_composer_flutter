import 'encoding_util.dart';
import 'parser.dart';
import 'token.dart';

/// Serialization, plain-text conversion and token-index extraction.
/// Faithful port of the serializer half of `encoding.js`.
class SmartComposerSerializer {
  SmartComposerSerializer._();

  /// Encode a single token to `[<prefix><tagType>:<display>](value)`.
  /// Mirrors `SC.tokenToEncoded`.
  static String tokenToEncoded(SmartComposerToken t) {
    final prefix = t.prefix.isNotEmpty ? t.prefix : EncodingUtil.prefixForType(t.tagType);
    final display = EncodingUtil.escDisplay(
      t.displayText.isNotEmpty ? t.displayText : t.valueText,
    );
    return '[$prefix${t.tagType}:$display](${EncodingUtil.escValue(t.valueText)})';
  }

  /// Serialize parser segments back to encoded text. Mirrors
  /// `SC.SmartComposerSerializer.serialize({ segments })`.
  static String serializeSegments(List<ParsedSegment> segments) {
    return segments
        .map((s) => s.isText ? s.text : tokenToEncoded(s.token!))
        .join();
  }
}

/// Converts encoded text → plain text (tokens become their displayText).
/// Mirrors `SC.SmartComposerPlainTextConverter`.
class SmartComposerPlainTextConverter {
  SmartComposerPlainTextConverter._();
  static String convert(String encodedText) =>
      SmartComposerParser.parse(encodedText).plainText;
}

/// Extracts a compact token index from encoded text. Mirrors
/// `SC.SmartComposerTokenIndex`.
class SmartComposerTokenIndex {
  SmartComposerTokenIndex._();
  static List<TokenIndexEntry> extract(String encodedText) {
    return SmartComposerParser.parse(encodedText).tokens.map((t) {
      return TokenIndexEntry(
        prefix: t.prefix,
        tagType: t.tagType,
        displayText: t.displayText,
        valueText: t.valueText,
      );
    }).toList();
  }
}
