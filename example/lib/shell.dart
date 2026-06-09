import 'package:flutter/material.dart';
import 'package:smart_composer_flutter/smart_composer_flutter.dart';

import 'tabs/playground_tab.dart';
import 'tabs/gallery_tab.dart';
import 'tabs/encoding_tab.dart';
import 'tabs/drop_tab.dart';
import 'tabs/tests_tab.dart';
import 'tabs/docs_tab.dart';
import 'ui.dart';

/// The app shell: GeniusLink-branded header with the cube mark, the tab strip,
/// the theme toggle and a body that swaps tabs. Mirrors `App` in showcase.jsx.
class ShowcaseShell extends StatefulWidget {
  const ShowcaseShell(
      {super.key, required this.brightness, required this.onToggleTheme});
  final Brightness brightness;
  final VoidCallback onToggleTheme;

  @override
  State<ShowcaseShell> createState() => _ShowcaseShellState();
}

class _ShowcaseShellState extends State<ShowcaseShell> {
  String _tab = 'playground';
  final _toast = ToastController();

  // Layout breakpoints — mirror SmartComposer.html exactly:
  //   ≤820px  tab strip collapses to a dropdown menu
  //   ≤460px  brand subtitle + version pill drop; dropdown shows icon only
  static const double kTabBreakpoint = 820;
  static const double kTinyBreakpoint = 460;

  static const _tabs = [
    ['playground', 'Playground', 'layout-panel-left'],
    ['examples', 'Examples', 'layout-grid'],
    ['encoding', 'Encoding', 'braces'],
    ['drop', 'Drag & Drop', 'mouse-pointer-2'],
    ['tests', 'Tests', 'flask-conical'],
    ['docs', 'Docs / API', 'book-open'],
  ];

  @override
  Widget build(BuildContext context) {
    final theme = ComposerThemeScope.of(context);
    return Scaffold(
      backgroundColor: theme.pageBg,
      body: Stack(
        children: [
          Column(
            children: [
              _header(theme),
              Expanded(child: _body(theme)),
            ],
          ),
          ToastHost(controller: _toast),
        ],
      ),
    );
  }

