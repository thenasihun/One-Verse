// Records the app (web build) as JPEG frames with scene markers.
const { chromium } = require('playwright');
const fs = require('fs');
const OUT = process.argv[2];
const sleep = ms => new Promise(r => setTimeout(r, ms));
(async () => {
  const b = await chromium.launch({ args: ['--autoplay-policy=no-user-gesture-required'] });
  const ctx = await b.newContext({ viewport: { width: 412, height: 892 }, deviceScaleFactor: 2, hasTouch: false });
  await ctx.addInitScript(() => {
    if (!localStorage.getItem('flutter.favSurahs')) {
      localStorage.setItem('flutter.favSurahs', JSON.stringify(['36', '18', '67']));
      localStorage.setItem('flutter.favReciters', JSON.stringify(['ov.saadghamdi']));
      localStorage.setItem('flutter.bookmarks', JSON.stringify(JSON.stringify([
        { s: 2, a: 255, n: 'Ayat al-Kursi, before sleep', t: Date.now() - 86400000 },
        { s: 94, a: 5, n: 'With hardship comes ease', t: Date.now() - 3 * 86400000 }])));
    }
    const css = `.ov-tap{position:fixed;width:46px;height:46px;margin:-23px 0 0 -23px;border-radius:50%;background:rgba(255,255,255,.45);
      border:2px solid rgba(255,255,255,.9);pointer-events:none;z-index:99999;animation:ovtap .55s ease-out forwards}
      @keyframes ovtap{0%{transform:scale(.4);opacity:1}100%{transform:scale(1.5);opacity:0}}
      .ov-hl{position:fixed;border:3px solid #E9C46A;border-radius:18px;pointer-events:none;z-index:99998;
      box-shadow:0 0 0 4px rgba(233,196,106,.25),0 0 28px rgba(233,196,106,.55);animation:ovhl 1.2s ease-in-out infinite alternate, ovin .25s ease-out}
      @keyframes ovhl{0%{box-shadow:0 0 0 3px rgba(233,196,106,.2),0 0 18px rgba(233,196,106,.4)}100%{box-shadow:0 0 0 7px rgba(233,196,106,.3),0 0 34px rgba(233,196,106,.7)}}
      @keyframes ovin{0%{opacity:0;transform:scale(1.08)}100%{opacity:1;transform:scale(1)}}`;
    const add = () => { const s = document.createElement('style'); s.textContent = css; document.head.appendChild(s); };
    if (document.head) add(); else document.addEventListener('DOMContentLoaded', add);
    window.__tap = (x, y) => { const d = document.createElement('div'); d.className = 'ov-tap'; d.style.left = x + 'px'; d.style.top = y + 'px'; document.body.appendChild(d); setTimeout(() => d.remove(), 700); };
    window.__hl = (x, y, w, h, ms) => { const d = document.createElement('div'); d.className = 'ov-hl'; Object.assign(d.style, { left: (x - 4) + 'px', top: (y - 4) + 'px', width: (w + 8) + 'px', height: (h + 8) + 'px' }); document.body.appendChild(d); setTimeout(() => d.remove(), ms); };
  });
  const p = await ctx.newPage();
  const logs = [];
  p.on('pageerror', e => logs.push('pageerror: ' + e.message));
  await p.goto('http://localhost:8765/?a11y=1&demo=1');
  await sleep(9000);
  await p.locator('flt-semantics-placeholder').click({ force: true }).catch(() => {});
  await sleep(1000);

  const find = async (label, opts = {}) => {
    const ex = opts.exact ?? false;
    const cands = [p.getByRole('tab', { name: label, exact: ex }), p.getByRole('button', { name: label, exact: ex }),
      p.locator(`flt-semantics[aria-label*="${label}"]`), p.getByText(label, { exact: ex })];
    for (const loc of cands) {
      const all = await loc.all();
      for (const l of (opts.first ? all : all.reverse())) {
        const bb = await l.boundingBox().catch(() => null);
        if (!bb || bb.y < (opts.minY ?? 0) || bb.y > (opts.maxY ?? 880) || bb.width === 0) continue;
        return bb;
      }
    }
    logs.push('not found: ' + label); return null;
  };
  const tapXY = async (x, y) => { await p.evaluate(([x, y]) => window.__tap(x, y), [x, y]); await sleep(120); await p.mouse.click(x, y); };
  const tap = async (label, opts) => { const bb = await find(label, opts); if (bb) await tapXY(bb.x + bb.width / 2, bb.y + bb.height / 2); return bb; };
  // scrolls until the label is on screen, then taps it
  const reach = async (label, opts = {}) => {
    const n0 = logs.length;
    for (let i = 0; i < 10; i++) {
      const bb = await find(label, { ...opts, minY: 90, maxY: 780 });
      if (bb) { logs.length = n0; return bb; }
      await p.mouse.move(206, 500); for (let k = 0; k < 4; k++) { await p.mouse.wheel(0, (opts.up ? -1 : 1) * 70); await sleep(40); }
      await sleep(250);
    }
    logs.length = n0; logs.push('not reached: ' + label);
    return null;
  };
  const hscroll = async (y, dx) => { await p.mouse.move(250, y); for (let i = 0; i < 16; i++) { await p.mouse.wheel(dx / 16, 0); await sleep(35); } };
  const hl = async (bb, ms = 1400) => { if (bb) await p.evaluate(([x, y, w, h, ms]) => window.__hl(x, y, w, h, ms), [bb.x, bb.y, bb.width, bb.height, ms]); };
  const hlLabel = async (label, ms, opts) => hl(await find(label, opts), ms);
  const scroll = async (dy, steps = 8, x = 206, y = 520) => { await p.mouse.move(x, y); for (let i = 0; i < steps; i++) { await p.mouse.wheel(0, dy / steps); await sleep(45); } };

  // close the "welcome back" sheet if it shows
  if (await find('Close', { exact: true })) { await tap('Close', { exact: true }); await sleep(1200); }
  logs.length = 0;

  // ---- screencast
  const client = await ctx.newCDPSession(p);
  let n = 0; const index = [];
  client.on('Page.screencastFrame', async f => {
    const name = `f${String(n++).padStart(6, '0')}.jpg`;
    fs.writeFileSync(`${OUT}/${name}`, Buffer.from(f.data, 'base64'));
    index.push([f.metadata.timestamp, name]);
    client.send('Page.screencastFrameAck', { sessionId: f.sessionId }).catch(() => {});
  });
  await client.send('Page.startScreencast', { format: 'jpeg', quality: 92, maxWidth: 824, maxHeight: 1784, everyNthFrame: 1 });
  const marks = {};
  const mark = (k, edge) => { marks[k] = marks[k] || {}; marks[k][edge] = Date.now() / 1000; };
  // keep frames flowing even when nothing changes
  await p.evaluate(() => { const d = document.createElement('div'); Object.assign(d.style, { position: 'fixed', left: '0', top: '0', width: '1px', height: '1px', zIndex: 1, opacity: 0.01, background: '#000' }); document.body.appendChild(d); let i = 0; setInterval(() => { d.style.background = (i++ % 2) ? '#000' : '#010101'; }, 33); });
  await sleep(800);


  // ---- home: Today card and suggestions
  mark('home', 'start');
  await sleep(1600);
  await hlLabel('TODAY', 1500); await sleep(1200);
  await scroll(300, 12); await sleep(500);
  await hlLabel('For this moment', 1600); await sleep(1900);
  await scroll(330, 12); await sleep(500);
  await hlLabel('Your playlists', 1500); await sleep(1600);
  mark('home', 'end');

  // open Ar-Rahman and play (cut away)
  await scroll(-3000, 6); await sleep(400);
  await tapXY(154, 862); await sleep(1500);
  await p.mouse.click(206, 86); await sleep(400); await p.keyboard.type('Rahman'); await sleep(1200);
  await p.mouse.click(206, 200); await sleep(5000);
  { const pl = await find('Play', { exact: true, maxY: 450, first: true }); if (pl) await tapXY(pl.x + pl.width / 2, pl.y + pl.height / 2); }
  await sleep(4500);
  mark('hook', 'start'); await sleep(7500); mark('hook', 'end');

  // share studio
  await tap('Share ayah', { first: true, minY: 120 }); await sleep(4200);
  mark('share', 'start');
  await sleep(700);
  await tap('Night'); await sleep(1200);
  await hscroll(773, 500); await sleep(500);
  for (const st of ['Gold sand', 'Rose sand']) { await tap(st); await sleep(1250); }
  await hscroll(773, 900); await sleep(400);
  await tap('Plum'); await sleep(1250);
  await tap('Video', { exact: true }); await sleep(1700);
  await tap('Audio', { exact: true }); await sleep(1700);
  await tap('Image', { exact: true }); await sleep(900);
  mark('share', 'end');
  await p.mouse.click(22, 30); await sleep(1500);

  // now playing deck
  await tapXY(150, 852); await sleep(1800);
  mark('deck', 'start');
  await sleep(600);
  await scroll(420, 10); await sleep(700);
  for (const l of ['Reciter', 'Translation', 'You hear']) { await hlLabel(l, 1150, { minY: 300 }); await sleep(1150); }
  mark('deck', 'end');

  // focus view
  { const f = await reach('Focus view'); if (f) await tapXY(f.x + f.width / 2, f.y + f.height / 2); }
  await sleep(2200);
  mark('focus', 'start');
  await sleep(1600);
  await hlLabel('Hear: ', 1300); await sleep(1300);
  await hscroll(764, 1400); await sleep(900);
  await hlLabel('Tafseer', 1200, { exact: true }); await sleep(1000);
  await tap('Ayahs', { exact: true }); await sleep(2600);
  await tap('Close', { exact: true }); await sleep(900);
  mark('focus', 'end');

  mark('tafseer', 'start');
  await tap('Tafseer', { exact: true }); await sleep(3800);
  await tap('Bayan ul Quran'); await sleep(3400);
  mark('tafseer', 'end');
  await tap('Close', { exact: true }); await sleep(900);

  // playlists
  await p.reload(); await sleep(9000);
  await p.locator('flt-semantics-placeholder').click({ force: true }).catch(() => {});
  await sleep(1000);
  { const n0 = logs.length; if (await find('Close', { exact: true })) { await tap('Close', { exact: true }); await sleep(1200); } logs.length = n0; }
  await tapXY(360, 862); await sleep(1800);
  mark('playlists', 'start');
  await sleep(500);
  await tap('Playlists'); await sleep(2000);
  await tap('Before sleep'); await sleep(2600);
  await scroll(400, 10); await sleep(1800);
  mark('playlists', 'end');
  await p.mouse.click(22, 30); await sleep(1200); await p.mouse.click(22, 30); await sleep(1200);

  await tapXY(51, 862); await sleep(1500);
  await scroll(-3000, 6); await sleep(800);
  mark('outro', 'start'); await sleep(3000); mark('outro', 'end');

  await client.send('Page.stopScreencast');
  await sleep(500);
  fs.writeFileSync(`${OUT}/index.json`, JSON.stringify({ index, marks }, null, 1));
  console.log('frames', n, JSON.stringify(marks));
  console.log(logs.join('\n'));
  await b.close();
})();
