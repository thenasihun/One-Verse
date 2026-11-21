# Promo video and teasers (version 2.3)

| File | Size | Length | Use |
|---|---|---|---|
| `one-verse-promo.mp4` | 1920×1080 | 55 s | YouTube, then the YouTube link in the Play listing |
| `one-verse-teaser-en.mp4` | 1080×1920 | 19 s | Reels, Shorts, TikTok, WhatsApp status (English) |
| `one-verse-teaser-ur.mp4` | 1080×1920 | 19 s | The same in Urdu, with an Urdu voice-over |

The promo opens on a hook ("Lost your place while listening?") over the reader lighting up each word, then
shows the Today card, Focus view, the one-line player, the share studio, playlists and tafseer, and ends on
the Play badge. English voice-over over a soft recitation of Ar-Rahman (Mishary Alafasy), which ducks under
the voice.

How it was made (`source/`):
1. `record.js` drives the web build (`flutter build web`, served on port 8765, opened with `?a11y=1&demo=1`)
   with Playwright and records the screen as JPEG frames through the Chrome DevTools screencast, with a marker
   at each scene. It draws a ripple on every tap and a gold outline on the option being explained.
2. `script.json` holds the voice-over lines, one per scene, spoken with edge-tts (`en-US-AndrewNeural`).
3. `assets.py` draws the background, the phone frame and the titles.
4. `build.py` cuts each scene from the frames, fits it to its voice-over, and joins the scenes with crossfades.
5. `compose.py` lays the screen into the phone, animates the titles and the progress bar, and mixes the voice
   with the recitation.
6. `teaser.py` builds the 9:16 teasers from the same scene clips, with big captions and an end card;
   `teaser_vo.json` holds their voice-over lines and timings (`ur-PK-AsadNeural` for Urdu).

```bash
node record.js $W/frames
python3 assets.py $W/build ../../../assets/fonts logo.png badge.png
python3 build.py $W
python3 compose.py $W one-verse-promo.mp4
python3 teaser.py $W ../../../assets/fonts logo.png ../../social/badge-en.png en one-verse-teaser-en.mp4
```

`$W` is a work folder that also holds `vo/<scene>.mp3`, `vo_teaser_<lang>/<n>.mp3` with `times.json`, and
`bed.mp3` (https://server8.mp3quran.net/afs/055.mp3).
