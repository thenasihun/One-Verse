# One Verse v2.1.0 (build 6): Play Store deployment guide

This file is a set of instructions for an AI agent (or a person) publishing this update to Google Play.
Follow the steps in order. Do not change the build files or upload a different file.

Version 2.0 is a complete rebuild of the app with a new design, and 2.1 adds tafseer, bookmarks with notes and
a memorise mode. The listing text, screenshots and feature graphic all change with it, and one new declaration
is needed (foreground service, section 7).

---

## 1. Release facts

| Item | Value |
|---|---|
| App name (on device) | One Verse |
| Package name | `com.nasihun.oneverse` |
| Version name | `2.1.0` |
| Version code | `6` (previous release: `4`, version 1.1.0; or `5` if 2.0.0 was uploaded) |
| Target SDK / Compile SDK | 36 (Android 16) |
| Min SDK | 24 (Android 7.0), unchanged |
| Signing key alias | `oneverse` |
| Upload certificate SHA-256 | `47:41:EF:75:41:49:1C:2E:6C:C1:1D:E1:E5:4D:29:F6:9A:05:8D:01:53:C0:4F:45:25:82:93:03:EC:19:D1:F9` |
| Developer account | Nasihun (`https://play.google.com/store/apps/dev?id=8907093897824220429`) |
| Privacy policy | `https://nasihun.com/privacy-policy` (update it first, see section 7) |
| Support email | `thenasihun@gmail.com` |

## 2. Files to upload

All paths are relative to the project root `/Users/Data/Development/flutter/One-Verse`.

| Purpose | File | Upload? |
|---|---|---|
| **App bundle (upload this to Play)** | `build/app/outputs/bundle/release/app-release.aab` | **Yes** |
| R8 deobfuscation mapping | `build/app/outputs/mapping/release/mapping.txt` | Yes (App bundle explorer → Downloads → ReTrace mapping file) |
| Phone screenshots (1080×1920) | `store/playstore/screenshots/01-overview.png` … `08-progress.png` | Yes, in this order |
| Extra screenshots | `store/playstore/screenshots/09-moments.png`, `10-offline.png` | Optional (tablet slots, see section 6) |
| Feature graphic (1024×500) | `store/playstore/feature-graphic.png` | Yes |
| App icon (512×512) | unchanged | No |
| Signed APK (testing or sideloading only) | `build/app/outputs/flutter-apk/app-release.apk` | No. Play only accepts the `.aab` |

How to build these files is in section 10.

---

## 3. Step by step in Google Play Console

1. Open https://play.google.com/console and sign in with the Nasihun developer account.
2. Select the app **One Verse** (`com.nasihun.oneverse`).
3. First do **App content → Foreground service permissions** (section 7). Play rejects the release without it.
4. Go to **Test and release → Production** (or **Closed testing** to test first).
5. Click **Create new release**.
6. Under **App bundles**, click **Upload** and choose `build/app/outputs/bundle/release/app-release.aab`.
   - Wait until it shows **Version 6 (2.1.0)** with no errors.
7. **Release name:** `2.1.0 (6) – Tafseer, bookmarks, memorise mode, 50+ reciters`
8. **Release notes:** paste the text from section 4. Add both `en-US` and `ur` if the Urdu listing exists.
9. Click **Next**. Read the warnings screen (section 8), then click **Save**.
10. Update the store listing (section 5) and the graphics (section 6).
11. Go to **Publishing overview** and click **Send changes for review**.
12. Recommended: a **staged rollout** of 20%, increased after 1–2 days with no crash reports in **Android vitals**.

Listing changes are reviewed together with the release.

---

## 4. Release notes ("What's new", maximum 500 characters each)

### en-US (447 characters)
```
One Verse 2.1
• NEW Tafseer: Ibn Kathir, Bayan ul Quran (Dr. Israr Ahmad), Ma'arif al-Qur'an and more, in Urdu, English and Arabic
• NEW Bookmarks with your own notes
• NEW Memorise mode: loop ayahs 3×, 5×, 10× or more, with a pause between rounds
• 50+ reciters, favourites, word-by-word highlight, 5 scripts
• Download the complete Quran; it keeps going in the background
• Sleep timer now fades out gently
• Continues exactly where you left off
```

