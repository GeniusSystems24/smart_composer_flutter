import 'reference.dart';
import 'reference_registry.dart';
import 'sample_data.dart';
import 'triggers.dart';

/// Default suggestion provider over [SampleData]. Filters across the trigger's
/// types, groups by registry group, returns generic suggestion items. Mirrors
/// `SC.search` 1:1 (prefix > word-start > substring scoring).
class ComposerSearch {
  ComposerSearch._();

  static int _score(String query, Map<String, dynamic> item) {
    if (query.isEmpty) return 1;
    final q = query.toLowerCase();
    final t = ('${item['title'] ?? ''} ${item['subtitle'] ?? ''}').toLowerCase();
    final i = t.indexOf(q);
    if (i == -1) return 0;
    if (i == 0) return 3; // prefix
    return t[i - 1] == ' ' ? 2 : 1; // word-start vs substring
  }

  /// Build a [ComposerReference] from a sample-data row, merging in the type.
  static ComposerReference referenceFromRow(String type, Map<String, dynamic> row) {
    return ComposerReference(
      type: type,
      title: (row['title'] ?? '') as String,
      subtitle: (row['subtitle'] ?? '') as String,
      displayText: row['displayText'] as String?,
      path: (row['path'] ?? '') as String,
      state: (row['state'] ?? 'ready') as String,
      mono: row['mono'] as bool?,
      metadata: (row['metadata'] as Map?)?.cast<String, dynamic>(),
    );
  }

  /// Default provider matching the `SC.search(query, types, opts)` signature.
  static List<SuggestionGroup> search(
    String query,
    List<String> types, [
    Map<String, dynamic> opts = const {},
  ]) {
    final perGroup = (opts['perGroup'] as int?) ?? 6;
    final groups = <String, List<_Scored>>{};
    for (final type in types) {
      final def = ReferenceRegistry.get(type);
      final rows = SampleData.data[type] ?? const [];
      for (final row in rows) {
        final s = _score(query, row);
        if (s <= 0) continue;
        final g = def.group;
        groups.putIfAbsent(g, () => []);
        groups[g]!.add(_Scored(s, referenceFromRow(type, row)));
      }
    }
    final out = <SuggestionGroup>[];
    groups.forEach((group, rows) {
      rows.sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        if (byScore != 0) return byScore;
        return a.ref.title.toLowerCase().compareTo(b.ref.title.toLowerCase());
      });
      out.add(SuggestionGroup(
        group: group,
        items: rows.take(perGroup).map((r) => r.ref).toList(),
      ));
    });
    return out;
  }
}

class _Scored {
  _Scored(this.score, this.ref);
  final int score;
  final ComposerReference ref;
}
