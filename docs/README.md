# One Verse: redesign research

Notes collected while designing the next version of One Verse. Read these before building.

| File | What it covers |
|---|---|
| [redesign-features.md](redesign-features.md) | Feature list and highlights for the new app, with how each one maps to Flutter packages and data sources |
| [quran-scripts-and-fonts.md](quran-scripts-and-fonts.md) | Why Arabic text renders badly on Android today, and which text must be paired with which font |
| [quran-foundation-api.md](quran-foundation-api.md) | What the Quran Foundation (Quran.com) Content and User APIs offer, and what One Verse should use |
| [audio-timing-and-reciters.md](audio-timing-and-reciters.md) | Word-by-word timing data, audio sources, reciter lists and reciter photos, and other Quran APIs (UmmahAPI, QuranHub, mp3quran, EveryAyah) |

The interactive prototype of the redesign is a private Claude artifact shared with the project owner.

## How this research was done

`api-docs.quran.foundation` and `ummahapi.com` could not be opened directly from the research environment
(its network policy blocks those hosts). Their content here comes from search results that quote the docs,
so every endpoint name and parameter in those two sections is marked **verify before use**. Everything else
(text editions, fonts, timing files) was downloaded and tested by rendering it in a browser.
