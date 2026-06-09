import 'package:flutter/material.dart';
import 'package:smart_composer_flutter/smart_composer_flutter.dart';

import '../ui.dart';

/// The Playground tab — a live composer with a mode picker, read-only toggle,
/// trigger chips, a value inspector (encodedText / plainText / tokensIndex) and
/// a callback log. Mirrors `Playground` in showcase.jsx.
class PlaygroundTab extends StatefulWidget {
  const PlaygroundTab({super.key, required this.toast});
  final ToastController toast;

  @override
  State<PlaygroundTab> createState() => _PlaygroundTabState();
}

class _PlaygroundTabState extends State<PlaygroundTab> {
  static const _modeOrder = [
    'aiPrompt', 'search', 'command', 'note', 'comment',
    'taskDescription', 'invoiceNote', 'financialEntry', 'message',
  ];

  String _modeId = 'aiPrompt';
  bool _readOnly = false;
  // config panel collapsed by default on mobile (stacked under the composer)
  bool _cfgOpen = false;
  final List<_LogEntry> _log = [];
  ComposerEditorValue _snap = ComposerEditorValue.empty;
  ComposerController? _api;

  ComposerMode get _mode => ComposerModes.byId[_modeId]!;

  void _pushLog(String name, String detail) {
    setState(() {
      _log.insert(0, _LogEntry(name, detail, TimeOfDay.now()));
      if (_log.length > 7) _log.removeRange(7, _log.length);
    });
  }

  ComposerCallbacks _callbacks() {
    final base = tapCallbacks(widget.toast, _pushLog);
    return ComposerCallbacks(
      onReferenceTap: base.onReferenceTap,
      onAttachmentTap: base.onAttachmentTap,
      onFilePathTap: base.onFilePathTap,
      onUserTap: base.onUserTap,
      onInvoiceTap: base.onInvoiceTap,
      onTaskTap: base.onTaskTap,
      onFinancialAccountTap: base.onFinancialAccountTap,
      onCommandTap: base.onCommandTap,
      onChanged: (v) => setState(() => _snap = v),
      onReferenceSelected: (r) => _pushLog('onReferenceSelected', r.title),
      onReferenceRemoved: (r) => _pushLog('onReferenceRemoved', r.title),
      onAttachmentAdded: (a) => _pushLog('onAttachmentAdded', a.title),
      onAttachmentRemoved: (a) => _pushLog('onAttachmentRemoved', a.title),
      onCommandSelected: (r) => _pushLog('onCommandSelected', '/${r.title}'),
      onSubmitted: (v) {
        _pushLog('onSubmitted', '${v.text.length} chars · ${v.references.length} refs');
        widget.toast.show('Submitted ✓', Icons.check);
      },
    );
  }

  void _seedBig() => _api?.setSegments(ComposerSeed.seedSegments(
        'Review invoice [INV-2026-001], compare it with account [Main Bank Account], assign task [Prepare Report] to user [Ahmed], and attach file [contracts/client-a.pdf].',
      ));

