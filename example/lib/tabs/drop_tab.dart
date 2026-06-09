import 'package:flutter/material.dart';
import 'package:smart_composer_flutter/smart_composer_flutter.dart';

import '../ui.dart';

class _TrayItem {
  const _TrayItem(this.raw, {this.note});
  final Map<String, dynamic> raw;
  final String? note;
}

final _tray = <_TrayItem>[
  _TrayItem({'type': 'image', 'name': 'storefront-render.png', 'size': (1.2 * 1024 * 1024).round(), 'mimeType': 'image/png', 'uri': 'file:///assets/storefront-render.png'}),
  _TrayItem({'type': 'document', 'name': 'Vendor Agreement.pdf', 'size': 880 * 1024, 'mimeType': 'application/pdf', 'uri': 'file:///contracts/vendor-agreement.pdf'}),
  _TrayItem({'type': 'video', 'name': 'walkthrough.mp4', 'size': (18.4 * 1024 * 1024).round(), 'mimeType': 'video/mp4', 'uri': 'file:///media/walkthrough.mp4'}),
  _TrayItem({'type': 'document', 'name': 'q4-reconciliation.xlsx', 'size': 760 * 1024, 'mimeType': 'application/vnd.ms-excel', 'uri': 'file:///finance/q4-reconciliation.xlsx'}),
  _TrayItem({'type': 'file', 'name': 'client-a.pdf', 'size': (2.4 * 1024 * 1024).round(), 'path': 'C:\\Users\\Al-saiary\\contracts\\client-a.pdf', 'uri': 'file:///C:/Users/Al-saiary/contracts/client-a.pdf'}),
  _TrayItem({'type': 'link', 'name': 'genius.link/q4-board', 'size': 0, 'isRemote': true, 'isLocal': false, 'uri': 'https://genius.link/q4-board'}),
  _TrayItem({'type': 'file', 'name': 'huge-backup.zip', 'size': 48 * 1024 * 1024, 'mimeType': 'application/zip', 'uri': 'file:///backups/huge-backup.zip'}, note: 'over 25 MB → rejected'),
  _TrayItem({'type': 'file', 'name': 'installer.exe', 'size': 4 * 1024 * 1024, 'mimeType': 'application/x-msdownload', 'uri': 'file:///downloads/installer.exe'}, note: 'blocked extension'),
];

/// The Drag & Drop tab — a tray of draggable resources, a drop-target composer,
/// live drop config and a callback log. Mirrors `DropTab` in drop-tab.jsx.
class DropTab extends StatefulWidget {
  const DropTab({super.key, required this.toast});
  final ToastController toast;

  @override
  State<DropTab> createState() => _DropTabState();
}

class _DropTabState extends State<DropTab> {
  final List<_Log> _log = [];
  String _encoded = '';
  double _maxMb = 25;
  bool _multiple = true;
  bool _imagesOnly = false;
  ComposerController? _api;

  void _push(String name, String detail, String kind) {
    setState(() {
      _log.insert(0, _Log(name, detail, kind, TimeOfDay.now()));
      if (_log.length > 9) _log.removeRange(9, _log.length);
    });
  }

  DropConfig get _dnd => DropConfig(
        maxFileSize: (_maxMb * 1024 * 1024).round(),
        allowMultiple: _multiple,
        allowedExtensions: _imagesOnly ? const ['png', 'jpg', 'jpeg', 'gif', 'webp', 'svg'] : null,
      );

  DropCallbacks get _dropCallbacks => DropCallbacks(
        onFilesDropped: (items) => _push('onFilesDropped', '${items.length} item(s)', 'info'),
        onDroppedTokenInserted: (tok, ref, item) {
          _push('onDroppedTokenInserted', '${tok.prefix}${tok.tagType} · ${tok.displayText}', 'ok');
          widget.toast.show('Inserted ${tok.displayText}', Icons.check);
          setState(() => _encoded = _api?.getEncodedText() ?? '');
        },
        onDropRejected: (rej) {
          for (final r in rej) {
            _push('onDropRejected', '${r.item?.name} — ${r.errors.first.message}', 'err');
          }
        },
        onDrop: (_) => setState(() => _encoded = _api?.getEncodedText() ?? ''),
      );

  ComposerCallbacks get _callbacks => ComposerCallbacks(
        onChanged: (_) => setState(() => _encoded = _api?.getEncodedText() ?? ''),
        onReferenceTap: (r) => widget.toast.show('${r.type} · ${r.value}', ComposerIcons.resolve(r.icon)),
      );

