// Renders the social posters from posters.html: 3 designs x English, Urdu, Arabic x portrait (1080x1350)
// and square (1080x1080).   node store/social/render.js   (needs Playwright)
const path = require('path');
const fs = require('fs');
const { chromium } = require('playwright');
const only = process.argv[2];
(async () => {
  const b = await chromium.launch();
  for (const f of ['portrait', 'square']) {
    const p = await b.newPage({ viewport: { width: 540, height: f === 'square' ? 540 : 675 }, deviceScaleFactor: 2 });
    const dir = path.join(__dirname, f);
    fs.mkdirSync(dir, { recursive: true });
    for (const c of ['hero', 'ayah', 'features']) {
      for (const lang of ['en', 'ur', 'ar']) {
        const name = `${c}-${lang}`;
        if (only && !name.includes(only)) continue;
        await p.goto(`file://${__dirname}/posters.html?c=${c}&lang=${lang}&f=${f}`);
        await p.waitForSelector('body[data-ready="1"]');
        await p.screenshot({ path: path.join(dir, `${name}.png`) });
      }
    }
  }
  await b.close();
})();
