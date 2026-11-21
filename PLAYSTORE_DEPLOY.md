# One Verse v2.3.0 (build 8): Play Store deployment guide

This file is a set of instructions for an AI agent (or a person) publishing this update to Google Play.
Follow the steps in order. Do not change the build files or upload a different file.

Version 2.3 adds the Today card and daily recommendations, a richer Focus view, a one-line player, the share
studio with twelve designs, playlists with ready templates, and an offline library sorted by surah and reciter.
The listing text, all screenshots (English and Urdu), both feature graphics and a new promo video change with it.
One declaration is needed if it was not done for 2.2 (foreground service, section 7).

---

## 1. Release facts

| Item | Value |
|---|---|
| App name (on device) | One Verse |
| Package name | `com.nasihun.oneverse` |
| Version name | `2.3.0` |
| Version code | `8` (higher than any earlier upload: 4 to 7) |
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
| Phone screenshots, English (1080×1920) | `store/playstore/screenshots/en/01-overview.png` … `08-urdu.png` | Yes, in this order (section 6) |
| Phone screenshots, Urdu (1080×1920) | `store/playstore/screenshots/ur/01-overview.png` … `08-urdu.png` | Yes, on the Urdu listing (section 5) |
| Extra screenshots | `screenshots/en/09-reciters.png`, `10-moments.png` (and the same in `ur/`) | Optional (tablet slots) |
| Feature graphic (1024×500) | `store/playstore/feature-graphic.png` (English), `feature-graphic-ur.png` (Urdu) | Yes |
| Promo video | `store/video/one-verse-promo.mp4` → upload to YouTube, paste the link | Yes (section 6) |
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
   - Wait until it shows **Version 8 (2.3.0)** with no errors.
7. **Release name:** `2.3.0 (8) – Smarter suggestions, Focus controls, library by reciter`
8. **Release notes:** paste the text from section 4. Add both `en-US` and `ur` if the Urdu listing exists.
9. Click **Next**. Read the warnings screen (section 8), then click **Save**.
10. Update the store listing (section 5) and the graphics (section 6), then add the Urdu translation of the
    listing (section 5) with its own screenshots and feature graphic.
11. Go to **Publishing overview** and click **Send changes for review**.
12. Recommended: a **staged rollout** of 20%, increased after 1–2 days with no crash reports in **Android vitals**.

Listing changes are reviewed together with the release.

---

## 4. Release notes ("What's new", maximum 500 characters each)

### en-US (495 characters)
```
One Verse 2.3
• Smarter suggestions for every moment: morning, night, Friday, Ramadan and the Hijri months, plus surahs to discover
• Today card: minutes, daily goal and streak at a glance
• Focus view: change reciter, translation and surah, pick any ayah from a list, share
• Pick any ayah by typing its number
• Library by surah or by reciter; reciters you saved and listen to most come first
• Playlists: repeat, shuffle, duplicate, add from any surah
• Eight new card backgrounds for sharing
```

### ur (Urdu, 420 characters)
```
ون ورس 2.3
• ہر وقت کے لیے بہتر تجاویز: صبح، رات، جمعہ، رمضان اور ہجری مہینے، اور نئی سورتیں
• آج کا کارڈ: منٹ، روزانہ ہدف اور اسٹریک ایک نظر میں
• فوکس ویو: قاری، ترجمہ اور سورت بدلیں، فہرست سے کوئی بھی آیت چنیں، شیئر کریں
• آیت نمبر لکھ کر سیدھا اس آیت پر جائیں
• لائبریری سورت یا قاری کے لحاظ سے؛ محفوظ اور زیادہ سنے گئے قاری اوپر
• پلے لسٹ: دہرائیں، شفل، کاپی، کسی بھی سورت سے شامل کریں
• شیئر کے لیے آٹھ نئے پس منظر
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
80 characters:
```
Quran audio, word-by-word highlight, tafseer, playlists and share. Free, no ads.
```

### Full description (maximum 4000 characters)
3839 characters:
```
One Verse – Hear the Quran. See every word.

A calm, beautiful Quran app for listening, reading and understanding, one ayah at a time. Free forever: no ads, no subscriptions, no sign-up.

✨ WORD-BY-WORD HIGHLIGHT
• Every word lights up exactly as the reciter says it
• Word-exact timing for 16 reciters, including Mishary Alafasy, Sudais and Maher Al-Muaiqly
• The page follows the recitation by itself, so you never lose your place

🌅 A VERSE FOR TODAY
• Each day One Verse picks a verse for you and the right surahs for the moment: Al-Kahf on Friday, Al-Mulk at night, morning and evening passages, and the special days of the Islamic year
• A Today card with your minutes, goal ring and streak

