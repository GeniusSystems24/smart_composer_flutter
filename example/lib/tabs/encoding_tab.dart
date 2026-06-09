import 'package:flutter/material.dart';
import 'package:smart_composer_flutter/smart_composer_flutter.dart';

import '../ui.dart';

const _fullExample =
    'I want you to use [\$tool:Browser Use](skill://openai-bundled/browser-use/0.1.0-alpha1/browser) to preview the page, then run [\$skill:Spreadsheets](skill://openai-primary-runtime/spreadsheets/26.423.10653) on [@source:Documents](plugin://documents@openai-primary-runtime).\n\nReview invoice [#invoice:INV-2026-001](invoice://INV-2026-001), compare it with account [\$financialAccount:Main Bank Account](financial-account://main_bank_account), assign task [#task:Prepare Report](task://task_prepare_report) to user [@user:Ahmed](user://user_123), and attach file [@file:contracts/client-a.pdf](file:///C:/Users/Al-saiary/contracts/client-a.pdf).';

const _stateDemos = [
  ['Resolved', '[@user:Ahmed](user://user_123)', 'loads, then enriches from backend'],
  ['Loading → shimmer', '[#invoice:INV-2026-014](invoice://INV-2026-014)', 'per-token shimmer; text never blocked'],
  ['Not found', '[@user:Sara Khan](user://missing_user)', 'clear fallback label'],
  ['Permission denied', '[#invoice:Q4 Audit](invoice://restricted_q4)', 'no sensitive metadata exposed'],
  ['Error + retry', '[@file:ledger.xlsx](file:///vault/error/ledger.xlsx)', 'keeps layout, offers retry'],
];

/// The Encoding tab — format anatomy, a live encodedText ↔ preview split, an
/// editor round-trip, and the remote resolve-state gallery. Mirrors `EncodingTab`.
class EncodingTab extends StatefulWidget {
  const EncodingTab({super.key, required this.toast});
  final ToastController toast;

  @override
  State<EncodingTab> createState() => _EncodingTabState();
}

class _EncodingTabState extends State<EncodingTab> {
  late final TextEditingController _enc = TextEditingController(text: _fullExample);
  String _style = 'inline';
  bool _resolve = true;
  int _nonce = 0;
  late final TokenResolver _resolver = makeDemoResolver(delay: 800);
  ComposerController? _editorApi;

  void _tap(SmartComposerToken t) {
    widget.toast.show('${t.tagType} · ${t.valueText}', ComposerIcons.resolve(ReferenceRegistry.get(t.tagType).icon));
  }

