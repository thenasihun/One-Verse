// Browser walkthrough of every screen on the web build.
// flutter build web --release --no-web-resources-cdn && (cd build/web && python3 -m http.server 8765) &
// node tool/web_e2e.js <out-dir> [dark|light]
const { chromium } = require('playwright');
const OUT = process.argv[2]; const scheme = process.argv[3] || 'dark';
(async () => {
  const b = await chromium.launch({ args: ['--autoplay-policy=no-user-gesture-required'] });
  const ctx = await b.newContext({ viewport: { width: 412, height: 892 }, deviceScaleFactor: 2, colorScheme: scheme });
  const p = await ctx.newPage();
  const logs = [];
  p.on('console', m => { if (['error','warning'].includes(m.type())) logs.push(m.type() + ': ' + m.text().slice(0, 300)); });
  p.on('pageerror', e => logs.push('pageerror: ' + e.message));
  await p.goto('http://localhost:8765/?a11y=1');
  await p.waitForTimeout(7000);
  await p.locator('flt-semantics-placeholder').click({ force: true }).catch(e => logs.push('no placeholder'));
  await p.waitForTimeout(800);
  console.log('semantics nodes', await p.locator('flt-semantics').count());
  await p.waitForTimeout(1200);
  let n = 0;
  const shot = async name => { await p.screenshot({ path: `${OUT}/${String(++n).padStart(2,'0')}-${name}.png` }); };
  const click = async (label, opts = {}) => {
    const ex = opts.exact ?? false;
    const cands = [p.getByRole('tab', { name: label, exact: ex }), p.getByRole('button', { name: label, exact: ex }),
      p.locator(`flt-semantics[aria-label*="${label}"]`), p.getByText(label, { exact: ex }), p.locator(`flt-semantics:has-text("${label}")`)];
    for (const loc of cands) {
      const all = await loc.all();
      const ordered = opts.first ? all : all.reverse();
      for (const l of ordered) {
        const bb = await l.boundingBox().catch(() => null);
        if (!bb || bb.y < 0 || bb.y > 880 || bb.width === 0) continue;
        await p.mouse.click(bb.x + bb.width / 2, bb.y + bb.height / 2); return true;
      }
    }
    logs.push('could not click ' + label); return false;
  };
  if (scheme === 'light') { await click('Script and reading'); await p.waitForTimeout(1200); await p.mouse.move(206, 600); await p.mouse.wheel(0, 2000); await p.waitForTimeout(800); await click('Light', { exact: true }); await p.waitForTimeout(800); await p.keyboard.press('Escape'); await p.waitForTimeout(1200); }
  await shot('home');
  await p.mouse.wheel(0, 700); await p.waitForTimeout(800); await shot('home-scrolled');
  await p.mouse.wheel(0, 1400); await p.waitForTimeout(2500); await shot('home-bottom');
  await click('Surahs', { exact: true }); await p.waitForTimeout(1500); await shot('surahs');
  await p.mouse.click(206, 86); await p.waitForTimeout(500); await p.keyboard.type('Mulk'); await p.waitForTimeout(1200); await shot('surahs-search');
  await p.mouse.click(206, 200); await p.waitForTimeout(6000); await shot('reader');
  await click('Play', { exact: true }); await p.waitForTimeout(9000); await shot('reader-playing');
  await p.waitForTimeout(6000); await shot('reader-playing-2');
  await click('Script and reading'); await p.waitForTimeout(1500); await shot('script-sheet');
  await click('IndoPak · Nastaleeq'); await p.waitForTimeout(800); await p.keyboard.press('Escape'); await p.waitForTimeout(1200); await shot('reader-indopak');
  await click('Script and reading'); await p.waitForTimeout(1200); await click('Tajweed colours'); await p.waitForTimeout(1000); await shot('script-tajweed-legend');
  await p.keyboard.press('Escape'); await p.waitForTimeout(1500); await shot('reader-tajweed');
  await click('Script and reading'); await p.waitForTimeout(1200); await click('Uthmani · Amiri Quran'); await p.waitForTimeout(800); await p.keyboard.press('Escape'); await p.waitForTimeout(1500); await shot('reader-uthmani');
  await click('Script and reading'); await p.waitForTimeout(1200); await click('Simple · Naskh'); await p.waitForTimeout(800); await p.keyboard.press('Escape'); await p.waitForTimeout(1500); await shot('reader-simple');
  await click('Script and reading'); await p.waitForTimeout(1200); await click('Madani · KFGQPC Hafs'); await p.waitForTimeout(800); await p.keyboard.press('Escape'); await p.waitForTimeout(1500);
  await click('Open in focus view', { first: true }); await p.waitForTimeout(4000); await shot('focus');
  await click('Close focus view'); await p.waitForTimeout(1500);
  await p.mouse.click(150, 852); await p.waitForTimeout(2500); await shot('now-playing');
  await p.mouse.move(206, 600); await p.mouse.wheel(0, 900); await p.waitForTimeout(1000); await shot('now-playing-2');
  await p.mouse.wheel(0, 1200); await p.waitForTimeout(1000); await shot('now-playing-3');
  await p.mouse.wheel(0, -3000); await p.waitForTimeout(800); await p.mouse.wheel(0, 600); await p.waitForTimeout(800);
  await click('Change', { exact: true }); await p.waitForTimeout(2500); await shot('reciters');
  await p.mouse.wheel(0, 900); await p.waitForTimeout(1500); await shot('reciters-2');
  await p.keyboard.press('Escape'); await p.waitForTimeout(1000);
  await click('Close', { exact: true }); await p.waitForTimeout(1200);
  await p.goBack().catch(()=>{}); await click('Back'); await p.waitForTimeout(1500);
  await click('Progress', { exact: true }); await p.waitForTimeout(2000); await shot('progress');
  await p.mouse.move(206, 450); await p.mouse.wheel(0, 700); await p.waitForTimeout(800); await shot('progress-2'); await p.mouse.wheel(0, 900); await p.waitForTimeout(800); await shot('progress-3');
  await click('Library', { exact: true }); await p.waitForTimeout(2000); await shot('library');
  await click('Home', { exact: true }); await p.waitForTimeout(1200); await p.mouse.move(206, 400); await p.mouse.wheel(0, -4000); await p.waitForTimeout(1000);
  await click('About and credits'); await p.waitForTimeout(2000); await shot('about');
  console.log(JSON.stringify(logs.slice(0, 40), null, 1));
  await b.close();
})();
