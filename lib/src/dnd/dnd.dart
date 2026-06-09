import '../encoding/encoding_util.dart';
import '../encoding/token.dart';

/// Drag & drop interaction state. Mirrors `SC.DROP_STATE`.
class DropState {
  static const idle = 'idle';
  static const dragOver = 'dragOver';
  static const rejected = 'rejected';
  static const dropped = 'dropped';
}

/// A normalized dropped resource. Mirrors `SmartComposerDropItem`.
class DropItem {
  DropItem({
    required this.type,
    required this.name,
    this.path = '',
    required this.uri,
    this.mimeType = '',
    this.extension = '',
    this.size = 0,
    this.bytes,
    Map<String, dynamic>? metadata,
    this.source = 'os-file',
    this.isLocal = true,
    this.isRemote = false,
    this.note,
  }) : metadata = metadata ?? <String, dynamic>{};

  final String type;
  final String name;
  final String path;
  final String uri;
  final String mimeType;
  final String extension;
  final int size;
  final List<int>? bytes;
  final Map<String, dynamic> metadata;
  final String source;
  final bool isLocal;
  final bool isRemote;

  /// Optional UI note used by demo tray chips (e.g. "over 25 MB → rejected").
  final String? note;
}

/// Configuration for drag & drop. Mirrors `SmartComposerDropConfig` /
/// `SC.DEFAULT_DROP_CONFIG`.
class DropConfig {
  const DropConfig({
    this.enabled = true,
    this.allowMultiple = true,
    this.allowedExtensions,
    this.allowedMimeTypes,
    this.blockedExtensions = const ['exe', 'bat', 'cmd', 'sh', 'dll', 'msi', 'app'],
    this.maxFileSize = 25 * 1024 * 1024,
    this.maxFilesCount = 10,
    this.insertAtDropPosition = true,
    this.fallbackInsertAtEnd = true,
    this.replaceSelectionOnDrop = true,
    this.generateTokenFromDropItem,
    this.customValidator,
  });

  final bool enabled;
  final bool allowMultiple;
  final List<String>? allowedExtensions;
  final List<String>? allowedMimeTypes;
  final List<String> blockedExtensions;
  final int maxFileSize;
  final int maxFilesCount;
  final bool insertAtDropPosition;
  final bool fallbackInsertAtEnd;
  final bool replaceSelectionOnDrop;
  final SmartComposerToken Function(DropItem item)? generateTokenFromDropItem;
  final DropValidationResult Function(DropItem item)? customValidator;

  DropConfig copyWith({
    bool? allowMultiple,
    List<String>? allowedExtensions,
    int? maxFileSize,
  }) {
    return DropConfig(
      enabled: enabled,
      allowMultiple: allowMultiple ?? this.allowMultiple,
      allowedExtensions: allowedExtensions ?? this.allowedExtensions,
      allowedMimeTypes: allowedMimeTypes,
      blockedExtensions: blockedExtensions,
      maxFileSize: maxFileSize ?? this.maxFileSize,
      maxFilesCount: maxFilesCount,
      insertAtDropPosition: insertAtDropPosition,
      fallbackInsertAtEnd: fallbackInsertAtEnd,
      replaceSelectionOnDrop: replaceSelectionOnDrop,
      generateTokenFromDropItem: generateTokenFromDropItem,
      customValidator: customValidator,
    );
  }
}

/// One validation error for a dropped item.
class DropError {
  const DropError({required this.code, required this.message});
  final String code;
  final String message;
}

/// Result of validating one dropped item. Mirrors `{ valid, errors, item }`.
class DropValidationResult {
  const DropValidationResult({required this.valid, required this.errors, this.item});
  final bool valid;
  final List<DropError> errors;
  final DropItem? item;
}

/// Turns dropped files / URLs / custom resources into typed smart tokens.
/// Faithful port of `dnd.js`.
class ComposerDnd {
  ComposerDnd._();

