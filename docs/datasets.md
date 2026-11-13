# Datasets: what the app uses, and what was checked for moods and topics

For each source: what it contains, how it was made or listed, its licence or terms, and what it is (or could
be) used for in One Verse. Checked on 2026-11-13. Counts come from the sources' own pages or live calls.

---

## 1. In use in the app today

| # | Source | What the app takes from it | How the data was made | Licence or terms | Open issue |
|---|---|---|---|---|---|
| 1 | **Quran.com / Quran Foundation** public API (`api.quran.com/api/v4`, `api.qurancdn.com/api/qdc`) | Word-by-word Quran text in five scripts (QPC Hafs, IndoPak, Uthmani, Tajweed, Imlaei), word timings (QDC) for the Quran.com reciters, full-surah audio links, and 9 tafseer books | The text goes back to the King Fahd Complex and Tanzil, prepared and checked by Quran.com. For the word timestamps, QUL's credits name Collin Fair for the original data. The tafseers are published works, digitised. | Quran Foundation Developer Terms: offline copies only through Content Sync, refreshed every 7 days; credit "Quran data provided by Quran Foundation" | TODO 1 and 2 |
| 2 | **AlQuran Cloud** (`api.alquran.cloud`, `cdn.islamic.network`) | 100+ translations in 40+ languages, ayah-by-ayah recitations, and translation audio (Urdu, English, French, Russian, Persian, Chinese, Uzbek, Turkish) | A free API by Islamic Network that credits Tanzil for many of its translations. The ayah audio is one file per ayah, as on EveryAyah (not checked in detail). | Free to use; credit expected | None known |
| 3 | **mp3quran.net** (`mp3quran.net/api/v3`) | Full-surah audio for 26 reciters, and ayah timestamps (`ayat_timing`) for 22 of them | The mp3quran team publishes the recordings. The timings are ayah start and end times that they marked for each recording. | Public API, free use with credit | 4 reciters have no timings (TODO 34) |
| 4 | **QuranHub** (Misraj AI) | Reciter photos, countries and short biographies | Collected by Misraj AI | Code: non-commercial licence; data and photo terms are not stated | TODO 3 |
| 5 | **QuranicAudio** (`download.quranicaudio.com`) | Full-surah audio files behind Quran.com recitations | A collection of famous recitations | Credit the reciters and the site | None known |
| 6 | **its3li/quran-word-timings** (GitHub) | Word timings for Muhammad Al-Luhaidan | A community project; the method is in its README (not verified here) | See its repository | Check the licence along with TODO 4 |
| 7 | **baklarrrr/quran-timings** (GitHub) | Word timings for Yasser Al-Dosari, Maher Al-Muaiqly, Nasser Al-Qatami and Islam Sobhi | A community project. Some ayahs are left untimed (`leftOut`) and stay unlit. | **No licence file** | TODO 4 |

---

## 2. Checked for the mood and topic feature

### 2.1 QUL: Quranic Universal Library (Tarteel), `qul.tarteel.ai`, the best candidate

QUL is a library of downloadable Quran datasets (SQLite, JSON, CSV) for packaging inside your own app; there is
no API. QUL says most of its resources were "created or curated by the community, not Tarteel". Contributors it
names include Tanzil, Quran.com, the King Fahd Complex, QuranWBW.com, Dr. Kais Dukes (Quran morphology) and
Greentech Apps Foundation. It warns that the data "may contain errors". A download needs a free QUL login. Each
resource has its own Licence tab, which loads only in a browser, so read it before shipping that resource
(TODO 6).

| QUL resource | Size | How it was made or listed | Use in One Verse |
|---|---|---|---|
| **Ayah Topics** (resource 45) | 3,158 topics | Three kinds. **Ontology topics** come from the Quranic Arabic Corpus ontology (300 concepts, 350 relations), built on traditional analysis, the hadith and the tafseer of Ibn Kathir. **Thematic topics** come from the index of *The Clear Quran* translation (Dr. Mustafa Khattab), in three themes: Doctrine, Stories and The Unseen. **General topics** are a broader list. | **Topics** for mood and topic browsing (TODO 19) |
| Topic sizes checked | — | Paradise 154 ayahs · Grave 12 · Day of Resurrection 50, Resurrection 130, Last Day 26 · Mountains 50 · Travel 29, Traveller 14 · Death 115 · Patience 87, patience in adversity 49 · Mercy 32 · Fear 90 · Hope 7 · Rain 44 · Sea and Night: several sub-topics · Anxiety 1 · Grief 1 · Gratitude and Sorrow: none | Good for places and themes; too thin for **moods** |
| **Ayah theme** (resource 62) | 1,049 themes, English | A short summary of what each passage is about, with the ayah range it covers | Passage headings in the reader (TODO 27) |
| **Similar ayahs** (resource 74) | 4,001 ayahs | Computed by word overlap: "matches 4 words with 50% coverage, similarity score 80" | "Similar ayahs" in the tafseer sheet (TODO 29) |
| **Mutashabihat ul Quran** (resource 73) | 5,278 phrases | Repeated phrases, with every ayah each appears in | Memorise mode (TODO 28) |
| **Surah information** | 9 languages, including Urdu | Descriptions of each surah: revelation, core themes, key topics | Surah introduction (TODO 26) |
| **Word-by-word translations** | 22 | From QuranWBW.com and others | Tap a word for its meaning (TODO 20) |
| **Segmented audio** | 131 recitations | Audio with ayah and word timestamps | Timings for more reciters (TODO 34) |
| Tafsirs | 115 (35 short, 80 detailed) | Published tafseers, with ayah grouping | More tafseer books |

