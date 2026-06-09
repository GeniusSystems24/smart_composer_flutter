/// An access / permission posture (AI / automation / finance flows).
/// Mirrors `SC.ACCESS_MODES` entries.
class AccessMode {
  const AccessMode({
    required this.id,
    required this.label,
    required this.icon,
    required this.accent,
    required this.desc,
  });

  final String id;
  final String label;
  final String icon;
  final String accent;
  final String desc;
}

/// The ordered list of access postures. Mirrors `SC.ACCESS_MODES`.
class AccessModes {
  AccessModes._();

  static const List<AccessMode> all = [
    AccessMode(id: 'fullAccess', label: 'Full access', icon: 'shield-check', accent: 'green', desc: 'May read and act on every reference.'),
    AccessMode(id: 'limitedAccess', label: 'Limited access', icon: 'shield', accent: 'blue', desc: 'Acts only within the current context.'),
    AccessMode(id: 'askBeforeAction', label: 'Ask first', icon: 'shield-question', accent: 'orange', desc: 'Requests confirmation before any action.'),
    AccessMode(id: 'noExternalAccess', label: 'No external access', icon: 'shield-off', accent: 'orange', desc: 'Local references only — no network.'),
    AccessMode(id: 'readOnly', label: 'Read only', icon: 'eye', accent: 'neutral', desc: 'Views references, takes no action.'),
  ];

  static AccessMode? byId(String? id) {
    for (final a in all) {
      if (a.id == id) return a;
    }
    return null;
  }
}
