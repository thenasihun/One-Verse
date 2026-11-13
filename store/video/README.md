# Promo video

`one-verse-promo.mp4`: 1920×1080, 30 fps, 83 s, English voice-over over a soft recitation of Ar-Rahman
(Mishary Alafasy).

How it was made (`source/`):
1. `record.js` drives the web build (`flutter build web`, served on port 8765) with Playwright and records the
   screen as JPEG frames through the Chrome DevTools screencast, with a marker at each scene. It draws a
   white ripple on every tap and a gold outline on the option being explained.
2. `script.json` holds the voice-over lines, one per scene. They were spoken with edge-tts (`en-US-AndrewNeural`).
3. `assets.py` draws the background, the phone frame and the titles.
4. `build.py` cuts each scene from the frames, fits it to its voice-over, and joins the scenes with crossfades.
5. `compose.py` lays the screen into the phone, animates the titles and the progress bar, and mixes the voice
   with the recitation, ducking the recitation under the voice.
