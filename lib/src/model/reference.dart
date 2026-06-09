import 'reference_registry.dart';

/// Monotonic id generator mirroring the React `uid(prefix)` helper:
/// `<prefix>_<base36 counter>_<base36 time tail>`.
class Uid {
  Uid._();
  static int _n = 0;
  static String make(String prefix) {
    _n += 1;
    final time = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final tail = time.length > 3 ? time.substring(time.length - 3) : time;
    return '${prefix}_${_n.toRadixString(36)}_$tail';
  }
}

/// Transient lifecycle state a token can reflect in the editor / preview.
/// Kept as plain strings to mirror the React model 1:1.
class RefState {
  static const ready = 'ready';
  static const loading = 'loading';
  static const error = 'error';
  static const disabled = 'disabled';
}

/// The universal entity shape. Every inline token is a [ComposerReference].
/// Most fields are optional; icon / accent are resolved from the registry when
/// omitted. Mirrors `SC.createReference` output 1:1.
class ComposerReference {
  ComposerReference({
    String? id,
    required this.type,
    this.title = '',
    this.subtitle = '',
    this.description = '',
    String? icon,
    String? accent,
    this.source = 'local',
    Map<String, dynamic>? metadata,
    String? displayText,
    Object? value,
    this.url = '',
    this.path = '',
    List<String>? permissions,
    this.isRemote = false,
    this.isLocal = true,
    this.isEnabled = true,
    this.state = RefState.ready,
    this.error = '',
    bool? mono,
  })  : id = id ?? Uid.make('ref'),
        icon = icon ?? ReferenceRegistry.get(type).icon,
        accent = accent ?? ReferenceRegistry.get(type).accent,
        metadata = metadata ?? <String, dynamic>{},
        displayText = displayText ?? (title.isNotEmpty ? title : ''),
        value = value ?? title,
        permissions = permissions ?? <String>[],
        mono = mono ?? ReferenceRegistry.get(type).mono;

  final String id;
  final String type;
  final String title;
  final String subtitle;
  final String description;
  final String icon;
  final String accent;
  final String source;
  final Map<String, dynamic> metadata;
  final String displayText;
  final Object? value;
  final String url;
  final String path;
  final List<String> permissions;
  final bool isRemote;
  final bool isLocal;
  final bool isEnabled;

  /// ready | loading | error | disabled
  final String state;
  final String error;
  final bool mono;

  ComposerReference copyWith({
    String? title,
    String? subtitle,
    String? icon,
    String? accent,
    String? displayText,
    Object? value,
    String? path,
    String? state,
    Map<String, dynamic>? metadata,
  }) {
    return ComposerReference(
      id: id,
      type: type,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description,
      icon: icon ?? this.icon,
      accent: accent ?? this.accent,
      source: source,
      metadata: metadata ?? this.metadata,
      displayText: displayText ?? this.displayText,
      value: value ?? this.value,
      url: url,
      path: path ?? this.path,
      permissions: permissions,
      isRemote: isRemote,
      isLocal: isLocal,
      isEnabled: isEnabled,
      state: state ?? this.state,
      error: error,
      mono: mono,
    );
  }
}
