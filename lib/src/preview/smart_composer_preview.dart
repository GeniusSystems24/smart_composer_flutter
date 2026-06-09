import 'package:flutter/material.dart';

import '../encoding/token.dart';
import '../model/accents.dart';
import '../model/reference_registry.dart';
import '../theme/composer_theme.dart';
import '../widgets/composer_icons.dart';
import 'preview_resolver.dart';

/// A read-only, render-only view of encoded text (`.scp-root`). Parses, then
/// renders text runs interleaved with resolved token chips. Optionally resolves
/// each token via a [TokenResolver], reflecting loading / error / notFound /
/// permissionDenied / deleted states inline. Faithful port of `<SmartComposerPreview>`.
class SmartComposerPreview extends StatefulWidget {
  const SmartComposerPreview({
    super.key,
    required this.encodedText,
    this.resolver,
    this.onTokenTap,
    this.dense = false,
  });

  final String encodedText;
  final TokenResolver? resolver;
  final void Function(SmartComposerToken token)? onTokenTap;
  final bool dense;

  @override
  State<SmartComposerPreview> createState() => _SmartComposerPreviewState();
}

class _SmartComposerPreviewState extends State<SmartComposerPreview> {
  late PreviewResolverModel _model;

  @override
  void initState() {
    super.initState();
    _model = PreviewResolverModel(encodedText: widget.encodedText, resolver: widget.resolver)
      ..addListener(_onUpdate);
  }

  @override
  void didUpdateWidget(SmartComposerPreview old) {
    super.didUpdateWidget(old);
    if (old.encodedText != widget.encodedText) {
      _model.resolver = widget.resolver;
      _model.setEncodedText(widget.encodedText);
    } else if (old.resolver != widget.resolver) {
      _model.resolver = widget.resolver;
      _model.retry();
    }
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _model.removeListener(_onUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ComposerThemeScope.of(context);
    final spans = <InlineSpan>[];
    var tokenIndex = -1;
    for (final seg in _model.segments) {
      if (seg.isText) {
        spans.add(TextSpan(text: seg.text));
      } else {
        tokenIndex++;
        final resolved = _model.resolvedFor(tokenIndex);
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          baseline: TextBaseline.alphabetic,
          child: _PreviewToken(
            theme: theme,
            token: resolved.token,
            state: resolved.state,
            subtitle: resolved.subtitle,
            onTap: widget.onTokenTap == null ? null : () => widget.onTokenTap!(resolved.token),
            onRetry: _model.retry,
          ),
        ));
      }
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(widget.dense ? 10 : 14),
      decoration: BoxDecoration(
        color: theme.bg2,
        borderRadius: BorderRadius.circular(theme.radius),
        border: Border.all(color: theme.borderSoft),
      ),
      child: SelectableText.rich(
        TextSpan(
          style: TextStyle(fontSize: 15, height: 1.8, color: theme.fg1, fontFamily: theme.bodyFont),
          children: spans.isEmpty ? [TextSpan(text: '', style: TextStyle(color: theme.fg3))] : spans,
        ),
      ),
    );
  }
}

class _PreviewToken extends StatefulWidget {
  const _PreviewToken({
    required this.theme,
    required this.token,
    required this.state,
    required this.subtitle,
    required this.onTap,
    required this.onRetry,
  });

  final ComposerTheme theme;
  final SmartComposerToken token;
  final String state;
  final String? subtitle;
  final VoidCallback? onTap;
  final VoidCallback onRetry;

  @override
  State<_PreviewToken> createState() => _PreviewTokenState();
}

class _PreviewTokenState extends State<_PreviewToken> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final token = widget.token;
    final def = ReferenceRegistry.get(token.tagType);
    final state = widget.state;

    final isError = state == ResolveState.error ||
        state == ResolveState.notFound ||
        state == ResolveState.deleted;
    final isDenied = state == ResolveState.permissionDenied;
    final isLoading = state == ResolveState.loading;
    final isDisabled = state == ResolveState.disabled;

    ComposerAccent acc = ComposerAccents.resolve(token.accent ?? def.accent);
    if (isError) acc = ComposerAccents.resolve('red');
    if (isDenied || isDisabled) acc = ComposerAccents.resolve('neutral');

    String icon = token.tagType == def.type ? def.icon : def.icon;
    if (isDenied) icon = 'lock';
    if (isError) icon = 'alert-triangle';
    if (state == ResolveState.notFound) icon = 'circle-help';

    final mono = def.mono;
    final label = token.displayText.isNotEmpty ? token.displayText : token.valueText;

    Widget body = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading)
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 1.6, color: acc.fg),
          )
        else
          Icon(ComposerIcons.resolve(icon), size: 13, color: acc.fg),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: acc.fg,
              fontSize: mono ? 12.5 : 13.5,
              fontWeight: mono ? FontWeight.w500 : FontWeight.w600,
              fontFamily: mono ? theme.monoFont : theme.bodyFont,
              decoration: (isDisabled || state == ResolveState.deleted) ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
        if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.only(left: 5),
            decoration: BoxDecoration(border: Border(left: BorderSide(color: acc.fg.withOpacity(0.35)))),
            child: Text(
              widget.subtitle!,
              style: TextStyle(color: acc.fg.withOpacity(0.75), fontSize: 11.5, fontWeight: FontWeight.w500),
            ),
          ),
        ],
        if (isError) ...[
          const SizedBox(width: 4),
          GestureDetector(
            onTap: widget.onRetry,
            child: Icon(ComposerIcons.resolve('rotate-cw'), size: 12, color: acc.fg.withOpacity(0.8)),
          ),
        ],
      ],
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 1),
          padding: const EdgeInsets.fromLTRB(6, 2, 6, 2),
          decoration: BoxDecoration(
            color: _hover ? acc.bgHover : acc.bg,
            borderRadius: BorderRadius.circular(theme.tokenRadius),
            border: Border.all(color: acc.border),
          ),
          child: body,
        ),
      ),
    );
  }
}
