import 'reference.dart';
import 'reference_registry.dart';

/// A composer attachment (shown in the attachment bar beneath the editor).
/// Mirrors `SC.createAttachment` output 1:1.
class ComposerAttachment {
  ComposerAttachment({
    String? id,
    String? type,
    this.title = '',
    this.subtitle = '',
    String? icon,
    String? accent,
    this.meta = '',
    this.url = '',
    this.path = '',
    this.preview = '',
    this.state = 'ready',
    double? progress,
  })  : id = id ?? Uid.make('att'),
        type = type ?? 'file',
        icon = icon ?? ReferenceRegistry.get(type ?? 'file').icon,
        accent = accent ?? ReferenceRegistry.get(type ?? 'file').accent,
        progress = progress ?? 1.0;

  final String id;
  final String type;
  final String title;
  final String subtitle;
  final String icon;
  final String accent;
  final String meta;
  final String url;
  final String path;
  final String preview;

  /// ready | uploading | error
  final String state;
  final double progress;
}
