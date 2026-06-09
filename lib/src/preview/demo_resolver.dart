import 'dart:async';
import 'dart:math';

import '../encoding/token.dart';
import 'preview_resolver.dart';

/// A demo [TokenResolver] that derives a resolve state from the token's
/// valueText so every state is observable, and "enriches" resolved tokens with
/// a subtitle. Replace with a real API in production. Faithful port of
/// `SC.makeDemoResolver`.
TokenResolver makeDemoResolver({int delay = 700}) {
  final rng = Random();
  return (SmartComposerToken token) {
    final v = token.valueText.toLowerCase();
    final ms = RegExp(r'idle|cached').hasMatch(token.tagType)
        ? 0
        : delay + rng.nextInt(300);
    final completer = Completer<ResolveResult>();
    Timer(Duration(milliseconds: ms), () {
      ResolveResult out;
      if (RegExp(r'restricted|private|secret|denied').hasMatch(v)) {
        out = const ResolveResult(state: ResolveState.permissionDenied);
      } else if (RegExp(r'missing|deleted|404|not-?found|ghost').hasMatch(v)) {
        out = const ResolveResult(state: ResolveState.notFound);
      } else if (RegExp(r'error|fail|broken').hasMatch(v)) {
        out = const ResolveResult(state: ResolveState.error);
      } else {
        const enrich = {
          'user': 'online',
          'invoice': '\$5,240.00 · paid',
          'task': 'In progress',
          'financialAccount': 'SAR · \$284,120.00',
          'file': 'synced',
          'tool': 'ready',
          'skill': 'v26.4',
          'plugin': 'enabled',
          'payment': 'settled',
          'report': 'live',
        };
        out = ResolveResult(
          state: ResolveState.resolved,
          subtitle: enrich[token.tagType],
          metadata: {'resolvedAt': DateTime.now().millisecondsSinceEpoch},
        );
      }
      completer.complete(out);
    });
    return completer.future;
  };
}

/// The preview render styles offered by the encoding tab (parity with
/// `SC.PREVIEW_STYLES`). All render the same content; style affects density.
const List<String> kPreviewStyles = [
  'inline',
  'compact',
  'card',
  'chatBubble',
  'detailed',
  'minimal',
  'debug',
];

/// The package version string (parity with `SC.version`).
const String kSmartComposerVersion = '1.0.0';
