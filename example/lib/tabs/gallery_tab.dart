import 'package:flutter/material.dart';
import 'package:smart_composer_flutter/smart_composer_flutter.dart';

import '../ui.dart';

ComposerSegment _t(String text) => ComposerSegment.text(text);
ComposerSegment _r(String type, {String title = '', String subtitle = '', String path = ''}) =>
    ComposerSegment.ref(ComposerReference(type: type, title: title, displayText: title, subtitle: subtitle, path: path));

class _Example {
  const _Example(this.key, this.title, this.icon, this.accent, this.desc, this.modeId, this.seed);
  final String key;
  final String title;
  final String icon;
  final String accent;
  final String desc;
  final String modeId;
  final List<ComposerSegment> seed;
}

/// The Examples gallery — eight ready-made configurations, the same core
/// component under different mode presets. Mirrors `Gallery` in showcase.jsx.
class GalleryTab extends StatelessWidget {
  const GalleryTab({super.key, required this.toast});
  final ToastController toast;

  static final List<_Example> examples = [
    _Example('ai', 'AI Prompt Composer', 'sparkles', 'blue',
        'Tools, skills, files & context with a model picker and access posture.', 'aiPrompt', [
      _t('Use '), _r('skill', title: 'Reconciliation'),
      _t(' on '), _r('file', title: 'q4-reconciliation.xlsx', path: 'finance/q4-reconciliation.xlsx'),
      _t(' and brief '),
    ]),
    _Example('file', 'File Path Composer', 'folder', 'orange',
        'Local & remote paths via file: / path:, truncated and tappable to preview.', 'note', [
      _t('Open '), _r('file', title: 'contracts/client-a.pdf', path: 'contracts/client-a.pdf', subtitle: 'remote'),
      _t(' next to '), _r('folder', title: 'finance/', path: 'finance/'),
    ]),
    _Example('invoice', 'Invoice Note Composer', 'receipt', 'green',
        'Permission-aware notes linking invoices, accounts & payments.', 'invoiceNote', [
      _t('Reviewed '), _r('invoice', title: 'INV-2026-001', subtitle: '\$5,240.00'),
      _t(' against '), _r('financialAccount', title: 'Main Bank Account'), _t('.'),
    ]),
    _Example('finance', 'Financial Account Reference', 'wallet', 'green',
        'Sensitive workflow — requires an account, validates references.', 'financialEntry', [
      _t('Settle '), _r('transaction', title: 'TR-9042', subtitle: '\$5,000.00'),
      _t(' from '), _r('bankAccount', title: 'Al-Rajhi · ****6612'),
    ]),
    _Example('task', 'Task Description Composer', 'square-check-big', 'violet',
        'Assignees, linked records, /due & /status commands, attachments.', 'taskDescription', [
      _t('Assign '), _r('task', title: 'Prepare Report'),
      _t(' to '), _r('user', title: 'Ahmed Al-Rashid', subtitle: 'Finance'), _t(' — due Friday.'),
    ]),
    _Example('mention', 'User Mention Composer', 'at-sign', 'blue',
        'Minimal comment box — only @ mentions, requires text.', 'comment', [
      _t('Great work '), _r('user', title: 'Sara Khan', subtitle: 'Accountant'),
      _t(' — can you confirm the figures?'),
    ]),
    _Example('command', 'Command Composer', 'terminal', 'blue',
        'Slash-only palette; validates that a command was chosen.', 'command', [
      _r('command', title: 'assign', subtitle: 'Assign to user'), _t(' '),
    ]),
    _Example('mixed', 'Mixed References Composer', 'shapes', 'violet',
        'Every entity type side-by-side — the spec example, fully tokenised.', 'aiPrompt',
        ComposerSeed.seedSegments('Review invoice [INV-2026-001], compare it with account [Main Bank Account], assign task [Prepare Report] to user [Ahmed], and attach file [contracts/client-a.pdf].')),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = ComposerThemeScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Ui.sectionNote(theme,
            'Eight ready-made configurations — same core component, different mode presets. Each is fully live: type a trigger, tap a token, add an attachment.'),
        LayoutBuilder(builder: (context, constraints) {
          final twoCol = constraints.maxWidth > 760;
          final cardWidth = twoCol ? (constraints.maxWidth - 20) / 2 : constraints.maxWidth;
          return Wrap(
            spacing: 20,
            runSpacing: 20,
            children: examples.map((ex) => SizedBox(width: cardWidth, child: _card(theme, ex))).toList(),
          );
        }),
      ],
    );
  }

  Widget _card(ComposerTheme theme, _Example ex) {
    final acc = ComposerAccents.resolve(ex.accent);
    return Ui.card(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: acc.bg, borderRadius: BorderRadius.circular(7)),
                child: Icon(ComposerIcons.resolve(ex.icon), size: 16, color: acc.fg),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ex.title, style: TextStyle(color: theme.fg1, fontSize: 14.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(ex.desc, style: TextStyle(color: theme.fg3, fontSize: 12, height: 1.45)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: theme.bg2, borderRadius: BorderRadius.circular(5), border: Border.all(color: theme.borderSoft)),
                child: Text(ex.modeId, style: TextStyle(fontFamily: theme.monoFont, fontSize: 10.5, color: theme.fg3)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SmartComposer(
            mode: ComposerModes.byId[ex.modeId]!,
            seed: ex.seed,
            callbacks: tapCallbacks(toast),
          ),
        ],
      ),
    );
  }
}
