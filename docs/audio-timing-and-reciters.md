# Audio, word timings, reciters and photos

All numbers below were checked against the live APIs on 2026-10-29.

## Word-exact highlighting

To light up the word being recited you need, for each ayah, `[word position, start ms, end ms]` measured on
the exact audio file you play, and the Quran text split into the same word positions.

| Source | Reciters | Licence or terms | Notes |
|---|---|---|---|
| **Quran Foundation chapter recitations** (`/chapter_recitations/{id}/{chapter}?segments=true`, or Content Sync `chapter_recitations`) | 14 chapter reciters on Quran.com: Mishary Alafasy, Abdur-Rahman As-Sudais, Saud Ash-Shuraym, Yasser Ad-Dosari, Abdul Basit (Murattal and Mujawwad), Mahmoud Khalil Al-Husary (Murattal and Muallim), Minshawi (Murattal and Kids repeat), Abu Bakr Ash-Shatri, Hani Ar-Rifai, Khalifa Al-Tunaiji | Quran Foundation Developer Terms | Every ayah of the 9 surahs tested had segments. 18 segments in Al-Baqarah were malformed; skip any row that is not 3 numbers. Audio on `download.quranicaudio.com/qdc/...` |
| [its3li/quran-word-timings](https://github.com/its3li/quran-word-timings) | Muhammad Al-Luhaidan, all 114 surahs | **CC0** | Prayer recordings: some phrases repeat, so highlight by time. Audio on mp3quran. |
| [baklarrrr/quran-timings](https://github.com/baklarrrr/quran-timings) | Yasser Al-Dosari, Maher Al-Muaiqly, Nasser Al-Qatami, Islam Sobhi (104–107 surahs each) | **No licence file**: ask the author before shipping | Some ayahs untimed (`leftOut`): recited, show them unlit. Audio on mp3quran. |
| [cpfair/quran-align](https://github.com/cpfair/quran-align) | EveryAyah reciters, ayah by ayah | CC BY 4.0 | Word indices on Tanzil Uthmani split by spaces |

All of these number words the way Quran.com does. Take the text word by word from the Quran Foundation API
(`words=true&word_fields=text_qpc_hafs,text_indopak,text_uthmani,text_imlaei,text_uthmani_tajweed`): every
script then has the same positions, and highlighting is exact in every script. The redesign prototype does
exactly this and needed no fallback mapping.

A timing file only matches the audio file it was measured on. Always play the URL that comes with the
timings, and re-download timings if the source replaces a file.

**Resulting reciter coverage in the prototype:** 15 reciters with word-exact timing, 9 more with estimated
timing, and the UI says which ("Word-exact timing" or "Estimated timing").

## Reciter photos: QuranHub

This is the API with photos and a long reciter list.

- `GET https://api.quranhub.com/v1/edition/format/audio` returns **208 audio editions (158 distinct
  reciters), 197 with `imageUrl`**, plus `shortDescription` in Arabic and English, Arabic name and
  `nationality` (`{code, en, ar}`).
- `GET https://api.quranhub.com/v1/edition/audio/nationality` and `/nationality/{code}` group reciters by
  country (for a "Reciters from Egypt" shelf).
- Identifiers mirror alquran.cloud's (`ar.alafasy` becomes `ar.alafasy.hafs`, also `.warsh`, `.qaloon`,
  `.aldouri` riwayat), so mapping the app's current reciters is a string change.
- Images are JPEGs on `quranhub.b-cdn.net` (about 12 KB). Cache them on the device and keep the generated
  monogram as fallback.
- **Licence:** the QuranHub code is under a Non-Commercial License (Misraj AI). The terms for the API data and
  the photos are not stated. Ask Misraj AI (hello@misraj.ai) for permission before shipping, especially if
  One Verse is ever monetised. Photos remain the property of their owners.

Other sources checked: Quran.com reciter endpoints have no photo field; mp3quran.net has no photo field;
UmmahAPI has no photo field.

## Audio sources

| Source | Reciters | Kind | Notes |
|---|---|---|---|
| alquran.cloud CDN (current app) | about 30 ayah-by-ayah editions (Arabic and translation voices), plus surah-by-surah ones | Ayah by ayah | Already integrated |
| **mp3quran.net API v3** (`/api/v3/reciters?language=eng`) | **244 reciters**, many riwayat (`moshaf` list with `server` URL and `surah_list`) | Surah by surah | The largest list. Its privacy page allows copying material and links; recordings remain the reciters' and publishers'. Pairs with the Luhaidan and baklarrrr timings. |
| Quran Foundation | 14 chapter reciters, more ayah recitations | Both, with timings | OAuth; offline copies through Content Sync |
| QuranHub | 158 reciters | Per edition | Has the photos and biographies |
| EveryAyah | Many | Ayah by ayah | No site-wide licence; asks for credit to the reciter and everyayah.com |
| UmmahAPI | 13 reciters | Both | See below |

Recommended: keep ayah-by-ayah audio for repeat and single-ayah downloads; add full-surah files with
timings for gapless playback. With timings you still know the exact ayah and word at every moment, and
`/audio/reciters/{id}/lookup` maps a playback time to an ayah.

## UmmahAPI (`https://ummahapi.com`)

Free, no sign-up; an optional key gives 5× the limit. Live headers show `ratelimit-policy: 5000;w=900`
(5,000 requests per 15 minutes without a key).

Quran endpoints: `/api/quran`, `/api/quran/surahs`, `/api/quran/surah/{n}?script=uthmani|indopak|tajweed|all&translation=...&reciter=...`,
`/api/quran/surah/{s}/ayah/{a}`, `/api/quran/random`, `/api/quran/search`, `/api/quran/juz/{n}`,
`/api/quran/page/{n}` (word data for a 15-line Madinah page), `/api/quran/reciters` (13),
`/api/quran/audio/{surah}[/{ayah}]`, `/api/quran/words/{surah}[/{ayah}]` (word by word),
`/api/quran/mutashabihat...` (1,200+ similar ayahs, useful for huffaz).

Also useful for One Verse:

- **Hijri calendar:** `/api/hijri-date?date=YYYY-MM-DD&timezone=...`, `/api/moon/hijri`, `/api/moon/months`
  (Umm al-Qura). Use this to schedule special-day reminders (Ramadan, last ten nights, Arafah, Eid).
- Ramadan timetable, prayer times and Qibla, tafsir (Ibn Kathir, Ma'arif al-Qur'an, Muyassar), 126 duas.

Its tajweed text uses `<tajweed class=...>` tags. Translations: 12 (Saheeh, Pickthall, Yusuf Ali, Urdu and
others). Good as a simple fallback; the Quran Foundation API is deeper and has the timings.

## fawazahmed0/quran-api

Static JSON on GitHub and jsDelivr: 90+ languages, Arabic editions including QPC Hafs, IndoPak, Warsh,
Qaloon and transliterations. No key, no rate limit. Its QPC Hafs copy needs two clean-ups (see
`quran-scripts-and-fonts.md`). Its word split differs slightly from Quran.com's (about 1–10% of ayahs), so
prefer Quran Foundation words when highlighting.
