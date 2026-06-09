import 'reference.dart';
import 'segment.dart';

/// Seeds a "[bracket]" demo string into editor segments. Maps each label to a
/// best-guess entity type so example text renders as real tokens. Mirrors
/// `SC.guessType` + `SC.seedSegments` 1:1.
class ComposerSeed {
  ComposerSeed._();

  static String guessType(String label) {
    final l = label.toLowerCase();
    if (RegExp(r'^inv[-\s]', caseSensitive: false).hasMatch(label)) return 'invoice';
    if (RegExp(r'^pay[-\s]', caseSensitive: false).hasMatch(label)) return 'payment';
    if (RegExp(r'^tr[-\s]', caseSensitive: false).hasMatch(label)) return 'transaction';
    if (RegExp(r'account|cash|assets|receivable').hasMatch(l)) return 'financialAccount';
    if (RegExp(r'\.(pdf|xlsx|csv|docx|png|mp4)$').hasMatch(l) || l.contains('/')) return 'file';
    if (RegExp(r'prepare|task|reconcile|assign|onboard').hasMatch(l)) return 'task';
    if (RegExp(r'report|p&l|balance').hasMatch(l)) return 'report';
    if (RegExp(r'task|prepare|reconcile').hasMatch(l)) return 'task';
    if (RegExp(r'team').hasMatch(l)) return 'team';
    return 'user';
  }

  /// Parse a string with `[label]` markers into text + ref segments.
  static List<ComposerSegment> seedSegments(String str) {
    final segs = <ComposerSegment>[];
    final re = RegExp(r'\[([^\]]+)\]');
    var last = 0;
    for (final m in re.allMatches(str)) {
      if (m.start > last) {
        segs.add(ComposerSegment.text(str.substring(last, m.start)));
      }
      final label = m.group(1)!;
      final type = guessType(label);
      segs.add(ComposerSegment.ref(ComposerReference(
        type: type,
        title: label,
        displayText: label,
        path: type == 'file' ? label : '',
      )));
      last = m.end;
    }
    if (last < str.length) {
      segs.add(ComposerSegment.text(str.substring(last)));
    }
    return segs;
  }
}
