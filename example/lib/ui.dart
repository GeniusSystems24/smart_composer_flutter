import 'package:flutter/material.dart';
import 'package:smart_composer_flutter/smart_composer_flutter.dart';

/// Lightweight shared UI helpers used across the example tabs — eyebrow with a
/// GeniusLink section marker, mini buttons, switches, code blocks and the toast
/// host — mirroring the `.pg-*` classes in the React showcase CSS.
class Ui {
  Ui._();

  static Widget marker(ComposerTheme theme, String accent) {
    final c = ComposerAccents.resolve(accent).fg;
    return Container(
      width: 4,
      height: 16,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(12)),
    );
  }

  static Widget eyebrow(ComposerTheme theme, String text, {String accent = 'blue'}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        marker(theme, accent),
        Text(
          text.toUpperCase(),
          style: TextStyle(
            color: theme.fg3,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }

  static Widget miniButton(ComposerTheme theme, IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: theme.bg2,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: theme.borderSoft),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: theme.fg2),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: theme.fg2, fontSize: 12.5, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  static Widget switchBtn(ComposerTheme theme, bool on, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 38,
        height: 22,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: on ? theme.accent : theme.bg2,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: on ? theme.accent : theme.borderSoft),
        ),
        child: Align(
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }

  static Widget codeBlock(ComposerTheme theme, String text, {String? emptyLabel}) {
    final isEmpty = text.isEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.bg2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.borderSoft),
      ),
      child: SelectableText(
        isEmpty ? (emptyLabel ?? '— empty —') : text,
        style: TextStyle(
          fontFamily: theme.monoFont,
          fontSize: 12,
          height: 1.5,
          color: isEmpty ? theme.fg3 : theme.fg2,
        ),
      ),
    );
  }

  static Widget panelHeader(ComposerTheme theme, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 15, color: theme.fg2),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: theme.fg1, fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  static Widget sectionNote(ComposerTheme theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Text(
        text,
        style: TextStyle(color: theme.fg3, fontSize: 13.5, height: 1.6),
      ),
    );
  }

  static Widget card(ComposerTheme theme, {required Widget child, EdgeInsets? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.bg,
        borderRadius: BorderRadius.circular(theme.radius),
        border: Border.all(color: theme.borderSoft),
        boxShadow: theme.brightness == Brightness.dark
            ? const [BoxShadow(color: Color(0x40000000), blurRadius: 50, offset: Offset(0, 25))]
            : const [BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 8))],
      ),
      child: child,
    );
  }
}

/// Simple toast overlay used by tap callbacks across the demo (the APP decides
/// navigation; the composer only fires callbacks). Mirrors the React `ToastHost`.
class ToastController extends ChangeNotifier {
  String? _text;
  IconData? _icon;
  String? get text => _text;
  IconData? get icon => _icon;

  void show(String text, [IconData? icon]) {
    _text = text;
    _icon = icon;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (_text == text) {
        _text = null;
        notifyListeners();
      }
    });
  }
}

class ToastHost extends StatelessWidget {
  const ToastHost({super.key, required this.controller});
  final ToastController controller;

  @override
  Widget build(BuildContext context) {
    final theme = ComposerThemeScope.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.text == null) return const SizedBox.shrink();
        return Positioned(
          bottom: 24,
          left: 0,
          right: 0,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark ? const Color(0xFF2A2D33) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.border),
                  boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 24, offset: Offset(0, 8))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(controller.icon ?? Icons.ads_click, size: 15, color: theme.accent),
                    const SizedBox(width: 8),
                    Text(controller.text!, style: TextStyle(color: theme.fg1, fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Standard callback set that surfaces taps as toasts. The app decides
/// navigation — the composer never navigates. Mirrors `tapCallbacks` in showcase.
ComposerCallbacks tapCallbacks(ToastController toast, [void Function(String, String)? log]) {
  return ComposerCallbacks(
    onReferenceTap: (r) {
      toast.show('Open ${ReferenceRegistry.get(r.type).label.toLowerCase()}: ${r.title}', ComposerIcons.resolve(r.icon));
      log?.call('onReferenceTap', r.title);
    },
    onAttachmentTap: (a) {
      toast.show('Open attachment: ${a.title}', ComposerIcons.resolve(a.icon));
      log?.call('onAttachmentTap', a.title);
    },
    onFilePathTap: (r) => log?.call('onFilePathTap', r.path.isNotEmpty ? r.path : r.title),
    onUserTap: (r) => log?.call('onUserTap', r.title),
    onInvoiceTap: (r) => log?.call('onInvoiceTap', r.title),
    onTaskTap: (r) => log?.call('onTaskTap', r.title),
    onFinancialAccountTap: (r) => log?.call('onFinancialAccountTap', r.title),
    onCommandTap: (r) => log?.call('onCommandTap', r.title),
  );
}