### ur (Urdu, 409 characters)
```
ون ورس 2.1
• نیا: تفسیر – ابنِ کثیر، بیان القرآن (ڈاکٹر اسرار احمد)، معارف القرآن اور مزید، اردو، انگریزی اور عربی میں
• نیا: بک مارکس، اپنے نوٹس کے ساتھ
• نیا: حفظ موڈ – آیات کو 3، 5، 10 یا زیادہ بار دہرائیں، ہر دور کے بیچ وقفہ
• 50 سے زائد قاری، پسندیدہ، لفظ بہ لفظ ہائی لائٹ، 5 رسم الخط
• مکمل قرآن ڈاؤن لوڈ، بیک گراؤنڈ میں بھی جاری
• سلیپ ٹائمر اب آہستہ آہستہ آواز کم کرتا ہے
• جہاں چھوڑا تھا وہیں سے جاری
```

---

## 5. Store listing (Grow users → Store presence → Main store listing)

### App name (maximum 30 characters)
Recommended (29 characters):
```
One Verse: Quran Word by Word
```
Alternatives: `One Verse - Quran Audio & Read` (30), `One Verse: Quran Audio Offline` (30).

### Short description (maximum 80 characters)
76 characters:
```
Quran audio with word-by-word highlight, 5 scripts, Urdu & 40+ translations.
```

### Full description (maximum 4000 characters)
3653 characters:
```
One Verse – Hear the Quran. See every word.

One Verse is a calm, beautiful Quran app for listening, reading and understanding, one ayah at a time. Free forever, with no ads, no subscriptions and no sign-up.

✨ WORD-BY-WORD HIGHLIGHT
• Every word lights up exactly as the reciter says it
• Word-exact timing for 16 reciters, including Mishary Alafasy, Abdur-Rahman As-Sudais and Maher Al-Muaiqly
• The reader scrolls along by itself, ayah by ayah

📖 5 QURAN SCRIPTS, EACH IN ITS OWN FONT
• Madani (KFGQPC Hafs) – the printed Madinah Mushaf
• IndoPak Nastaleeq – the style most readers in Pakistan and India learned
• Tajweed colours – Madd, Ghunnah, Qalqalah, Ikhfa, Idgham, Iqlab and more
• Uthmani and Simple (modern spelling)
• Every mark sits in the right place, so the text reads correctly on Android

🎧 50+ RECITERS, WITH THEIR PHOTOS
• Mishary Alafasy, Sudais, Shuraim, Maher Al-Muaiqly, Yasser Al-Dosari, Saad Al-Ghamdi, Khalid Al-Jaleel, Idrees Abkar, Fares Abbad, Mansour Al-Salimi, Husary, Minshawi, Abdul Basit and many more
• Keep your favourite reciters and surahs one tap away
• Short biographies, Murattal, Mujawwad and teaching styles

🌍 UNDERSTAND EVERY AYAH
• 100+ translations in 40+ languages: Urdu, English, Hindi, Bengali, Indonesian, Turkish, French, Persian and more
• Urdu shown in beautiful Nastaliq
• Hear the translation audio after each Arabic ayah (English, Urdu, French, Russian, Persian, Chinese, Uzbek)
• Switch translation with one tap

▶️ A PLAYER MADE FOR THE QURAN
• Repeat an ayah 1×, 3× or forever – ideal for memorising
• Speed from 0.75× to 1.5× and a sleep timer that fades out gently
• Keeps playing in the background, with controls in the notification and on the lock screen
• Arabic only, Arabic + translation, or translation only

📚 TAFSEER, BOOKMARKS AND NOTES
• Read the tafseer of any ayah: Ibn Kathir, Bayan ul Quran (Dr. Israr Ahmad), Tazkir ul Quran and Fi Zilal al-Quran in Urdu; Ibn Kathir, Ma'arif al-Qur'an and Tazkirul Quran in English; Muyassar and Al-Sa'di in Arabic
• Bookmark ayahs and write your own notes and reflections

🧠 MEMORISE (HIFZ) MODE
• Loop a range of ayahs 3, 5, 10, 20 times or until you stop
• Add a pause between rounds to recite from memory

🕌 FOCUS VIEW
• One ayah, full screen, with its meaning below
• Swipe to move between ayahs; the screen stays awake

🔥 BUILD A DAILY HABIT
• Minutes listened today, this week, this month and this year
• Daily goal ring, listening streak and a calendar of your days
• Gentle reminders: your daily goal, Al-Kahf on Fridays, Al-Mulk before sleep
• Special days: Ramadan, the last ten nights, Arafah, Eid and Ashura

📶 ALWAYS READY, EVEN OFFLINE
• The whole Quran text in all five scripts, your translation and word timings are kept on your phone for 30 days
• On Wi-Fi it refreshes by itself, so it is always ready without internet
• Download the complete Quran with one tap, or any single surah. It keeps downloading in the background, pauses and resumes, and carries on by itself on Wi-Fi

⏯️ CONTINUE WHERE YOU LEFT OFF
• Close the app or restart your phone – One Verse opens on the same ayah, with the same reciter and settings

🎨 MADE WITH CARE
• Dark (emerald and gold) and light themes
• Adjustable Arabic and translation size
• Share any ayah

🔒 PRIVATE BY DESIGN
No account, no ads, no tracking. Your listening history stays on your device.

Quran text and word timings: Quran.com (Quran Foundation). Fonts: King Fahd Glorious Quran Printing Complex. Translations and audio: AlQuran Cloud, Quranic Audio and mp3quran. Full credits are in the app's About screen.

Made by Nasihun – nasihun.com. Please remember us in your duas.
```

