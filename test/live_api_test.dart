@Tags(['live'])
@Timeout(Duration(minutes: 10))
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oneverse/data/cache_store_memory.dart';
import 'package:oneverse/data/catalog.dart';
import 'package:oneverse/data/downloads.dart';
import 'package:oneverse/data/models.dart';
import 'package:oneverse/data/repository.dart';
import 'package:oneverse/data/tafsir.dart';

/// Hits every real API the app uses. Run with: flutter test --tags live
void main() {
  final repo = QuranRepository(store: MemoryCacheStore());

  test('Quran.com words: all five scripts, same word count, every ayah', () async {
    for (final (n, count) in [(1, 7), (67, 30), (2, 286), (114, 6)]) {
      final verses = await repo.words(n);
      expect(verses.length, count, reason: 'surah $n');
      for (final v in verses) {
        final w = v.wordCount;
        expect(w, greaterThan(0));
        for (final s in QuranScript.values) {
          expect(v.of(s).length, w, reason: '$n:${v.ayah} ${s.name}');
          expect(v.of(s).every((x) => x.isNotEmpty), isTrue, reason: '$n:${v.ayah} ${s.name} has an empty word');
        }
      }
    }
    final v = (await repo.words(67))[1];
    expect(v.of(QuranScript.hafs).first, startsWith('ٱل'));
    expect(v.of(QuranScript.tajweed).any((x) => x.contains('<rule class=')), isTrue);
    expect(v.of(QuranScript.hafs).join(' '), contains('عَمَلٗاۚ'), reason: 'QPC open tanween U+0657 for the Hafs font');
  });

  test('alquran.cloud translations and translation list', () async {
    for (final ed in ['en.sahih', 'en.asad', 'ur.jalandhry', 'fr.hamidullah', 'ru.kuliev', 'fa.fooladvand', 'zh.jian', 'uz.sodik', 'tr.vakfi']) {
      final t = await repo.translation(ed, 67);
      expect(t.length, 30, reason: ed);
      expect(t.first.trim(), isNotEmpty, reason: ed);
    }
    await repo.loadTranslationList();
    expect(repo.translationList.length, greaterThan(100));
    expect(repo.translationList.map((t) => t.id), containsAll(defaultQuickTranslations));
  });

  test('ayah-by-ayah audio for every reciter and translation voice', () async {
    for (final r in [...reciters, ...translationVoices].where((r) => r.ayahEdition != null)) {
      final urls = await repo.ayahAudio(r.ayahEdition!, 112);
      expect(urls.length, 4, reason: r.id);
      expect(urls.first, startsWith('https://'), reason: r.id);
    }
  });

  test('word timings for every reciter that has them', () async {
    for (final r in reciters.where((r) => r.hasWordSync)) {
      for (final n in [1, 67, 114]) {
        final t = await repo.timing(r, n);
        expect(t, isNotNull, reason: '${r.id} $n');
        final verses = await repo.words(n);
        expect(t!.ayahs.length, verses.length, reason: '${r.id} $n');
        expect(t.audioUrl, startsWith('https://'));
        var exact = 0;
        for (var i = 0; i < verses.length; i++) {
          final segs = t.ayahs[i].segments;
          if (segs.isEmpty) continue;
          final maxPos = segs.map((s) => s[0]).reduce((a, b) => a > b ? a : b);
          if (maxPos == verses[i].wordCount) exact++;
          expect(t.ayahs[i].to, greaterThanOrEqualTo(t.ayahs[i].from));
        }
        expect(exact / verses.length, greaterThan(0.85), reason: '${r.id} $n word positions match the text');
      }
    }
  });

  test('every mp3quran reciter: full surahs answer, timings line up', () async {
    for (final r in reciters.where((r) => r.timing?.kind == TimingKind.mp3quran)) {
      final t = (await repo.timing(r, 67))!;
      final head = await repo.api.dio.head<void>(t.audioUrl);
      expect(head.statusCode, 200, reason: '${r.id} ${t.audioUrl}');
      if (r.timing!.read == null) {
        expect(t.ayahs, isEmpty, reason: '${r.id}: estimated by the player');
        continue;
      }
      expect(t.ayahs, hasLength(30), reason: r.id);
      for (var i = 1; i < 30; i++) {
        expect(t.ayahs[i].from, greaterThanOrEqualTo(t.ayahs[i - 1].from), reason: '${r.id} ayah ${i + 1}');
      }
      expect(t.ayahs.first.from, greaterThan(0), reason: r.id);
    }
  });

  test('size of the complete Quran for each kind of reciter', () async {
    final dl = Downloads(repo);
    final sizes = {
      for (final id in ['ar.alafasy', 'ar.mahermuaiqly', 'ov.luhaidan', 'ar.husarymujawwad', 'ar.muhammadayyoub'])
        id: await dl.estimateQuranBytes(reciterById(id)),
      'ov.saadghamdi': await dl.estimateQuranBytes(reciterById('ov.saadghamdi')),
    };
    for (final e in sizes.entries) {
      expect(e.value, inInclusiveRange(4e8, 4e9), reason: '${e.key}: ${e.value}');
    }
    expect(sizes['ar.alafasy'], inInclusiveRange(1.6e9, 1.9e9), reason: 'exact Quran.com file sizes');
    final withUrdu = await dl.estimateQuranBytes(reciterById('ar.alafasy'), voice: reciterById('ur.khan'));
    expect(withUrdu! - sizes['ar.alafasy']!, inInclusiveRange(1e8, 1.5e9));
  });

  test('ayah lengths from file sizes add up to the surah', () async {
    final dl = Downloads(repo);
    // Al-Ikhlas by Alafasy: the ayah files should add up to its full-surah file.
    final ayahs = await dl.ayahDurations('ar.alafasy', 112);
    expect(ayahs, hasLength(4));
    expect(ayahs.every((ms) => ms != null && ms > 1500 && ms < 20000), isTrue, reason: '$ayahs');
    final full = (await repo.timing(reciterById('ar.alafasy'), 112))!;
    final total = ayahs.fold<int>(0, (t, ms) => t + ms!);
    expect((total - full.ayahs.last.to).abs(), lessThan(4000), reason: 'ayah files $total ms, full surah ${full.ayahs.last.to} ms');
  });

  test('QuranHub reciter photos and bios', () async {
    await repo.loadProfiles();
    final withPhoto = reciters.where((r) => repo.profileOf(r)?.imageUrl != null).length;
    expect(withPhoto, greaterThanOrEqualTo(22));
    expect(repo.profileOf(reciters.first)!.country, 'Kuwait');
    expect(repo.profileOf(reciters.first)!.bio, isNotEmpty);
  });

  test('tafsir: every book answers for Ayat al-Kursi', () async {
    for (final b in tafsirBooks) {
      final e = await repo.tafsir(b.id, 2, 255);
      expect(e.blocks, isNotEmpty, reason: b.name);
      expect(e.verses, contains('2:255'), reason: b.name);
      if (b.urdu) expect(e.blocks.first.text, matches(RegExp('[\u0600-\u06FF]')), reason: b.name);
    }
  });
}
