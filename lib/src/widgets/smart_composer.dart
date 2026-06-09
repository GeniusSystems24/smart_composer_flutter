import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controller/callbacks.dart';
import '../controller/composer_controller.dart';
import '../dnd/dnd.dart';
import '../model/modes.dart';
import '../model/reference.dart';
import '../model/segment.dart';
import '../model/attachment.dart';
import '../model/triggers.dart';
import '../theme/composer_theme.dart';
import 'attachment_bar.dart';
import 'composer_icons.dart';
import 'suggestion_menu.dart';
import 'toolbar.dart';
import 'token_chip.dart';

/// The composer widget — a faithful Flutter port of the React `<SmartComposer>`.
/// Mixes plain text with inline reference tokens, with triggers, a floating
/// suggestion menu, an attachment bar, a validation banner, a configurable
/// toolbar and drag & drop. Pass a [mode] (and optional [seed]/[callbacks]),
/// or supply your own [controller].
class SmartComposer extends StatefulWidget {
  const SmartComposer({
    super.key,
    this.mode,
    this.controller,
    this.callbacks = const ComposerCallbacks(),
    this.dropCallbacks = const DropCallbacks(),
    this.dnd,
    this.seed,
    this.attachments,
    this.readOnly = false,
    this.accessMode,
    this.modelName,
    this.submitOnEnter = true,
    this.searchProvider,
    this.onReady,
  }) : assert(mode != null || controller != null, 'Provide a mode or a controller');

  final ComposerMode? mode;
  final ComposerController? controller;
  final ComposerCallbacks callbacks;
  final DropCallbacks dropCallbacks;
  final DropConfig? dnd;
  final List<ComposerSegment>? seed;
  final List<ComposerAttachment>? attachments;
  final bool readOnly;
  final String? accessMode;
  final String? modelName;
  final bool submitOnEnter;
  final SearchProvider? searchProvider;
  final void Function(ComposerController controller)? onReady;

  @override
  State<SmartComposer> createState() => _SmartComposerState();
}

class _SmartComposerState extends State<SmartComposer> {
  late final ComposerController _controller;
  late final bool _ownsController;
  final _portalController = OverlayPortalController();