  @override
  void dispose() {
    _enc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ComposerThemeScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Ui.sectionNote(theme,
            'The composer\u2019s source of truth is human-readable encoded text — Markdown-link-like, but with a typed prefix and a resolvable value. plainText is derived; JSON is never required to restore the editor.'),
        _anatomy(theme),
        const SizedBox(height: 24),
        _split(theme),
        const SizedBox(height: 28),
        _roundTrip(theme),
        const SizedBox(height: 28),
        Ui.eyebrow(theme, 'Remote resolve states', accent: 'orange'),
        const SizedBox(height: 14),
        _states(theme),
      ],
    );
  }

  Widget _anatomy(ComposerTheme theme) {
    final parts = [
      ['prefix', '\$', 'blue', 'category / trigger style'],
      ['tagType', 'tool', 'violet', 'the real entity type'],
      ['displayText', 'Browser Use', 'green', 'human-readable label'],
      ['valueText', 'skill://…/browser', 'orange', 'system value to resolve / open'],
    ];
    Color c(String k) => ComposerAccents.resolve(k).fg;
    return Ui.card(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            children: [
              Text('[', style: TextStyle(fontFamily: theme.monoFont, color: theme.fg3, fontSize: 15)),
              Text('<prefix>', style: TextStyle(fontFamily: theme.monoFont, color: c('blue'), fontSize: 15)),
              Text('<tagType>', style: TextStyle(fontFamily: theme.monoFont, color: c('violet'), fontSize: 15)),
              Text(':', style: TextStyle(fontFamily: theme.monoFont, color: theme.fg3, fontSize: 15)),
              Text('<displayText>', style: TextStyle(fontFamily: theme.monoFont, color: c('green'), fontSize: 15)),
              Text('](', style: TextStyle(fontFamily: theme.monoFont, color: theme.fg3, fontSize: 15)),
              Text('<valueText>', style: TextStyle(fontFamily: theme.monoFont, color: c('orange'), fontSize: 15)),
              Text(')', style: TextStyle(fontFamily: theme.monoFont, color: theme.fg3, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, constraints) {
            final w = constraints.maxWidth;
            final cols = w > 720 ? 4 : (w > 380 ? 2 : 1);
            final cellW = (w - (cols - 1) * 12) / cols;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: parts.map((p) {
                final acc = ComposerAccents.resolve(p[2]);
                return SizedBox(
                  width: cellW,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: acc.bg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border(left: BorderSide(color: acc.fg, width: 3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p[0], style: TextStyle(color: acc.fg, fontSize: 11, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(p[1], style: TextStyle(fontFamily: theme.monoFont, color: theme.fg1, fontSize: 13)),
                        const SizedBox(height: 6),
                        Text(p[3], style: TextStyle(color: theme.fg3, fontSize: 11.5, height: 1.4)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _split(ComposerTheme theme) {
    final plain = SmartComposerPlainTextConverter.convert(_enc.text).replaceAll(RegExp(r'\n+'), ' ');
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth > 760;
      final left = _encPane(theme);
      final right = _previewPane(theme, plain);
      if (wide) {
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [Expanded(child: left), const SizedBox(width: 16), Expanded(child: right)],
          ),
        );
      }
      return Column(children: [left, const SizedBox(height: 16), right]);
    });
  }

  Widget _encPane(ComposerTheme theme) {
    return Ui.card(
      theme,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(ComposerIcons.resolve('code'), size: 14, color: theme.fg2),
              const SizedBox(width: 6),
              Text('encodedText', style: TextStyle(color: theme.fg1, fontSize: 13, fontWeight: FontWeight.w600, fontFamily: theme.monoFont)),
              const Spacer(),
              Text('source of truth — edit me', style: TextStyle(color: theme.fg3, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _enc,
            onChanged: (_) => setState(() {}),
            maxLines: 9,
            style: TextStyle(fontFamily: theme.monoFont, fontSize: 12, height: 1.5, color: theme.fg2),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: theme.bg2,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.borderSoft)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.borderSoft)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.accent)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewPane(ComposerTheme theme, String plain) {
    return Ui.card(
      theme,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(ComposerIcons.resolve('eye'), size: 14, color: theme.fg2),
              const SizedBox(width: 6),
              Text('SmartComposerPreview', style: TextStyle(color: theme.fg1, fontSize: 13, fontWeight: FontWeight.w600)),
              const Spacer(),
              _styleSwitch(theme),
            ],
          ),
          const SizedBox(height: 10),
          SmartComposerPreview(
            key: ValueKey('pv-$_nonce-$_style-$_resolve'),
            encodedText: _enc.text,
            resolver: _resolve ? _resolver : null,
            onTokenTap: _tap,
            dense: _style == 'compact' || _style == 'minimal',
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Ui.switchBtn(theme, _resolve, () => setState(() => _resolve = !_resolve)),
              const SizedBox(width: 8),
              Text('remote resolver', style: TextStyle(color: theme.fg3, fontSize: 11.5)),
              const Spacer(),
              Ui.miniButton(theme, ComposerIcons.resolve('rotate-cw'), 'Replay resolve', () => setState(() => _nonce++)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.borderSoft))),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(text: 'plainText → ', style: TextStyle(fontFamily: theme.monoFont, fontSize: 11, color: theme.accent, fontWeight: FontWeight.w600)),
                  TextSpan(text: plain, style: TextStyle(color: theme.fg2, fontSize: 12, height: 1.4)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _styleSwitch(ComposerTheme theme) {
    return Wrap(
      spacing: 3,
      children: kPreviewStyles.map((s) {
        final on = s == _style;
        return GestureDetector(
          onTap: () => setState(() => _style = s),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: on ? theme.accent.withOpacity(0.14) : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: on ? theme.accent : theme.borderSoft),
            ),
            child: Text(s, style: TextStyle(fontSize: 10, color: on ? theme.accent : theme.fg3)),
          ),
        );
      }).toList(),
    );
  }

  Widget _roundTrip(ComposerTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Ui.eyebrow(theme, 'Editor ↔ encodedText round-trip', accent: 'green'),
            const Spacer(),
            Ui.miniButton(theme, ComposerIcons.resolve('download'), 'Load encoded into editor', () => _editorApi?.setEncodedText(_enc.text)),
            const SizedBox(width: 8),
            Ui.miniButton(theme, ComposerIcons.resolve('upload'), 'Read editor → encoded', () {
              if (_editorApi != null) setState(() => _enc.text = _editorApi!.getEncodedText());
            }),
          ],
        ),
        const SizedBox(height: 12),
        SmartComposer(
          mode: ComposerModes.aiPrompt,
          seed: ComposerBridge.encodedToSegments(_fullExample),
          callbacks: ComposerCallbacks(onReferenceTap: (r) => _tap(ComposerBridge.refToToken(r))),
          onReady: (c) => _editorApi = c,
        ),
      ],
    );
  }

  Widget _states(ComposerTheme theme) {
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth > 760 ? 2 : 1;
      final cellW = (constraints.maxWidth - (cols - 1) * 16) / cols;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: _stateDemos.map((d) {
          return SizedBox(
            width: cellW,
            child: Ui.card(
              theme,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d[0], style: TextStyle(color: theme.fg1, fontSize: 12.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  SmartComposerPreview(
                    key: ValueKey('state-$_nonce-${d[0]}'),
                    encodedText: d[1],
                    resolver: _resolver,
                    onTokenTap: _tap,
                  ),
                  const SizedBox(height: 8),
                  Text(d[2], style: TextStyle(color: theme.fg3, fontSize: 11.5, height: 1.4)),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(color: theme.bg2, borderRadius: BorderRadius.circular(6), border: Border.all(color: theme.borderSoft)),
                    child: Text(d[1], style: TextStyle(fontFamily: theme.monoFont, fontSize: 10.5, color: theme.fg3)),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    });
  }
}
