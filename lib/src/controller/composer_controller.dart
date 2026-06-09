import 'dart:async';

import 'package:flutter/widgets.dart';

import '../dnd/dnd.dart';
import '../encoding/bridge.dart';
import '../encoding/parser.dart';
import '../encoding/serializer.dart';
import '../encoding/token.dart';
import '../model/attachment.dart';
import '../model/modes.dart';
import '../model/reference.dart';
import '../model/reference_registry.dart';
import '../model/segment.dart';
import '../model/triggers.dart';
import '../model/search.dart';
import '../model/validation.dart';
import 'callbacks.dart';

/// View-state of the floating suggestion menu. Mirrors the React `sug` object.
class SuggestionState {
  const SuggestionState({
    this.open = false,
    this.key,
    this.trig,
    this.query = '',
    this.groups = const [],
    this.flat = const [],
    this.active = 0,
    this.empty = false,
  });

  final bool open;
  final String? key;
  final TriggerConfig? trig;
  final String query;
  final List<SuggestionGroup> groups;
  final List<ComposerReference> flat;
  final int active;
  final bool empty;

  static const closed = SuggestionState();
}

/// A [TextEditingController] that renders reference tokens as inline,
/// non-editable [WidgetSpan]s. Each token occupies a single Unicode
/// Private-Use-Area sentinel char in [text]; [refByCode] maps the sentinel code
/// point back to its [ComposerReference]. This is the Flutter equivalent of the
/// React contentEditable token spans.
class ComposerEditingController extends TextEditingController {
  ComposerEditingController();

  final Map<int, ComposerReference> refByCode = {};
  int _nextCode = 0xE000;
  int? selectedCode;

  /// Builds the visual chip for a token (set by the SmartComposer widget).
  Widget Function(
          BuildContext context, ComposerReference ref, int code, bool selected)?
      chipBuilder;

  /// Allocate a fresh sentinel code for [ref].
  String allocate(ComposerReference ref) {
    final code = _nextCode++;
    refByCode[code] = ref;
    return String.fromCharCode(code);
  }

  bool _isSentinel(int code) =>
      code >= 0xE000 && code <= 0xF8FF && refByCode.containsKey(code);

  @override
  TextSpan buildTextSpan(
      {required BuildContext context,
      TextStyle? style,
      required bool withComposing}) {
    final children = <InlineSpan>[];
    final buf = StringBuffer();
    void flush() {
      if (buf.isNotEmpty) {
        children.add(TextSpan(text: buf.toString(), style: style));
        buf.clear();
      }
    }

    for (final rune in text.runes) {
      if (_isSentinel(rune)) {
        flush();
        final ref = refByCode[rune]!;
        final chip =
            chipBuilder?.call(context, ref, rune, selectedCode == rune) ??
                const SizedBox.shrink();
        children.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          baseline: TextBaseline.alphabetic,
          child: chip,
        ));
      } else {
        buf.writeCharCode(rune);
      }
    }
    flush();
    return TextSpan(style: style, children: children);
  }
}

/// The MVC controller. Owns the editing surface, trigger detection, token
/// insert/remove, suggestion state, validation and submit, and emits the value
/// + callbacks. Frameworks bind to this; mirrors `SC.Editor` method-for-method
/// where the platform allows. Extends [ChangeNotifier] so widgets rebuild.
class ComposerController extends ChangeNotifier {
  ComposerController({
    required ComposerMode mode,
    this.callbacks = const ComposerCallbacks(),
    this.dropCallbacks = const DropCallbacks(),
    DropConfig? dnd,
    SearchProvider? searchProvider,
    String? accessMode,
    String? modelName,
    bool readOnly = false,
    this.submitOnEnter = true,
  })  : _mode = mode,
        dropConfig = dnd ?? const DropConfig(),
        _searchProvider = searchProvider,
        _accessMode = accessMode ?? mode.defaultAccess,
        modelName = modelName ?? 'sonnet',
        _readOnly = readOnly {
    ReferenceRegistry.ensureDefaults();
    editing = ComposerEditingController();
    editing.addListener(_onEditingChanged);
  }

  // ---- config ----
  ComposerMode _mode;
  ComposerMode get mode => _mode;
  final ComposerCallbacks callbacks;
  final DropCallbacks dropCallbacks;
  DropConfig dropConfig;
  final SearchProvider? _searchProvider;
  final bool submitOnEnter;

