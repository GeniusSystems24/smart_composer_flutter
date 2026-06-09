import 'package:flutter/material.dart';

import '../controller/composer_controller.dart';
import '../model/accents.dart';
import '../model/attachment.dart';
import '../model/reference_registry.dart';
import '../theme/composer_theme.dart';
import 'composer_icons.dart';

/// The attachment bar beneath the editor (`.sc-attbar`).
class AttachmentBar extends StatelessWidget {
  const AttachmentBar({super.key, required this.controller, required this.attachments});

  final ComposerController controller;
  final List<ComposerAttachment> attachments;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();
    final theme = ComposerThemeScope.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: attachments.map((a) => _chip(context, theme, a)).toList(),
      ),
    );
  }

  Widget _chip(BuildContext context, ComposerTheme theme, ComposerAttachment a) {
    final def = ReferenceRegistry.get(a.type);
    final acc = ComposerAccents.resolve(a.accent);
    final meta = a.meta.isNotEmpty ? a.meta : a.subtitle;
    return GestureDetector(
      onTap: () => controller.callbacks.onAttachmentTap?.call(a),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 240),
        padding: const EdgeInsets.fromLTRB(6, 6, 8, 6),
        decoration: BoxDecoration(
          color: theme.bg2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.borderSoft),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(color: acc.bg, borderRadius: BorderRadius.circular(6)),
              child: Icon(ComposerIcons.resolve(a.icon.isNotEmpty ? a.icon : def.icon), size: 16, color: acc.fg),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: theme.fg1, fontWeight: FontWeight.w600, fontSize: 12.5)),
                  if (meta.isNotEmpty)
                    Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: theme.fg3, fontSize: 11)),
                  if (a.state == 'uploading')
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(value: a.progress, minHeight: 3, backgroundColor: theme.borderSoft, color: theme.accent),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => controller.removeAttachment(a.id),
              child: Icon(Icons.close, size: 14, color: theme.fg3),
            ),
          ],
        ),
      ),
    );
  }
}

/// The validation / state banner (`.sc-banner--error`).
class ComposerBanner extends StatelessWidget {
  const ComposerBanner({super.key, required this.controller});

  final ComposerController controller;

  @override
  Widget build(BuildContext context) {
    final theme = ComposerThemeScope.of(context);
    if (controller.stateName == 'readOnly') return const SizedBox.shrink();
    final v = controller.validation;
    if (v.valid || controller.isEmpty) return const SizedBox.shrink();
    if (v.errors.isEmpty) return const SizedBox.shrink();
    final first = v.errors.first;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0x1FEF4444),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0x4DEF4444)),
        ),
        child: Row(
          children: [
            Icon(ComposerIcons.resolve('alert-triangle'), size: 15, color: const Color(0xFFFCA5A5)),
            const SizedBox(width: 8),
            Flexible(child: Text(first.message, style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12.5))),
          ],
        ),
      ),
    );
  }
}
