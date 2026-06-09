import 'package:flutter/widgets.dart';

/// A swappable composer theme — the data form of a `ComposerTheme`. Defaults
/// reproduce the GeniusLink design tokens (dark + light), matching
/// `colors_and_type.css` and the `.sc-root` CSS variable mapping. Override any
/// field to re-skin a single composer instance.
@immutable
class ComposerTheme {
  const ComposerTheme({
    required this.brightness,
    required this.bg, // sc-bg  → gl-surface (card)
    required this.bg2, // sc-bg-2 → gl-input-bg
    required this.surface, // gl-surface (menus/popovers)
    required this.border, // sc-border → gl-border-strong
    required this.borderSoft, // sc-border-soft → gl-border
    required this.hover, // gl-hover
    required this.fg1,
    required this.fg2,
    required this.fg3,
    required this.fg4,
    required this.accent, // gl-blue-500
    required this.accentHover, // #5E8DFF
    required this.accentPressed, // gl-blue-700
    required this.accentSoft, // gl-blue-200
    required this.danger,
    required this.success,
    required this.warning,
    this.radius = 12,
    this.tokenRadius = 6,
    this.bodyFont = 'Inter',
    this.monoFont = 'JetBrainsMono',
    this.displayFont = 'Manrope',
  });

  final Brightness brightness;
  final Color bg;
  final Color bg2;
  final Color surface;
  final Color border;
  final Color borderSoft;
  final Color hover;
  final Color fg1;
  final Color fg2;
  final Color fg3;
  final Color fg4;
  final Color accent;
  final Color accentHover;
  final Color accentPressed;
  final Color accentSoft;
  final Color danger;
  final Color success;
  final Color warning;
  final double radius;
  final double tokenRadius;
  final String bodyFont;
  final String monoFont;
  final String displayFont;

  static const _blue = Color(0xFF4A7CFF);
  static const _blueHover = Color(0xFF5E8DFF);
  static const _blue700 = Color(0xFF005AC2);
  static const _blue200 = Color(0xFFADC6FF);
  static const _danger = Color(0xFFEF4444);
  static const _success = Color(0xFF1DB88A);
  static const _warning = Color(0xFFF97316);

  /// GeniusLink dark theme (the product default).
  factory ComposerTheme.dark() => const ComposerTheme(
        brightness: Brightness.dark,
        bg: Color(0xFF1E2025), // card
        bg2: Color(0xFF33353A), // input
        surface: Color(0xFF1E2025),
        border: Color(0xFF434654), // border-strong
        borderSoft: Color(0x66434654), // rgba(67,70,84,0.4)
        hover: Color(0xFF2F3540),
        fg1: Color(0xFFE2E2E9),
        fg2: Color(0xFFC3C6D7),
        fg3: Color(0xFF8D90A0),
        fg4: Color(0xFF44474E),
        accent: _blue,
        accentHover: _blueHover,
        accentPressed: _blue700,
        accentSoft: _blue200,
        danger: _danger,
        success: _success,
        warning: _warning,
      );

  /// GeniusLink light theme (offered in parity).
  factory ComposerTheme.light() => const ComposerTheme(
        brightness: Brightness.light,
        bg: Color(0xFFFFFFFF),
        bg2: Color(0xFFF1F3F8),
        surface: Color(0xFFFFFFFF),
        border: Color(0xFFC2C6D6),
        borderSoft: Color(0xFFE2E8F0),
        hover: Color(0xFFEEF1F7),
        fg1: Color(0xFF0F172A),
        fg2: Color(0xFF424754),
        fg3: Color(0xFF64748B),
        fg4: Color(0xFFC2C6D6),
        accent: _blue,
        accentHover: _blueHover,
        accentPressed: _blue700,
        accentSoft: _blue200,
        danger: _danger,
        success: _success,
        warning: _warning,
      );

  /// The page background (`--gl-bg`) — used by host apps for letterboxing.
  Color get pageBg =>
      brightness == Brightness.dark ? const Color(0xFF111318) : const Color(0xFFF7F8FA);

  TextStyle get bodyStyle => TextStyle(fontFamily: bodyFont, color: fg1);
  TextStyle get monoStyle => TextStyle(fontFamily: monoFont, color: fg1);
}

/// Provides a [ComposerTheme] down the tree. Widgets read [ComposerTheme] via
/// [ComposerThemeScope.of]. Falls back to [ComposerTheme.dark] when absent.
class ComposerThemeScope extends InheritedWidget {
  const ComposerThemeScope({super.key, required this.theme, required super.child});

  final ComposerTheme theme;

  static ComposerTheme of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ComposerThemeScope>();
    return scope?.theme ?? ComposerTheme.dark();
  }

  @override
  bool updateShouldNotify(ComposerThemeScope oldWidget) => oldWidget.theme != theme;
}
