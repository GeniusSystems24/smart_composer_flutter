import 'dart:async';

import '../encoding/parser.dart';
import '../encoding/token.dart';

/// Resolver result for a single token. Mirrors the React `resolver` return shape.
class ResolveResult {
  const ResolveResult({
    required this.state,
    this.displayText,
    this.subtitle,
    this.metadata,
  });
  final String state; // ResolveState.*
  final String? displayText;
  final String? subtitle;
  final Map<String, dynamic>? metadata;
}

/// Resolves a token to remote state. Given the token, returns (or async-returns)
/// a [ResolveResult]. Mirrors `(token) => ResolveResult | Promise<ResolveResult>`.
typedef TokenResolver = FutureOr<ResolveResult> Function(SmartComposerToken token);

/// A resolved view-model for one token in the preview.
class ResolvedToken {
  ResolvedToken({
    required this.token,
    required this.state,
    this.subtitle,
    this.metadata,
  });
  SmartComposerToken token;
  String state;
  String? subtitle;
  Map<String, dynamic>? metadata;
}

/// Drives token resolution for [SmartComposerPreview]. Parses encoded text, then
/// runs the optional [resolver] across each token, emitting updates as each
/// resolves. Mirrors the resolution engine inside `preview.jsx`.
class PreviewResolverModel {
  PreviewResolverModel({required String encodedText, this.resolver}) {
    setEncodedText(encodedText);
  }

  TokenResolver? resolver;
  late ParseResult _parsed;
  final Map<int, ResolvedToken> _byIndex = {};

  /// Listeners notified whenever a token's resolve state changes.
  final List<void Function()> _listeners = [];
  void addListener(void Function() fn) => _listeners.add(fn);
  void removeListener(void Function() fn) => _listeners.remove(fn);
  void _notify() {
    for (final l in List.of(_listeners)) {
      l();
    }
  }

  ParseResult get parsed => _parsed;
  List<ParsedSegment> get segments => _parsed.segments;
  List<ParseError> get errors => _parsed.errors;

  ResolvedToken resolvedFor(int tokenIndex) => _byIndex[tokenIndex]!;

  void setEncodedText(String encodedText) {
    _parsed = SmartComposerParser.parse(encodedText);
    _byIndex.clear();
    for (var i = 0; i < _parsed.tokens.length; i++) {
      final t = _parsed.tokens[i];
      _byIndex[i] = ResolvedToken(token: t, state: ResolveState.idle);
    }
    _notify();
    _runResolution();
  }

  void retry() => _runResolution(force: true);

  Future<void> _runResolution({bool force = false}) async {
    if (resolver == null) {
      for (final r in _byIndex.values) {
        r.state = ResolveState.resolved;
      }
      _notify();
      return;
    }
    for (var i = 0; i < _parsed.tokens.length; i++) {
      final entry = _byIndex[i]!;
      if (!force && entry.state == ResolveState.resolved) continue;
      entry.state = ResolveState.loading;
    }
    _notify();
    final futures = <Future<void>>[];
    for (var i = 0; i < _parsed.tokens.length; i++) {
      final idx = i;
      futures.add(Future(() async {
        final entry = _byIndex[idx]!;
        try {
          final res = await resolver!(entry.token);
          entry.state = res.state;
          entry.subtitle = res.subtitle;
          entry.metadata = res.metadata;
          if (res.displayText != null) {
            entry.token = entry.token.copyWith(displayText: res.displayText);
          }
        } catch (_) {
          entry.state = ResolveState.error;
        }
        _notify();
      }));
    }
    await Future.wait(futures);
    _notify();
  }
}
