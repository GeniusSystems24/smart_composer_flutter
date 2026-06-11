/* =============================================================================
   SmartComposer — DRAG & DROP  (framework-agnostic; no React)
   -----------------------------------------------------------------------------
   Turns dropped files / images / videos / documents / URLs / custom resources
   into encoded smart tokens — [<prefix><tagType>:<displayText>](valueText).
   The editor never uploads anything and never hardcodes backend logic; it only
   builds tokens and emits callbacks. All shapes mirror the spec models.

   Exposes:
     SC.DEFAULT_DROP_CONFIG
     SC.makeDropItemFromFile(file) / makeDropItemFromUrl(url) / makeDropItem(raw)
     SC.mapExtToType(ext, mime)
     SC.dropItemToToken(item)            // SmartComposerDropItem -> SmartComposerToken
     SC.SmartComposerDropValidator.validate(item, config)
     SC.DROP_STATE
============================================================================= */
(function () {
  const SC = (window.SC = window.SC || {});

  SC.DROP_STATE = Object.freeze({ idle: 'idle', dragOver: 'dragOver', rejected: 'rejected', dropped: 'dropped' });

  /* ---- default config (SmartComposerDropConfig) ---- */
  SC.DEFAULT_DROP_CONFIG = {
    enabled: true,
    allowMultiple: true,
    allowedExtensions: null,     // e.g. ['pdf','png'] — null = any
    allowedMimeTypes: null,      // e.g. ['image/*'] — null = any
    blockedExtensions: ['exe', 'bat', 'cmd', 'sh', 'dll', 'msi', 'app'],
    maxFileSize: 25 * 1024 * 1024,  // 25 MB
    maxFilesCount: 10,
    insertAtDropPosition: true,
    fallbackInsertAtEnd: true,
    replaceSelectionOnDrop: true,
    // generateTokenFromDropItem / customValidator can be supplied by the app
  };

  /* ---- extension / mime → tagType ---- */
  const EXT = {
    image: ['png', 'jpg', 'jpeg', 'gif', 'webp', 'svg', 'bmp', 'heic', 'avif'],
    video: ['mp4', 'mov', 'avi', 'mkv', 'webm', 'm4v'],
    document: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'csv', 'md', 'rtf', 'pages', 'numbers', 'key'],
  };
  SC.mapExtToType = function (ext, mime) {
    ext = (ext || '').toLowerCase();
    mime = (mime || '').toLowerCase();
    if (mime.startsWith('image/') || EXT.image.includes(ext)) return 'image';
    if (mime.startsWith('video/') || EXT.video.includes(ext)) return 'video';
    if (EXT.document.includes(ext) || /pdf|word|excel|powerpoint|spreadsheet|presentation|msword|officedocument|csv|text\/plain/.test(mime)) return 'document';
    return 'file';
  };

  function extOf(name) { const m = /\.([A-Za-z0-9]+)$/.exec(name || ''); return m ? m[1].toLowerCase() : ''; }
  function basename(p) { return String(p || '').split(/[\\/]/).pop(); }

  // Build a safe file URI. Browsers can't read absolute OS paths from a real
  // drop (security), so we fall back to a name-based file:/// URI; a richer
  // host (Electron / native) can pass a full path which we preserve.
  function fileUri(pathOrName) {
    const p = pathOrName || '';
    if (/^[a-z][\w+.-]*:\/\//i.test(p)) return p;             // already a URI
    if (/^[a-zA-Z]:[\\/]/.test(p)) return 'file:///' + p.replace(/\\/g, '/'); // windows path
    if (p.startsWith('/')) return 'file://' + p;               // posix absolute
    return 'file:///' + encodeURI(p).replace(/^\/+/, '');      // bare name
  }

  /* ---- SmartComposerDropItem factory ---- */
  SC.makeDropItem = function (raw) {
    const name = raw.name || basename(raw.path) || basename(raw.uri) || 'file';
    const ext = raw.extension || extOf(name);
    const type = raw.type || SC.mapExtToType(ext, raw.mimeType);
    return {
      type, name,
      path: raw.path || '',
      uri: raw.uri || fileUri(raw.path || name),
      mimeType: raw.mimeType || '',
      extension: ext,
      size: raw.size != null ? raw.size : 0,
      bytes: raw.bytes || null,
      metadata: raw.metadata || {},
      source: raw.source || 'os-file',
      isLocal: raw.isLocal !== false,
      isRemote: !!raw.isRemote,
    };
  };

  SC.makeDropItemFromFile = function (file) {
    const ext = extOf(file.name);
    // file.path exists only in Electron-like hosts; webkitRelativePath in dir picks
    const p = file.path || file.webkitRelativePath || file.name;
    return SC.makeDropItem({
      type: SC.mapExtToType(ext, file.type), name: file.name, path: file.path || '',
      uri: fileUri(p), mimeType: file.type || '', extension: ext, size: file.size,
      source: 'os-file', isLocal: true,
    });
  };

  SC.makeDropItemFromUrl = function (url) {
    const clean = String(url).trim();
    const label = clean.replace(/^https?:\/\//, '').replace(/\/$/, '');
    return SC.makeDropItem({
      type: 'link', name: label, uri: clean, mimeType: 'text/uri-list',
      source: 'url', isLocal: false, isRemote: true,
    });
  };

  /* ---- dropped item → encoded token ---- */
  SC.dropItemToToken = function (item) {
    return {
      prefix: SC.prefixForType(item.type),
      tagType: item.type,
      displayText: item.name,
      valueText: item.uri,
      rawText: '',
      metadata: item.metadata || {},
      resolveState: SC.RESOLVE_STATE ? SC.RESOLVE_STATE.idle : 'idle',
    };
  };

  /* ---- validator (SmartComposerDropValidator) ---- */
  SC.SmartComposerDropValidator = {
    validate(item, cfg) {
      cfg = Object.assign({}, SC.DEFAULT_DROP_CONFIG, cfg || {});
      const errors = [];
      const ext = (item.extension || '').toLowerCase();
      if (cfg.blockedExtensions && cfg.blockedExtensions.includes(ext))
        errors.push({ code: 'blockedType', message: `.${ext} files are not allowed.` });
      if (cfg.allowedExtensions && ext && !cfg.allowedExtensions.includes(ext))
        errors.push({ code: 'extensionNotAllowed', message: `.${ext} is not an accepted type.` });
      if (cfg.allowedMimeTypes && item.mimeType && !mimeOk(item.mimeType, cfg.allowedMimeTypes))
        errors.push({ code: 'mimeNotAllowed', message: `${item.mimeType} is not accepted.` });
      if (cfg.maxFileSize && item.size && item.size > cfg.maxFileSize)
        errors.push({ code: 'tooLarge', message: `${fmtSize(item.size)} exceeds the ${fmtSize(cfg.maxFileSize)} limit.` });
      if (cfg.customValidator) {
        const r = cfg.customValidator(item);
        if (r && r.valid === false) errors.push(...(r.errors || [{ code: 'custom', message: 'Rejected.' }]));
      }
      return { valid: errors.length === 0, errors, item };
    },
  };
  function mimeOk(mime, list) {
    return list.some((p) => p === mime || (p.endsWith('/*') && mime.startsWith(p.slice(0, -1))));
  }
  function fmtSize(n) {
    if (n < 1024) return n + ' B';
    if (n < 1024 * 1024) return (n / 1024).toFixed(0) + ' KB';
    return (n / 1024 / 1024).toFixed(1) + ' MB';
  }
  SC.formatBytes = fmtSize;

  /* ---- read a DataTransfer into SmartComposerDropItems ----
     Priority: app-custom payload > OS files > URL/text. Returns [] if nothing. */
  SC.dropItemsFromDataTransfer = function (dt) {
    const items = [];
    // 1) custom in-app drag payload (draggable chips, resource lists, etc.)
    try {
      const custom = dt.getData('application/x-smartcomposer');
      if (custom) {
        const arr = JSON.parse(custom);
        (Array.isArray(arr) ? arr : [arr]).forEach((r) => items.push(SC.makeDropItem(r)));
        if (items.length) return items;
      }
    } catch (e) { /* ignore malformed */ }
    // 2) real OS files
    if (dt.files && dt.files.length) {
      for (let i = 0; i < dt.files.length; i++) items.push(SC.makeDropItemFromFile(dt.files[i]));
      if (items.length) return items;
    }
    // 3) URL / text
    const uri = dt.getData('text/uri-list') || dt.getData('text/plain');
    if (uri && /^(https?|ftp|mailto):/i.test(uri.trim())) {
      uri.split(/\r?\n/).filter((l) => l && !l.startsWith('#')).forEach((u) => items.push(SC.makeDropItemFromUrl(u)));
    }
    return items;
  };
})();
