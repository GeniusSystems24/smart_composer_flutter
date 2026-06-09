import 'dart:ui';

/// A resolved accent: a foreground color plus tinted background / hover /
/// border derived from a single hue. Mirrors `SC.ACCENTS` in the React model.
class ComposerAccent {
  const ComposerAccent({
    required this.fg,
    required this.bg,
    required this.bgHover,
    required this.border,
  });

  final Color fg;
  final Color bg;
  final Color bgHover;
  final Color border;

  /// Build an accent from a base hex color the same way the React model does:
  /// fg = solid, bg = 14% alpha, bgHover = 22% alpha, border = 42% alpha.
  factory ComposerAccent.fromHex(int hex) {
    final base = Color(0xFF000000 | hex);
    return ComposerAccent(
      fg: base,
      bg: base.withOpacity(0.14),
      bgHover: base.withOpacity(0.22),
      border: base.withOpacity(0.42),
    );
  }
}

/// The disciplined 6-hue accent registry — one brand blue, the GeniusLink
/// semantic green/orange/red, a brand violet (the cube logo's accent face) and
/// a neutral. Keyed by name exactly as in the React model (`SC.ACCENTS`).
class ComposerAccents {
  ComposerAccents._();

  static final Map<String, ComposerAccent> all = {
    'blue': ComposerAccent.fromHex(0x4A7CFF),
    'green': ComposerAccent.fromHex(0x1DB88A),
    'orange': ComposerAccent.fromHex(0xF97316),
    'violet': ComposerAccent.fromHex(0x8B7CF6),
    'red': ComposerAccent.fromHex(0xEF4444),
    'neutral': ComposerAccent.fromHex(0x8D90A0),
  };

  /// Resolve an accent by key, falling back to `neutral` (never null).
  static ComposerAccent resolve(String? key) =>
      all[key] ?? all['neutral']!;
}
