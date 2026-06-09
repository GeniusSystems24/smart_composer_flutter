import 'package:flutter/material.dart';

/// A swappable composer theme — the data form of a `ComposerTheme`. Defaults
/// reproduce the GeniusLink design tokens (dark + light), matching
/// `colors_and_type.css` and the `.sc-root` CSS variable mapping. Override any
/// field to re-skin a single composer instance.
///
/// `ComposerTheme` is a [ThemeExtension], so it can be injected into the app's
/// [ThemeData] once and read anywhere via `Theme.of(context).extension<ComposerTheme>()`:
///
/// ```dart
/// MaterialApp(
///   theme: ThemeData.light().copyWith(extensions: [ComposerTheme.light()]),
///   darkTheme: ThemeData.dark().copyWith(extensions: [ComposerTheme.dark()]),
///   themeMode: ThemeMode.system,
/// );
/// ```
///
/// When no `ComposerTheme` is injected, [ComposerThemeScope.of] falls back to
/// [ComposerTheme.dark] or [ComposerTheme.light] according to the ambient
/// [Theme] brightness (driven by the app's [ThemeMode]).
@immutable
class ComposerTheme extends ThemeExtension<ComposerTheme> {
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

  @override
  ComposerTheme copyWith({
    Brightness? brightness,
    Color? bg,
    Color? bg2,
    Color? surface,
    Color? border,
    Color? borderSoft,
    Color? hover,
    Color? fg1,
    Color? fg2,
    Color? fg3,
    Color? fg4,
    Color? accent,
    Color? accentHover,
    Color? accentPressed,
    Color? accentSoft,
    Color? danger,
    Color? success,
    Color? warning,
    double? radius,
    double? tokenRadius,
    String? bodyFont,
    String? monoFont,
    String? displayFont,
  }) {
    return ComposerTheme(
      brightness: brightness ?? this.brightness,
      bg: bg ?? this.bg,
      bg2: bg2 ?? this.bg2,
      surface: surface ?? this.surface,
      border: border ?? this.border,
      borderSoft: borderSoft ?? this.borderSoft,
      hover: hover ?? this.hover,
      fg1: fg1 ?? this.fg1,
      fg2: fg2 ?? this.fg2,
      fg3: fg3 ?? this.fg3,
      fg4: fg4 ?? this.fg4,
      accent: accent ?? this.accent,
      accentHover: accentHover ?? this.accentHover,
      accentPressed: accentPressed ?? this.accentPressed,
      accentSoft: accentSoft ?? this.accentSoft,
      danger: danger ?? this.danger,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      radius: radius ?? this.radius,
      tokenRadius: tokenRadius ?? this.tokenRadius,
      bodyFont: bodyFont ?? this.bodyFont,
      monoFont: monoFont ?? this.monoFont,
      displayFont: displayFont ?? this.displayFont,
    );
  }

  @override
  ComposerTheme lerp(covariant ThemeExtension<ComposerTheme>? other, double t) {
    if (other is! ComposerTheme) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    double d(double a, double b) => a + (b - a) * t;
    final pick = t < 0.5 ? this : other;
    return ComposerTheme(
      brightness: pick.brightness,
      bg: c(bg, other.bg),
      bg2: c(bg2, other.bg2),
      surface: c(surface, other.surface),
      border: c(border, other.border),
      borderSoft: c(borderSoft, other.borderSoft),
      hover: c(hover, other.hover),
      fg1: c(fg1, other.fg1),
      fg2: c(fg2, other.fg2),
      fg3: c(fg3, other.fg3),
      fg4: c(fg4, other.fg4),
      accent: c(accent, other.accent),
      accentHover: c(accentHover, other.accentHover),
      accentPressed: c(accentPressed, other.accentPressed),
      accentSoft: c(accentSoft, other.accentSoft),
      danger: c(danger, other.danger),
      success: c(success, other.success),
      warning: c(warning, other.warning),
      radius: d(radius, other.radius),
      tokenRadius: d(tokenRadius, other.tokenRadius),
      bodyFont: pick.bodyFont,
      monoFont: pick.monoFont,
      displayFont: pick.displayFont,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ComposerTheme &&
        other.brightness == brightness &&
        other.bg == bg &&
        other.bg2 == bg2 &&
        other.surface == surface &&
        other.border == border &&
        other.borderSoft == borderSoft &&
        other.hover == hover &&
        other.fg1 == fg1 &&
        other.fg2 == fg2 &&
        other.fg3 == fg3 &&
        other.fg4 == fg4 &&
        other.accent == accent &&
        other.accentHover == accentHover &&
        other.accentPressed == accentPressed &&
        other.accentSoft == accentSoft &&
        other.danger == danger &&
        other.success == success &&
        other.warning == warning &&
        other.radius == radius &&
        other.tokenRadius == tokenRadius &&
        other.bodyFont == bodyFont &&
        other.monoFont == monoFont &&
        other.displayFont == displayFont;
  }

  @override
  int get hashCode => Object.hashAll([
        brightness, bg, bg2, surface, border, borderSoft, hover,
        fg1, fg2, fg3, fg4, accent, accentHover, accentPressed, accentSoft,
        danger, success, warning, radius, tokenRadius, bodyFont, monoFont, displayFont,
      ]);
}

/// Provides a [ComposerTheme] down the tree as a per-instance override (e.g.
/// the suggestion-menu overlay re-injects the resolved theme across its portal).
///
/// [ComposerThemeScope.of] resolves the active theme in priority order:
///   1. The nearest enclosing [ComposerThemeScope] (explicit per-instance theme).
///   2. A [ComposerTheme] injected into the app's [ThemeData] as a
///      [ThemeExtension] (`Theme.of(context).extension<ComposerTheme>()`).
///   3. A default — [ComposerTheme.dark] or [ComposerTheme.light] — chosen by
///      the ambient [Theme] brightness, which the app's [ThemeMode] drives.
class ComposerThemeScope extends InheritedWidget {
  const ComposerThemeScope({super.key, required this.theme, required super.child});

  final ComposerTheme theme;

  static ComposerTheme of(BuildContext context) {
    // 1. Explicit per-instance override.
    final scope = context.dependOnInheritedWidgetOfExactType<ComposerThemeScope>();
    if (scope != null) return scope.theme;

    // 2. Injected into the app's ThemeData as a ThemeExtension.
    final injected = Theme.of(context).extension<ComposerTheme>();
    if (injected != null) return injected;

    // 3. Default by the ambient brightness (driven by the app's ThemeMode).
    return Theme.of(context).brightness == Brightness.dark
        ? ComposerTheme.dark()
        : ComposerTheme.light();
  }

  @override
  bool updateShouldNotify(ComposerThemeScope oldWidget) => oldWidget.theme != theme;
}
