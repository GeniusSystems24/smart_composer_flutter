import 'package:flutter/material.dart';

import '../controller/composer_controller.dart';
import '../model/accents.dart';
import '../model/access_modes.dart';
import '../model/attachment.dart';
import '../theme/composer_theme.dart';
import 'composer_icons.dart';

class _Model {
  const _Model(this.id, this.label, this.desc, this.icon, this.accent);
  final String id;
  final String label;
  final String desc;
  final String icon;
  final String accent;
}

const _models = [
  _Model('sonnet', 'Claude Sonnet', 'Balanced · default', 'sparkles', 'blue'),
  _Model('opus', 'Claude Opus', 'Most capable', 'brain', 'violet'),
  _Model('haiku', 'Claude Haiku', 'Fastest', 'zap', 'green'),
];

const _attachOptions = [
  ['file', 'Upload file', 'file'],
  ['image', 'Add image', 'image'],
  ['invoice', 'Attach invoice', 'receipt'],
  ['report', 'Attach report', 'chart-column'],
  ['link', 'Add link', 'link'],
];

ComposerAttachment _sampleAttachment(String key) {
  switch (key) {
    case 'file':
      return ComposerAttachment(type: 'file', title: 'q4-reconciliation.xlsx', meta: '880 KB · Sheet', path: 'finance/q4-reconciliation.xlsx');
    case 'image':
      return ComposerAttachment(type: 'image', title: 'storefront-render.png', meta: '1.2 MB · PNG');
    case 'invoice':
      return ComposerAttachment(type: 'invoice', title: 'INV-2026-001', meta: 'Client A · \$5,240.00');
    case 'report':
      return ComposerAttachment(type: 'report', title: 'Q4 P&L', meta: 'PDF · generated');
    case 'link':
      return ComposerAttachment(type: 'link', title: 'genius.link/q4-board', meta: 'External link');
    default:
      return ComposerAttachment(type: 'file', title: key);
  }
}

/// The configurable toolbar (`.sc-toolbar`). Renders only the buttons named in
/// `mode.toolbar`, in order.
class ComposerToolbar extends StatelessWidget {
  const ComposerToolbar({super.key, required this.controller});

  final ComposerController controller;

