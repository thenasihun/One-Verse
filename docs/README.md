# One Verse: redesign research

Notes collected while designing the next version of One Verse. Read these before building.

| File | What it covers |
|---|---|
| [redesign-features.md](redesign-features.md) | Feature list and highlights for the new app, with Flutter packages, data sources and build order |
| [quran-scripts-and-fonts.md](quran-scripts-and-fonts.md) | Why Arabic text renders badly on Android today, and which text goes with which font |
| [quran-foundation-api.md](quran-foundation-api.md) | Quran Foundation (Quran.com) Developer Terms, Content APIs, Content Sync, User APIs, Connected Apps |
| [audio-timing-and-reciters.md](audio-timing-and-reciters.md) | Word timings, reciter photos (QuranHub), audio sources (mp3quran, Quran Foundation), UmmahAPI |

The interactive prototype of the redesign is a private Claude artifact shared with the project owner.

## How this research was done (2026-10-29)

- All 342 pages of `api-docs.quran.foundation` were downloaded and read, together with its two OpenAPI files.
- UmmahAPI, QuranHub, mp3quran, Quran.com and the timing repositories were called live; counts and limits in
  these notes come from those responses.
- Text and font pairings were checked by rendering them in a browser.

## Five things to know before building

1. The current Arabic text and font do not match; that is the Android reading bug.
2. Quran Foundation content may only be kept offline through Content Sync, refreshed weekly. Fonts may be
   bundled with credit.
3. Quran Foundation words give every script the same word positions as its timing data, so word-exact
   highlighting works in all scripts.
4. Activity days have an `AUDIO` type: listening time can count toward streaks and goals once accounts arrive.
5. QuranHub has the reciter photos (197) and biographies, but its licence must be cleared first.
