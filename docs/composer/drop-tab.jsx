/* =============================================================================
   SmartComposer — DRAG & DROP demo tab
   exposes window.SCDropTab
============================================================================= */
(function () {
  const { useState, useRef } = React;
  const h = React.createElement;
  const Icon = window.SCIcon;
  const toast = (t, i) => window.SCtoast && window.SCtoast(t, i);

  // sample draggable resources (mimics OS files / in-app resources / a URL)
  const TRAY = [
    { type: 'image', name: 'storefront-render.png', size: 1.2 * 1024 * 1024, mimeType: 'image/png', uri: 'file:///assets/storefront-render.png' },
    { type: 'document', name: 'Vendor Agreement.pdf', size: 880 * 1024, mimeType: 'application/pdf', uri: 'file:///contracts/vendor-agreement.pdf' },
    { type: 'video', name: 'walkthrough.mp4', size: 18.4 * 1024 * 1024, mimeType: 'video/mp4', uri: 'file:///media/walkthrough.mp4' },
    { type: 'document', name: 'q4-reconciliation.xlsx', size: 760 * 1024, mimeType: 'application/vnd.ms-excel', uri: 'file:///finance/q4-reconciliation.xlsx' },
    { type: 'file', name: 'client-a.pdf', size: 2.4 * 1024 * 1024, path: 'C:\\Users\\Al-saiary\\contracts\\client-a.pdf', uri: 'file:///C:/Users/Al-saiary/contracts/client-a.pdf' },
    { type: 'link', name: 'genius.link/q4-board', size: 0, isRemote: true, isLocal: false, uri: 'https://genius.link/q4-board' },
    { type: 'file', name: 'huge-backup.zip', size: 48 * 1024 * 1024, mimeType: 'application/zip', uri: 'file:///backups/huge-backup.zip', _note: 'over 25 MB → rejected' },
    { type: 'file', name: 'installer.exe', size: 4 * 1024 * 1024, mimeType: 'application/x-msdownload', uri: 'file:///downloads/installer.exe', _note: 'blocked extension' },
  ];

  function TrayChip({ item }) {
    const def = SC.ReferenceRegistry.get(item.type);
    const acc = SC.ACCENTS[def.accent] || SC.ACCENTS.neutral;
    const onDragStart = (e) => {
      e.dataTransfer.effectAllowed = 'copy';
      e.dataTransfer.setData('application/x-smartcomposer', JSON.stringify(item));
      e.dataTransfer.setData('text/plain', item.name);
    };
    return h('div', { className: 'drop-chip' + (item._note ? ' drop-chip--warn' : ''), draggable: true, onDragStart, title: 'Drag into the composer' },
      h('span', { className: 'drop-chip__ic', style: { '--tk': acc.fg, '--tk-bg': acc.bg } }, h(Icon, { name: def.icon, size: 15 })),
      h('span', { className: 'drop-chip__body' },
        h('span', { className: 'drop-chip__t' }, item.name),
        h('span', { className: 'drop-chip__m' }, item._note ? item._note : (item.size ? SC.formatBytes(item.size) : (item.isRemote ? 'remote link' : 'resource')))
      ),
      h(Icon, { name: 'grip-vertical', size: 14, className: 'drop-chip__grip' })
    );
  }

  function DropTab() {
    const [log, setLog] = useState([]);
    const [encoded, setEncoded] = useState('');
    const [maxMb, setMaxMb] = useState(25);
    const [multiple, setMultiple] = useState(true);
    const [imagesOnly, setImagesOnly] = useState(false);
    const api = useRef(null);
    const push = (name, detail, kind) => setLog((l) => [{ id: Date.now() + Math.random(), name, detail, kind, t: new Date().toLocaleTimeString([], { hour12: false }) }, ...l].slice(0, 9));

    const dnd = {
      maxFileSize: maxMb * 1024 * 1024,
      allowMultiple: multiple,
      allowedExtensions: imagesOnly ? ['png', 'jpg', 'jpeg', 'gif', 'webp', 'svg'] : null,
    };
    const dropCallbacks = {
      onFilesDropped: (items) => push('onFilesDropped', `${items.length} item(s)`, 'info'),
      onDroppedTokenInserted: (tok) => { push('onDroppedTokenInserted', `${tok.prefix}${tok.tagType} · ${tok.displayText}`, 'ok'); toast('Inserted ' + tok.displayText, 'check'); setEncoded(api.current.getEncodedText()); },
      onDropRejected: (rej) => rej.forEach((r) => push('onDropRejected', `${r.item.name} — ${r.errors[0].message}`, 'err')),
      onDrop: () => setEncoded(api.current ? api.current.getEncodedText() : ''),
    };
    const callbacks = {
      onChanged: () => setEncoded(api.current ? api.current.getEncodedText() : ''),
      onReferenceTap: (r) => toast(`${r.type} · ${r.value}`, r.icon),
    };

    return h('div', { className: 'enc-wrap' },
      h('p', { className: 'pg-section-note' }, 'Drag any resource below into the composer — it becomes a typed smart token at the drop point. Files map to image / video / document / file by extension; URLs become links; absolute paths become file:// URIs. Drops never upload; they only build tokens and fire callbacks.'),

      h('div', { className: 'drop-grid' },
        // tray
        h('div', null,
          h('div', { className: 'pg-eyebrow', style: { display: 'flex', marginBottom: 12 } }, h('span', { className: 'gl-mk gl-mk--orange' }), 'Draggable resources'),
          h('div', { className: 'drop-tray' }, TRAY.map((it, i) => h(TrayChip, { key: i, item: it }))),
          h('div', { className: 'drop-cfg' },
            h('div', { className: 'drop-cfg__h' }, h(Icon, { name: 'sliders-horizontal', size: 14 }), 'Drop config'),
            h('label', { className: 'drop-cfg__row' },
              h('span', null, 'Max file size'),
              h('span', { className: 'drop-cfg__val' }, maxMb + ' MB'),
              h('input', { type: 'range', min: 1, max: 50, value: maxMb, onChange: (e) => setMaxMb(+e.target.value) })),
            h('label', { className: 'drop-cfg__row drop-cfg__row--toggle', onClick: () => setMultiple(!multiple) },
              h('span', null, 'Allow multiple'), h('span', { className: 'pg-switch' + (multiple ? ' is-on' : '') }, h('span', { className: 'pg-switch__k' }))),
            h('label', { className: 'drop-cfg__row drop-cfg__row--toggle', onClick: () => setImagesOnly(!imagesOnly) },
              h('span', null, 'Images only'), h('span', { className: 'pg-switch' + (imagesOnly ? ' is-on' : '') }, h('span', { className: 'pg-switch__k' })))
          )
        ),
        // composer + log
        h('div', null,
          h('div', { className: 'pg-eyebrow', style: { display: 'flex', marginBottom: 12 } }, h('span', { className: 'gl-mk gl-mk--blue' }), 'Drop target'),
          h(SmartComposer, { mode: SC.MODES.message, apiRef: api, dnd, dropCallbacks, callbacks,
            seed: SC.encodedToSegments('Please review these before the audit: ') }),
          encoded && h('div', { className: 'enc-plain', style: { borderTop: 'none', paddingLeft: 2, marginTop: 8 } }, h('span', { className: 'enc-plain__k' }, 'encodedText →'), ' ', encoded),
          h('div', { className: 'pg-panel__h', style: { marginTop: 20 } }, h(Icon, { name: 'activity', size: 15 }), 'Drop callbacks'),
          h('div', { className: 'pg-log' },
            log.length === 0 && h('div', { className: 'pg-muted', style: { padding: '8px 2px' } }, 'Drag a resource into the composer — try the two warning chips to see rejection.'),
            log.map((e) => h('div', { key: e.id, className: 'pg-logrow' },
              h('span', { className: 'pg-logt' }, e.t),
              h('code', { className: 'pg-logname', style: e.kind === 'err' ? { color: 'var(--gl-danger-500)' } : e.kind === 'ok' ? { color: 'var(--gl-success-500)' } : null }, e.name),
              h('span', { className: 'pg-logd' }, e.detail))))
        )
      )
    );
  }

  window.SCDropTab = DropTab;
})();