  ComposerController get c => _controller;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
    } else {
      _controller = ComposerController(
        mode: widget.mode!,
        callbacks: widget.callbacks,
        dropCallbacks: widget.dropCallbacks,
        dnd: widget.dnd,
        searchProvider: widget.searchProvider,
        accessMode: widget.accessMode,
        modelName: widget.modelName,
        readOnly: widget.readOnly,
        submitOnEnter: widget.submitOnEnter,
      );
      _ownsController = true;
    }

    _controller.editing.chipBuilder = (ctx, ref, code, selected) => ComposerTokenChip(
          controller: _controller,
          reference: ref,
          code: code,
          selected: selected,
          readOnly: _controller.readOnly,
        );

    _controller.focusNode.onKeyEvent = _onKeyEvent;
    _controller.focusNode.addListener(_onFocusChange);
    _controller.addListener(_syncPortal);

    if (widget.seed != null) _controller.setSegments(widget.seed!);
    if (widget.attachments != null) _controller.setAttachments(widget.attachments!);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onReady?.call(_controller);
    });
  }

  @override
  void didUpdateWidget(SmartComposer old) {
    super.didUpdateWidget(old);
    if (_ownsController) {
      if (widget.mode != null && widget.mode != old.mode) _controller.setMode(widget.mode!);
      if (widget.readOnly != old.readOnly) _controller.setReadOnly(widget.readOnly);
    }
  }

  void _onFocusChange() => _controller.setFocused(_controller.focusNode.hasFocus);

  void _syncPortal() {
    final open = _controller.suggestion.open;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (open && !_portalController.isShowing) {
        _portalController.show();
      } else if (!open && _portalController.isShowing) {
        _portalController.hide();
      }
    });
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final sug = _controller.suggestion;
    if (sug.open) {
      if (key == LogicalKeyboardKey.arrowDown) {
        _controller.moveActive(1);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowUp) {
        _controller.moveActive(-1);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.tab) {
        _controller.confirmActive();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.escape) {
        _controller.closeMenu();
        return KeyEventResult.handled;
      }
    }
    if (key == LogicalKeyboardKey.backspace) {
      if (_controller.handleBackspace()) return KeyEventResult.handled;
      return KeyEventResult.ignored;
    }
    if (key == LogicalKeyboardKey.enter &&
        !HardwareKeyboard.instance.isShiftPressed &&
        widget.submitOnEnter &&
        !sug.open) {
      _controller.submit();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _controller.removeListener(_syncPortal);
    _controller.focusNode.removeListener(_onFocusChange);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ComposerThemeScope.of(context);
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final mode = _controller.mode;
        final dragOver = _controller.dragState == DropState.dragOver;
        final dragReject = _controller.dragState == DropState.rejected;
        final invalid = !_controller.validation.valid && !_controller.isEmpty;
        final focused = _controller.focused;

        Color borderColor = theme.borderSoft;
        if (invalid) borderColor = theme.danger;
        if (focused || dragOver) borderColor = theme.accent;
        if (dragReject) borderColor = theme.danger;

        return DragTarget<List<DropItem>>(
          onWillAcceptWithDetails: (_) {
            _controller.onDragEnter();
            return _controller.dropEnabled;
          },
          onLeave: (_) => _controller.onDragLeave(),
          onAcceptWithDetails: (details) => _controller.handleDrop(details.data),
          builder: (context, candidate, rejected) {
            return Container(
              decoration: BoxDecoration(
                color: theme.bg,
                borderRadius: BorderRadius.circular(theme.radius),
                border: Border.all(color: borderColor, width: 1),
                boxShadow: [
                  if (focused || dragOver)
                    BoxShadow(color: theme.accent.withOpacity(0.22), blurRadius: 0, spreadRadius: 3),
                  BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 24, offset: const Offset(0, 12)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildEditor(theme, mode.placeholder, dragOver, dragReject),
                  ComposerBanner(controller: _controller),
                  AttachmentBar(controller: _controller, attachments: _controller.attachments),
                  if (!_controller.readOnly && mode.toolbar.isNotEmpty)
                    ComposerToolbar(controller: _controller),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEditor(ComposerTheme theme, String placeholder, bool dragOver, bool dragReject) {
    final field = Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      child: OverlayPortal(
        controller: _portalController,
        overlayChildBuilder: (context) {
          return _MenuFollower(
            link: _link,
            child: ComposerThemeScope(
              theme: theme,
              child: SuggestionMenu(controller: _controller, maxWidth: 340),
            ),
          );
        },
        child: CompositedTransformTarget(
          link: _link,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240),
            child: TextField(
              controller: _controller.editing,
              focusNode: _controller.focusNode,
              readOnly: _controller.readOnly,
              maxLines: null,
              minLines: 1,
              cursorColor: theme.accent,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              style: TextStyle(fontSize: 15, height: 1.7, color: theme.fg1, fontFamily: theme.bodyFont),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                hintText: placeholder,
                hintStyle: TextStyle(color: theme.fg3, fontSize: 15, height: 1.7),
              ),
            ),
          ),
        ),
      ),
    );

    if (!dragOver && !dragReject) return field;
    return Stack(
      children: [
        field,
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                color: (dragReject ? theme.danger : theme.accent).withOpacity(0.10),
                borderRadius: BorderRadius.circular(theme.radius),
                border: Border.all(color: dragReject ? theme.danger : theme.accent, width: 2, style: BorderStyle.solid),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(ComposerIcons.resolve(dragReject ? 'file-x' : 'file-down'), size: 22, color: dragReject ? theme.danger : theme.accent),
                  const SizedBox(height: 8),
                  Text(
                    dragReject ? 'Drops are disabled here' : 'Drop to insert as a reference',
                    style: TextStyle(color: dragReject ? theme.danger : theme.accent, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  final LayerLink _link = LayerLink();
}

class _MenuFollower extends StatelessWidget {
  const _MenuFollower({required this.link, required this.child});
  final LayerLink link;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      width: 340,
      child: CompositedTransformFollower(
        link: link,
        targetAnchor: Alignment.bottomLeft,
        followerAnchor: Alignment.topLeft,
        offset: const Offset(0, 6),
        child: Align(alignment: Alignment.topLeft, child: child),
      ),
    );
  }
}
