# Quran scripts and fonts

## The bug in the current app

`PlaybackConfig.arabicTextEdition` is `quran-uthmani` (the Tanzil Uthmani text from alquran.cloud) and the
default Arabic font is `UthmanicHafs` (`assets/fonts/UthmanicHafs1 Ver18.ttf`, the King Fahd Complex
"KFGQPC Uthmanic Script HAFS" font).

These two do not belong together. The KFGQPC font was built for the King Fahd Complex's own Hafs text
(`text_qpc_hafs`), which uses different code points for several marks. Fed the Tanzil text, it draws some
marks wrongly. For example in 67:11 `فَٱعۡتَرَفُوا۟` the small high rounded zero (U+06DF) comes out as a filled
black circle. Readers see a broken word, which is the "parhne mein issue" on Android.

**Rule: every Quran text must be shown in the font it was encoded for.** Picking a script in settings switches
both the text field and the font. Quran Foundation's font tutorial says the same: `text_qpc_hafs` only with
UthmanicHafs, `text_indopak_nastaleeq` only with its IndoPak Nastaleeq font file.

## Recommended source: Quran Foundation words

Request verses with
`words=true&word_fields=text_qpc_hafs,text_indopak_nastaleeq,text_indopak,text_uthmani,text_imlaei,text_uthmani_tajweed`.
Every script then comes split into the same word `position`s, which are also the positions used by the word
timings. Each verse ends with a word whose `char_type_name` is `end` (the ayah number).

## Pairings (each one rendered and checked)

| Script in the app | Field | Font | Notes |
|---|---|---|---|
| **Madani (default)** | `text_qpc_hafs` | `UthmanicHafs1Ver18` (already in `assets/fonts`; CDN `verses.quran.foundation/fonts/quran/hafs/uthmanic_hafs/`) | Looks like the printed Madinah Mushaf. The font draws Arabic-Indic digits as the ornamented ayah marker, so the `end` word (`٢`) gives a correctly aligned marker. |
| **IndoPak** | `text_indopak_nastaleeq` (preferred by QF) or `text_indopak` (deprecated, but complete in testing) | `indopak-nastaleeq-waqf-lazim-v4.2.1` (CDN `verses.quran.foundation/fonts/quran/hafs/nastaleeq/indopak/`) | The style readers in Pakistan and India learned from. QF says to keep the IndoPak `end` marker in this font when using `text_indopak_nastaleeq`. With `text_indopak`, draw the number with the Hafs font. See the 67:2 note in `quran-foundation-api.md`. |
| **Tajweed colours** | `text_uthmani_tajweed` (`<rule class=ham_wasl>…</rule>` tags) | Amiri Quran | Map rule classes to colours: ham_wasl, slnt, laam_shamsiyah (grey), madda_normal, madda_permissible, madda_obligatory, madda_necessary (blues), qalaqah (red), ghunnah (orange), ikhafa, ikhafa_shafawi (purples), idgham_ghunnah, idgham_wo_ghunnah, idgham_shafawi (greens), iqlab (light blue), idgham_mutajanisayn, idgham_mutaqaribayn (grey). In testing, Amiri joined the coloured pieces more cleanly than the Hafs font. For a full Mushaf look, QF's QCF V4 page fonts carry the colours inside the font instead. |
| **Uthmani (Amiri)** | `text_uthmani` | Amiri Quran (already bundled) | Also the safe font for the alquran.cloud `quran-uthmani` text the app uses today. |
| **Simple** | `text_imlaei` | Scheherazade New or Noto Naskh Arabic (both bundled) | Modern spelling, no Uthmani marks. Easiest for new readers. |
| Exact Mushaf pages (later) | `code_v2` + `page_number` | QCF V2, one font file per page (`hafs/v2/woff2/p{1..604}.woff2`) | Load only the fonts for visible pages. Draw `end` markers with UthmanicHafs. |
| Kitab (optional) | alquran.cloud `quran-uthmani-quran-academy` | Kitab (bundled) | alquran.cloud says this edition was modified to work with the Kitab font. |

Do not pair `me_quran` with the Tanzil text: it showed broken boxes in testing.

**Licence for fonts:** QF allows caching or bundling its font files inside the app if you keep an active
Developer Console account and credit Quran Foundation (for example "Quran fonts provided by Quran
Foundation"). The files may not be offered separately. The text itself may not be bundled; see the Content
Sync rules in `quran-foundation-api.md`.

## If you use the fawazahmed0 copies instead

[fawazahmed0/quran-api](https://github.com/fawazahmed0/quran-api) has `ara-quranuthmanihaf` and
`ara-quranindopak` as plain JSON. They need two clean-ups:

1. **Hafs open tanween.** The file replaced U+0657, U+065E, U+0656 with U+08F0, U+08F1, U+08F2 and put a
   space before the following alef (`عَمَلࣰ اۚ`). UthmanicHafs1Ver18 draws that as a gap with the tanween
   missing. Map them back and remove the space before a lone alef.
2. **IndoPak iqlab split.** Words with the small low meem (U+06ED) are split by a space (`تُنۭۡ بِتُ`).
   Remove the space after U+06ED and strip the trailing U+200F.

Their word split also differs from Quran.com's in 1–10% of ayahs, which breaks exact word highlighting.
The Quran Foundation words avoid all three problems.

## Words, waqf signs, ayah numbers and Bismillah

- With Quran Foundation words, waqf signs are already part of the word. With space-split text (Tanzil),
  attach any token without Arabic letters (such as `ۖ`) to the word before it.
- Ayah numbers: use the `end` word in the Hafs font (or in the IndoPak font for `text_indopak_nastaleeq`).
  This fixes the number spilling out of the bottom of the circle.
- Bismillah: alquran.cloud puts it inside ayah 1 of every surah except 1 and 9; strip the first four words and
  show it as a header. Quran Foundation texts already leave it out.

## Size and layout

- QF recommends a 10-level size scale with level 3 as default. From level 4 up, drop Mushaf line breaks and
  let lines wrap ("big text layout").
- Line height: about 2.15 for Hafs and Amiri, 2.35 for IndoPak, 1.9 for Simple.

## Flutter notes

- Keep a map `script -> (field, font family, line height, scale)`. Changing the script re-reads the cached
  words; no network needed.
- Store words per script in the offline database (through Content Sync when the source is QF).
