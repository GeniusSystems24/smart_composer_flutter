import 'package:flutter/material.dart';

import '../controller/composer_controller.dart';
import '../model/accents.dart';
import '../model/reference.dart';
import '../theme/composer_theme.dart';
import 'composer_icons.dart';

/// An inline reference token rendered inside the editor (the Flutter equivalent
/// of the React `.sc-token` span). Shows an icon, label, optional subtitle and a
/// hover-reveal remove (×) button. Tapping the chip fires the tap callbacks;
/// tapping × removes it.
class ComposerTokenChip extends StatefulWidget {
  const ComposerTokenChip({
    super.key,
    required this.controller,
    required this.reference,
    required this.code,
    required this.selected,
    required this.readOnly,
  });

  final ComposerController controller;
  final ComposerReference reference;
  final int code;
  final bool selected;
  final bool readOnly;

  @override
  State<ComposerTokenChip> createState() => _ComposerTokenChipState();
}

class _ComposerTokenChipState extends State<ComposerTokenChip> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = ComposerThemeScope.of(context);
    final ref = widget.reference;
    final isError = ref.state == 'error';
    final isDisabled = ref.state == 'disabled' || !ref.isEnabled;

    ComposerAccent acc = ComposerAccents.resolve(ref.accent);
    if (isError) acc = ComposerAccents.resolve('red');

    final fg = acc.fg;
    final bg = widget.selected
        ? Color.alphaBlend(acc.fg.withOpacity(0.30), theme.bg)
        : (_hover ? acc.bgHover : acc.bg);

    final label = ref.displayText.isNotEmpty
        ? ref.displayText
        : (ref.title.isNotEmpty ? ref.title : (ref.value?.toString() ?? ''));

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.controller.tapToken(ref),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 1),
          padding: const EdgeInsets.fromLTRB(6, 2, 6, 2),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(theme.tokenRadius),
            border: Border.all(color: acc.border),
            boxShadow: widget.selected
                ? [BoxShadow(color: acc.fg, spreadRadius: 1.5, blurRadius: 0)]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(ComposerIcons.resolve(ref.icon), size: 13, color: fg),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fg,
                    fontSize: ref.mono ? 12.5 : 13.5,
                    fontWeight: ref.mono ? FontWeight.w500 : FontWeight.w600,
                    fontFamily: ref.mono ? theme.monoFont : theme.bodyFont,
                    decoration: isDisabled ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              if (ref.subtitle.isNotEmpty) ...[
                const SizedBox(width: 5),
                Container(
                  margin: const EdgeInsets.only(right: 1),
                  padding: const EdgeInsets.only(left: 5),
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(color: acc.fg.withOpacity(0.35))),
                  ),
                  child: Text(
                    ref.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color.alphaBlend(acc.fg.withOpacity(0.62), theme.fg3),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      fontFamily: theme.bodyFont,
                    ),
                  ),
                ),
              ],
              if (isError) ...[
                const SizedBox(width: 2),
                Text('!', style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 13.5)),
              ],
              if (!widget.readOnly && (_hover || widget.selected)) ...[
                const SizedBox(width: 2),
                GestureDetector(
                  onTap: () => widget.controller.removeTokenByCode(widget.code),
                  child: Icon(Icons.close, size: 12, color: fg.withOpacity(0.75)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
