# One Verse: open to-dos

Every suggestion made so far that is not built yet, plus the checks still owed. Numbers stay fixed so items can
be referred to ("do 7 and 12"). Status as of 2026-11-13, version 2.2.0 (7).

Legend: **P1** do before the next wide promotion · **P2** next features · **P3** later.

---

## A. Licences and compliance (P1)

1. **Quran Foundation terms for cached content.** The app reads Quran.com's public API (text in five scripts,
   word timings, tafsir) and keeps it on the phone for 30 days. Quran Foundation's Developer Terms
   (`docs/quran-foundation-api.md`) allow offline copies only through their Content Sync API, refreshed at least
   every 7 days. Either move to Content Sync, which needs a Developer Console account, a client id and a small
   backend for the token, or ask Quran Foundation whether the public API may be cached this way.
2. **Credit Quran Foundation on shared images and videos.** Social videos made from their content are allowed
   only with credit. The share caption now says "Quran data provided by Quran Foundation". The card itself only
   shows One Verse, so add a small credit line to the card (image and video).
3. **QuranHub photos and biographies.** The code licence is non-commercial and the terms for the data and
   photos are not stated. Ask Misraj AI (hello@misraj.ai) for written permission, or replace the photos.
4. **baklarrrr/quran-timings has no licence file.** It supplies the word timings for Yasser Al-Dosari, Maher
   Al-Muaiqly, Nasser Al-Qatami and Islam Sobhi. Ask the author, or drop those timings.
5. **Add a LICENSE file to the repository.** The app is described as open source, but the repository has no
   licence. ffmpeg-kit is LGPL, which is fine with an open-source or closed app as long as it is linked as a
   library, as it is now.
6. **QUL resources:** check the licence tab of each QUL resource before shipping it (see `docs/datasets.md`).

## B. Test on a real phone (P1)

7. Background downloads: one surah, the complete Quran and a playlist; the notification; closing the app while
   a download runs.
8. Notification and lock-screen controls, Bluetooth buttons, and unplugging headphones.
9. Reminders: daily, Friday Al-Kahf, Al-Mulk, special days, and playlist reminders on chosen weekdays; tapping
   one opens the right thing.
10. Share studio: image, video (hardware H.264 first, MPEG-4 as fallback), audio with and without translation,
    Save to phone, and sending to WhatsApp and WhatsApp status.
11. A playlist with Ayat al-Kursi (2:255): the jump deep into Al-Baqarah. It did not land in the cloud browser
    test, and the cause there is still unknown.
12. Reciters without ayah timings (Bader Al-Turki and the others): whole surah only, the explanations, and the
    ±15 s buttons.
13. Arabic + translation audio for Urdu (Shamshad Ali Khan) over a long surah.

## C. Play Store (P1)

14. Play Console: the "Data sync" foreground-service declaration (text in `PLAYSTORE_DEPLOY.md`, section 7).
15. Upload 2.2.0 (7) with the release notes in `PLAYSTORE_DEPLOY.md`.
16. New screenshots: the current ten show 2.0. Add the share studio, playlists and the new player.
17. Upload `store/video/one-verse-promo.mp4` to YouTube and put the link in the listing (Play takes only
    YouTube links).
18. Make a 9:16 cut of the promo video for Reels, Shorts and WhatsApp status, and an Urdu voice-over version.

## D. Features (P2)

19. **Mood and topic ayahs.** Topics from QUL Ayah Topics (Jannah, the grave, the Last Day, travel, night,
    mountains, rain, death, patience…). Moods (sad, anxious, lonely, grateful, angry, hopeful) from a short
    hand-made list of well-known ayahs, checked by a scholar before release. Waiting for your decision; see
    `docs/datasets.md`.
20. **Word-by-word meaning:** tap a word to see its Urdu or English meaning (QUL has 22 word-by-word
    translations; Quran.com also has word translations).
21. **Khatam tracker:** progress through the whole Quran, and a 30-day Ramadan plan.
22. **Android home-screen widgets:** "Continue listening" and "Ayah of the day".
23. **Android Auto and car screens:** a browsable media tree in `audio_service`.
24. **Accounts and cloud backup (opt-in):** favourites, bookmarks, playlists and streak. Quran Foundation's User
    APIs (Quran ID, activity days with an `AUDIO` type) fit this.
25. **Prayer-time reminders:** "after Fajr" or "after Isha" instead of a clock time; needs the city or location.
26. **Surah introduction:** when and where it was revealed, and its themes, before the first ayah (QUL Surah
    information, including Urdu).
27. **Passage headings:** QUL Ayah theme summaries above groups of ayahs in the reader.
28. **Mutashabihat in memorise mode:** mark phrases that repeat elsewhere, so they are not mixed up (QUL).
29. **Similar ayahs** link in the tafseer sheet (QUL).
30. **Short passages from ayah files:** for a passage deep in a long surah (Ayat al-Kursi), play and download
    only those ayah files instead of the whole surah (Al-Baqarah is about 116 MB). Word highlighting would then
    be estimated for that passage.
31. **Show the size before a playlist download**, and download only the ayahs a passage needs (with 30).
32. **Tafseer offline:** download a whole tafseer book at once.
33. **Video sharing:** word-by-word highlight inside the video, more card designs, and more than 20 ayahs.
34. **Ayah timings for the four untimed reciters** (Bader Al-Turki, Yasser Al-Qurashi, Al-Muhaisany, Hatem
    Farid): QUL has 131 timed (segmented) recitations, among them a Hatem Farid Taraweeh recording. Timings
    only work with the exact same audio file, so check that it matches the mp3quran recording first.

## E. Reciters and voices (P3)

35. Noreen Muhammad Siddiq (ad-Duri reading), only with a clear "Duri" label.
36. Hazza Al-Balushi and Salman Al-Utaybi, when their recordings cover all 114 surahs.
37. Omar Hisham Al-Arabi: not on mp3quran, QuranicAudio or QuranHub; look for another source.
38. Translation audio for more languages (Hindi, Bengali and Indonesian, among others, are text only today).

## F. App and code (P3)

39. **Logo:** concepts A (Ayah Seal, recommended), B (Verse Wave) and C (Play Star) are in
    `store/logo-concepts/`. On hold at your request.
40. **Web icons** (`web/icons/`) are still the Flutter default; replace them with the One Verse icon.
41. **APK size:** ffmpeg-kit adds about 16 MB per ABI (arm64 24 → 40 MB). It could move to an on-demand Play
    Feature Delivery module that downloads the first time someone shares audio or video.
42. **iOS:** build and test on an iPhone (background audio, notifications, file sharing).
43. **Remote Control on the Mac** (Claude app → Settings → Claude Code → Remote Control → add the One-Verse
    folder), so that builds with the real signing key can run from a cloud session.