### Category and tags
- Category: **Books & Reference** (keep the current one if it is different).
- Tags (pick up to 5): Religion & spirituality, Audiobooks, Education, Books, Reference.

---

## 6. Graphics (Main store listing → Graphics)

Play allows **up to 8 phone screenshots**. Upload them in this order:

| # | File | Shows |
|---|---|---|
| 1 | `store/playstore/screenshots/01-overview.png` | All 12 features with icons |
| 2 | `02-word.png` | Word-by-word highlight in the reader |
| 3 | `03-player.png` | Now Playing: repeat, speed, sleep timer, lock-screen controls |
| 4 | `04-scripts.png` | 5 Quran scripts and tajweed colours |
| 5 | `05-urdu.png` | IndoPak text with Urdu translation |
| 6 | `06-reciters.png` | 50+ reciters with photos |
| 7 | `07-focus.png` | Focus view |
| 8 | `08-progress.png` | Streaks and listening stats |

Optional:
- `09-moments.png` (Home and special days) and `10-offline.png` (offline library).
  - They can go in the **7-inch tablet** and **10-inch tablet** screenshot slots, or replace 7 and 8 above.
- **Feature graphic:** `store/playstore/feature-graphic.png` (1024×500).
- **App icon:** unchanged.
- **Promo video:** optional. `demo/one-verse-ad.mp4` is from the old 1.1.0 design, so do not use it for this release.

All images are PNG without transparency, at the sizes Play requires. To regenerate them, see
`store/playstore/README.md`.

---

## 7. Declarations (Policy and programs → App content)

### Foreground service permissions (new, required)
The app now declares `FOREGROUND_SERVICE_MEDIA_PLAYBACK`, so recitation keeps playing in the background with
notification controls.
- **Type:** Media playback.
- **Description to paste:**
  ```
  One Verse plays Quran recitation chosen by the user. The media playback foreground service keeps the recitation playing when the screen is off or the user switches to another app, and shows play/pause, next, previous and repeat controls in the notification and on the lock screen. Playback only starts when the user taps Play, and it stops when they pause or close it.
  ```
- **Video link:** if Play asks for one, record a 20–30 second screen recording and upload it to YouTube as
  *Unlisted*. Show these steps: play a surah → press Home → the notification controls → pause from the
  notification.

The app also declares `FOREGROUND_SERVICE_DATA_SYNC` (used by the `background_downloader` package), so recitation
downloads the user starts keep going in the background.
- **Type:** Data sync.
- **Description to paste:**
  ```
  One Verse downloads Quran recitations the user asks for (one surah, or the complete Quran) so they can listen offline. The data sync foreground service keeps these downloads running when the user leaves the app, and shows their progress in a notification. Downloads only start when the user taps Download, and can be paused or cancelled at any time.
  ```
- **Video link:** show tapping "Download complete Quran", pressing Home, and the download notification.