  late final ComposerEditingController editing;
  final FocusNode focusNode = FocusNode();

  // ---- reactive state ----
  SuggestionState suggestion = SuggestionState.closed;
  String? _accessMode;
  String? modelName;
  bool _readOnly;
  bool focused = false;
  String dragState = DropState.idle;
  int _dragCount = 0;
  bool? _lastValid;
  _TriggerCtx? _ctx;
  int _suppressReconcile = 0;

  String? get accessMode => _accessMode;
  bool get readOnly => _readOnly;

  // =========================================================================
  // VALUE
  // =========================================================================
  /// Walk the field text into ordered [ComposerSegment]s.
  List<ComposerSegment> getSegments() {
    final segs = <ComposerSegment>[];
    final buf = StringBuffer();
    void flush() {
      if (buf.isNotEmpty) {
        segs.add(ComposerSegment.text(buf.toString()));
        buf.clear();
      }
    }

    for (final rune in editing.text.runes) {
      final ref =
          (rune >= 0xE000 && rune <= 0xF8FF) ? editing.refByCode[rune] : null;
      if (ref != null) {
        flush();
        segs.add(ComposerSegment.ref(ref));
      } else {
        buf.writeCharCode(rune);
      }
    }
    flush();
    return segs;
  }

  ComposerEditorValue getValue() {
    final segments = getSegments();
    final references = <ComposerReference>[];
    final textBuf = StringBuffer();
    final plainBuf = StringBuffer();
    for (final s in segments) {
      if (s.isText) {
        textBuf.write(s.text);
        plainBuf.write(s.text);
      } else {
        final ref = s.ref!;
        references.add(ref);
        final label = ref.displayText.isNotEmpty ? ref.displayText : ref.title;
        textBuf.write('[$label]');
        plainBuf.write(label);
      }
    }
    return ComposerEditorValue(
      text: textBuf.toString(),
      segments: segments,
      references: references,
      attachments: List.unmodifiable(_attachments),
      encodedText: ComposerBridge.segmentsToEncoded(segments),
      plainText: plainBuf.toString(),
    );
  }

  ComposerEditorValue get value => getValue();

  String getEncodedText() => ComposerBridge.segmentsToEncoded(getSegments());
  String getPlainText() =>
      SmartComposerPlainTextConverter.convert(getEncodedText());
  List<TokenIndexEntry> getTokenIndex() =>
      SmartComposerTokenIndex.extract(getEncodedText());

  void setEncodedText(String str) =>
      setSegments(ComposerBridge.encodedToSegments(str));

  ComposerValidationResult get validation {
    final v = getValue();
    return ComposerValidator.validate(
      text: v.text,
      references: v.references,
      attachments: _attachments,
      rules: _mode.validation,
    );
  }

  // =========================================================================
  // SEEDING / MUTATION
  // =========================================================================
  /// Replace all content with [segs]. Mirrors `setSegments`.
  void setSegments(List<ComposerSegment> segs) {
    _suppressReconcile++;
    editing.refByCode.clear();
    final buf = StringBuffer();
    for (final s in segs) {
      if (s.isText) {
        buf.write(s.text);
      } else {
        buf.write(editing.allocate(s.ref!));
        buf.write(' ');
      }
    }
    editing.value = TextEditingValue(
      text: buf.toString(),
      selection: TextSelection.collapsed(offset: buf.length),
    );
    _suppressReconcile--;
    _afterChange();
  }

  void clear() {
    _suppressReconcile++;
    editing.refByCode.clear();
    editing.value = const TextEditingValue(text: '');
    _suppressReconcile--;
    _afterChange();
  }

  // ---- attachments ----
  final List<ComposerAttachment> _attachments = [];
  List<ComposerAttachment> get attachments => List.unmodifiable(_attachments);

  void setAttachments(List<ComposerAttachment> list) {
    _attachments
      ..clear()
      ..addAll(list);
    _emit();
  }

  void addAttachment(ComposerAttachment att) {
    _attachments.add(att);
    callbacks.onAttachmentAdded?.call(att);
    _afterChange();
  }

  void removeAttachment(String id) {
    final i = _attachments.indexWhere((a) => a.id == id);
    if (i < 0) return;
    final a = _attachments.removeAt(i);
    callbacks.onAttachmentRemoved?.call(a);
    _afterChange();
  }

