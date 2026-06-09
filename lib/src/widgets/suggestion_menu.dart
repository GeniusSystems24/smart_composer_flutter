import 'package:flutter/material.dart';

import '../controller/composer_controller.dart';
import '../model/accents.dart';
import '../model/reference_registry.dart';
import '../theme/composer_theme.dart';
import 'composer_icons.dart';

/// The floating suggestion menu (`.sc-menu`). Rendered by [SmartComposer] inside
/// an overlay, anchored beneath the editor.
class SuggestionMenu extends StatelessWidget {
  const SuggestionMenu({super.key, required this.controller, required this.maxWidth});

  final ComposerController controller;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = ComposerThemeScope.of(context);
    final sug = controller.suggestion;
    if (!sug.open) return const SizedBox.shrink();
    final trig = sug.trig;

    final width = maxWidth.clamp(0, 340).toDouble();

    return Material(
      color: Colors.transparent,
      child: Container(
        width: width,
        constraints: const BoxConstraints(maxHeight: 320),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.border),
          boxShadow: const [BoxShadow(color: Color(0x73000000), blurRadius: 32, offset: Offset(0, 12))],
        ),
        padding: const EdgeInsets.all(6),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // header
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
                child: Row(
                  children: [
                    Text(
                      trig?.symbol ?? '',
                      style: TextStyle(fontFamily: theme.monoFont, color: theme.accent, fontWeight: FontWeight.w700, fontSize: 11),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      (trig?.label ?? 'Suggestions').toUpperCase(),
                      style: TextStyle(color: theme.fg3, fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 0.5),
                    ),
                    if (trig?.hint != null) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '· ${trig!.hint}',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: theme.fg3, fontWeight: FontWeight.w500, fontSize: 11),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (sug.empty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
                  child: Row(
                    children: [
                      Icon(ComposerIcons.resolve('search-x'), size: 16, color: theme.fg3),
                      const SizedBox(width: 8),
                      Flexible(child: Text('No matches for “${sug.query}”', style: TextStyle(color: theme.fg3, fontSize: 12.5))),
                    ],
                  ),
                )
              else
                ..._buildGroups(context, theme),
              // footer
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.borderSoft))),
                child: Row(
                  children: [
                    _kbd(theme, '↑'),
                    _kbd(theme, '↓'),
                    Text(' navigate', style: TextStyle(color: theme.fg3, fontSize: 10.5)),
                    const SizedBox(width: 12),
                    _kbd(theme, '↵'),
                    Text(' select', style: TextStyle(color: theme.fg3, fontSize: 10.5)),
                    const SizedBox(width: 12),
                    _kbd(theme, 'esc'),
                    Text(' dismiss', style: TextStyle(color: theme.fg3, fontSize: 10.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildGroups(BuildContext context, ComposerTheme theme) {
    final sug = controller.suggestion;
    final out = <Widget>[];
    var flatIdx = -1;
    for (final g in sug.groups) {
      out.add(Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
        child: Text(
          g.group.toUpperCase(),
          style: TextStyle(color: theme.fg3, fontWeight: FontWeight.w700, fontSize: 10, letterSpacing: 0.8),
        ),
      ));
      for (final it in g.items) {
        flatIdx++;
        final idx = flatIdx;
        final def = ReferenceRegistry.get(it.type);
        final acc = ComposerAccents.resolve(it.accent);
        final meta = (it.metadata['amount'] ?? it.metadata['args'])?.toString();
        final active = idx == sug.active;
        out.add(_Option(
          theme: theme,
          accentFg: acc.fg,
          accentBg: acc.bg,
          icon: it.icon,
          title: it.title,
          subtitle: it.subtitle,
          mono: it.mono || def.mono,
          meta: meta,
          active: active,
          onHover: () => controller.setActive(idx),
          onTap: () => controller.confirmActive(idx),
        ));
      }
    }
    return out;
  }

  Widget _kbd(ComposerTheme theme, String s) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 1),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          border: Border.all(color: theme.borderSoft),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(s, style: TextStyle(fontFamily: theme.monoFont, fontSize: 10, color: theme.fg3)),
      );
}

class _Option extends StatefulWidget {
  const _Option({
    required this.theme,
    required this.accentFg,
    required this.accentBg,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.mono,
    required this.meta,
    required this.active,
    required this.onHover,
    required this.onTap,
  });

  final ComposerTheme theme;
  final Color accentFg;
  final Color accentBg;
  final String icon;
  final String title;
  final String subtitle;
  final bool mono;
  final String? meta;
  final bool active;
  final VoidCallback onHover;
  final VoidCallback onTap;

  @override
  State<_Option> createState() => _OptionState();
}

class _OptionState extends State<_Option> {
  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return MouseRegion(
      onEnter: (_) => widget.onHover(),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: widget.active ? theme.hover : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: widget.accentBg, borderRadius: BorderRadius.circular(6)),
                child: Icon(ComposerIcons.resolve(widget.icon), size: 15, color: widget.accentFg),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.fg1,
                        fontSize: widget.mono ? 12.5 : 13.5,
                        fontWeight: widget.mono ? FontWeight.w500 : FontWeight.w600,
                        fontFamily: widget.mono ? theme.monoFont : theme.bodyFont,
                      ),
                    ),
                    if (widget.subtitle.isNotEmpty)
                      Text(
                        widget.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: theme.fg3, fontSize: 11.5),
                      ),
                  ],
                ),
              ),
              if (widget.meta != null) ...[
                const SizedBox(width: 8),
                Text(widget.meta!, style: TextStyle(fontFamily: theme.monoFont, fontSize: 11, color: theme.fg3)),
              ],
              if (widget.active) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(border: Border.all(color: theme.borderSoft), borderRadius: BorderRadius.circular(4)),
                  child: Text('↵', style: TextStyle(fontFamily: theme.monoFont, fontSize: 10, color: theme.fg3)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
