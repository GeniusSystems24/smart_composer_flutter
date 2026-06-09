import '../dnd/dnd.dart';
import '../encoding/token.dart';
import '../model/attachment.dart';
import '../model/reference.dart';
import '../model/validation.dart';

/// The composer callback set. The component never navigates — it calls you and
/// you decide. Both generic and typed-convenience callbacks fire. Mirrors the
/// React `callbacks` object.
class ComposerCallbacks {
  const ComposerCallbacks({
    this.onChanged,
    this.onSubmitted,
    this.onReferenceSelected,
    this.onReferenceRemoved,
    this.onReferenceTap,
    this.onAttachmentAdded,
    this.onAttachmentRemoved,
    this.onAttachmentTap,
    this.onSuggestionSearch,
    this.onCommandSelected,
    this.onAccessModeChanged,
    this.onValidationChanged,
    this.onTokenTap,
    this.onFilePathTap,
    this.onUserTap,
    this.onInvoiceTap,
    this.onTaskTap,
    this.onFinancialAccountTap,
    this.onCommandTap,
  });

  final void Function(ComposerEditorValue value)? onChanged;
  final void Function(ComposerEditorValue value)? onSubmitted;
  final void Function(ComposerReference ref)? onReferenceSelected;
  final void Function(ComposerReference ref)? onReferenceRemoved;
  final void Function(ComposerReference ref)? onReferenceTap;
  final void Function(ComposerAttachment att)? onAttachmentAdded;
  final void Function(ComposerAttachment att)? onAttachmentRemoved;
  final void Function(ComposerAttachment att)? onAttachmentTap;
  final void Function(String query, List<String> types)? onSuggestionSearch;
  final void Function(ComposerReference ref)? onCommandSelected;
  final void Function(String accessModeId)? onAccessModeChanged;
  final void Function(ComposerValidationResult result)? onValidationChanged;
  final void Function(ComposerReference ref)? onTokenTap;
  final void Function(ComposerReference ref)? onFilePathTap;
  final void Function(ComposerReference ref)? onUserTap;
  final void Function(ComposerReference ref)? onInvoiceTap;
  final void Function(ComposerReference ref)? onTaskTap;
  final void Function(ComposerReference ref)? onFinancialAccountTap;
  final void Function(ComposerReference ref)? onCommandTap;
}

/// Drag & drop callbacks. Mirrors the React `dropCallbacks` object.
class DropCallbacks {
  const DropCallbacks({
    this.onFilesDropped,
    this.onDroppedTokenInserted,
    this.onDropRejected,
    this.onDropValidationError,
    this.onDrop,
  });

  final void Function(List<DropItem> items)? onFilesDropped;
  final void Function(SmartComposerToken token, ComposerReference ref, DropItem item)? onDroppedTokenInserted;
  final void Function(List<DropValidationResult> rejections)? onDropRejected;
  final void Function(DropValidationResult rejection)? onDropValidationError;
  final void Function(DropResult result)? onDrop;
}

/// Aggregate result emitted after a drop. Mirrors `{ inserted, rejected, items }`.
class DropResult {
  const DropResult({required this.inserted, required this.rejected, required this.items});
  final List<({SmartComposerToken token, ComposerReference ref, DropItem item})> inserted;
  final List<DropValidationResult> rejected;
  final List<DropItem> items;
}

/// The immutable value snapshot of the editor. Mirrors `editor.getValue()`.
class ComposerEditorValue {
  const ComposerEditorValue({
    required this.text,
    required this.segments,
    required this.references,
    required this.attachments,
    required this.encodedText,
    required this.plainText,
  });

  /// Bracketed text (refs contribute `[displayText]`) — used for the char count.
  final String text;
  final List<dynamic> segments; // List<ComposerSegment>
  final List<ComposerReference> references;
  final List<ComposerAttachment> attachments;
  final String encodedText;
  final String plainText;

  static const empty = ComposerEditorValue(
    text: '',
    segments: [],
    references: [],
    attachments: [],
    encodedText: '',
    plainText: '',
  );
}