  @override
  Widget build(BuildContext context) {
    final theme = ComposerThemeScope.of(context);
    final mode = controller.mode;
    final v = controller.value;
    final count = v.text.length;
    final maxLen = mode.validation.maxLength;
    final access = AccessModes.byId(controller.accessMode) ?? AccessModes.all.first;
    final model = _models.firstWhere((m) => m.id == controller.modelName, orElse: () => _models.first);

    return Container(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.borderSoft))),
      child: LayoutBuilder(
        builder: (context, c) {
          // Responsive toolbar — mirrors the ResizeObserver-driven `.sc-toolbar`
          // in view.jsx. As the toolbar narrows, pill / button text collapses to
          // icons so the single row never overflows (Flutter Rows don't wrap).
          // Thresholds are picked so the laid-out row always fits its width.
          final narrow = c.maxWidth < 540; // hide model / access / assign labels
          final tiny = c.maxWidth < 420;   // also hide char counter + send label
          final children = <Widget>[];
          for (final key in mode.toolbar) {
            switch (key) {
              case 'spacer':
                children.add(const Spacer());
                break;
              case 'attach':
                children.add(_attachMenu(context, theme));
                break;
              case 'reference':
                children.add(_iconBtn(theme, 'at-sign', 'Insert reference (@)', () => controller.openTrigger('@')));
                break;
              case 'command':
                children.add(_iconBtn(theme, 'slash-square', 'Run command (/)', () => controller.openTrigger('/')));
                break;
              case 'assignee':
                children.add(_textBtn(theme, 'user-plus', 'Assign', () => controller.openTrigger('@'), collapsed: narrow));
                break;
              case 'model':
                children.add(_modelMenu(context, theme, model, narrow));
                break;
              case 'access':
                children.add(_accessMenu(context, theme, access, narrow));
                break;
              case 'send':
                children.add(_sendGroup(theme, count, maxLen, tiny: tiny));
                break;
            }
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(children: _spaced(children)),
          );
        },
      ),
    );
  }

  List<Widget> _spaced(List<Widget> items) {
    final out = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      out.add(items[i]);
      if (i != items.length - 1 && items[i] is! Spacer && items[i + 1] is! Spacer) {
        out.add(const SizedBox(width: 4));
      }
    }
    return out;
  }

  Widget _iconBtn(ComposerTheme theme, String icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: Icon(ComposerIcons.resolve(icon), size: 16, color: theme.fg2),
        ),
      ),
    );
  }

  Widget _textBtn(ComposerTheme theme, String icon, String label, VoidCallback onTap, {bool collapsed = false}) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 32,
          width: collapsed ? 32 : null,
          alignment: collapsed ? Alignment.center : null,
          padding: collapsed ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(ComposerIcons.resolve(icon), size: 16, color: theme.fg2),
              if (!collapsed) ...[
                const SizedBox(width: 6),
                Text(label, style: TextStyle(color: theme.fg2, fontSize: 12.5, fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(ComposerTheme theme, String icon, String label, Color color, VoidCallback onTap, {bool collapsed = false}) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 32,
          padding: EdgeInsets.symmetric(horizontal: collapsed ? 7 : 8),
          decoration: BoxDecoration(
            border: Border.all(color: theme.borderSoft),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(ComposerIcons.resolve(icon), size: 15, color: color),
              if (!collapsed) ...[
                const SizedBox(width: 6),
                Text(label, style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w600)),
              ],
              const SizedBox(width: 4),
              Icon(ComposerIcons.resolve('chevron-down'), size: 13, color: color),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sendGroup(ComposerTheme theme, int count, int? maxLen, {bool tiny = false}) {
    final disabled = controller.isEmpty || !controller.validation.valid;
    final mode = controller.mode;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (maxLen != null && !tiny) ...[
          Text('$count/$maxLen',
              style: TextStyle(fontFamily: theme.monoFont, fontSize: 11, color: count > maxLen ? theme.danger : theme.fg3)),
          const SizedBox(width: 4),
        ],
        Opacity(
          opacity: disabled ? 0.4 : 1,
          child: Material(
            color: theme.accent,
            borderRadius: BorderRadius.circular(6),
            child: InkWell(
              onTap: disabled ? null : () => controller.submit(),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: tiny ? 9 : 14, vertical: 7),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!tiny) ...[
                      Text(mode.submitLabel, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 7),
                    ],
                    Icon(ComposerIcons.resolve(mode.submitIcon), size: 15, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---- menus ----
  Widget _menuRow(ComposerTheme theme, {required String icon, required Color accentFg, required Color accentBg, required String title, String? desc, bool active = false, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: active ? theme.accent.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(color: accentBg, borderRadius: BorderRadius.circular(6)),
              child: Icon(ComposerIcons.resolve(icon), size: 15, color: accentFg),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: TextStyle(color: theme.fg1, fontSize: 13, fontWeight: FontWeight.w600)),
                  if (desc != null) Text(desc, style: TextStyle(color: theme.fg3, fontSize: 11.5)),
                ],
              ),
            ),
            if (active) Icon(ComposerIcons.resolve('check'), size: 16, color: theme.accent),
          ],
        ),
      ),
    );
  }

  MenuStyle _menuStyle(ComposerTheme theme) => MenuStyle(
        backgroundColor: MaterialStatePropertyAll(theme.surface),
        side: MaterialStatePropertyAll(BorderSide(color: theme.border)),
        shape: MaterialStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        padding: const MaterialStatePropertyAll(EdgeInsets.all(6)),
      );

  Widget _modelMenu(BuildContext context, ComposerTheme theme, _Model model, bool collapsed) {
    return MenuAnchor(
      style: _menuStyle(theme),
      builder: (ctx, ctrl, _) => GestureDetector(
        onTap: () => ctrl.isOpen ? ctrl.close() : ctrl.open(),
        child: _pill(theme, model.icon, model.label, theme.fg2, () => ctrl.isOpen ? ctrl.close() : ctrl.open(), collapsed: collapsed),
      ),
      menuChildren: _models.map((m) {
        final acc = ComposerAccents.resolve(m.accent);
        return _menuRow(theme,
            icon: m.icon, accentFg: acc.fg, accentBg: acc.bg, title: m.label, desc: m.desc, active: m.id == model.id,
            onTap: () => controller.setModel(m.id));
      }).toList(),
    );
  }

  Widget _accessMenu(BuildContext context, ComposerTheme theme, AccessMode access, bool collapsed) {
    final accColor = ComposerAccents.resolve(access.accent).fg;
    return MenuAnchor(
      style: _menuStyle(theme),
      builder: (ctx, ctrl, _) => _pill(theme, access.icon, access.label, accColor, () => ctrl.isOpen ? ctrl.close() : ctrl.open(), collapsed: collapsed),
      menuChildren: AccessModes.all.map((a) {
        final acc = ComposerAccents.resolve(a.accent);
        return _menuRow(theme,
            icon: a.icon, accentFg: acc.fg, accentBg: acc.bg, title: a.label, desc: a.desc, active: a.id == access.id,
            onTap: () => controller.setAccessMode(a.id));
      }).toList(),
    );
  }

  Widget _attachMenu(BuildContext context, ComposerTheme theme) {
    return MenuAnchor(
      style: _menuStyle(theme),
      builder: (ctx, ctrl, _) => _iconBtn(theme, 'plus', 'Add attachment', () => ctrl.isOpen ? ctrl.close() : ctrl.open()),
      menuChildren: _attachOptions.map((opt) {
        return _menuRow(theme,
            icon: opt[2], accentFg: theme.fg2, accentBg: theme.bg2, title: opt[1],
            onTap: () => controller.addAttachment(_sampleAttachment(opt[0])));
      }).toList(),
    );
  }
}
