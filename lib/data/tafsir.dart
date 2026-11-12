/// Tafsir (commentary) books served by Quran.com, one ayah at a time.
class TafsirBook {
  final int id;
  final String name, author, language; // language: ur, en, ar
  const TafsirBook(this.id, this.name, this.author, this.language);

  bool get rtl => language != 'en';
  bool get urdu => language == 'ur';
  String get languageName => const {'ur': 'Urdu', 'en': 'English', 'ar': 'Arabic'}[language] ?? language;
}

const tafsirBooks = [
  TafsirBook(160, 'Tafsir Ibn Kathir', 'Hafiz Ibn Kathir', 'ur'),
  TafsirBook(159, 'Bayan ul Quran', 'Dr. Israr Ahmad', 'ur'),
  TafsirBook(818, 'Tazkir ul Quran', 'Maulana Wahiduddin Khan', 'ur'),
  TafsirBook(157, 'Fi Zilal al-Quran', 'Sayyid Qutb', 'ur'),
  TafsirBook(169, 'Ibn Kathir (Abridged)', 'Hafiz Ibn Kathir', 'en'),
  TafsirBook(168, "Ma'arif al-Qur'an", 'Mufti Muhammad Shafi', 'en'),
  TafsirBook(817, 'Tazkirul Quran', 'Maulana Wahiduddin Khan', 'en'),
  TafsirBook(16, 'Tafsir al-Muyassar', 'King Fahd Complex', 'ar'),
  TafsirBook(91, "Tafsir al-Sa'di", "Abdur-Rahman al-Sa'di", 'ar'),
];

TafsirBook tafsirById(int id) => tafsirBooks.firstWhere((b) => b.id == id, orElse: () => tafsirBooks.first);

/// The book to open first: Urdu for Urdu readers, Arabic for Arabic, English
/// otherwise.
int defaultTafsirFor(String translationId) {
  final lang = translationId.split('.').first;
  return lang == 'ur' ? 160 : lang == 'ar' ? 16 : 169;
}

/// One paragraph of commentary.
class TafsirBlock {
  final String text;
  final bool heading;
  const TafsirBlock(this.text, {this.heading = false});
}

/// The commentary for one ayah. [verses] are the ayah keys it explains
/// together (some books explain a group of ayahs at once).
class TafsirEntry {
  final List<TafsirBlock> blocks;
  final List<String> verses;
  const TafsirEntry(this.blocks, this.verses);

  bool get isEmpty => blocks.isEmpty;
}

/// Turns the HTML the API returns into plain paragraphs and headings.
List<TafsirBlock> parseTafsirHtml(String html) {
  final out = <TafsirBlock>[];
  // Mark block boundaries, keeping whether the block was a heading.
  var s = html
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAllMapped(RegExp(r'<h[1-6][^>]*>', caseSensitive: false), (_) => '\n\u0001')
      .replaceAll(RegExp(r'</h[1-6]>', caseSensitive: false), '\u0002\n')
      .replaceAll(RegExp(r'</?(p|div|li|ul|ol|blockquote)[^>]*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '');
  s = _decodeEntities(s);
  for (final raw in s.split('\n')) {
    final heading = raw.contains('\u0001') || raw.contains('\u0002');
    final text = raw.replaceAll(RegExp('[\u0001\u0002]'), '').replaceAll(RegExp(r'[ \t ]+'), ' ').trim();
    if (text.isEmpty) continue;
    out.add(TafsirBlock(text, heading: heading && text.length < 160));
  }
  return out;
}

String _decodeEntities(String s) => s
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .replaceAll('&apos;', "'")
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAllMapped(RegExp(r'&#(\d+);'), (m) => String.fromCharCode(int.parse(m[1]!)))
    .replaceAll('&amp;', '&');
