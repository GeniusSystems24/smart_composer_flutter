/// Prefix ⇄ category maps and escaping helpers. The tagType is always
/// authoritative for the entity; prefix is presentation/category only.
/// Mirrors the corresponding helpers in `encoding.js`.
class EncodingUtil {
  EncodingUtil._();

  static const Map<String, List<String>> prefixByType = {
    '@': ['user', 'member', 'team', 'club', 'file', 'folder', 'document', 'image', 'video', 'source', 'link'],
    '#': ['task', 'project', 'invoice', 'report'],
    '\$': ['tool', 'skill', 'plugin', 'financialAccount', 'bankAccount', 'payment', 'transaction'],
    '/': ['command'],
  };

  /// The category prefix for a tagType (defaults to `@`). Mirrors `SC.prefixForType`.
  static String prefixForType(String type) {
    for (final entry in prefixByType.entries) {
      if (entry.value.contains(type)) return entry.key;
    }
    return '@';
  }

  /// URI scheme for a tagType (kebab-cased). Mirrors `SC.schemeForType`.
  static String schemeForType(String type) {
    const special = {
      'financialAccount': 'financial-account',
      'bankAccount': 'bank-account',
    };
    if (special.containsKey(type)) return special[type]!;
    return type.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (m) => '${m.group(1)}-${m.group(2)}',
    ).toLowerCase();
  }

  /// Escape displayText: terminates at `]`; escape `\`, `]`, newline.
  static String escDisplay(String s) {
    return s
        .replaceAll('\\', '\\\\')
        .replaceAll(']', '\\]')
        .replaceAll('\n', '\\n');
  }

  /// Escape valueText: terminates at `)`; escape `\`, `)`, newline.
  static String escValue(String s) {
    return s
        .replaceAll('\\', '\\\\')
        .replaceAll(')', '\\)')
        .replaceAll('\n', '\\n');
  }
}