### 2.2 Other sources checked

| Source | What it is | How it was made | Licence | Verdict |
|---|---|---|---|---|
| **Quranic Arabic Corpus ontology** (`corpus.quran.com`, Dr. Kais Dukes, University of Leeds) | 300 concepts such as Paradise and Hell, with the ayahs for each | Hand-built from hadith and the tafseer of Ibn Kathir, plus named-entity tagging | GNU GPL and the corpus terms of use (2010 announcement; check the current terms) | Already inside QUL's ontology topics; take it from QUL |
| **AlfaazPlus/QuranAppTopicsCMS** (GitHub) | SQLite: about 2.5k topics, 3.5k titles, 1.7k relations, 31k topic-to-ayah links | The source is not stated; it has ontology and thematic flags like QUL's | The app using it (QuranApp) is GPL-3.0; the database licence is not stated | Looks close to QUL topics; prefer QUL, the documented source |
| **talhamahamud/Quran-Index** (GitHub) | Verses "structured by topics and surah" | Not documented | None shown | Not usable without documentation |
| **ymorsi7/QuranicSentiment** (GitHub) | All 6,236 ayahs in 6 emotions: joyful, peaceful, angry, fearful, remorseful, reflective | Emotion-word dictionaries with VADER and TextBlob, which are automatic sentiment tools made for English social media; no scholarly review mentioned | MIT | **Not recommended**: automatic labels are not right for the Quran |
| **Kaggle: Quranic Thematic & Emotional Annotation Dataset** (nabeelqureshitiii) | Thematic and emotion annotations for emotion-aware recommendation | Not visible from here (kaggle.com is blocked in this environment) | MIT according to its metadata | Open it from a normal browser and check how the labels were made before using it |
| **Tanzil** (`tanzil.net`) | Quran text and many translations | Audited text | Tanzil terms (verbatim text, credit) | Text only, no topics |

---

## 3. Recommendation for the mood and topic feature

1. **Topics** (Jannah, the grave, Qiyamah, travel, night, mountains, rain, the sea, death, patience, mercy):
   take QUL Ayah Topics. It is documented and scholarly, built on Ibn Kathir and *The Clear Quran*.
   - Show 5–10 ayahs a topic, with a "show all" option.
2. **Moods** (sad, anxious, lonely, grateful, angry, hopeless, happy):
   - No reliable dataset exists.
   - Build a short hand-made list of well-known ayahs, for example:
     - sad: 94:5–6, 2:286, 9:40, 12:86, 3:139
     - anxious: 13:28, 65:3, 2:152
     - hopeless: 39:53, 12:87
     - grateful: 14:7, 55:13
   - Have a scholar check the list before release.
   - Keep it in the app as a small JSON file with the source of each choice.
3. Before shipping, check each QUL resource's licence tab (TODO 6) and credit QUL and its contributors in the
   About screen.

What is needed from you: download the Ayah Topics SQLite from QUL (free login) and add it to the repository, or
say whether the topic list may be taken from the public topic pages instead.

Sources: [QUL resources](https://qul.tarteel.ai/resources) ·
[QUL Ayah Topics](https://qul.tarteel.ai/resources/ayah-topics/45) · [QUL credits](https://qul.tarteel.ai/credits) ·
[Quranic Arabic Corpus](https://corpus.quran.com/concept.jsp?id=hell) ·
[QuranAppTopicsCMS](https://github.com/AlfaazPlus/QuranAppTopicsCMS) ·
[Quran-Index](https://github.com/talhamahamud/Quran-Index) ·
[QuranicSentiment](https://github.com/ymorsi7/QuranicSentiment) ·
[Kaggle dataset](https://www.kaggle.com/datasets/nabeelqureshitiii/quranic-thematic-and-emotional-annotation-dataset)
