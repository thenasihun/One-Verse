import 'package:flutter/foundation.dart';

/// A Quran script is a text field paired with the font it was encoded for.
enum QuranScript {
  hafs('Madani · KFGQPC Hafs', 'Madani', 'UthmanicHafs', 2.15, 1.0,
      'King Fahd Complex text in its own Hafs font. Same look as the printed Madinah Mushaf.'),
  indopak('IndoPak · Nastaleeq', 'IndoPak', 'IndoPakNastaleeq', 2.35, 0.98,
      'The South Asian style most readers in Pakistan and India learned from.'),
  tajweed('Tajweed colours', 'Tajweed', 'AmiriQuran', 2.2, 1.0, 'Uthmani text with colour-coded tajweed rules.'),
  uthmani('Uthmani · Amiri Quran', 'Uthmani', 'AmiriQuran', 2.2, 1.0, 'Uthmani text in the Amiri Quran font.'),
  simple('Simple · Naskh', 'Simple', 'ScheherazadeNew', 1.9, 1.06,
      'Modern spelling without Uthmani marks. Easiest for new readers.');

  final String title, short, fontFamily, note;
  final double lineHeight, scale;
  const QuranScript(this.title, this.short, this.fontFamily, this.lineHeight, this.scale, this.note);

  static QuranScript byName(String? n) => values.firstWhere((s) => s.name == n, orElse: () => hafs);
}

@immutable
class SurahInfo {
  final int number, ayahs;
  final String nameAr, nameEn, meaning;
  final bool meccan;
  const SurahInfo(this.number, this.nameAr, this.nameEn, this.meaning, this.ayahs, this.meccan);

  String get type => meccan ? 'Meccan' : 'Medinan';

  factory SurahInfo.fromJson(Map<String, dynamic> j) => SurahInfo(
        j['number'] as int,
        (j['name'] as String).replaceAll('سُورَةُ ', '').replaceAll('سورة ', ''),
        j['englishName'] as String,
        j['englishNameTranslation'] as String,
        j['numberOfAyahs'] as int,
        j['revelationType'] == 'Meccan',
      );
}

/// One ayah's words in every script. Word lists share Quran.com word positions,
/// which are also the positions used by the word timings.
@immutable
class VerseText {
  final int ayah, page, juz;
  final Map<QuranScript, List<String>> words;
  const VerseText(this.ayah, this.page, this.juz, this.words);

  List<String> of(QuranScript s) => words[s] ?? words[QuranScript.uthmani] ?? const [];
  String plain([QuranScript s = QuranScript.uthmani]) =>
      of(s).join(' ').replaceAll(RegExp(r'<[^>]+>'), '');
  int get wordCount => of(QuranScript.hafs).length;

  Map<String, dynamic> toJson() => {
        'a': ayah,
        'p': page,
        'j': juz,
        'w': {for (final e in words.entries) e.key.name: e.value},
      };

  factory VerseText.fromJson(Map<String, dynamic> j) => VerseText(
        j['a'] as int,
        j['p'] as int? ?? 0,
        j['j'] as int? ?? 0,
        {
          for (final e in (j['w'] as Map).entries)
            QuranScript.byName(e.key as String): List<String>.from(e.value as List)
        },
      );
}

enum TimingKind { qdc, github }

/// Where a reciter's full-surah audio and word timings come from.
@immutable
class TimingSource {
  final TimingKind kind;
  final int? qdcId;
  final String? slug; // baklarrrr reciter slug or 'luhaidan'
  const TimingSource.qdc(int id)
      : kind = TimingKind.qdc,
        qdcId = id,
        slug = null;
  const TimingSource.github(String s)
      : kind = TimingKind.github,
        qdcId = null,
        slug = s;
}

@immutable
class Reciter {
  final String id, name, initials, style;
  final String? ayahEdition; // alquran.cloud ayah-by-ayah edition
  final TimingSource? timing;
  final String? quranHubId;
  final String? language; // set for translation voices
  final String? textEdition; // translation text that matches a translation voice
  const Reciter({
    required this.id,
    required this.name,
    required this.initials,
    this.style = 'Murattal',
    this.ayahEdition,
    this.timing,
    this.quranHubId,
    this.language,
    this.textEdition,
  });

  bool get isTranslationVoice => language != null;
  bool get hasWordSync => timing != null;
}

@immutable
class ReciterProfile {
  final String? country, bio, nameAr, imageUrl;
  const ReciterProfile({this.country, this.bio, this.nameAr, this.imageUrl});
}

@immutable
class TranslationEdition {
  final String id, name, englishName, language;
  const TranslationEdition(this.id, this.name, this.englishName, this.language);

  bool get rtl => const {'ur', 'fa', 'ar', 'ps', 'sd', 'ug', 'dv', 'ku', 'he'}.contains(language);
  bool get urdu => language == 'ur';

  factory TranslationEdition.fromJson(Map<String, dynamic> j) => TranslationEdition(
        j['identifier'] as String,
        (j['name'] as String?) ?? j['identifier'] as String,
        (j['englishName'] as String?) ?? '',
        (j['language'] as String?) ?? '',
      );

  Map<String, dynamic> toJson() => {'identifier': id, 'name': name, 'englishName': englishName, 'language': language};
}

/// Timing of one ayah inside a full-surah audio file, in milliseconds.
@immutable
class AyahTiming {
  final int from, to;
  final List<List<int>> segments; // [word position (1-based), start, end]
  const AyahTiming(this.from, this.to, this.segments);
}

@immutable
class SurahTiming {
  final String audioUrl;
  final List<AyahTiming> ayahs;
  const SurahTiming(this.audioUrl, this.ayahs);

  /// Index of the ayah playing at [ms], or -1 before the first ayah.
  int ayahAt(int ms) {
    for (var i = ayahs.length - 1; i >= 0; i--) {
      if (ms >= ayahs[i].from) return i;
    }
    return -1;
  }

  Map<String, dynamic> toJson() => {
        'u': audioUrl,
        'v': [
          for (final a in ayahs) [a.from, a.to, a.segments]
        ],
      };

  factory SurahTiming.fromJson(Map<String, dynamic> j) => SurahTiming(
        j['u'] as String,
        [
          for (final v in j['v'] as List)
            AyahTiming((v as List)[0] as int, v[1] as int, [
              for (final s in v[2] as List) List<int>.from(s as List),
            ]),
        ],
      );
}

/// Which word is being recited at [ms] inside an ayah, mapped to a script that
/// has [wordCount] words. Returns -1 before the first word.
int wordAt(AyahTiming t, int ms, int wordCount) {
  if (t.segments.isEmpty) return wordCount; // untimed ayah: shown fully lit
  var pos = 0;
  var maxPos = 0;
  for (final s in t.segments) {
    if (s[0] > maxPos) maxPos = s[0];
    if (s[1] <= ms) pos = s[0];
  }
  if (pos == 0) return -1;
  if (maxPos == wordCount || maxPos == 0) return (pos - 1).clamp(0, wordCount - 1);
  return ((pos - 1) * wordCount / maxPos).floor().clamp(0, wordCount - 1);
}

enum ListenMode { arabic, arabicTranslation, translation }

enum ShowMode { both, arabic, translation }
