/// A registered entity kind. Adding a new entity type is a single
/// [ReferenceRegistry.register] call — the editor, tokens, suggestion menu and
/// toolbar all read icon / accent / group from here. Mirrors `SC.ReferenceType`.
class ReferenceType {
  const ReferenceType({
    required this.type,
    required this.label,
    required this.icon,
    this.accent = 'neutral',
    this.group = 'Other',
    this.mono = false,
    this.openLabel,
  });

  /// The authoritative entity key (e.g. `user`, `invoice`, `financialAccount`).
  final String type;

  /// Human-readable label shown in menus and toolbars.
  final String label;

  /// Lucide icon name (resolved to an [IconData] by `ComposerIcons`).
  final String icon;

  /// Accent key into `ComposerAccents` (blue/green/orange/violet/red/neutral).
  final String accent;

  /// Suggestion-menu section this type lives under.
  final String group;

  /// Render the token label in the monospace face (ids / paths).
  final bool mono;

  /// Optional verb used by typed "open" callbacks.
  final String? openLabel;

  ReferenceType copyWith({
    String? accent,
    String? group,
    bool? mono,
    String? icon,
    String? label,
    String? openLabel,
  }) {
    return ReferenceType(
      type: type,
      label: label ?? this.label,
      icon: icon ?? this.icon,
      accent: accent ?? this.accent,
      group: group ?? this.group,
      mono: mono ?? this.mono,
      openLabel: openLabel ?? this.openLabel,
    );
  }
}

/// The single source of truth for entity kinds. Pre-seeded with the GeniusLink
/// default types; extend with [register]. Mirrors `SC.ReferenceRegistry`.
class ReferenceRegistry {
  ReferenceRegistry._();

  static final Map<String, ReferenceType> _types = {};

  /// Register (or overwrite) a type. Returns the stored definition.
  static ReferenceType register(ReferenceType def) {
    _types[def.type] = def;
    return def;
  }

  /// Look up a type; returns a generic neutral fallback if unknown (the editor
  /// never crashes on an unregistered type).
  static ReferenceType get(String type) {
    return _types[type] ??
        ReferenceType(
          type: type,
          label: type,
          icon: 'box',
          accent: 'neutral',
          group: 'Other',
        );
  }

  static List<ReferenceType> all() => _types.values.toList();

  static bool has(String type) => _types.containsKey(type);

  /// Install the default GeniusLink entity types. Called once at startup by
  /// [ensureDefaults]; idempotent.
  static bool _seeded = false;
  static void ensureDefaults() {
    if (_seeded) return;
    _seeded = true;
    const defaults = <ReferenceType>[
      // People — blue
      ReferenceType(type: 'user', label: 'User', icon: 'user', accent: 'blue', group: 'People'),
      ReferenceType(type: 'member', label: 'Member', icon: 'user-round', accent: 'blue', group: 'People'),
      ReferenceType(type: 'team', label: 'Team', icon: 'users', accent: 'blue', group: 'People'),
      ReferenceType(type: 'club', label: 'Club', icon: 'shield', accent: 'blue', group: 'People'),
      // Files & media — orange
      ReferenceType(type: 'file', label: 'File', icon: 'file', accent: 'orange', group: 'Files', mono: true),
      ReferenceType(type: 'folder', label: 'Folder', icon: 'folder', accent: 'orange', group: 'Files', mono: true),
      ReferenceType(type: 'document', label: 'Document', icon: 'file-text', accent: 'orange', group: 'Files'),
      ReferenceType(type: 'image', label: 'Image', icon: 'image', accent: 'orange', group: 'Files'),
      ReferenceType(type: 'video', label: 'Video', icon: 'video', accent: 'orange', group: 'Files'),
      // Financial — green
      ReferenceType(type: 'invoice', label: 'Invoice', icon: 'receipt', accent: 'green', group: 'Financial', mono: true),
      ReferenceType(type: 'payment', label: 'Payment', icon: 'credit-card', accent: 'green', group: 'Financial', mono: true),
      ReferenceType(type: 'financialAccount', label: 'Account', icon: 'wallet', accent: 'green', group: 'Financial'),
      ReferenceType(type: 'bankAccount', label: 'Bank Account', icon: 'landmark', accent: 'green', group: 'Financial'),
      ReferenceType(type: 'transaction', label: 'Transaction', icon: 'arrow-left-right', accent: 'green', group: 'Financial', mono: true),
      ReferenceType(type: 'report', label: 'Report', icon: 'chart-column', accent: 'green', group: 'Financial'),
      // Work — violet
      ReferenceType(type: 'task', label: 'Task', icon: 'square-check-big', accent: 'violet', group: 'Work'),
      ReferenceType(type: 'project', label: 'Project', icon: 'layers', accent: 'violet', group: 'Work'),
      // System / AI — blue
      ReferenceType(type: 'tool', label: 'Tool', icon: 'wrench', accent: 'blue', group: 'AI Tools'),
      ReferenceType(type: 'skill', label: 'Skill', icon: 'sparkles', accent: 'blue', group: 'AI Tools'),
      ReferenceType(type: 'command', label: 'Command', icon: 'terminal', accent: 'blue', group: 'Commands'),
      ReferenceType(type: 'link', label: 'Link', icon: 'link', accent: 'blue', group: 'Links', mono: true),
      ReferenceType(type: 'custom', label: 'Custom', icon: 'box', accent: 'neutral', group: 'Other'),
    ];
    for (final d in defaults) {
      _types[d.type] = d;
    }
  }
}