📖 5 QURAN SCRIPTS, EACH IN ITS OWN FONT
• Madani (KFGQPC Hafs), IndoPak Nastaleeq, Tajweed colours, Uthmani and Simple
• Every mark sits in the right place, so the text reads correctly on Android

🎧 50+ RECITERS
• Mishary Alafasy, Sudais, Shuraim, Maher Al-Muaiqly, Yasser Al-Dosari, Saad Al-Ghamdi, Khalid Al-Jaleel, Idrees Abkar, Husary, Minshawi, Abdul Basit and many more
• The reciters you listen to most rise to the top, and downloaded reciters are marked with a tick
• Pick the ayah to start from by typing its number or choosing it from the list

🌍 UNDERSTAND EVERY AYAH
• 100+ translations in 40+ languages: Urdu, English, Hindi, Bengali, Indonesian, Turkish, French, Persian and more
• Urdu in beautiful Nastaliq
• Hear the translation audio after each ayah, or the translation alone (English, Urdu and more)

📚 TAFSEER, BOOKMARKS AND NOTES
• Ibn Kathir, Bayan ul Quran (Dr. Israr Ahmad), Tazkir ul Quran and Fi Zilal al-Quran in Urdu; Ibn Kathir, Ma'arif al-Qur'an and Tazkirul Quran in English; Muyassar and Al-Sa'di in Arabic
• Bookmark ayahs with your own notes and reflections

🕌 FOCUS VIEW
• One ayah, full screen, with its meaning below
• Reciter, translation, what you hear, ayah list, tafseer, bookmark and share in one row of buttons
• Move to the next or previous surah without leaving

▶️ A PLAYER MADE FOR THE QURAN
• Change reciter, translation or what you hear with one tap
• Repeat, speed, and a sleep timer that fades out gently
• Plays in the background, with lock-screen and notification controls

📤 SHARE STUDIO
• Share any ayah, passage or surah as an image, a video with the recitation, or an audio file
• Twelve card designs, including sand, gold and night
• Story or square size, with or without translation, or the translation audio alone
• Send to WhatsApp and status, or save to your phone

🎶 PLAYLISTS
• Ready lists to start from: Morning, Before sleep, Friday and Protection
• Your surahs and passages in your order, with your reciter
• Repeat, shuffle and duplicate
• A reminder on the days and time you choose
• Download a whole playlist to listen offline

🧠 MEMORISE (HIFZ) MODE
• Loop a range of ayahs 3, 5, 10 or 20 times, with a pause to recite from memory

🔥 BUILD A DAILY HABIT
• Minutes today, this week, month and year, a daily goal and a listening streak
• Gentle reminders: daily goal, Al-Kahf on Fridays, Al-Mulk before sleep, Ramadan, Arafah and Eid

📶 OFFLINE LIBRARY
• Download the complete Quran with one tap, or any surah, in the background
• See your downloads by surah or by reciter, and check the files with one tap
• The text, translation and timings stay on your phone, ready without internet

⏯️ CONTINUE WHERE YOU LEFT OFF
• One Verse opens on the same ayah, with the same reciter and settings

🔒 PRIVATE BY DESIGN
No account, no ads, no tracking. Your listening history stays on your phone.

Quran text and word timings: Quran.com (Quran Foundation). Fonts: King Fahd Glorious Quran Printing Complex. Translations and audio: AlQuran Cloud, Quranic Audio and mp3quran. Full credits are in the app's About screen.

Made by Nasihun – nasihun.com. Please remember us in your duas.
```

### Urdu listing (Store presence → Main store listing → Manage translations → add Urdu)
Add Urdu (`ur`) as a translation of the listing, paste the text below, and upload the Urdu screenshots
(`store/playstore/screenshots/ur/`) and `feature-graphic-ur.png` in that language's Graphics section. People
whose phone is set to Urdu then see the Urdu listing.

App name (23 characters):
```
ون ورس: قرآن لفظ بہ لفظ
```
Short description (80 characters):
```
قرآن کی تلاوت لفظ بہ لفظ، اردو ترجمہ، تفسیر، پلے لسٹس اور شیئر۔ مفت، بغیر اشتہار
```
Full description (1625 characters):
```
ون ورس – قرآن سنیں، ہر لفظ ساتھ دیکھیں۔

قرآن سننے، پڑھنے اور سمجھنے کے لیے ایک پُرسکون اور خوبصورت ایپ۔ ہمیشہ مفت: کوئی اشتہار نہیں، کوئی سبسکرپشن نہیں، کوئی سائن اپ نہیں۔

