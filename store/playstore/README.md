# Play Store graphics

| File | Size | Use |
|---|---|---|
| `screenshots/01-overview.png` … `10-offline.png` | 1080×1920 | Phone screenshots, in upload order (Play takes 8; see `PLAYSTORE_DEPLOY.md`) |
| `feature-graphic.png` | 1024×500 | Feature graphic |
| `design/` | | Sources: `slides.html`, `feature.html`, the app screens they use, and `render.js` |

## Regenerating

1. Edit the text or the callout positions in `design/slides.html` (the `S` object) or `design/feature.html`.
2. Render:

   ```bash
   npm install playwright && npx playwright install chromium
   node store/playstore/design/render.js
   ```

## Retaking the app screens

The phone screens inside the slides come from the web build, which can fill in sample listening history for
screenshots. This only runs on the web, and only with `?demo=1`:

```bash
flutter build web --release --no-web-resources-cdn
cd build/web && python3 -m http.server 8765
```

Open `http://localhost:8765/?demo=1` in Chrome's phone emulation (393×852, device pixel ratio 3). It starts with
a 15-day streak and Al-Mulk ayah 12 as the place you stopped.

Optional query parameters set the reading options:
- `&script=indopak` (or `hafs`, `tajweed`, `uthmani`, `simple`)
- `&tr=ur.jalandhry` (any AlQuran Cloud translation id)

Save each screen as a PNG over the matching file in `design/`, then render again.
