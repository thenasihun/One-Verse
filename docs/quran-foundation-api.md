# Quran Foundation API (Quran.com)

Docs: <https://api-docs.quran.foundation/docs/developer-journey/>. The same docs are mirrored at
`api-docs.quran.com`. This summary was built from search results quoting those pages because the docs host
was blocked from the research environment. **Verify every path and parameter before use.**

## Access

- Register an app to get a `client_id` and `client_secret`.
- Two environments that must not be mixed (a token from one is rejected by the other):

  | | Auth host | API host |
  |---|---|---|
  | Pre-live (testing) | `prelive-oauth2.quran.foundation` | `apis-prelive.quran.foundation` |
  | Production | `oauth2.quran.foundation` | `apis.quran.foundation` |

- **Content APIs** use the OAuth2 client-credentials grant: `POST {auth}/oauth2/token` with HTTP Basic
  `client_id:client_secret` and body `grant_type=client_credentials&scope=content`. Tokens last 1 hour.
  Requests go to `{api}/content/api/v4/...` with headers `x-auth-token` and `x-client-id`. On a 401, fetch a
  new token once and retry once.
- **User APIs** use OAuth2 / OpenID Connect sign-in (authorization code with PKCE on mobile), with scopes the
  user consents to (for example `bookmark.read`, `collection.create`, `reading_session.*`, `note.publish`).
- The old `api.quran.com/api/v4` base is being replaced by these hosts (there is a migration guide).
- Keep the client secret off the device. For Content APIs, put a small proxy (for example a serverless
  function) between the app and the API, or cache content in your own backend.
- The audio and texts are Quran Foundation content under its Developer Terms, which govern storage, offline
  use and redistribution. Read them before enabling offline downloads from this source.

## Content APIs worth using

| Area | What it gives One Verse |
|---|---|
| Chapters | Surah names, revelation place, ayah counts, chapter info |
| Verses by chapter / page / juz / hizb / rub el hizb / range / key | Text plus metadata (`juz_number`, `hizb_number`, `rub_el_hizb_number`, `page_number`) for navigation |
| Verse `fields` | `text_uthmani`, `text_qpc_hafs`, `text_indopak`, `text_qpc_nastaleeq`, `text_uthmani_tajweed`, `text_imlaei`, `code_v1`/`code_v2` (QCF glyph fonts, with `v2_page` to pick the page font) |
| `words=true` with `word_fields` | Word-by-word text in each script, word translation and transliteration, word audio path, `char_type` (word or end marker), `position` |
| Mushafs | Mushaf ids such as KFGQPC Hafs (5), IndoPak 15-line (6) and 16-line (7), QCF V2 (1), Tajweed V4 (19), and a page-layout API for true mushaf pages |
| Translations and tafsirs | Resource lists, then attach by id to verse requests (for example `translations=...`, `tafsirs=169`) |
| Recitations (ayah by ayah) | `/resources/recitations` and per-verse audio files |
| Chapter recitations (surah by surah) | `/resources/chapter_reciters` and the chapter audio file; `segments=true` adds word timings `[word position, start ms, end ms]` per ayah. The two reciter id lists are separate. |
| Timestamp helpers | "Lookup verse by timestamp" and "Get timestamp range", useful for seeking in a full-surah file |
| Search | Text search across translations |
| Qira'at | Qira'at readers and a per-chapter qira'at matrix |
| Font rendering tutorial | `docs/tutorials/fonts/font-rendering`: which font goes with which text field |

### What One Verse should take from it

1. **Text per script** with `fields=text_qpc_hafs,text_indopak,text_uthmani_tajweed` and `words=true`, so the
   word positions match the timing data.
2. **Full-surah audio with word segments** for gapless playback and word-exact highlighting. Ayah-by-ayah
   audio can stay as a fallback for reciters without chapter audio.
3. **Translations and tafsir** catalogue instead of the hard-coded list.
4. **Juz, hizb and page metadata** for "go to juz", "go to page" and progress by juz.

## User APIs (for accounts and cloud sync later)

| Group | Use in One Verse |
|---|---|
| Users | Sign-in, profile |
| Reading sessions | Store the last position (surah, ayah) for "continue listening" on every device. They do **not** count time or streaks. |
| Activity days | `POST /v1/activity-days` with the ranges read, active seconds and mushaf id. This is what credits streaks, goals and the activity calendar. Send a listening session here. |
| Streaks | Get streaks and current streak days: the streak shown on Home and Progress |
| Goals | Create, update, delete and estimate goals, and "today's goal plan" |
| Bookmarks and collections | Favourite ayahs (`POST /v1/collections/__default__/bookmarks`) and named collections |
| Notes | Personal notes and reflections on an ayah, optionally published |
| Preferences | Reciter, translation, script and theme, synced across devices |

The full machine-readable list is the OpenAPI file:
`https://api-docs.quran.foundation/openAPI/user-related-apis/v1.json`.

Plan: build Progress, streaks and resume locally first (see `redesign-features.md`) with the same data shape
(reading session = position, activity day = date + seconds + ranges), so moving to these APIs later is a
sync job, not a rewrite.
