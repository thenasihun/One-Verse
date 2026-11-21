# Social posters

Three designs, each in English, Urdu and Arabic, in two sizes:

| Design | What it says |
|---|---|
| `hero-*` | "Listen to the Quran. Follow every word." with the player, the share studio and the Home screen |
| `ayah-*` | Ash-Sharh 94:5–6 ("with hardship comes ease") with its translation, for a calm, shareable post |
| `features-*` | Six features in a grid: reciters, tafseer, sharing, playlists, scripts, offline |

- `portrait/`: 1080×1350 (Instagram and Facebook feed, 4:5)
- `square/`: 1080×1080 (any feed, WhatsApp, X)

Each ends with the Google Play badge in its own language and the line "Free · No ads · No sign-up".
For stories and status (9:16), use the teasers in `store/video/`.

Rebuild with `node store/social/render.js` (Playwright). The text for each language is in `posters.html`;
Urdu uses Noto Nastaliq, Arabic uses Reem Kufi and Noto Naskh, the ayah uses the KFGQPC Hafs font.
The Urdu translation is Fateh Muhammad Jalandhry's and the English one is Saheeh International's.