  Widget _header(ComposerTheme theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final narrow = w <= kTabBreakpoint;
        final tiny = w <= kTinyBreakpoint;
        return Container(
          decoration: BoxDecoration(
            color: theme.bg,
            border: Border(bottom: BorderSide(color: theme.borderSoft)),
          ),
          padding:
              EdgeInsets.symmetric(horizontal: tiny ? 16 : 20, vertical: 12),
          child: Padding(
            padding: EdgeInsets.only(top: narrow ? 24.0 : 0),
            child: Row(
              children: [
                Flexible(child: _brand(theme, tiny: tiny)),
                const Spacer(),
                if (narrow)
                  _tabDropdown(theme, tiny: tiny)
                else
                  _tabStrip(theme),
                SizedBox(width: narrow ? 8 : 14),
                IconButton(
                  onPressed: widget.onToggleTheme,
                  tooltip: 'Toggle theme',
                  icon: Icon(
                    ComposerIcons.resolve(
                        widget.brightness == Brightness.dark ? 'sun' : 'moon'),
                    size: 18,
                    color: theme.fg2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _brand(ComposerTheme theme, {required bool tiny}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _CubeMark(),
        const SizedBox(width: 12),
        // title column shrinks + ellipsizes so the header never overflows
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('SmartComposer',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: theme.fg1,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: theme.displayFont,
                      letterSpacing: -0.3)),
              if (!tiny)
                Text('GeniusLink · entity-aware editor',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: theme.fg3, fontSize: 11.5)),
            ],
          ),
        ),
        if (!tiny) ...[
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: theme.bg2,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: theme.borderSoft),
            ),
            child: Text('v$kSmartComposerVersion',
                style: TextStyle(
                    color: theme.fg3,
                    fontSize: 11,
                    fontFamily: theme.monoFont)),
          ),
        ],
      ],
    );
  }

  /// Compact tab dropdown shown ≤820px in place of the [_tabStrip]. Mirrors the
  /// `.pg-tabsel` menu in showcase.jsx — 44px touch-target rows, current tab
  /// marked with a check, icon-only trigger on tiny screens.
  Widget _tabDropdown(ComposerTheme theme, {required bool tiny}) {
    final cur = _tabs.firstWhere((t) => t[0] == _tab);
    return PopupMenuButton<String>(
      tooltip: 'Switch tab',
      onSelected: (id) => setState(() => _tab = id),
      color: theme.bg,
      elevation: 8,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: theme.border),
      ),
      itemBuilder: (context) => _tabs.map((t) {
        final on = t[0] == _tab;
        return PopupMenuItem<String>(
          value: t[0],
          height: 44,
          child: Row(
            children: [
              Icon(ComposerIcons.resolve(t[2]),
                  size: 16, color: on ? theme.accent : theme.fg2),
              const SizedBox(width: 10),
              Text(t[1],
                  style: TextStyle(
                      color: on ? theme.accent : theme.fg2,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              if (on) ...[
                const Spacer(),
                Icon(ComposerIcons.resolve('check'),
                    size: 15, color: theme.accent),
              ],
            ],
          ),
        );
      }).toList(),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: theme.bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ComposerIcons.resolve(cur[2]), size: 16, color: theme.accent),
            if (!tiny) ...[
              const SizedBox(width: 8),
              Text(cur[1],
                  style: TextStyle(
                      color: theme.fg1,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
            const SizedBox(width: 6),
            Icon(ComposerIcons.resolve('chevron-down'),
                size: 15, color: theme.fg3),
          ],
        ),
      ),
    );
  }

  Widget _tabStrip(ComposerTheme theme) {
    return Wrap(
      spacing: 2,
      children: _tabs.map((t) {
        final on = _tab == t[0];
        return Material(
          color: on ? theme.accent.withOpacity(0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          child: InkWell(
            onTap: () => setState(() => _tab = t[0]),
            borderRadius: BorderRadius.circular(7),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(ComposerIcons.resolve(t[2]),
                      size: 15, color: on ? theme.accent : theme.fg3),
                  const SizedBox(width: 6),
                  Text(t[1],
                      style: TextStyle(
                          color: on ? theme.accent : theme.fg2,
                          fontSize: 13,
                          fontWeight: on ? FontWeight.w600 : FontWeight.w500)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _body(ComposerTheme theme) {
    final maxWidth = 1180.0;
    Widget content;
    switch (_tab) {
      case 'examples':
        content = GalleryTab(toast: _toast);
        break;
      case 'encoding':
        content = EncodingTab(toast: _toast);
        break;
      case 'drop':
        content = DropTab(toast: _toast);
        break;
      case 'tests':
        content = const TestsTab();
        break;
      case 'docs':
        content = const DocsTab();
        break;
      case 'playground':
      default:
        content = PlaygroundTab(toast: _toast);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        // tighten horizontal gutter on phones (mirrors clamp(16px,4vw,…) in CSS)
        final hPad = constraints.maxWidth <= kTinyBreakpoint ? 16.0 : 24.0;
        return SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(
                padding: EdgeInsets.fromLTRB(hPad, 28, hPad, 64),
                child: content,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The 3-face isometric GeniusLink cube mark (CSS recreation as a CustomPaint).
class _CubeMark extends StatelessWidget {
  const _CubeMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 30, height: 30, child: CustomPaint(painter: _CubePainter()));
  }
}

class _CubePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cx = w / 2;
    final top = Offset(cx, h * 0.06);
    final right = Offset(w * 0.94, h * 0.30);
    final bottomR = Offset(w * 0.94, h * 0.72);
    final bottom = Offset(cx, h * 0.96);
    final bottomL = Offset(w * 0.06, h * 0.72);
    final left = Offset(w * 0.06, h * 0.30);
    final mid = Offset(cx, h * 0.52);

    void face(List<Offset> pts, Color c) {
      final p = Path()..moveTo(pts[0].dx, pts[0].dy);
      for (final pt in pts.skip(1)) {
        p.lineTo(pt.dx, pt.dy);
      }
      p.close();
      canvas.drawPath(p, Paint()..color = c);
    }

    // top face (violet accent), left (blue), right (darker blue)
    face([top, right, mid, left], const Color(0xFF8B7CF6));
    face([left, mid, bottom, bottomL], const Color(0xFF4A7CFF));
    face([mid, right, bottomR, bottom], const Color(0xFF2C5BD8));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
