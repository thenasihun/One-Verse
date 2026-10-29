# One Verse v2.0.0 (build 5): Play Store deployment guide

This file is a set of instructions for an AI agent (or a person) publishing this update to Google Play.
Follow the steps in order. Do not change the build files or upload a different file.

Version 2.0.0 is a complete rebuild of the app with a new design. The listing text, screenshots and feature
graphic all change with it, and one new declaration is needed (foreground service, section 7).

---

## 1. Release facts

| Item | Value |
|---|---|
| App name (on device) | One Verse |
| Package name | `com.nasihun.oneverse` |
| Version name | `2.0.0` |
| Version code | `5` (previous release: `4`, version 1.1.0) |
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
   - Wait until it shows **Version 5 (2.0.0)** with no errors.
7. **Release name:** `2.0.0 (5) – All-new One Verse: word-by-word highlight, 5 scripts, offline`
8. **Release notes:** paste the text from section 4. Add both `en-US` and `ur` if the Urdu listing exists.
9. Click **Next**. Read the warnings screen (section 8), then click **Save**.
10. Update the store listing (section 5) and the graphics (section 6).
11. Go to **Publishing overview** and click **Send changes for review**.
12. Recommended: a **staged rollout** of 20%, increased after 1–2 days with no crash reports in **Android vitals**.

Listing changes are reviewed together with the release.

---

## 4. Release notes ("What's new", maximum 500 characters each)

### en-US (431 characters)
```
One Verse 2.0 – all new
• Word-by-word highlight: every word lights up as it's recited
• 5 Quran scripts: Madani, IndoPak, Tajweed colours, Uthmani, Simple
• 25 reciters with photos; Urdu & 40+ translations in one tap
• New player: repeat ayah, speed, sleep timer, lock-screen controls
• Focus view, streaks, listening stats and gentle reminders
• Works offline for 30 days and syncs on Wi-Fi
• Continues exactly where you left off
```

### ur (Urdu, 419 characters)
```
ون ورس 2.0 – بالکل نئی ایپ
• لفظ بہ لفظ ہائی لائٹ: تلاوت کے ساتھ ہر لفظ روشن ہوتا ہے
• قرآن کے 5 رسم الخط: مدنی، انڈو پاک، تجوید رنگوں کے ساتھ، عثمانی، سادہ
• تصاویر کے ساتھ 25 قاری، اردو اور 40 سے زائد ترجمے ایک ٹیپ پر
• نیا پلیئر: آیت دہرائیں، رفتار، سلیپ ٹائمر، لاک اسکرین کنٹرول
• فوکس ویو، اسٹریک، سننے کے اعداد و شمار اور یاددہانیاں
• 30 دن تک بغیر انٹرنیٹ، وائی فائی پر خودکار اپڈیٹ
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
2957 characters:
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

🎧 25 RECITERS, WITH THEIR PHOTOS
• Mishary Alafasy, Sudais, Shuraim, Maher Al-Muaiqly, Yasser Al-Dosari, Husary, Minshawi, Abdul Basit, Nasser Al-Qatami and more
• Short biographies, Murattal, Mujawwad and teaching styles

🌍 UNDERSTAND EVERY AYAH
• 100+ translations in 40+ languages: Urdu, English, Hindi, Bengali, Indonesian, Turkish, French, Persian and more
• Urdu shown in beautiful Nastaliq
• Hear the translation audio after each Arabic ayah (English, Urdu, French, Russian, Persian, Chinese, Uzbek)
• Switch translation with one tap

▶️ A PLAYER MADE FOR THE QURAN
• Repeat an ayah 1×, 3× or forever – ideal for memorising
• Speed from 0.75× to 1.5× and a sleep timer
• Keeps playing in the background, with controls in the notification and on the lock screen
• Arabic only, Arabic + translation, or translation only

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
• Download any surah's recitation to listen offline

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
| 6 | `06-reciters.png` | 25 reciters with photos |
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
- `RECEIVE_BOOT_COMPLETED`: restores scheduled reminders after a restart.
- `VIBRATE`: reminder notifications.

None of these need a separate declaration except the foreground service above.

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
| "Version code 5 has already been used" | In `pubspec.yaml`, change `version: 2.0.0+5` to `+6`. Rebuild with `flutter build appbundle --release` and upload again. |
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
- Surah recitations can be downloaded to private storage.

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
- 19 unit tests.
- Live API tests: every script, translations, audio for all reciters, timings for all 16 synced reciters,
  photos.
- A Playwright walkthrough of every screen (`tool/web_e2e.js`).
