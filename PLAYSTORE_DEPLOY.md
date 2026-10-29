# OneVerse v1.1.0 (build 4): Play Store deployment guide

This file is a set of instructions for an AI agent (or a person) publishing this update to Google Play.
Follow the steps in order. Do not change the build files or upload a different file.

---

## 1. Release facts

| Item | Value |
|---|---|
| App name (on device) | One Verse |
| Package name | `com.nasihun.oneverse` |
| Version name | `1.1.0` |
| Version code | `4` (previous release: `3`) |
| Target SDK / Compile SDK | 36 (Android 16) |
| Min SDK | 24 (Android 7.0). **Changed:** older builds supported lower versions |
| Signing key alias | `oneverse` |
| Upload certificate SHA-256 | `47:41:EF:75:41:49:1C:2E:6C:C1:1D:E1:E5:4D:29:F6:9A:05:8D:01:53:C0:4F:45:25:82:93:03:EC:19:D1:F9` |
| Developer account | Nasihun (`https://play.google.com/store/apps/dev?id=8907093897824220429`) |
| Privacy policy | `https://nasihun.com/privacy-policy` |
| Support email | `thenasihun@gmail.com` |

## 2. Files to upload

All paths are relative to the project root `/Users/Data/Development/flutter/One-Verse`.

| Purpose | File | Upload? |
|---|---|---|
| **App bundle (upload this to Play)** | `build/app/outputs/bundle/release/app-release.aab` | **Yes** |
| R8 deobfuscation mapping | `build/app/outputs/mapping/release/mapping.txt` | Yes (App bundle explorer → Downloads → ReTrace mapping file) |
| Signed APK (for testing or sideloading only) | `build/app/outputs/flutter-apk/app-release.apk` | No. Play only accepts the `.aab` |

Both files are signed with the release keystore, and the signature has been verified.

---

## 3. Step by step in Google Play Console

1. Open https://play.google.com/console and sign in with the Nasihun developer account.
2. Select the app **One Verse** (`com.nasihun.oneverse`).
3. In the left menu, go to **Test and release → Production**. A **Closed testing** track also works if you want to test first.
4. Click **Create new release**.
5. Under **App bundles**, click **Upload** and choose `build/app/outputs/bundle/release/app-release.aab`.
   - Wait until it shows **Version 4 (1.1.0)** with no errors.
6. **Release name:** `1.1.0 (4) – Offline surah download & verse-by-verse translation audio`
7. **Release notes:** paste the text from section 4 below. Add both `en-US` and `ur` if the Urdu listing exists.
8. Click **Next**. Read the warnings screen (see section 7 for expected warnings), then click **Save**.
9. Go to **Publishing overview** and click **Send changes for review**.
10. Optional: choose a **staged rollout** (for example 20%) and increase it after 1–2 days with no crash reports.

After saving, update the store listing (section 5) and check the declarations (section 6).
Listing changes are reviewed together with the release.

---

## 4. Release notes ("What's new", maximum 500 characters each)

### en-US
```
What's new in 1.1.0
• Download complete Surahs for offline listening – tap the download button in the Player (or long-press for one-tap download)
• Verse-by-verse: hear each Arabic verse followed by its translation audio (Urdu, English, French & more)
• Choose your Arabic reciter, translation reciter & playback mode
• No internet? The app shows which Surahs you can play offline
• New Offline Downloads screen to play or delete downloads
• Faster loading & bug fixes
```

### ur (Urdu)
```
نیا کیا ہے – ورژن 1.1.0
• مکمل سورت آف لائن سننے کے لیے ڈاؤن لوڈ کریں – پلیئر میں ڈاؤن لوڈ بٹن دبائیں (یا لانگ پریس کریں)
• آیت بہ آیت: ہر عربی آیت کے بعد اس کا ترجمہ آڈیو (اردو، انگریزی وغیرہ)
• عربی قاری، ترجمہ قاری اور پلے بیک موڈ خود منتخب کریں
• انٹرنیٹ نہیں؟ ایپ بتائے گی کون سی سورتیں آف لائن دستیاب ہیں
• نئی آف لائن ڈاؤن لوڈز اسکرین
• تیز رفتار لوڈنگ اور بہتریاں
```

---

## 5. Store listing update (Grow users → Store presence → Main store listing)

### App name (maximum 30 characters)
Recommended (29 characters):
```
OneVerse: Quran Audio Offline
```
Alternative if you want to keep the current name: `One Verse - Al Quran MP3 Audio`

### Short description (maximum 80 characters)
```
Quran verse by verse with translation audio. Download Surahs & listen offline.
```