### Data safety
**No data collected**, unchanged. The answers stay:
- No data collected and no data shared.
- No account, ads or analytics.
- Listening history, streaks, settings and the resume point are stored **only on the device**.
- The app downloads public Quran content (text, translations, word timings, audio, reciter photos) from:
  - Quran.com
  - AlQuran Cloud
  - QuranHub
  - Quranic Audio and mp3quran
  - Two GitHub-hosted timing projects

  No user data is sent to any of them.

### Permissions
Removed in 2.0.0:
- `READ_MEDIA_AUDIO`
- `READ_EXTERNAL_STORAGE`
- `WRITE_EXTERNAL_STORAGE`

Downloads now go to the app's private storage.

Added in 2.0.0:
- `POST_NOTIFICATIONS`: playback controls, plus reminders the user turns on. The app asks for it when the user
  turns on a reminder.
- `FOREGROUND_SERVICE` and `FOREGROUND_SERVICE_MEDIA_PLAYBACK`: background playback.
- `WAKE_LOCK`: background playback.
- `FOREGROUND_SERVICE_DATA_SYNC`: downloads keep going in the background.
- `RECEIVE_BOOT_COMPLETED`: restores scheduled reminders after a restart.
- `VIBRATE`: reminder notifications.

None of these need a separate declaration except the two foreground service types above.

### Privacy policy
The repository's `privacy-policy.html` has been updated for 2.0.0:
- notification and background-playback permissions
- no storage permission
- listening history kept only on the device
- the list of content providers

**Copy it to `https://nasihun.com/privacy-policy` before sending the release for review.** The live page still
describes the storage permission of 1.x.

### Target audience, content rating and ads
- Target audience and content rating: unchanged.
- Ads: the app still contains **no ads**.

---

## 8. Expected warnings (all safe to ignore)

- *"There is no deobfuscation file associated with this App Bundle."* Upload `mapping.txt` (section 2), or
  ignore it.
- *"This App Bundle contains native code, and you've not uploaded debug symbols."* This is safe to ignore.
- *"Permissions removed: READ_MEDIA_AUDIO…"* This is expected (section 7).

## 9. Troubleshooting

| Error | Fix |
|---|---|
| "Version code 6 has already been used" | In `pubspec.yaml`, change `version: 2.1.0+6` to `+7`. Rebuild with `flutter build appbundle --release` and upload again. |
| "Your Android App Bundle is signed with the wrong key" | The bundle must be signed with the `oneverse` key (SHA-256 in section 1). Make sure `android/key.properties` exists and points to `OneVerseKey.jks`. When it does, the build log shows `✔ Using release keystore`. |
| "signed in debug mode" | `android/key.properties` is missing, so the build fell back to debug signing. Restore it and rebuild. |
| "You must complete the foreground service declaration" | Do the first part of section 7. |
| Build error `Failed to find target with hash string 'android-36'` | In Android Studio, open **SDK Manager** and install **Android SDK Platform 36**. Then rebuild. |

## 10. How to build (on the Mac)

```bash
cd /Users/Data/Development/flutter/One-Verse
git checkout main && git pull origin main
flutter clean && flutter pub get
flutter test test/unit_test.dart        # must print "All tests passed!"
flutter build appbundle --release       # log must show "✔ Using release keystore"
flutter build apk --release             # optional: signed APK for testing on a phone
```

Signing setup:
- `android/key.properties` contains:
  - `storePassword` and `keyPassword`
  - `keyAlias=oneverse`
  - `storeFile=` the path to `OneVerseKey.jks`
- `key.properties` and `*.jks` are git-ignored. **Never commit or share them.**
- Keep a backup of `OneVerseKey.jks` and its passwords somewhere safe.

Check the signature before uploading:
```bash
keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab | grep SHA256
```
It must match the upload certificate SHA-256 in section 1.

---

## 11. Changelog for this version (technical)

### 2.1.0 (build 6)

**Tafseer**
- Per-ayah commentary from Quran.com (`/qdc/tafsirs/{id}/by_ayah`), cached for offline reading like the rest of
  the text.
- Nine books:
  - Urdu: Ibn Kathir, Bayan ul Quran, Tazkir ul Quran, Fi Zilal al-Quran
  - English: Ibn Kathir (Abridged), Ma'arif al-Qur'an, Tazkirul Quran
  - Arabic: Muyassar, Al-Sa'di
- The first book follows the translation's language; the reader's choice is remembered.
- Commentary that covers a group of ayahs says so, and the next arrow moves past the group.

