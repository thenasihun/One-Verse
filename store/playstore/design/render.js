// Renders the Play Store graphics from slides.html and feature.html.
// node store/playstore/design/render.js   (needs Playwright; uses the app screens in this folder)
const path = require('path');
const { chromium } = require('playwright');
const ORDER = ['overview', 'word', 'player', 'scripts', 'urdu', 'reciters', 'focus', 'progress', 'moments', 'offline'];
const out = path.join(__dirname, '..');
(async () => {
  const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: 540, height: 960 }, deviceScaleFactor: 2 });
  for (const [i, k] of ORDER.entries()) {
    await p.goto(`file://${__dirname}/slides.html?s=${k}`);
    await p.waitForSelector('body[data-ready="1"]');
    await p.screenshot({ path: path.join(out, 'screenshots', `${String(i + 1).padStart(2, '0')}-${k}.png`) });
  }
  const f = await b.newPage({ viewport: { width: 1024, height: 500 }, deviceScaleFactor: 1 });
  await f.goto(`file://${__dirname}/feature.html`);
  await f.waitForSelector('body[data-ready="1"]');
  await f.screenshot({ path: path.join(out, 'feature-graphic.png') });
  await b.close();
})();
