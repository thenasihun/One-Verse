// Renders the Play Store graphics from slides.html and feature.html, in English and Urdu.
// node store/playstore/design/render.js   (needs Playwright; uses the app screens in this folder)
const path = require('path');
const fs = require('fs');
const { chromium } = require('playwright');
const ORDER = ['overview', 'word', 'share', 'player', 'tafseer', 'playlists', 'scripts', 'urdu', 'reciters', 'moments'];
const out = path.join(__dirname, '..');
(async () => {
  const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: 540, height: 960 }, deviceScaleFactor: 2 });
  for (const lang of ['en', 'ur']) {
    const dir = path.join(out, 'screenshots', lang);
    fs.mkdirSync(dir, { recursive: true });
    for (const [i, k] of ORDER.entries()) {
      await p.goto(`file://${__dirname}/slides.html?s=${k}&lang=${lang}`);
      await p.waitForSelector('body[data-ready="1"]');
      await p.screenshot({ path: path.join(dir, `${String(i + 1).padStart(2, '0')}-${k}.png`) });
    }
  }
  const f = await b.newPage({ viewport: { width: 1024, height: 500 }, deviceScaleFactor: 1 });
  for (const lang of ['en', 'ur']) {
    await f.goto(`file://${__dirname}/feature.html?lang=${lang}`);
    await f.waitForSelector('body[data-ready="1"]');
    await f.screenshot({ path: path.join(out, lang === 'en' ? 'feature-graphic.png' : 'feature-graphic-ur.png') });
  }
  await b.close();
})();
