import 'package:flutter/material.dart';
import 'package:smart_composer_flutter/smart_composer_flutter.dart';

import '../ui.dart';

/// The Tests tab — renders the in-library encoding test suite grouped by
/// section with pass/fail badges. Mirrors `TestsTab` in encoding-tab.jsx.
class TestsTab extends StatefulWidget {
  const TestsTab({super.key});

  @override
  State<TestsTab> createState() => _TestsTabState();
}

class _TestsTabState extends State<TestsTab> {
  late final TestRun _run = runComposerTests();

  @override
  Widget build(BuildContext context) {
    final theme = ComposerThemeScope.of(context);
    final groups = <String, List<TestResult>>{};
    for (final r in _run.results) {
      groups.putIfAbsent(r.group, () => []).add(r);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (_run.fail == 0 ? theme.success : theme.danger).withOpacity(0.16),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: (_run.fail == 0 ? theme.success : theme.danger).withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(ComposerIcons.resolve(_run.fail == 0 ? 'check-check' : 'x'), size: 16, color: _run.fail == 0 ? theme.success : theme.danger),
                  const SizedBox(width: 8),
                  Text('${_run.pass}/${_run.total} passing', style: TextStyle(color: _run.fail == 0 ? theme.success : theme.danger, fontSize: 13, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            if (_run.fail > 0) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: theme.danger.withOpacity(0.16), borderRadius: BorderRadius.circular(7)),
                child: Text('${_run.fail} failing', style: TextStyle(color: theme.danger, fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Text('Unit tests for the encoding layer — parsing, serialization, escaping, plainText, invalid tokens, unknown types, adjacency, scale, restore.',
            style: TextStyle(color: theme.fg3, fontSize: 13, height: 1.5)),
        const SizedBox(height: 20),
        ...groups.entries.map((e) => _group(theme, e.key, e.value)),
      ],
    );
  }

  Widget _group(ComposerTheme theme, String name, List<TestResult> rows) {
    final pass = rows.where((r) => r.pass).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Ui.card(
        theme,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(name, style: TextStyle(color: theme.fg1, fontSize: 13.5, fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('$pass/${rows.length}', style: TextStyle(color: theme.fg3, fontSize: 11.5, fontFamily: theme.monoFont)),
              ],
            ),
            const SizedBox(height: 10),
            ...rows.map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: (r.pass ? theme.success : theme.danger).withOpacity(0.16),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(ComposerIcons.resolve(r.pass ? 'check' : 'x'), size: 12, color: r.pass ? theme.success : theme.danger),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(r.name, style: TextStyle(color: theme.fg2, fontSize: 12.5))),
                      if (!r.pass)
                        Flexible(child: Text(r.detail, style: TextStyle(color: theme.danger, fontSize: 11, fontFamily: theme.monoFont))),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