### Full description (maximum 4000 characters)
```
OneVerse – Listen to the Holy Quran, one verse at a time.

Connect with the Quran wherever you are. OneVerse plays the Quran verse by verse with beautiful recitations, translation audio and text — and now works completely offline.

★ NEW: OFFLINE SURAH DOWNLOAD
• Download a complete Surah with one tap (long-press the download button in the Player)
• Everything you need is saved: Arabic recitation, translation recitation, Arabic text and translation text
• No internet? OneVerse shows which Surahs are available offline – tap and play
• Manage downloads: see size, play or delete from the Offline Downloads screen

★ NEW: VERSE-BY-VERSE WITH TRANSLATION AUDIO
• Hear each Arabic verse followed by its translation audio
• Translation recitations in Urdu, English, French, Persian, Turkish, Russian, Chinese and more
• Three playback modes: Arabic only, Arabic + Translation, Translation only
• Repeat a verse (Arabic + translation together) to memorise and reflect

🎧 BEAUTIFUL RECITATION
• Famous reciters including Mishary Alafasy, Abdul Rahman Al-Sudais, Saud Al-Shuraim and more
• Smooth, continuous playback through the whole Surah
• Previous / next verse, jump to any Surah or Ayah

📖 READ AND UNDERSTAND
• Authentic Uthmani script (KFGQPC Hafs font) and other Arabic fonts
• 100+ text translations in 40+ languages including Urdu, English, Hindi, Bengali, Indonesian, Turkish
• Split view, Arabic only or translation only

💾 SAVE AND SHARE SINGLE VERSES
• Save any verse as an MP3 to Music/OneVerse (Language › Reciter › Surah › Ayah)
• Share a verse as text or audio – perfect for content creators

🎨 MADE FOR YOU
• Dark mode (Emerald & Gold) and light mode
• Adjustable Arabic and translation font size and style
• Free, no sign-up

Made with love by Nasihun – nasihun.com
```

### Screenshots (recommended, optional)
Add 2–3 new phone screenshots (1080×2400) showing:
1. The Player with the **Arabic · Reciter → Translation · Reciter** chips (verse-by-verse mode)
2. The **Download** sheet ("This Verse" / "Complete Surah (offline)")
3. The **"You're Offline"** screen listing downloaded Surahs, or the **Offline Downloads** screen

---

## 6. Declarations to check (Policy and programs → App content)

- **Data safety:** no change is needed. The app has no login, analytics or ads, and does not collect personal data.
  - It downloads Quran text and audio from `api.alquran.cloud` and `cdn.islamic.network`. These are public content downloads; no user data is sent.
  - Downloads are stored on the device only.
- **Permissions:** the app requests **"Music and audio" (READ_MEDIA_AUDIO)** on Android 13+, only when the user saves a single verse to the Music folder.
  - Storage permissions are now limited (`WRITE_EXTERNAL_STORAGE` up to Android 9, `READ_EXTERNAL_STORAGE` up to Android 12).
  - No new sensitive permissions were added.
- **Target audience, content rating and ads:** unchanged. If Play asks, the app still contains **no ads**.

---

## 7. Expected warnings (all safe to ignore)

- *"This release will not be available to users on API levels 21–23"* (or similar device-loss warning).
  - Cause: min SDK is now 24 because of the Flutter upgrade. Those devices keep the old version.
- *"There is no deobfuscation file associated with this App Bundle."*
  - Fix: upload `build/app/outputs/mapping/release/mapping.txt`, or ignore it.
- *"This App Bundle contains native code, and you've not uploaded debug symbols."* This is safe to ignore.

## 8. Troubleshooting

| Error | Fix |
|---|---|
| "Version code 4 has already been used" | In `pubspec.yaml`, change `version: 1.1.0+4` to `+5` (or the next unused number). Then run `flutter build appbundle --release` and upload again. |
| "Your Android App Bundle is signed with the wrong key" | The bundle must be signed with the `oneverse` key (SHA-256 shown in section 1). Make sure `android/key.properties` exists and points to `OneVerseKey.jks`. When it does, the build log shows `✔ Using release keystore`. |
| "signed in debug mode" | `android/key.properties` is missing, so the build fell back to debug signing. Restore it and rebuild. |

## 9. How to rebuild (if needed)

```bash
cd /Users/Data/Development/flutter/One-Verse
flutter clean && flutter pub get
flutter test                          # must print "All tests passed!"
flutter build appbundle --release     # log must show "✔ Using release keystore"
```

Signing setup:
- `android/key.properties` contains the passwords, alias `oneverse` and the path to `OneVerseKey.jks`.
- `key.properties` and `*.jks` are git-ignored. **Never commit or share them.**
- Keep a backup of `OneVerseKey.jks` and its passwords somewhere safe. Losing the upload key means asking Google for an upload key reset.

---

## 10. Changelog for this version (technical)

- Complete-surah offline download. Files download 4 at a time, with retry, progress, cancel and a mirror fallback.
- New Offline Downloads screen.
- Verse-by-verse Arabic → translation audio playlist, with a repeat-verse mode that repeats both parts.
- Settings: Arabic reciter, translation audio reciter, playback mode, offline downloads.
- Offline-first loading:
  - The surah list is bundled with the app.
  - Editions and surah text are cached.
  - An offline screen lists the surahs that can be played.
- Single-verse save to `Music/OneVerse` now works on Android 11+ without the storage permission.
- Build tooling: Gradle 8.14.3 and AGP 8.13.1. Packages updated: `fluttertoast` 10, `font_awesome_flutter` 11, `google_fonts` 6.3.3.