✨ لفظ بہ لفظ ہائی لائٹ
• قاری جو لفظ پڑھے، وہی لفظ روشن ہوتا ہے
• صفحہ خود تلاوت کے ساتھ چلتا ہے، آپ کبھی جگہ نہیں بھولیں گے

🌅 آج کی آیت
• ہر دن آپ کے لیے ایک آیت، اور اس وقت کے لیے مناسب سورتیں: جمعہ کو سورۃ الکہف، رات کو سورۃ الملک، صبح و شام کی آیات اور اسلامی سال کے خاص دن

📖 مصحف کے 5 خط
• عثمانی (مدنی)، انڈوپاک نستعلیق، تجوید کے رنگ، اور مزید
• اردو ترجمہ خوبصورت نستعلیق میں

🎧 50 سے زیادہ قاری
• مشاری العفاسی، السدیس، الشریم، ماہر المعیقلی، سعد الغامدی، عبدالباسط اور بہت سے
• جنہیں آپ زیادہ سنیں وہ اوپر، اور ڈاؤن لوڈ شدہ قاری پر سبز نشان

🌍 ہر آیت سمجھیں
• 40 سے زیادہ زبانوں میں 100 سے زیادہ ترجمے
• ہر آیت کے بعد اردو ترجمے کی آواز، یا صرف ترجمہ

📚 تفسیر، بُک مارک اور نوٹس
• تفسیر ابن کثیر، بیان القرآن (ڈاکٹر اسرار احمد)، تذکیر القرآن، فی ظلال القرآن اور مزید
• آیات محفوظ کریں اور اپنے نوٹس لکھیں

📤 شیئر اسٹوڈیو
• کوئی بھی آیت تصویر، تلاوت والی ویڈیو یا آڈیو کی شکل میں
• بارہ خوبصورت ڈیزائن، واٹس ایپ اور اسٹیٹس کے لیے

🎶 پلے لسٹس
• صبح، سونے سے پہلے، جمعہ اور حفاظت کی تیار فہرستیں
• اپنی ترتیب، اپنا قاری، منتخب دنوں پر یاد دہانی
• پوری پلے لسٹ ایک بار میں ڈاؤن لوڈ کریں

🧠 حفظ موڈ
• چند آیات 3، 5، 10 یا 20 بار دہرائیں، درمیان میں وقفے کے ساتھ

🔥 روزانہ کی عادت
• روزانہ ہدف، سلسلہ (اسٹریک) اور نرم یاد دہانیاں

📶 بغیر انٹرنیٹ
• پورا قرآن ایک ٹیپ میں ڈاؤن لوڈ کریں، قاری اور سورت کے حساب سے ترتیب

🔒 مکمل پرائیویسی
کوئی اکاؤنٹ نہیں، کوئی اشتہار نہیں، کوئی ٹریکنگ نہیں۔

نصیحون کی طرف سے – nasihun.com۔ اپنی دعاؤں میں یاد رکھیں۔
```

### Category and tags
- Category: **Books & Reference** (keep the current one if it is different).
- Tags (pick up to 5): Religion & spirituality, Audiobooks, Education, Books, Reference.

---

## 6. Graphics (Main store listing → Graphics)

Play allows **up to 8 phone screenshots**. Upload them in this order (English listing from
`store/playstore/screenshots/en/`, Urdu listing from `store/playstore/screenshots/ur/`; the file names match):

| # | File | Shows |
|---|---|---|
| 1 | `01-overview.png` | One Verse and its main features |
| 2 | `02-word.png` | Word-by-word highlight in the reader |
| 3 | `03-share.png` | Share studio: image, video or audio in twelve designs |
| 4 | `04-player.png` | The new player with the one-line deck |
| 5 | `05-tafseer.png` | Tafseer of any ayah |
| 6 | `06-playlists.png` | Playlists with templates, reminders and offline download |
| 7 | `07-scripts.png` | 5 Quran scripts and tajweed colours |
| 8 | `08-urdu.png` | IndoPak text with Urdu translation |

Optional:
- `09-reciters.png` (50+ reciters) and `10-moments.png` (Today card and suggestions).
  - They can go in the **7-inch tablet** and **10-inch tablet** screenshot slots, or replace 7 and 8 above.
- **Feature graphic:** `store/playstore/feature-graphic.png` (English) and `feature-graphic-ur.png` (Urdu), 1024×500.
- **App icon:** unchanged.
- **Promo video:** Play takes only a YouTube link. Upload `store/video/one-verse-promo.mp4` (55 s, 1920×1080) to
  YouTube as public or unlisted, with ads turned off, and paste the link in **Video**.

All images are PNG without transparency, at the sizes Play requires. To regenerate them, see
`store/playstore/README.md`.

### For social media (not for Play)
- `store/video/one-verse-teaser-en.mp4` and `one-verse-teaser-ur.mp4`: 19 s, 9:16, for Reels, Shorts, TikTok and
  WhatsApp status.
- `store/social/portrait/` (1080×1350) and `store/social/square/` (1080×1080): three posters each in English,
  Urdu and Arabic. See `store/social/README.md`.

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
| "Version code 8 has already been used" | In `pubspec.yaml`, change `version: 2.3.0+8` to `+9`. Rebuild with `flutter build appbundle --release` and upload again. |
| "Your Android App Bundle is signed with the wrong key" | The bundle must be signed with the `oneverse` key (SHA-256 in section 1). Make sure `android/key.properties` exists and points to `OneVerseKey.jks`. When it does, the build log shows `✔ Using release keystore`. |
| "signed in debug mode" | `android/key.properties` is missing, so the build fell back to debug signing. Restore it and rebuild. |
| "You must complete the foreground service declaration" | Do the first part of section 7. |
| Build error `Failed to find target with hash string 'android-36'` | In Android Studio, open **SDK Manager** and install **Android SDK Platform 36**. Then rebuild. |

## 10. How to build (on the Mac)

Flutter 3.47 or newer is needed (`flutter --version`; run `flutter upgrade` if it is older). The first build
also downloads ffmpeg-kit from Maven Central, so it takes a few minutes longer.

```bash
cd /Users/Data/Development/flutter/One-Verse
git checkout main && git pull origin main
flutter clean && flutter pub get
flutter test test/unit_test.dart        # must print "All tests passed!"
flutter build appbundle --release       # log must show "✔ Using release keystore"
flutter build apk --release --split-per-abi   # optional: signed APKs for testing (arm64 for most phones)
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