  @override
  Widget build(BuildContext context) {
    final theme = ComposerThemeScope.of(context);
    // ≤940px the layout stacks and the config panel becomes collapsible
    final wide = MediaQuery.of(context).size.width > 940;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _intro(theme),
        const SizedBox(height: 24),
        Flex(
          direction: wide ? Axis.horizontal : Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: wide ? 3 : 0, child: _main(theme)),
            SizedBox(width: wide ? 20 : 0, height: wide ? 0 : 20),
            SizedBox(width: wide ? 320 : double.infinity, child: _panel(theme, collapsible: !wide)),
          ],
        ),
      ],
    );
  }

  Widget _intro(ComposerTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Ui.eyebrow(theme, 'Reusable · extensible · themeable'),
        const SizedBox(height: 12),
        Text('One composer. Every entity.',
            style: TextStyle(color: theme.fg1, fontSize: 30, fontWeight: FontWeight.w800, fontFamily: theme.displayFont, letterSpacing: -0.5)),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Text(
            'A generic rich-text editor that mixes plain text with inline reference tokens — files, users, invoices, accounts, tasks, tools, commands and any custom type. MVC core, framework-agnostic model, no module-specific behaviour hardcoded.',
            style: TextStyle(color: theme.fg3, fontSize: 14.5, height: 1.6),
          ),
        ),
      ],
    );
  }

  Widget _main(ComposerTheme theme) {
    final triggers = _mode.triggers;
    return Column(
      key: ValueKey('main-$_modeId-$_readOnly'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Ui.eyebrow(theme, 'Live composer · ${_mode.label}'),
            const Spacer(),
            Ui.miniButton(theme, ComposerIcons.resolve('wand-sparkles'), 'Seed example', _seedBig),
            const SizedBox(width: 8),
            Ui.miniButton(theme, ComposerIcons.resolve('eraser'), 'Clear', () => _api?.clear()),
          ],
        ),
        const SizedBox(height: 12),
        SmartComposer(
          key: ValueKey('composer-$_modeId-$_readOnly'),
          mode: _mode,
          callbacks: _callbacks(),
          readOnly: _readOnly,
          onReady: (c) {
            _api = c;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _snap = c.getValue());
            });
          },
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Try a trigger:', style: TextStyle(color: theme.fg3, fontSize: 12.5)),
            ...triggers.map((k) {
              final tg = Triggers.all[k]!;
              return Material(
                color: theme.bg2,
                borderRadius: BorderRadius.circular(6),
                child: InkWell(
                  onTap: () => _api?.openTrigger(tg.symbol),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.all(color: theme.borderSoft)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(tg.symbol, style: TextStyle(fontFamily: theme.monoFont, color: theme.accent, fontSize: 12, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 6),
                        Text(tg.hint, style: TextStyle(color: theme.fg2, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 18),
        _inspector(theme),
      ],
    );
  }

  Widget _inspector(ComposerTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _inspectCol(theme, 'encodedText · source of truth', Ui.codeBlock(theme, _snap.encodedText, emptyLabel: '— empty —')),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _inspectCol(theme, 'plainText · derived', Ui.codeBlock(theme, _snap.plainText, emptyLabel: '— empty —'))),
            const SizedBox(width: 12),
            Expanded(child: _inspectCol(theme, 'tokensIndex · ${_snap.references.length}', _refList(theme))),
          ],
        ),
      ],
    );
  }

  Widget _inspectCol(ComposerTheme theme, String header, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(header.toUpperCase(), style: TextStyle(color: theme.fg3, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        ),
        child,
      ],
    );
  }

  Widget _refList(ComposerTheme theme) {
    if (_snap.references.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: theme.bg2, borderRadius: BorderRadius.circular(8), border: Border.all(color: theme.borderSoft)),
        child: Text('none', style: TextStyle(color: theme.fg3, fontSize: 12)),
      );
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: _snap.references.map((r) {
        final acc = ComposerAccents.resolve(r.accent);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(color: acc.bg, borderRadius: BorderRadius.circular(6), border: Border.all(color: acc.border)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(ComposerIcons.resolve(r.icon), size: 12, color: acc.fg),
              const SizedBox(width: 5),
              Text('${EncodingUtil.prefixForType(r.type)}${r.type}', style: TextStyle(fontFamily: theme.monoFont, fontSize: 10.5, color: acc.fg)),
              const SizedBox(width: 5),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 110),
                child: Text(r.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: theme.fg2, fontSize: 11.5)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _panel(ComposerTheme theme, {bool collapsible = false}) {
    final triggers = _mode.triggers;
    final showBody = !collapsible || _cfgOpen;
    return Ui.card(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Configuration header doubles as a collapse toggle on mobile
          if (collapsible)
            InkWell(
              onTap: () => setState(() => _cfgOpen = !_cfgOpen),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Icon(ComposerIcons.resolve('sliders-horizontal'), size: 15, color: theme.fg2),
                    const SizedBox(width: 8),
                    Text('Configuration', style: TextStyle(color: theme.fg1, fontSize: 13, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    AnimatedRotation(
                      turns: _cfgOpen ? 0 : -0.25,
                      duration: const Duration(milliseconds: 180),
                      child: Icon(ComposerIcons.resolve('chevron-down'), size: 15, color: theme.fg3),
                    ),
                  ],
                ),
              ),
            )
          else
            Ui.panelHeader(theme, ComposerIcons.resolve('sliders-horizontal'), 'Configuration'),
          if (showBody) ...[
          _fieldLabel(theme, 'Mode'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _modeOrder.map((id) {
              final m = ComposerModes.byId[id]!;
              final on = id == _modeId;
              return Material(
                color: on ? theme.accent : theme.bg2,
                borderRadius: BorderRadius.circular(6),
                child: InkWell(
                  onTap: () => setState(() => _modeId = id),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.all(color: on ? theme.accent : theme.borderSoft)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(ComposerIcons.resolve(m.icon), size: 13, color: on ? Colors.white : theme.fg2),
                        const SizedBox(width: 5),
                        Text(m.label, style: TextStyle(color: on ? Colors.white : theme.fg2, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _fieldLabel(theme, 'Read only'),
              Ui.switchBtn(theme, _readOnly, () => setState(() => _readOnly = !_readOnly)),
            ],
          ),
          const SizedBox(height: 16),
          _fieldLabel(theme, 'Active triggers'),
          Wrap(
            spacing: 6,
            children: triggers.map((k) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(color: theme.bg2, borderRadius: BorderRadius.circular(5), border: Border.all(color: theme.borderSoft)),
              child: Text(Triggers.all[k]!.symbol, style: TextStyle(fontFamily: theme.monoFont, color: theme.accent, fontSize: 11.5, fontWeight: FontWeight.w700)),
            )).toList(),
          ),
          const SizedBox(height: 16),
          _fieldLabel(theme, 'Toolbar'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _mode.toolbar.where((t) => t != 'spacer').map((t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(color: theme.bg2, borderRadius: BorderRadius.circular(5), border: Border.all(color: theme.borderSoft)),
              child: Text(t, style: TextStyle(color: theme.fg3, fontSize: 11, fontFamily: theme.monoFont)),
            )).toList(),
          ),
          const SizedBox(height: 20),
          Ui.panelHeader(theme, ComposerIcons.resolve('activity'), 'Callback log'),
          _logView(theme),
          ],
        ],
      ),
    );
  }

  Widget _fieldLabel(ComposerTheme theme, String s) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(s.toUpperCase(), style: TextStyle(color: theme.fg3, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      );

  Widget _logView(ComposerTheme theme) {
    if (_log.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        child: Text('Interact with the composer — callbacks appear here.', style: TextStyle(color: theme.fg3, fontSize: 12)),
      );
    }
    return Column(
      children: _log.map((e) {
        final t = '${e.time.hour.toString().padLeft(2, '0')}:${e.time.minute.toString().padLeft(2, '0')}';
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t, style: TextStyle(fontFamily: theme.monoFont, fontSize: 10.5, color: theme.fg3)),
              const SizedBox(width: 8),
              Text(e.name, style: TextStyle(fontFamily: theme.monoFont, fontSize: 11, color: theme.accent, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Expanded(child: Text(e.detail, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: theme.fg2, fontSize: 11.5))),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _LogEntry {
  _LogEntry(this.name, this.detail, this.time);
  final String name;
  final String detail;
  final TimeOfDay time;
}
