/* =============================================================================
   SmartComposer — TESTS  (in-page unit tests for the encoding layer)
   Exposes SC.runTests() -> [{ group, name, pass, detail }]
============================================================================= */
(function () {
  const SC = window.SC;
  const P = SC.SmartComposerParser;

  function run() {
    const results = [];
    let group = '';
    const G = (g) => (group = g);
    const ok = (name, cond, detail) => results.push({ group, name, pass: !!cond, detail: detail || '' });
    const eq = (name, a, b) => ok(name, a === b, a === b ? '' : `got ${JSON.stringify(a)} ≠ ${JSON.stringify(b)}`);

    /* ---- parsing ---- */
    G('Parsing');
    {
      const r = P.parse('Hello [@user:Ahmed](user://user_123)!');
      eq('segment count', r.segments.length, 3);
      eq('leading text', r.segments[0].text, 'Hello ');
      eq('token prefix', r.tokens[0].prefix, '@');
      eq('token tagType', r.tokens[0].tagType, 'user');
      eq('token displayText', r.tokens[0].displayText, 'Ahmed');
      eq('token valueText', r.tokens[0].valueText, 'user://user_123');
      eq('trailing text', r.segments[2].text, '!');
    }
    {
      const r = P.parse('[$tool:Browser Use](skill://openai-bundled/browser-use/0.1.0-alpha1/browser)');
      eq('uri value preserved', r.tokens[0].valueText, 'skill://openai-bundled/browser-use/0.1.0-alpha1/browser');
      eq('display with space', r.tokens[0].displayText, 'Browser Use');
    }

    /* ---- token position: begin / middle / end / adjacent ---- */
    G('Positions');
    {
      eq('token at beginning', P.parse('[@user:A](user://a) tail').segments[0].kind, 'token');
      eq('token at end', P.parse('lead [@user:A](user://a)').segments.slice(-1)[0].kind, 'token');
      const adj = P.parse('[@user:A](user://a)[#task:B](task://b)');
      eq('adjacent: 2 tokens', adj.tokens.length, 2);
      eq('adjacent: no text between', adj.segments.length, 2);
    }

    /* ---- serialization round-trip ---- */
    G('Serialization');
    {
      const src = 'Pay [#invoice:INV-2026-001](invoice://INV-2026-001) from [$financialAccount:Main Bank Account](financial-account://main_bank_account).';
      const v = SC.SmartComposerValue.fromEncodedText(src);
      eq('round-trips identically', SC.SmartComposerSerializer.serialize(v), src);
      eq('segments round-trip', SC.SmartComposerSerializer.serialize({ segments: v.segments }), src);
    }

    /* ---- plainText conversion ---- */
    G('plainText');
    {
      const enc = 'Pay invoice [#invoice:INV-2026-001](invoice://INV-2026-001) from [$financialAccount:Main Bank Account](financial-account://main_bank_account).';
      eq('tokens → displayText', SC.SmartComposerPlainTextConverter.convert(enc), 'Pay invoice INV-2026-001 from Main Bank Account.');
      ok('no encoded syntax leaks', !/[\[\]\(\)]/.test(SC.SmartComposerPlainTextConverter.convert(enc)));
    }

    /* ---- escaping ---- */
    G('Escaping');
    {
      const t = { prefix: '@', tagType: 'user', displayText: 'Ahmed: Lead [VIP]', valueText: 'user://u_1' };
      const enc = SC.tokenToEncoded(t);
      const back = P.parse(enc).tokens[0];
      eq('display with ] survives', back.displayText, 'Ahmed: Lead [VIP]');
      const t2 = { prefix: '@', tagType: 'file', displayText: 'weird) name', valueText: 'file:///a/b(c).pdf' };
      const back2 = P.parse(SC.tokenToEncoded(t2)).tokens[0];
      eq('value with ) survives', back2.valueText, 'file:///a/b(c).pdf');
      eq('display with ) survives', back2.displayText, 'weird) name');
    }

    /* ---- windows path → file uri ---- */
    G('File URIs');
    {
      const ref = SC.createReference({ type: 'file', title: 'client-a.pdf', path: 'C:\\Users\\Al-saiary\\contracts\\client-a.pdf' });
      eq('windows path encodes to file:///', SC.valueTextForRef(ref), 'file:///C:/Users/Al-saiary/contracts/client-a.pdf');
    }

    /* ---- invalid tokens become text (never crash) ---- */
    G('Invalid → text');
    {
      eq('missing closing bracket', P.parse('[@user:Ahmed(user://x)').tokens.length, 0);
      eq('missing paren', P.parse('[@user:Ahmed] hi').tokens.length, 0);
      eq('empty tagType invalid', P.parse('[@:Ahmed](user://x)').tokens.length, 0);
      eq('empty valueText invalid', P.parse('[@user:Ahmed]()').tokens.length, 0);
      eq('plain markdown link untouched', P.parse('see [docs](https://x.y)').tokens.length, 0);
      const r = P.parse('[@:Ahmed](user://x)');
      eq('invalid kept as text', r.segments[0].kind, 'text');
      ok('error recorded', r.errors.length > 0);
    }

    /* ---- empty displayText falls back to valueText ---- */
    G('Fallbacks');
    {
      eq('empty display → value', P.parse('[@user:](user://user_9)').tokens[0].displayText, 'user://user_9');
    }

    /* ---- unknown tagType still parses (generic) ---- */
    G('Unknown types');
    {
      const r = P.parse('[~widget:Gadget](widget://w_1)');
      eq('unknown tagType parsed', r.tokens.length, 1);
      eq('unknown prefix kept', r.tokens[0].prefix, '~');
      eq('unknown tagType kept', r.tokens[0].tagType, 'widget');
    }

    /* ---- long values & many tokens ---- */
    G('Scale');
    {
      const long = 'x'.repeat(2000);
      const r = P.parse(`[@file:big](file:///${long})`);
      eq('long value intact', r.tokens[0].valueText.length, ('file:///' + long).length);
      const many = Array.from({ length: 50 }, (_, i) => `[#task:T${i}](task://t_${i})`).join(' ');
      eq('50 tokens parsed', P.parse(many).tokens.length, 50);
    }

    /* ---- token index extractor ---- */
    G('Token index');
    {
      const idx = SC.SmartComposerTokenIndex.extract('[#invoice:INV-1](invoice://1) & [@user:A](user://a)');
      eq('index length', idx.length, 2);
      eq('index entry shape', Object.keys(idx[0]).sort().join(','), 'displayText,prefix,tagType,valueText');
    }

    /* ---- restore from encodedText alone (no JSON) ---- */
    G('Restore');
    {
      const src = 'Use [$tool:Browser Use](skill://o/b) on [@source:Documents](plugin://documents@x).';
      const segs = SC.encodedToSegments(src);
      eq('rebuilt segment count', segs.length, 5);
      eq('rebuilt back to encoded', SC.segmentsToEncoded(segs), src);
    }

    /* ---- drag & drop: file → token mapping ---- */
    G('Drag & drop');
    {
      eq('png → image', SC.mapExtToType('png', 'image/png'), 'image');
      eq('mp4 → video', SC.mapExtToType('mp4', 'video/mp4'), 'video');
      eq('pdf → document', SC.mapExtToType('pdf', 'application/pdf'), 'document');
      eq('zip → file (fallback)', SC.mapExtToType('zip', 'application/zip'), 'file');
      const item = SC.makeDropItem({ name: 'client-a.pdf', path: 'C:\\contracts\\client-a.pdf', size: 2400000 });
      eq('drop item type', item.type, 'document');
      eq('drop item uri = file://', item.uri, 'file:///C:/contracts/client-a.pdf');
      const tok = SC.dropItemToToken(item);
      eq('dropped token tagType', tok.tagType, 'document');
      eq('dropped token displayText', tok.displayText, 'client-a.pdf');
      const enc = SC.tokenToEncoded(tok);
      eq('dropped token round-trips', SC.SmartComposerParser.parse(enc).tokens[0].valueText, 'file:///C:/contracts/client-a.pdf');
      const url = SC.makeDropItemFromUrl('https://genius.link/q4-board/');
      eq('url → link', url.type, 'link');
      eq('url display trimmed', url.name, 'genius.link/q4-board');
    }

    /* ---- drop validation ---- */
    G('Drop validation');
    {
      const big = SC.makeDropItem({ name: 'huge.zip', size: 48 * 1024 * 1024 });
      ok('rejects oversize', SC.SmartComposerDropValidator.validate(big, { maxFileSize: 25 * 1024 * 1024 }).valid === false);
      const exe = SC.makeDropItem({ name: 'installer.exe', size: 10 });
      ok('rejects blocked ext', SC.SmartComposerDropValidator.validate(exe, {}).valid === false);
      const png = SC.makeDropItem({ name: 'a.png', mimeType: 'image/png', size: 1000 });
      ok('accepts allowed ext', SC.SmartComposerDropValidator.validate(png, { allowedExtensions: ['png'] }).valid === true);
      ok('rejects ext not in allow-list', SC.SmartComposerDropValidator.validate(SC.makeDropItem({ name: 'a.pdf', size: 1 }), { allowedExtensions: ['png'] }).valid === false);
      ok('mime wildcard match', SC.SmartComposerDropValidator.validate(png, { allowedMimeTypes: ['image/*'] }).valid === true);
    }

    /* ---- caret-aware insertion (offset → segments) ---- */
    G('Caret insertion');
    {
      // build segments representing "Hello | world" then insert a token at the bar
      const before = SC.encodedToSegments('Hello  world');
      // simulate insertTokenAtOffset by string-splicing the encoded form
      const enc = 'Hello [@user:Ahmed](user://u) world';
      const segs = SC.encodedToSegments(enc);
      eq('token sits between text', segs[1].kind, 'ref');
      eq('text after token preserved', segs[2].text, ' world');
      eq('round-trips with mid token', SC.segmentsToEncoded(segs), enc);
    }

    const pass = results.filter((r) => r.pass).length;
    return { results, pass, fail: results.length - pass, total: results.length };
  }

  SC.runTests = run;
})();
