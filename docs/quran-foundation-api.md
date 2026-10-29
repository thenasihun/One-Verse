# Quran Foundation API (Quran.com)

Read in full on 2026-10-29 from <https://api-docs.quran.foundation> (342 pages, plus the OpenAPI files
`openAPI/content/v4.json` and `openAPI/user-related-apis/v1.json`). Docs are also mirrored at
`api-docs.quran.com`.

## 1. The rules that shape One Verse (Developer Terms, updated 2026-10-11)

These decide the architecture, so read them first.

- **Offline copies only through Content Sync.** QF Content (Quran text, translations, metadata, audio) may
  not be cached or stored longer than **1 week**, unless it is kept through the **Content Sync APIs**. If a
  resource is available through Content Sync, Content Sync is the *only* permitted way to keep an offline
  copy; you may not build one from normal API responses. A synced copy must be refreshed at least every
  **7 days** when the device is online. If the device is offline longer, it may keep using the old copy and
  must sync promptly when back online.
- **No prepackaged database.** Shipping QF text or translations inside the app bundle is redistribution and
  needs a separate commercial licence. **Fonts and Mushaf images are the exception**: they may be cached or
  bundled if you keep an active Developer Console account and credit Quran Foundation (for example
  "Quran fonts provided by Quran Foundation"). They may not be offered separately.
- **Do not modify the Quran text.** Display only, in context.
- Paid apps, subscriptions, ads, donations and freemium are allowed, as long as QF Content is only shown
  inside the app and not sold or redistributed as data.