  @override
  Widget build(BuildContext context) {
    final theme = ComposerThemeScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Ui.sectionNote(theme,
            'Drag any resource below into the composer — it becomes a typed smart token at the drop point. Files map to image / video / document / file by extension; URLs become links; absolute paths become file:// URIs. Drops never upload; they only build tokens and fire callbacks.'),
        LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth > 820;
          final tray = _trayColumn(theme);
          final target = _targetColumn(theme);
          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 320, child: tray),
                const SizedBox(width: 20),
                Expanded(child: target),
              ],
            );
          }
          return Column(children: [tray, const SizedBox(height: 20), target]);
        }),
      ],
    );
  }

  Widget _trayColumn(ComposerTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Ui.eyebrow(theme, 'Draggable resources', accent: 'orange'),
        const SizedBox(height: 12),
        ..._tray.map((it) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _TrayChip(item: it),
            )),
        const SizedBox(height: 8),
        Ui.card(
          theme,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Ui.panelHeader(theme, ComposerIcons.resolve('sliders-horizontal'), 'Drop config'),
              Row(
                children: [
                  Expanded(child: Text('Max file size', style: TextStyle(color: theme.fg2, fontSize: 12.5))),
                  Text('${_maxMb.round()} MB', style: TextStyle(fontFamily: theme.monoFont, fontSize: 12, color: theme.fg3)),
                ],
              ),
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 3,
                  activeTrackColor: theme.accent,
                  inactiveTrackColor: theme.borderSoft,
                  thumbColor: theme.accent,
                  overlayShape: SliderComponentShape.noOverlay,
                ),
                child: Slider(min: 1, max: 50, value: _maxMb, onChanged: (v) => setState(() => _maxMb = v)),
              ),
              _toggleRow(theme, 'Allow multiple', _multiple, () => setState(() => _multiple = !_multiple)),
              const SizedBox(height: 10),
              _toggleRow(theme, 'Images only', _imagesOnly, () => setState(() => _imagesOnly = !_imagesOnly)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _toggleRow(ComposerTheme theme, String label, bool on, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: theme.fg2, fontSize: 12.5)),
        Ui.switchBtn(theme, on, onTap),
      ],
    );
  }

  Widget _targetColumn(ComposerTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Ui.eyebrow(theme, 'Drop target', accent: 'blue'),
        const SizedBox(height: 12),
        SmartComposer(
          key: ValueKey('drop-${_maxMb.round()}-$_multiple-$_imagesOnly'),
          mode: ComposerModes.message,
          dnd: _dnd,
          dropCallbacks: _dropCallbacks,
          callbacks: _callbacks,
          seed: ComposerBridge.encodedToSegments('Please review these before the audit: '),
          onReady: (c) => _api = c,
        ),
        if (_encoded.isNotEmpty) ...[
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(children: [
              TextSpan(text: 'encodedText → ', style: TextStyle(fontFamily: theme.monoFont, fontSize: 11, color: theme.accent, fontWeight: FontWeight.w600)),
              TextSpan(text: _encoded, style: TextStyle(color: theme.fg2, fontSize: 12, height: 1.4, fontFamily: theme.monoFont)),
            ]),
          ),
        ],
        const SizedBox(height: 20),
        Ui.panelHeader(theme, ComposerIcons.resolve('activity'), 'Drop callbacks'),
        if (_log.isEmpty)
          Text('Drag a resource into the composer — try the two warning chips to see rejection.',
              style: TextStyle(color: theme.fg3, fontSize: 12))
        else
          ..._log.map((e) {
            final t = '${e.time.hour.toString().padLeft(2, '0')}:${e.time.minute.toString().padLeft(2, '0')}';
            final color = e.kind == 'err' ? theme.danger : (e.kind == 'ok' ? theme.success : theme.accent);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t, style: TextStyle(fontFamily: theme.monoFont, fontSize: 10.5, color: theme.fg3)),
                  const SizedBox(width: 8),
                  Text(e.name, style: TextStyle(fontFamily: theme.monoFont, fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(e.detail, maxLines: 2, style: TextStyle(color: theme.fg2, fontSize: 11.5))),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class _TrayChip extends StatelessWidget {
  const _TrayChip({required this.item});
  final _TrayItem item;

  @override
  Widget build(BuildContext context) {
    final theme = ComposerThemeScope.of(context);
    final type = item.raw['type'] as String;
    final def = ReferenceRegistry.get(type);
    final acc = ComposerAccents.resolve(def.accent);
    final dropItem = ComposerDnd.makeDropItem({...item.raw, if (item.note != null) '_note': item.note});
    final size = item.raw['size'] as int? ?? 0;
    final meta = item.note ?? (size > 0 ? ComposerDnd.formatBytes(size) : (item.raw['isRemote'] == true ? 'remote link' : 'resource'));

    final chip = Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: item.note != null ? theme.warning.withOpacity(0.5) : theme.borderSoft),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: acc.bg, borderRadius: BorderRadius.circular(6)),
            child: Icon(ComposerIcons.resolve(def.icon), size: 15, color: acc.fg),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item.raw['name'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: theme.fg1, fontSize: 12.5, fontWeight: FontWeight.w600)),
                Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: item.note != null ? theme.warning : theme.fg3, fontSize: 11)),
              ],
            ),
          ),
          Icon(ComposerIcons.resolve('grip-vertical'), size: 14, color: theme.fg3),
        ],
      ),
    );

    return Draggable<List<DropItem>>(
      data: [dropItem],
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.9,
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 280), child: chip),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: chip),
      child: MouseRegion(cursor: SystemMouseCursors.grab, child: chip),
    );
  }
}

class _Log {
  _Log(this.name, this.detail, this.kind, this.time);
  final String name;
  final String detail;
  final String kind;
  final TimeOfDay time;
}