  // =========================================================================
  // TOKEN INSERTION
  // =========================================================================
  /// Insert a reference token at the caret, replacing any selection. Returns
  /// the placeholder length consumed (always inserts a trailing space).
  void _insertRefAtSelection(ComposerReference ref,
      {int? replaceStart, int? replaceEnd}) {
    final sel = editing.selection;
    final text = editing.text;
    var start = replaceStart ?? (sel.isValid ? sel.start : text.length);
    var end = replaceEnd ?? (sel.isValid ? sel.end : text.length);
    if (start < 0) start = text.length;
    if (end < 0) end = text.length;
    final placeholder = editing.allocate(ref);
    final insert = '$placeholder ';
    final newText = text.replaceRange(start, end, insert);
    _suppressReconcile++;
    editing.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + insert.length),
    );
    _suppressReconcile--;
  }

  /// Insert a reference at the caret (toolbar pickers / programmatic).
  void insertReference(ComposerReference ref) {
    _ensureFocus();
    _insertRefAtSelection(ref);
    callbacks.onReferenceSelected?.call(ref);
    _closeMenu();
    _afterChange();
  }

  ComposerReference insertTokenAtCursor(SmartComposerToken token) {
    _ensureFocus();
    _ensureLeadingSpace();
    final ref = ComposerBridge.tokenToRef(token);
    _insertRefAtSelection(ref);
    _afterChange();
    return ref;
  }

  ComposerReference? insertEncodedTokenAtCursor(String encodedToken) {
    final r = SmartComposerParserParseHelper.firstToken(encodedToken);
    if (r == null) return null;
    return insertTokenAtCursor(r);
  }

  ComposerReference replaceSelectionWithToken(SmartComposerToken token) {
    _ensureFocus();
    final ref = ComposerBridge.tokenToRef(token);
    _insertRefAtSelection(ref);
    _afterChange();
    return ref;
  }

  ComposerReference insertTokenAtOffset(SmartComposerToken token, int offset) {
    _ensureFocus();
    final clamped = offset.clamp(0, editing.text.length);
    editing.selection = TextSelection.collapsed(offset: clamped);
    final ref = ComposerBridge.tokenToRef(token);
    _insertRefAtSelection(ref);
    _afterChange();
    return ref;
  }

  ComposerReference insertDroppedItemAtCursor(DropItem item) =>
      insertTokenAtCursor(ComposerDnd.dropItemToToken(item));

  List<ComposerReference> insertDroppedItemsAtCursor(List<DropItem> items) {
    _ensureFocus();
    final refs = <ComposerReference>[];
    for (final item in items) {
      refs.add(insertTokenAtCursor(ComposerDnd.dropItemToToken(item)));
    }
    return refs;
  }

  void _ensureLeadingSpace() {
    final sel = editing.selection;
    if (!sel.isValid) return;
    final o = sel.start;
    if (o > 0) {
      final ch = editing.text[o - 1];
      final isSpace = RegExp(r'\s').hasMatch(ch);
      final isSentinel = ch.runes.first >= 0xE000 && ch.runes.first <= 0xF8FF;
      if (!isSpace && (isSentinel || ch != ' ')) {
        // insert a space only when previous char is a token or a non-space glyph
        if (isSentinel) insertText(' ');
      }
    }
  }

  /// Insert plain text at the caret. Mirrors `insertText`.
  void insertText(String str) {
    _ensureFocus();
    final sel = editing.selection;
    final text = editing.text;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;
    final newText = text.replaceRange(start, end, str);
    editing.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + str.length),
    );
  }

  /// Insert a trigger symbol (adds a leading space if needed). Mirrors `openTrigger`.
  void openTrigger(String sym) {
    _ensureFocus();
    final sel = editing.selection;
    var needSpace = false;
    if (sel.isValid && sel.start > 0) {
      final ch = editing.text[sel.start - 1];
      if (!RegExp(r'\s').hasMatch(ch)) needSpace = true;
    }
    insertText((needSpace ? ' ' : '') + sym);
    _refreshSuggestions();
  }

  // =========================================================================
  // SUGGESTIONS
  // =========================================================================
  List<String> _activeTriggerKeys() {
    final allowed = _mode.triggers;
    return Triggers.keys.where(allowed.contains).toList();
  }

  _TriggerCtx? _detectTrigger() {
    final sel = editing.selection;
    if (!sel.isValid || !sel.isCollapsed) return null;
    final caret = sel.start;
    if (caret < 0 || caret > editing.text.length) return null;
    final before = editing.text.substring(0, caret);
    // cut at the last sentinel / newline so the query is within the current run
    var cut = 0;
    for (var i = 0; i < before.length; i++) {
      final c = before.codeUnitAt(i);
      if (c == 0x0A || (c >= 0xE000 && c <= 0xF8FF)) cut = i + 1;
    }
    final run = before.substring(cut);
    for (final key in _activeTriggerKeys()) {
      final trig = Triggers.all[key]!;
      final sym = trig.symbol;
      final symFirst = RegExp.escape(sym[0]);
      final re = RegExp('(^|\\s)(${RegExp.escape(sym)})([^\\s$symFirst]*)\$');
      final m = re.firstMatch(run);
      if (m != null) {
        final query = m.group(3) ?? '';
        final start = caret - (sym.length + query.length);
        return _TriggerCtx(
            key: key, trig: trig, query: query, start: start, end: caret);
      }
    }
    return null;
  }

  Future<void> _refreshSuggestions() async {
    if (_readOnly) {
      _closeMenu();
      return;
    }
    final ctx = _detectTrigger();
    if (ctx == null) {
      _closeMenu();
      return;
    }
    _ctx = ctx;
    final provider = ctx.trig.searchProvider ?? _searchProvider;
    final result = await provider
            ?.call(ctx.query, ctx.trig.types, {'trigger': ctx.key}) ??
        ComposerSearch.search(ctx.query, ctx.trig.types, {'trigger': ctx.key});
    // guard: caret may have moved while awaiting
    final still = _detectTrigger();
    if (still == null || still.key != ctx.key || still.query != ctx.query)
      return;
    final flat = <ComposerReference>[];
    for (final g in result) {
      flat.addAll(g.items);
    }
    callbacks.onSuggestionSearch?.call(ctx.query, ctx.trig.types);
    suggestion = SuggestionState(
      open: true,
      key: ctx.key,
      trig: ctx.trig,
      query: ctx.query,
      groups: result,
      flat: flat,
      active: 0,
      empty: flat.isEmpty,
    );
    _emit();
  }

  void _closeMenu() {
    if (suggestion.open) {
      suggestion = SuggestionState.closed;
      _emit();
    } else {
      suggestion = SuggestionState.closed;
    }
  }

  void closeMenu() => _closeMenu();

  void moveActive(int dir) {
    if (!suggestion.open || suggestion.flat.isEmpty) return;
    final n = suggestion.flat.length;
    final next = (suggestion.active + dir + n) % n;
    suggestion = SuggestionState(
      open: true,
      key: suggestion.key,
      trig: suggestion.trig,
      query: suggestion.query,
      groups: suggestion.groups,
      flat: suggestion.flat,
      active: next,
      empty: suggestion.empty,
    );
    _emit();
  }

  void setActive(int i) {
    if (!suggestion.open) return;
    suggestion = SuggestionState(
      open: true,
      key: suggestion.key,
      trig: suggestion.trig,
      query: suggestion.query,
      groups: suggestion.groups,
      flat: suggestion.flat,
      active: i,
      empty: suggestion.empty,
    );
    _emit();
  }

  void confirmActive([int? i]) {
    if (!suggestion.open) return;
    final idx = i ?? suggestion.active;
    if (idx < 0 || idx >= suggestion.flat.length) return;
    var ref = suggestion.flat[idx];
    final ctx = _detectTrigger() ?? _ctx;
    final builder = ctx?.trig.tokenBuilder;
    if (builder != null) ref = builder(ref);
    if (ctx != null) {
      _insertRefAtSelection(ref, replaceStart: ctx.start, replaceEnd: ctx.end);
    } else {
      insertReference(ref);
      return;
    }
    if (ref.type == 'command') callbacks.onCommandSelected?.call(ref);
    callbacks.onReferenceSelected?.call(ref);
    _closeMenu();
    _afterChange();
  }

  // =========================================================================
  // TOKEN TAP / REMOVAL
  // =========================================================================
  void tapToken(ComposerReference ref) {
    callbacks.onTokenTap?.call(ref);
    callbacks.onReferenceTap?.call(ref);
    switch (ref.type) {
      case 'file':
      case 'folder':
        callbacks.onFilePathTap?.call(ref);
        break;
      case 'user':
      case 'member':
        callbacks.onUserTap?.call(ref);
        break;
      case 'invoice':
        callbacks.onInvoiceTap?.call(ref);
        break;
      case 'task':
        callbacks.onTaskTap?.call(ref);
        break;
      case 'financialAccount':
      case 'bankAccount':
        callbacks.onFinancialAccountTap?.call(ref);
        break;
      case 'command':
        callbacks.onCommandTap?.call(ref);
        break;
    }
  }

  /// Remove a token by its sentinel code (the × button / backspace).
  void removeTokenByCode(int code) {
    final ref = editing.refByCode[code];
    final text = editing.text;
    final placeholder = String.fromCharCode(code);
    final idx = text.indexOf(placeholder);
    if (idx < 0) return;
    var end = idx + 1;
    // also swallow a single trailing auto-space
    if (end < text.length && text[end] == ' ') end++;
    _suppressReconcile++;
    editing.value = TextEditingValue(
      text: text.replaceRange(idx, end, ''),
      selection: TextSelection.collapsed(offset: idx),
    );
    editing.refByCode.remove(code);
    if (editing.selectedCode == code) editing.selectedCode = null;
    _suppressReconcile--;
    if (ref != null) callbacks.onReferenceRemoved?.call(ref);
    _afterChange();
  }

  /// Backspace handling: first press selects a trailing token, second removes.
  /// Returns true if the key was consumed.
  bool handleBackspace() {
    if (editing.selectedCode != null) {
      removeTokenByCode(editing.selectedCode!);
      return true;
    }
    final sel = editing.selection;
    if (!sel.isValid || !sel.isCollapsed) return false;
    final caret = sel.start;
    if (caret <= 0) return false;
    final prev = editing.text.codeUnitAt(caret - 1);
    if (prev >= 0xE000 &&
        prev <= 0xF8FF &&
        editing.refByCode.containsKey(prev)) {
      editing.selectedCode = prev;
      _emit();
      return true;
    }
    return false;
  }

  void clearTokenSelection() {
    if (editing.selectedCode != null) {
      editing.selectedCode = null;
      _emit();
    }
  }

  // =========================================================================
  // SUBMIT
  // =========================================================================
  ComposerValidationResult submit() {
    final v = getValue();
    final result = validation;
    if (!result.valid) {
      callbacks.onValidationChanged?.call(result);
      _emit();
      return result;
    }
    callbacks.onSubmitted?.call(v);
    return result;
  }

  // =========================================================================
  // SETTERS
  // =========================================================================
  void setMode(ComposerMode mode) {
    _mode = mode;
    _emit();
  }

  void setReadOnly(bool ro) {
    _readOnly = ro;
    _emit();
  }

  void setAccessMode(String id) {
    _accessMode = id;
    callbacks.onAccessModeChanged?.call(id);
    _emit();
  }

  void setModel(String id) {
    modelName = id;
    _emit();
  }

  void focus() => focusNode.requestFocus();

  // ---- drag state (driven by the widget's DragTarget) ----
  bool get dropEnabled => dropConfig.enabled && !_readOnly;

  void onDragEnter() {
    _dragCount++;
    dragState = dropEnabled ? DropState.dragOver : DropState.rejected;
    _emit();
  }

  void onDragLeave() {
    _dragCount = (_dragCount - 1).clamp(0, 1 << 30);
    if (_dragCount == 0 && dragState != DropState.idle) {
      dragState = DropState.idle;
      _emit();
    }
  }

  void resetDrag() {
    _dragCount = 0;
    dragState = DropState.idle;
    _emit();
  }

  /// Handle a list of dropped items at [offset] (or the caret/end). Mirrors the
  /// controller's `_onDrop` token-building + validation pipeline.
  void handleDrop(List<DropItem> items, {int? offset}) {
    resetDrag();
    if (!dropEnabled || items.isEmpty) return;
    dropCallbacks.onFilesDropped?.call(items);
    if (offset != null) {
      editing.selection =
          TextSelection.collapsed(offset: offset.clamp(0, editing.text.length));
    } else if (dropConfig.fallbackInsertAtEnd) {
      editing.selection = TextSelection.collapsed(offset: editing.text.length);
    }
    var list = dropConfig.allowMultiple
        ? List<DropItem>.from(items)
        : items.take(1).toList();
    final rejected = <DropValidationResult>[];
    if (list.length > dropConfig.maxFilesCount) {
      for (final it in list.skip(dropConfig.maxFilesCount)) {
        rejected.add(DropValidationResult(valid: false, item: it, errors: [
          DropError(
              code: 'tooManyFiles',
              message: 'At most ${dropConfig.maxFilesCount} files.'),
        ]));
      }
      list = list.take(dropConfig.maxFilesCount).toList();
    }
    final inserted =
        <({SmartComposerToken token, ComposerReference ref, DropItem item})>[];
    for (final item in list) {
      final v = SmartComposerDropValidator.validate(item, dropConfig);
      if (!v.valid) {
        rejected.add(v);
        dropCallbacks.onDropValidationError?.call(v);
        continue;
      }
      final token = dropConfig.generateTokenFromDropItem?.call(item) ??
          ComposerDnd.dropItemToToken(item);
      _ensureLeadingSpace();
      final ref = ComposerBridge.tokenToRef(token);
      _insertRefAtSelection(ref);
      inserted.add((token: token, ref: ref, item: item));
      dropCallbacks.onDroppedTokenInserted?.call(token, ref, item);
    }
    if (rejected.isNotEmpty) dropCallbacks.onDropRejected?.call(rejected);
    dropCallbacks.onDrop?.call(
        DropResult(inserted: inserted, rejected: rejected, items: items));
    _afterChange();
  }

  // =========================================================================
  // INTERNAL
  // =========================================================================
  void setFocused(bool f) {
    focused = f;
    _emit();
  }

  void _ensureFocus() {
    if (!focusNode.hasFocus) focusNode.requestFocus();
  }

  void _onEditingChanged() {
    if (_suppressReconcile > 0) return;
    if (editing.selectedCode != null) editing.selectedCode = null;
    _reconcileRefs();
    _refreshSuggestions();
    _afterChange();
  }

  /// Drop refs whose sentinel no longer appears in the text and fire removals.
  void _reconcileRefs() {
    final present = <int>{};
    for (final r in editing.text.runes) {
      if (r >= 0xE000 && r <= 0xF8FF && editing.refByCode.containsKey(r))
        present.add(r);
    }
    final removed =
        editing.refByCode.keys.where((k) => !present.contains(k)).toList();
    for (final code in removed) {
      final ref = editing.refByCode.remove(code);
      if (ref != null) callbacks.onReferenceRemoved?.call(ref);
    }
  }

  void _afterChange() {
    final v = getValue();
    final result = validation;
    callbacks.onChanged?.call(v);
    if (_lastValid != result.valid) {
      _lastValid = result.valid;
      callbacks.onValidationChanged?.call(result);
    }
    _emit();
  }

  void _emit() => notifyListeners();

  // ---- derived view-state getters ----
  bool get isEmpty {
    final v = getValue();
    return v.text.trim().isEmpty && v.references.isEmpty;
  }

  /// The high-level UI state string. Mirrors the React `state` field.
  String get stateName {
    if (_readOnly) return 'readOnly';
    if (suggestion.open) return 'suggestionOpen';
    if (dragState == DropState.dragOver) return 'dragOver';
    if (focused) return isEmpty ? 'focused' : 'typing';
    return 'idle';
  }

  String? get selectedTokenId {
    final code = editing.selectedCode;
    if (code == null) return null;
    return editing.refByCode[code]?.id;
  }

  @override
  void dispose() {
    editing.removeListener(_onEditingChanged);
    editing.dispose();
    focusNode.dispose();
    super.dispose();
  }
}

class _TriggerCtx {
  _TriggerCtx(
      {required this.key,
      required this.trig,
      required this.query,
      required this.start,
      required this.end});
  final String key;
  final TriggerConfig trig;
  final String query;
  final int start;
  final int end;
}

/// Small helper to grab the first parsed token from an encoded fragment.
class SmartComposerParserParseHelper {
  SmartComposerParserParseHelper._();
  static SmartComposerToken? firstToken(String encoded) {
    final r = SmartComposerParser.parse(encoded);
    return r.tokens.isNotEmpty ? r.tokens.first : null;
  }
}
