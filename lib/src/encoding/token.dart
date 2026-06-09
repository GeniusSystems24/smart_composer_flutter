/// Remote token resolution lifecycle. Mirrors `SC.RESOLVE_STATE` 1:1.
class ResolveState {
  static const idle = 'idle';
  static const loading = 'loading';
  static const resolved = 'resolved';
  static const error = 'error';
  static const notFound = 'notFound';
  static const permissionDenied = 'permissionDenied';
  static const deleted = 'deleted';
  static const disabled = 'disabled';

  static const all = [
    idle, loading, resolved, error, notFound, permissionDenied, deleted, disabled,
  ];
}

/// A parsed smart token: `[<prefix><tagType>:<displayText>](valueText)`.
/// Mirrors `SmartComposerToken`.
class SmartComposerToken {
  SmartComposerToken({
    required this.prefix,
    required this.tagType,
    required this.displayText,
    required this.valueText,
    this.rawText = '',
    this.startOffset = -1,
    this.endOffset = -1,
    Map<String, dynamic>? metadata,
    this.resolveState = ResolveState.idle,
    String? accent,
  })  : metadata = metadata ?? <String, dynamic>{},
        accent = accent;

  final String prefix;
  final String tagType;
  final String displayText;
  final String valueText;
  final String rawText;
  final int startOffset;
  final int endOffset;
  final Map<String, dynamic> metadata;
  final String resolveState;

  /// Optional accent override (otherwise resolved from the registry).
  final String? accent;

  SmartComposerToken copyWith({String? resolveState, String? displayText}) {
    return SmartComposerToken(
      prefix: prefix,
      tagType: tagType,
      displayText: displayText ?? this.displayText,
      valueText: valueText,
      rawText: rawText,
      startOffset: startOffset,
      endOffset: endOffset,
      metadata: metadata,
      resolveState: resolveState ?? this.resolveState,
      accent: accent,
    );
  }
}

/// A compact token-index entry. Mirrors `{ prefix, tagType, displayText, valueText }`.
class TokenIndexEntry {
  const TokenIndexEntry({
    required this.prefix,
    required this.tagType,
    required this.displayText,
    required this.valueText,
  });
  final String prefix;
  final String tagType;
  final String displayText;
  final String valueText;
}

/// A parser segment: either plain [text] or a [token]. Mirrors the parser's
/// `{ kind:'text', text } | { kind:'token', token }`.
class ParsedSegment {
  const ParsedSegment.text(this.text) : token = null, kind = 'text';
  const ParsedSegment.token(this.token) : text = '', kind = 'token';
  final String kind;
  final String text;
  final SmartComposerToken? token;
  bool get isText => kind == 'text';
  bool get isToken => kind == 'token';
}

/// A parse error (collected, never thrown). Mirrors `{ index, reason }`.
class ParseError {
  const ParseError({required this.index, required this.reason});
  final int index;
  final String reason;
}

/// The full parse result. Mirrors `SmartComposerParseResult`.
class ParseResult {
  const ParseResult({
    required this.encodedText,
    required this.segments,
    required this.tokens,
    required this.errors,
    required this.plainText,
  });
  final String encodedText;
  final List<ParsedSegment> segments;
  final List<SmartComposerToken> tokens;
  final List<ParseError> errors;
  final String plainText;
}