### 2.3.0 (build 8): QA round

- **Recommendations** (`lib/data/recommend.dart`): "For this moment" now draws on:
  - special days and the Hijri month (Ramadan, the last ten nights, Eid, the ten days of Dhul Hijjah, Arafah,
    Ashura, the new Hijri year, Rajab, Sha'ban, Rabi' al-Awwal)
  - Friday: Al-Kahf, As-Sajdah and Al-Insan in the morning; Qaf, Al-Jumu'ah and Fussilat later
  - wide lists for morning, afternoon, evening and night, rotating by date
  - one surah to discover that was not heard in the last week
  - no repeats, and passages (Ayat al-Kursi, the end of Al-Baqarah) that stop at their end

  Verse of the day draws from 60 ayahs, with fitting ones on special days.
- **Home:** a Today card with minutes, goal and streak.
- **Focus view:**
  - previous and next surah, and a surah list
  - a strip with the reciter, translation, what you hear, the ayah list, tafseer, bookmark, share and add to
    playlist
- **Ayah picker:** type the number or pick from a list showing each ayah's first words. Used in share, playlists,
  memorise and Go to ayah.
- **Player:** translation and "you hear" on one line; the repeat and speed tiles were removed.
- **Share:**
  - eight more backgrounds
  - the card follows translation changes at once
  - audio can be Arabic, Arabic + translation or translation only
  - no Quran Foundation line in captions
- **Library:**
  - by surah, with every saved reciter, or by reciter
  - a check that forgets incomplete downloads
- **Reciter picker:** reciters saved for the surah come first with a tick, then the most-listened ones.
- **Playlists:** repeat, shuffle, duplicate, and Add to playlist from the reader and Focus view.


### 2.2.0 (build 7)

**Share studio** (the share button on any ayah)
- Image: a 1080 px card, story (9:16) or square, in the reader's script, with the translation, the reference
  and One Verse in a corner; four styles. Long passages scale down to fit.
- Video: one card per ayah over the recitation, with fades; up to 20 ayahs.
- Audio: one .m4a of an ayah, a passage or the whole surah, optionally with the translation audio after each
  ayah. Works with ayah-by-ayah reciters and with full-surah recordings that have ayah timings.
- Text, as before. Every format can be shared to any app; audio, video and images can be saved to the phone.
- Made on the phone with ffmpeg-kit (minimal LGPL build, `ffmpeg_kit_flutter_new_min`). It adds about 16 MB
  per ABI to the APK (Play delivers only the ABI a phone needs).

**Playlists**
- Whole surahs or passages in any order, a chosen reciter, and a reminder on chosen days and time.
- Ready lists: Morning, Before sleep, Friday, Protection.

**Player**
- The cycle buttons and chip rows became a deck of large tiles: reciter, translation, what you hear, repeat
  and speed. Each opens a sheet of large options.
- Jumps far into a full-surah file no longer skip a playlist item.

### 2.1.0 (build 6)

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
