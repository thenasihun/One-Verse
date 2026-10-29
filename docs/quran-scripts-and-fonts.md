# Quran scripts and fonts

## The bug in the current app

`PlaybackConfig.arabicTextEdition` is `quran-uthmani` (the Tanzil Uthmani text from alquran.cloud) and the
default Arabic font is `UthmanicHafs` (`assets/fonts/UthmanicHafs1 Ver18.ttf`, the King Fahd Complex
"KFGQPC Uthmanic Script HAFS" font).

These two do not belong together. The KFGQPC font was built for the King Fahd Complex's own Hafs text, which
uses different code points for several marks. Fed the Tanzil text, it draws some marks wrongly. For example in
67:11 `فَٱعۡتَرَفُوا۟` the small high rounded zero (U+06DF) comes out as a filled black circle. Readers see a
broken word, which is the "parhne mein issue" on Android.

**Rule: every Quran text must be shown in the font it was encoded for.** Picking a font in settings must also
switch the text edition.

## Pairings that render correctly (tested)

| Script in the app | Text source | Font | Notes |
|---|---|---|---|
| **Madani (default)** | KFGQPC Hafs text: Quran Foundation `text_qpc_hafs`, or `ara-quranuthmanihaf` from [fawazahmed0/quran-api](https://github.com/fawazahmed0/quran-api) | `UthmanicHafs1Ver18` (already in `assets/fonts`) | Looks like the printed Madinah Mushaf. The font draws Arabic-Indic digits as the ornamented ayah-end marker, so append `٢٣` after the ayah and you get a correctly aligned marker for free. |
| **IndoPak** | Quran Foundation `text_indopak`, or `ara-quranindopak` from fawazahmed0/quran-api | `indopak-nastaleeq-waqf-lazim-v4.2.1` (from the Quran.com web app, `public/fonts/quran/hafs/nastaleeq/indopak/`) | The style most readers in Pakistan and India learned from. The font has no ayah-marker digits, so draw the number with the Hafs font. |
| **Tajweed colours** | alquran.cloud `quran-tajweed` (inline tags like `[h:1[ٱ]`), or Quran Foundation `text_uthmani_tajweed` | Amiri Quran | Parse the tags into coloured spans. Tag letters: h hamzat al-wasl, s silent, l lam shamsiyyah, n madd 2, p madd 2/4/6, o madd 4/5, m madd 6, q qalqalah, g ghunnah, f ikhfa, c ikhfa shafawi, a idgham with ghunnah, u idgham without ghunnah, w idgham shafawi, d idgham mutajanisayn, b idgham mutaqaribayn, i iqlab. A tag can cross a space, so split into words after parsing. |
| **Uthmani (Amiri)** | alquran.cloud `quran-uthmani` (what the app loads today) | Amiri Quran (already in `assets/fonts`) | The safe pairing for the current text. |
| **Simple** | alquran.cloud `quran-simple` | Scheherazade New or Noto Naskh Arabic (both already bundled) | Modern spelling, no Uthmani marks. Easiest for new readers. |
| Kitab (optional) | alquran.cloud `quran-uthmani-quran-academy` | Kitab (already bundled) | That edition is described by alquran.cloud as "modified to work with the Kitab font". |

Do not pair `me_quran` with the Tanzil text: it showed broken boxes in testing.

## Fixes needed for the fawazahmed0 copies

The fawazahmed0 copies are convenient (plain JSON per surah) but need two clean-ups before display:

1. **Hafs open tanween.** The file replaced the KFGQPC code points U+0657, U+065E, U+0656 with U+08F0,
   U+08F1, U+08F2, and put a space before the alef that follows (`عَمَلࣰ اۚ`). `UthmanicHafs1Ver18` draws
   that as a gap with the tanween missing. Map them back (U+08F0 to U+0657, U+08F1 to U+065E, U+08F2 to
   U+0656) and remove the space before a lone alef. After that, `فِرَٰشٗا` and `عَمَلٗاۚ` render exactly like
   the Mushaf.
2. **IndoPak iqlab split.** Words with the small low meem (U+06ED) are split by a space (`تُنۭۡ بِتُ`).
   Remove the space after U+06ED. Also strip the trailing U+200F mark.

Getting the text from the Quran Foundation API instead (`text_qpc_hafs`, `text_indopak`) avoids both issues
and keeps word positions identical to its audio timings.

## Words, waqf signs and ayah numbers

- Split on spaces, then attach any token without Arabic letters (a waqf sign such as `ۖ` in the Tanzil text)
  to the word before it. Highlighting then moves word by word, never onto a lone sign.
- Draw the ayah number with the Hafs font in every script. It gives one consistent ornament that sits on the
  baseline, which fixes the number spilling out of the bottom of the circle.
- Bismillah: alquran.cloud puts it inside ayah 1 of every surah except 1 and 9. Strip the first four words and
  show it as a header instead. The fawazahmed0 and Quran Foundation texts already leave it out.

## Flutter notes

- Ship each font as an asset and keep a map `script -> (text edition, font family, line height, scale)`.
  IndoPak needs a taller line height (about 2.35) than Hafs (about 2.15).
- Store the text per script in the offline cache so a downloaded surah reads correctly without network.
- Licence: check the King Fahd Complex font terms and the Quran Foundation "Mushaf fonts and images" page
  before shipping fonts taken from the Quran.com repository.
