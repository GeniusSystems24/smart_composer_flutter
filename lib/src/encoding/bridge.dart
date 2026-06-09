import '../model/reference.dart';
import '../model/reference_registry.dart';
import '../model/segment.dart';
import 'encoding_util.dart';
import 'parser.dart';
import 'serializer.dart';
import 'token.dart';

/// Bridges the editor's [ComposerReference] world to the encoded
/// [SmartComposerToken] world. Faithful port of the bridge half of `encoding.js`.
class ComposerBridge {
  ComposerBridge._();

  static const List<String> fileTypes = ['file', 'folder', 'document', 'image', 'video'];

  static final RegExp _uriRe = RegExp(r'^[a-z][\w+.-]*:\/\/', caseSensitive: false);
  static final RegExp _winRe = RegExp(r'^[a-zA-Z]:[\\/]');

  static String _slug(String s) {
    return s
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  static String _firstNonEmpty(List<String> candidates) {
    for (final c in candidates) {
      if (c.isNotEmpty) return c;
    }
    return '';
  }

  /// Compute the system valueText (URI) for a reference. Mirrors `SC.valueTextForRef`.
  static String valueTextForRef(ComposerReference ref) {
    final v = ref.value?.toString() ?? '';
    if (v.isNotEmpty && _uriRe.hasMatch(v)) return v;
    if (ref.url.isNotEmpty) return ref.url;
    if (fileTypes.contains(ref.type)) {
      final p = _firstNonEmpty([ref.path, v, ref.title]);
      if (_uriRe.hasMatch(p)) return p;
      if (_winRe.hasMatch(p)) return 'file:///${p.replaceAll('\\', '/')}';
      return 'file:///${p.replaceAll(RegExp(r'^/+'), '')}';
    }
    final id = _firstNonEmpty([v, ref.id, _slug(ref.title)]);
    return '${EncodingUtil.schemeForType(ref.type)}://$id';
  }

  /// Reference → token. Mirrors `SC.refToToken`.
  static SmartComposerToken refToToken(ComposerReference ref) {
    final resolveState = ref.state == 'error'
        ? ResolveState.error
        : ref.state == 'loading'
            ? ResolveState.loading
            : ref.state == 'disabled'
                ? ResolveState.disabled
                : ResolveState.idle;
    return SmartComposerToken(
      prefix: EncodingUtil.prefixForType(ref.type),
      tagType: ref.type,
      displayText: _firstNonEmpty([ref.displayText, ref.title, ref.value?.toString() ?? '']),
      valueText: valueTextForRef(ref),
      rawText: '',
      metadata: ref.metadata,
      resolveState: resolveState,
      accent: ref.accent,
    );
  }

  /// Token → reference. Mirrors `SC.tokenToRef`.
  static ComposerReference tokenToRef(SmartComposerToken token) {
    final def = ReferenceRegistry.get(token.tagType);
    final isFile = fileTypes.contains(token.tagType);
    var path = '';
    if (isFile) {
      final m = RegExp(r'^file:\/\/\/(.*)$', caseSensitive: false).firstMatch(token.valueText);
      path = m != null ? (m.group(1) ?? '') : token.valueText;
    }
    final rs = token.resolveState;
    final state = (rs == ResolveState.error || rs == ResolveState.notFound)
        ? 'error'
        : rs == ResolveState.loading
            ? 'loading'
            : (rs == ResolveState.disabled || rs == ResolveState.deleted)
                ? 'disabled'
                : 'ready';
    return ComposerReference(
      type: token.tagType,
      title: token.displayText,
      displayText: token.displayText,
      value: token.valueText,
      path: path,
      icon: def.icon,
      accent: def.accent,
      state: state,
      metadata: token.metadata,
    );
  }

  /// Encoded string → editor segments (text | ref). Mirrors `SC.encodedToSegments`.
  static List<ComposerSegment> encodedToSegments(String encodedText) {
    return SmartComposerParser.parse(encodedText).segments.map((s) {
      return s.isText
          ? ComposerSegment.text(s.text)
          : ComposerSegment.ref(tokenToRef(s.token!));
    }).toList();
  }

  /// Editor segments → encoded string. Mirrors `SC.segmentsToEncoded`.
  static String segmentsToEncoded(List<ComposerSegment> segments) {
    return segments.map((s) {
      return s.isText
          ? s.text
          : SmartComposerSerializer.tokenToEncoded(refToToken(s.ref!));
    }).join();
  }
}