**Bookmarks and notes**
- Bookmark any ayah from the reader, Focus view or Now Playing, with an optional note.
- Bookmarks screen (from Library) and a Bookmarks row on Home.

**Memorise mode**
- Loops ayahs A–B of the playing surah 3, 5, 7, 10, 20 times or until stopped, with an optional 3–10 s pause
  between rounds.
- Works with full-surah files and ayah-by-ayah audio; the per-ayah repeat still applies inside the loop.
- It stops after the last round, and a banner in Now Playing shows the round.

**Other**
- The sleep timer fades out over its last 12 seconds.
- Now Playing's "More" section is now a grid: Memorise, Tafseer, Bookmark, Sleep timer, Download, Share, Focus and
  Go to ayah.
- Fixed chips stretching to the full width in wrapped rows (translation chips in Now Playing).

### 2.0.0 (build 5)

Rebuilt from scratch on a new design: a dark emerald and gold theme, plus a light theme.

**Screens**
- Home, Surahs, Reader, Focus view, Now Playing, Progress, Library and About.
- Bottom navigation and a mini player.

**Text**
- Quran.com word-by-word data in five scripts, each paired with the font it was encoded for:
  - `text_qpc_hafs` + UthmanicHafs
  - `text_indopak` + IndoPak Nastaleeq
  - `text_uthmani_tajweed` + Amiri Quran with rule colours
  - `text_uthmani` + Amiri Quran
  - `text_imlaei` + Scheherazade New
- This fixes broken marks on Android, and the ayah-number ornament no longer spills out of its circle.

**Word timing and playback**
- Word timings come from Quran.com (QDC) and two GitHub timing projects, for 16 reciters.
- Exact word highlighting, and the reader scrolls along with the recitation.
- Playback runs on `just_audio` + `audio_service`:
  - background playback, with notification and lock-screen controls (repeat, previous, play/pause, next, stop)
  - Arabic + translation audio mode
  - repeat 1×/3×/∞, speed 0.75–1.5×, sleep timer
- The session (surah, ayah, position and settings) survives the app being closed.

**Offline**
- The whole Quran text in all scripts, the chosen translation, and timings for the chosen reciter are cached
  for 30 days.
- On Wi-Fi, anything older than 3 days is refreshed in the background.
- Surah recitations can be downloaded to private storage, one surah at a time or the complete Quran in one go.
  Downloads go through the system downloader (`background_downloader`), six files and three surahs at a time,
  and keep running in the background as a foreground service:
  - the size is shown before starting (exact for Quran.com recitations, measured for the others)
  - pause, resume and cancel; Wi-Fi only by default, with an option to use mobile data
  - it carries on after the app is closed, retries failed surahs, and shows progress in a notification

**Reciters and favourites**
- 51 reciters. 26 of them stream full surahs from mp3quran.net:
  - 22 with published ayah timings, so the reader follows the ayah
  - 4 with ayahs estimated from the text length
- Favourite surahs and reciters: hearts in the reader, the player and the reciter picker; a Favourites filter;
  and a section on Home.
- A downloaded surah plays with the reciter it was saved with. Offline, the app switches to a saved reciter
  by itself.
- Streams that stop are reloaded at the same place, and playback resumes when the connection returns.
- Large playback buffers, and a pause when headphones are unplugged.
- The next surah starts by itself, and the reader turns to it.
- Surah search accepts common spellings: Kausar, Rehman, Yaseen, Zariyat.

**Habits**
- Listening log with day, week, month and year charts, our own streak algorithm (60 s/day), a goal ring and a
  calendar heatmap.
- Reminders via `flutter_local_notifications`:
  - daily goal and an evening nudge
  - Al-Kahf on Fridays, Al-Mulk at night
  - Hijri special days: Ramadan, the last ten nights, Arafah, both Eids, Ashura
- Reciter photos and bios come from QuranHub.

**Removed**
- Storage permissions, `permission_handler` and `device_info_plus`.

**Tests**
- 19 unit tests, plus 6 tests for the complete-Quran download and 3 widget tests for the Library screen.
- Live API tests: every script, translations, audio for all reciters, timings for all 16 synced reciters,
  photos.
- A Playwright walkthrough of every screen (`tool/web_e2e.js`).