  static const _ext = {
    'image': ['png', 'jpg', 'jpeg', 'gif', 'webp', 'svg', 'bmp', 'heic', 'avif'],
    'video': ['mp4', 'mov', 'avi', 'mkv', 'webm', 'm4v'],
    'document': ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'csv', 'md', 'rtf', 'pages', 'numbers', 'key'],
  };

  /// Extension / MIME → tagType. Mirrors `SC.mapExtToType`.
  static String mapExtToType(String? ext, [String? mime]) {
    final e = (ext ?? '').toLowerCase();
    final m = (mime ?? '').toLowerCase();
    if (m.startsWith('image/') || _ext['image']!.contains(e)) return 'image';
    if (m.startsWith('video/') || _ext['video']!.contains(e)) return 'video';
    if (_ext['document']!.contains(e) ||
        RegExp(r'pdf|word|excel|powerpoint|spreadsheet|presentation|msword|officedocument|csv|text\/plain').hasMatch(m)) {
      return 'document';
    }
    return 'file';
  }

  static String _extOf(String name) {
    final m = RegExp(r'\.([A-Za-z0-9]+)$').firstMatch(name);
    return m != null ? m.group(1)!.toLowerCase() : '';
  }

  static String _basename(String p) => p.split(RegExp(r'[\\/]')).last;

  /// Build a safe file URI from a path or bare name. Mirrors the private
  /// `fileUri()` in `dnd.js`.
  static String fileUri(String pathOrName) {
    final p = pathOrName;
    if (RegExp(r'^[a-z][\w+.-]*:\/\/', caseSensitive: false).hasMatch(p)) return p;
    if (RegExp(r'^[a-zA-Z]:[\\/]').hasMatch(p)) return 'file:///${p.replaceAll('\\', '/')}';
    if (p.startsWith('/')) return 'file://$p';
    return 'file:///${Uri.encodeFull(p).replaceAll(RegExp(r'^/+'), '')}';
  }

  /// Build a [DropItem] from a raw map. Mirrors `SC.makeDropItem`.
  static DropItem makeDropItem(Map<String, dynamic> raw) {
    final name = (raw['name'] as String?) ??
        (raw['path'] != null ? _basename(raw['path'] as String) : null) ??
        (raw['uri'] != null ? _basename(raw['uri'] as String) : null) ??
        'file';
    final ext = (raw['extension'] as String?) ?? _extOf(name);
    final type = (raw['type'] as String?) ?? mapExtToType(ext, raw['mimeType'] as String?);
    return DropItem(
      type: type,
      name: name,
      path: (raw['path'] as String?) ?? '',
      uri: (raw['uri'] as String?) ?? fileUri((raw['path'] as String?) ?? name),
      mimeType: (raw['mimeType'] as String?) ?? '',
      extension: ext,
      size: (raw['size'] as num?)?.round() ?? 0,
      bytes: (raw['bytes'] as List?)?.cast<int>(),
      metadata: (raw['metadata'] as Map?)?.cast<String, dynamic>(),
      source: (raw['source'] as String?) ?? 'os-file',
      isLocal: raw['isLocal'] != false,
      isRemote: raw['isRemote'] == true,
      note: raw['_note'] as String?,
    );
  }

  /// Build a [DropItem] from a URL. Mirrors `SC.makeDropItemFromUrl`.
  static DropItem makeDropItemFromUrl(String url) {
    final clean = url.trim();
    final label = clean.replaceAll(RegExp(r'^https?:\/\/'), '').replaceAll(RegExp(r'\/$'), '');
    return makeDropItem({
      'type': 'link',
      'name': label,
      'uri': clean,
      'mimeType': 'text/uri-list',
      'source': 'url',
      'isLocal': false,
      'isRemote': true,
    });
  }

  /// Dropped item → encoded token. Mirrors `SC.dropItemToToken`.
  static SmartComposerToken dropItemToToken(DropItem item) {
    return SmartComposerToken(
      prefix: EncodingUtil.prefixForType(item.type),
      tagType: item.type,
      displayText: item.name,
      valueText: item.uri,
      rawText: '',
      metadata: item.metadata,
      resolveState: ResolveState.idle,
    );
  }

  /// Human-readable byte size. Mirrors `SC.formatBytes`.
  static String formatBytes(num n) {
    if (n < 1024) return '${n.round()} B';
    if (n < 1024 * 1024) return '${(n / 1024).round()} KB';
    return '${(n / 1024 / 1024).toStringAsFixed(1)} MB';
  }
}

/// Validates a dropped item against a [DropConfig]. Mirrors
/// `SC.SmartComposerDropValidator`.
class SmartComposerDropValidator {
  SmartComposerDropValidator._();

  static bool _mimeOk(String mime, List<String> list) {
    return list.any((p) => p == mime || (p.endsWith('/*') && mime.startsWith(p.substring(0, p.length - 1))));
  }

  static DropValidationResult validate(DropItem item, DropConfig cfg) {
    final errors = <DropError>[];
    final ext = item.extension.toLowerCase();
    if (cfg.blockedExtensions.contains(ext)) {
      errors.add(DropError(code: 'blockedType', message: '.$ext files are not allowed.'));
    }
    if (cfg.allowedExtensions != null && ext.isNotEmpty && !cfg.allowedExtensions!.contains(ext)) {
      errors.add(DropError(code: 'extensionNotAllowed', message: '.$ext is not an accepted type.'));
    }
    if (cfg.allowedMimeTypes != null && item.mimeType.isNotEmpty && !_mimeOk(item.mimeType, cfg.allowedMimeTypes!)) {
      errors.add(DropError(code: 'mimeNotAllowed', message: '${item.mimeType} is not accepted.'));
    }
    if (item.size > 0 && item.size > cfg.maxFileSize) {
      errors.add(DropError(
        code: 'tooLarge',
        message: '${ComposerDnd.formatBytes(item.size)} exceeds the ${ComposerDnd.formatBytes(cfg.maxFileSize)} limit.',
      ));
    }
    if (cfg.customValidator != null) {
      final r = cfg.customValidator!(item);
      if (!r.valid) {
        errors.addAll(r.errors.isNotEmpty ? r.errors : const [DropError(code: 'custom', message: 'Rejected.')]);
      }
    }
    return DropValidationResult(valid: errors.isEmpty, errors: errors, item: item);
  }
}
