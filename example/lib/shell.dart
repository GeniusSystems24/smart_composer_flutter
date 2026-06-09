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
  const ShowcaseShell({super.key, required this.brightness, required this.onToggleTheme});
  final Brightness brightness;
  final VoidCallback onToggleTheme;

  @override
  State<ShowcaseShell> createState() => _ShowcaseShellState();
}

class _ShowcaseShellState extends State<ShowcaseShell> {
  String _tab = 'playground';
  final _toast = ToastController();

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
    return Container(
      decoration: BoxDecoration(
        color: theme.bg,
        border: Border(bottom: BorderSide(color: theme.borderSoft)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          _brand(theme),
          const Spacer(),
          _tabStrip(theme),
          const SizedBox(width: 14),
          IconButton(
            onPressed: widget.onToggleTheme,
            tooltip: 'Toggle theme',
            icon: Icon(
              ComposerIcons.resolve(widget.brightness == Brightness.dark ? 'sun' : 'moon'),
              size: 18,
              color: theme.fg2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _brand(ComposerTheme theme) {
    return Row(
      children: [
        const _CubeMark(),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('SmartComposer', style: TextStyle(color: theme.fg1, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: theme.displayFont, letterSpacing: -0.3)),
            Text('GeniusLink · entity-aware editor', style: TextStyle(color: theme.fg3, fontSize: 11.5)),
          ],
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: theme.bg2,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: theme.borderSoft),
          ),
          child: Text('v$kSmartComposerVersion', style: TextStyle(color: theme.fg3, fontSize: 11, fontFamily: theme.monoFont)),
        ),
      ],
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
                  Icon(ComposerIcons.resolve(t[2]), size: 15, color: on ? theme.accent : theme.fg3),
                  const SizedBox(width: 6),
                  Text(t[1], style: TextStyle(color: on ? theme.accent : theme.fg2, fontSize: 13, fontWeight: on ? FontWeight.w600 : FontWeight.w500)),
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
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 64),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// The 3-face isometric GeniusLink cube mark (CSS recreation as a CustomPaint).
class _CubeMark extends StatelessWidget {
  const _CubeMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 30, height: 30, child: CustomPaint(painter: _CubePainter()));
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
