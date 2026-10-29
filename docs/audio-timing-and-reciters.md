# Audio, word timings and reciters

## Word-exact highlighting

To light up the exact word being recited you need, for each ayah, `[word position, start ms, end ms]`
measured on the same audio file you play. Sources found:

| Source | Reciters | Format | Licence | Notes |
|---|---|---|---|---|
| Quran Foundation chapter recitations (`segments=true`) | Several Quran.com reciters | Quran.com `chapter_recitations` shape | Quran Foundation Developer Terms | The primary source once API access is set up |
| [its3li/quran-word-timings](https://github.com/its3li/quran-word-timings) | Muhammad Al-Luhaidan, all 114 surahs | Quran.com shape (`verse_timings[].segments`) plus a detailed file with confidence scores | **CC0** | Prayer recordings: words can repeat when the imam repeats a phrase. Highlight by time, which handles repeats. |
| [baklarrrr/quran-timings](https://github.com/baklarrrr/quran-timings) | Yasser Al-Dosari (107 surahs), Maher Al-Muaiqly (105), Nasser Al-Qatami (106), Islam Sobhi (104) | Quran.com shape; `reciters.json` lists audio and timing URL templates | No licence file in the repo: ask the author before shipping | Some ayahs are listed as untimed (`leftOut`). They are recited; show them unlit. |
| [cpfair/quran-align](https://github.com/cpfair/quran-align) | EveryAyah reciters | Per-ayah segments, word indices on Tanzil Uthmani split by spaces | CC BY 4.0 (credit required) | Data is in GitHub releases. Fits the current ayah-by-ayah EveryAyah-style audio. |
| QUL (Tarteel, `qul.tarteel.ai`) | Many | Surah-by-surah and ayah-by-ayah segment downloads | See QUL terms | Also hosts fonts and script data |

All of these use Quran.com word positions, so take the text from the Quran Foundation API (or another source
with the same word split) and fall back to proportional mapping when a script splits an ayah into a different
number of words. In testing with the fawazahmed0 texts, the word counts matched for 95–99% of ayahs in Hafs,
and the rest mapped well proportionally.

The timings are tied to one exact audio file (for example `https://cdn.mp3quran.net/audio/islam-sobhi/r1/067.mp3`).
If a source replaces the file, the timings stop matching. Play the URL named in the timing file.

**Prototype note:** in the redesign preview, Maher Al-Muaiqly and Muhammad Al-Luhaidan use these real
timings. Other reciters use estimated timing (words spread over the ayah), and the UI says so with a
"Word-exact timing" or "Estimated timing" badge.

## Audio sources

| Source | Kind | Notes |
|---|---|---|
| alquran.cloud CDN (current app) | Ayah by ayah | Simple, already integrated. Good for repeat-ayah and downloading single ayahs. |
| mp3quran.net API | Surah by surah, very large reciter list | Free public API. Pairs with the baklarrrr and its3li timings. Their privacy page allows copying material and links; recordings remain the reciters' and publishers' work. |
| Quran Foundation | Both | Needs OAuth; terms govern offline storage |
| EveryAyah | Ayah by ayah | No site-wide licence; asks for credit to the reciter and everyayah.com. Bitrates vary by reciter. |

Recommended: keep ayah-by-ayah playback, and add full-surah files with timings where available. A full file
gives gapless recitation, and the timings still tell you which ayah and which word is playing.

## Reciter photos

- **QuranHub API** ([misraj-ai/quranhub](https://github.com/misraj-ai/quranhub)): its README says the audio
  edition endpoints return reciter metadata with `imageUrl`, a short description and nationality, for about
  141 reciters. This is the closest match to "an API with reciter pictures and a long list".
- **JuzzQuran API**: reciter objects with `image_url`, country and style for about 75 reciters (listed on a
  third-party API marketplace; check the source and terms).
- **Wikipedia page-summary API** (`/api/rest_v1/page/summary/<title>`): a thumbnail for well-known reciters.
- Always keep the generated monogram as a fallback, and cache images on the device.

None of these sources state a licence for the photos themselves. Ask for permission or use only images
whose licence allows app use.

## Other Quran APIs looked at

- **UmmahAPI** (`ummahapi.com`, could not be opened directly; summary from its own pages): free, no sign-up,
  optional key for higher limits. Quran endpoints include `/api/quran/surah/{surah}` with
  `script=uthmani|indopak|tajweed|all`, `/api/quran/surah/{s}/ayah/{a}`, `/api/quran/words/{s}/{a}` (word by
  word), `/api/quran/reciters`, search, juz and random ayah, plus tafsir, duas and prayer times. Its pages
  disagree on limits (100 requests per minute vs 5,000 per 15 minutes) and on counts (8 or 12 translations and
  reciters). Useful as a simple fallback for IndoPak and tajweed text; the Quran Foundation API is deeper.
- **fawazahmed0/quran-api**: static JSON on GitHub/jsDelivr, 90+ languages, Arabic editions including QPC
  Hafs, IndoPak, Warsh, Qaloon and transliterations. No key, no rate limit. Good for bundling text offline.
- **Quranpedia API**: reciters with riwayah and timing URLs; no photo field seen.
