# More reciters: candidates (not added yet)

These are well-known reciters who are not in the app yet. Every one has **all 114 surahs** as full-surah files,
which was checked on 2026-11-06 (the files for surahs 1 and 114 answer). None has word timings, so they would play
whole surahs without word-by-word highlight. That is enough for people who want to listen rather than read along.

Source of the audio: mp3quran.net (`https://mp3quran.net/api/v3/reciters`); the files are at
`{server}/001.mp3` … `114.mp3`. Photos come from QuranHub, where it has them.
Every server path below starts with `https://cdn.mp3quran.net/audio/`.

## Most listened

| # | Reciter | Known for | mp3quran id | Server | Photo |
|---|---|---|---|---|---|
| 1 | Saad Al-Ghamdi | One of the most played murattal recitations worldwide | 30 | `cdn.mp3quran.net/audio/saad-ghamdi/r1/` | Yes |
| 2 | Khalid Al-Jaleel | Riyadh imam, very popular soft murattal | 20 | `…/khalid-jalil/r1/` | Yes |
| 3 | Idrees Abkar | Popular emotional recitation | 12 | `…/idrees-abkar/r1/` | No |
| 4 | Fares Abbad | Clear, calm murattal | 81 | `…/fares-abbad/r1/` | Yes |
| 5 | Mansour Al-Salimi | Young reciter, widely shared | 245 | `…/mansour-salimi/r1/` | Yes |
| 6 | Wadee Hammadi Al-Yamani | Emotional Yemeni style | 219 | `…/wadee-yamani/r1/` | Yes |
| 7 | Ahmed Al-Nufais | Young Saudi reciter, popular on social media | 259 | `…/ahmad-nufais/r1/` | Yes |
| 8 | Bader Al-Turki | Trending recent recitations | 254 | `…/badr-turki/r1/` | Yes |
| 9 | Abdullah Awad Al-Juhany | Imam of Masjid al-Haram | 62 | `…/abdullah-juhani/r1/` | Yes |
| 10 | Bandar Baleela | Imam of Masjid al-Haram | 217 | `…/bandar-baleela/r1/` | Yes |
| 11 | Salah Bukhatir | Gentle Emirati murattal | 46 | `…/salah-bukhatir/r1/` | Yes |
| 12 | Ali Jaber | Classic Masjid al-Haram recitation | 76 | `…/ali-jaber/r1/` | Yes |
| 13 | Raad Al-Kurdi | Very popular Kurdish reciter | 221 | `…/raad-kurdi/r1/` | No |
| 14 | Muhammad Al-Mohaisany | Taraweeh imam, popular voice | 108 | `…/muhammad-muhaisni/r1/` | No |
| 15 | Yasser Al-Qurashi | Popular murattal | 93 | `…/yasser-qurashi/r1/` | Yes |

## Also good

| Reciter | Note | mp3quran id | Photo |
|---|---|---|---|
| Abdulrahman Al-Ossi | Saudi murattal | 225 | Yes |
| Salah Al-Budair | Imam of Masjid an-Nabawi | 43 | Yes |
| Abdulmohsen Al-Qasim | Imam of Masjid an-Nabawi | 67 | Yes |
| Hatem Farid Al-Waer | Known for Taraweeh | 163 | Yes |
| Mustafa Ismail | Classic Egyptian, murattal and mujawwad | 125 | Yes |
| Mahmoud Ali Al-Banna | Classic Egyptian, murattal and mujawwad | 121 | Yes |
| Muhammad Al-Tablawi | Classic Egyptian | 106 | Yes |
| Abdullah Khayyat | Early Masjid al-Haram imam | 61 | Yes |
| Sahl Yassin | Saudi murattal | 32 | Yes |
| Nabil Ar-Rifai | Murattal | 87 | Yes |
| Abdulwadud Haneef | Murattal | 71 | Yes |

## Checked but not recommended now

- **Noreen Muhammad Siddiq** (id 138): complete, but in the **ad-Duri** reading, not Hafs. The app's text is Hafs,
  so some words would differ from what is shown. Add only with a "Duri" label.
- **Omar Hisham Al-Arabi:** not on mp3quran, QuranicAudio or QuranHub.
- **Hazza Al-Balushi** (91 surahs) and **Salman Al-Utaybi** (75 surahs): incomplete.

## How they would be added

1. Each becomes a `Reciter` with a full-surah source (the mp3quran server).
2. They play as one file per surah, the same way timed reciters do, but without the word highlight.
3. They show a "Full surah" badge instead of "Word sync".
4. "Download complete Quran" works for them: the files are about 0.5–1.5 GB per reciter.