- Social-media videos made from QF Content are an allowed end-user use if Quran Foundation is credited
  (useful for One Verse's content-creator users).
- Required: a public privacy policy and terms of use, TLS and encryption at rest, minimum OAuth scopes,
  a way for users to revoke access and delete their data, and reporting incidents within 24 hours.
- No building ML models or ad profiles from QF Content or user data without written consent.
- Attribution wherever Quran content appears: **"Quran data provided by Quran Foundation."** Also credit each
  translation, tafsir and reciter by name.
- Breaking changes get about 30 days' notice. Two translations were removed at the copyright holders'
  request (Clear Quran, Russian word-by-word), so the translation list must come from the API, never be
  hard-coded.

**What this means for One Verse:** today the app downloads alquran.cloud audio and text into
`Music/OneVerse`. If the app moves to Quran Foundation content, offline text, translations and Quran
Foundation audio must be stored through Content Sync and refreshed weekly. Fonts can be bundled with credit.
Audio from other sources (alquran.cloud CDN, mp3quran, EveryAyah) follows those sources' own terms.

## 2. Access and environments

| | Auth host | API host | Notes |
|---|---|---|---|
| Pre-live | `prelive-oauth2.quran.foundation` | `apis-prelive.quran.foundation` | New apps start here. Content is only **Al-Fatihah and Al-Baqarah**. |
| Production | `oauth2.quran.foundation` | `apis.quran.foundation` | Full content after production access is approved |

- Create the app in the Developer Console. Choose **Backend/server app** (has a secret) or
  **Frontend or mobile app** (public client, PKCE, no secret).
- **Content APIs:** client-credentials grant, `POST {auth}/oauth2/token`, HTTP Basic `client_id:client_secret`,
  body `grant_type=client_credentials&scope=content`. The token lasts 1 hour. Call
  `{api}/content/api/v4/...` with headers `x-auth-token` and `x-client-id`. Because it needs the secret, this
  must run on a backend; a mobile-only app needs a small proxy (for example a serverless function).
- **User APIs:** Authorization Code + PKCE ("Quran ID"), with OpenID Connect for identity, `offline_access`
  for refresh tokens. The docs recommend AppAuth on Android. Base path `{api}/auth/v1/...`.
- Errors: on 401 get a new token once and retry once; on 429 back off with jitter; 403 means a wrong client,
  environment, scope or permission. A plain-text `403 error code: 1010` means the User-Agent is blocked; send
  your own (for example `OneVerse/1.2`).
- Do not mix pre-live and production tokens, hosts or caches.

## 3. Content APIs (v4) worth using

| Group | Endpoints | Use in One Verse |
|---|---|---|
| Chapters, Juz, Hizb, Rub el Hizb, Ruku, Manzil, Pages | `/chapters`, `/chapters/{id}/info`, `/juzs`, `/hizbs`, `/rub_el_hizbs`, `/rukus`, `/manzils`, `/pages`, `/pages/lookup` | Surah list, surah info, "go to juz / page", progress by juz |
| Verses | `/verses/by_chapter|by_page|by_juz|by_hizb|by_rub|by_manzil|by_ruku/{n}`, `/verses/by_range`, `/verses/by_key/{key}`, `/verses/random` | Reader. `words=true` with `word_fields` gives every word in every script with the same `position`. `/verses/random` for verse of the day. |
| Scripts | `/quran/verses/{uthmani, uthmani_simple, uthmani_tajweed, indopak, indopak_nastaleeq, imlaei, code_v1, code_v2}` | Whole-verse text per script |
| Translations, tafsirs | `/resources/translations`, `/resources/tafsirs`, `/translations/{id}/by_chapter/{n}`, `/tafsirs/{id}/by_ayah/{key}`, `/foot_notes/{id}` | Translation picker (40+), tafsir sheet, footnotes |
| Ayah audio | `/resources/recitations`, `/recitations/{id}/by_chapter/{n}` (also by juz, page, hizb, rub, manzil, ruku, ayah) | Ayah-by-ayah playback, optional `segments` |
| Chapter audio | `/resources/chapter_reciters`, `/chapter_recitations/{reciter}/{chapter}?segments=true` | Gapless full-surah audio with **verse and word timings** |
| Audio timing helpers | `/audio/reciters/{id}/timestamp`, `/audio/reciters/{id}/lookup` | Seek to an ayah inside a surah file; find the ayah at a playback time |
| Word audio | `word.audio_url` (relative `wbw/067_001_001.mp3`) on `https://audio.qurancdn.com/` | Tap a word to hear it alone (learning mode) |
| Hadith, Answers, QuranReflect, Qira'at | `/hadith_references/by_ayah/{key}`, `/answers/by_ayah/{key}`, `/quran-reflect/v1/posts/feed`, `/qiraat/...` | Later: related hadith, Q&A and reflections under an ayah. Qira'at needs its own scope and is production only. |
| Content Sync | `/resources/sync`, `/resources/snapshots/{group}/{id}` | The offline engine (section 5) |
| Verse media | `/resources/verse_media` | Verse images |
| Share image (User API host, no auth) | `POST /media/share-verse` | Ready-made square share image for one ayah or 2–7 ayahs, any of 19 interface languages |

Two separate audio ID families: chapter reciters (`/resources/chapter_reciters`) and ayah recitations
(`/resources/recitations`). They are not interchangeable.

Chapter timing format: `timestamp_from`/`timestamp_to` in ms from the start of the surah file, and
`segments: [[word_position, start_ms, end_ms], ...]` with 1-based positions. In testing, 18 segments in
Al-Baqarah had a malformed shape (2 or 4 numbers), so validate and skip bad rows.

Search API (`scope=search`, separate permission) and Analytics Events API (`analytics.events.write`) also
exist.

## 4. Fonts

See `quran-scripts-and-fonts.md`. Summary from the font-rendering tutorial:

| Want | Field | Font file (CDN `https://verses.quran.foundation/fonts/quran/`) |
|---|---|---|
| Quickest, Madani look | `text_qpc_hafs` | `hafs/uthmanic_hafs/UthmanicHafs1Ver18.woff2` / `.ttf` |
| IndoPak | `text_indopak_nastaleeq` (`text_indopak` is deprecated) | `hafs/nastaleeq/indopak/indopak-nastaleeq-waqf-lazim-v4.2.1.woff2` / `.ttf` |
| Exact printed Mushaf pages | `code_v2` + `page_number`, mushaf 1 | `hafs/v2/woff2/p{1..604}.woff2` (one font per page) |
| Tajweed colours | `code_v2`, mushaf 19 | `hafs/v4/colrv1/...` or `hafs/v4/ot-svg/{light,dark,sepia}/...` |

- Verse-end markers (`char_type_name = end`): with QCF glyph fonts draw them in UthmanicHafs; with IndoPak
  keep them in the IndoPak font.
- Recommended 10-level size scale, default level 3. At level 4 and above, switch from Mushaf line breaks to
  free wrapping ("big text layout").
- Mushaf IDs: 1 QCF V2, 2 QCF V1, 3 IndoPak, 4 Uthmani Hafs, 5 KFGQPC Hafs, 6 IndoPak 15-line, 7 IndoPak
  16-line, 11 Tajweed, 19 QCF Tajweed V4. User APIs ask for `mushafId` with activity, goals and bookmarks.

## 5. Content Sync (offline, required for QF content)

Groups: `quran_core` (singleton 1: 114 chapters, 6,236 verses, 83,665 words with IndoPak Nastaleeq,
IndoPak, Uthmani Tajweed and Imla'i text, plus juz/hizb/rub boundaries), `mushafs` (page layout and positioned
words; `mushafs:4` gives word-level Uthmani text), `translations`, `word_by_word_translations`,
`word_by_word_transliterations`, `tafsirs`, `recitations` (ayah audio files plus compatible chapter files
and timings), `chapter_recitations` (chapter audio files plus verse and word timing rows), `articles`.

Flow:

1. First run: `GET /resources/sync?bootstrap=true&resources=quran_core:1;mushafs:5;translations:20;chapter_recitations:7&per_page=100`.
   Follow `next_page_url` while `has_more`. Each `RESOURCE_CREATE` has a `snapshot_url`; fetch it and replace
   that resource's local rows in one transaction.
2. Save `next_sync_token` from the final page only, keyed by the exact resource filter.
3. On app start, network return, and at least weekly: `GET /resources/sync?sync_token=...&resources=<same filter>`.
   Apply `ROW_CREATE/UPDATE/DELETE` by `(resource_group, resource_id, record_type, record_key)`; on
   `RESOURCE_INVALIDATE` re-fetch the snapshot; on `RESOURCE_DELETE` hide the resource; `RESOURCE_UPDATE` is
   only a freshness marker.
4. On `resync_required` or `token_filter_mismatch`, bootstrap that filter again. Never store the new token
   before every page and snapshot is applied.

The UI always reads from the local database; sync runs in the background. For Flutter: `drift` or `isar`
for the tables, `workmanager` for the weekly background sync.

(The IDs in the example filter are placeholders: look them up from the resources endpoints.)

## 6. User APIs (accounts and cloud sync, later phase)

| Group | Endpoints | Use in One Verse |
|---|---|---|
| Reading sessions | `POST/GET /v1/reading-sessions` `{chapterNumber, verseNumber}` | "Continue listening" on every device. Updates the latest session if touched within 20 minutes, otherwise starts a new one. Does **not** count time. |
| Activity days | `POST/GET /v1/activity-days`, `GET /v1/activity-days/estimate-reading-time` | Credits time and ranges toward streaks, goals and the calendar. **There is an `AUDIO` type**: `{type:"AUDIO", mushafId, durationSeconds, ranges:["67:1-67:12"], date}`, made for listening apps. Send header `x-timezone`. |
| Streaks | `GET /v1/streaks` (status ACTIVE or BROKEN), `GET /v1/streaks/current-streak-days` | Streak pill and Progress tab |
| Goals | `POST /v1/goals` (`QURAN_TIME`, `QURAN_PAGES`, `QURAN_RANGE`, optional duration in days), `GET /v1/goals/get-todays-plan`, `GET /v1/goals/estimate`, `PUT/DELETE /v1/goals/{id}` | Daily goal ring ("20 minutes a day") and khatm plans |
| Bookmarks and collections | `/v1/bookmarks`, `/v1/collections`, `POST /v1/collections/__default__/bookmarks` (favourite ayah) | Favourite ayahs, playlists of ayahs |
| Reading bookmarks | `/v1/reading-bookmarks` slots 1–3 | Three named "places" (for example "Night recitation") |
| Notes | `/v1/notes`, by verse, by range, publish | Personal reflections on an ayah |
| Preferences | `POST /v1/preferences` and `/bulk`, groups `audio`, `translations`, `tafsirs`, `theme`, `quranReaderStyles`, `reading`, `language` | Sync reciter, translation, script and theme across devices |
| App State | `/v1/app-state/...` with bootstrap and change sync | Private app-specific state (pre-live only, needs approval). Could hold One Verse-only settings later. |
| Users, rooms, posts, comments | QuranReflect social features | Not needed now |

How Quran.com reports progress (copy this pattern):

1. When an ayah becomes current, debounce `POST /v1/reading-sessions` with the latest position.
2. Count active seconds only while playing (for listening) or while the reader is visible (for reading).
3. Every few seconds merge the ayah keys into ranges and `POST /v1/activity-days`.
4. Clear the local progress cache so streak and calendar views refetch.

Scopes are fine-grained (for example `reading_session`, `activity_day`, `streak.read`, `goal`,
`bookmark`, `collection`, `preference`, `note`), with parent scopes that cover child scopes. Request only
the scopes a feature needs, and explain each one before the consent screen.

## 7. Connected Apps and the Quran App Store

Quran Foundation lists reviewed apps at Quran.com/apps. Four gates: content integrity and updates, security
and privacy, compliance with the terms, and maintenance (named technical contact). Quran ID sign-in is
required for "Vision-Aligned" status and is the only allowed sign-in for "Transformational" status.

Their **gamification guidance** applies directly to our Progress tab:

- Reminders, milestones and memorisation support are welcome when they preserve choice and avoid pressure.
- Avoid hasanat counters or any number that looks like spiritual reward.
- Streaks and badges must not imply spiritual rank, shame users, or push them with fear of losing a score.
  No manipulative countdowns, scarcity claims or social comparison around worship.

So: keep streaks gentle ("You listened 12 days in a row"), never "Don't lose your streak!", make every
reminder opt-in, and describe these mechanics if One Verse is submitted to the store.

## 8. Public endpoints observed during research

`api.quran.com/api/v4` and `api.qurancdn.com/api/qdc` currently answer without a token. The redesign
prototype used them for its sample data. A shipped app should use the authenticated hosts above and follow
the terms, because these are the legacy hosts being replaced.

Observation to verify with production credentials: on the legacy host, `text_indopak_nastaleeq` for 67:2
begins `لَّذِیْ` while the IndoPak text from the same API's word data begins `اۨلَّذِىۡ`. Check the
production field before relying on it.
