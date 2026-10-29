import 'package:flutter_test/flutter_test.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:oneverse/data/cache_store_memory.dart';
import 'package:oneverse/data/catalog.dart';
import 'package:oneverse/data/models.dart';
import 'package:oneverse/data/network.dart';
import 'package:oneverse/data/repository.dart';
import 'package:oneverse/state/listening_log.dart';
import 'package:oneverse/state/reminders.dart';
import 'package:oneverse/ui/screens/home_screen.dart';
import 'package:oneverse/ui/widgets/quran_text.dart';

void main() {
  group('Quran.com word parsing', () {
    test('keeps only words, one list per script, same positions', () {
      final verses = QuranRepository.parseQuranComVerses([
        {
          'verse_number': 2,
          'page_number': 562,
          'juz_number': 29,
          'words': [
            for (var i = 1; i <= 3; i++)
              {
                'char_type_name': 'word',
                'text_qpc_hafs': 'h$i',
                'text_indopak': 'i$i‏',
                'text_uthmani': 'u$i',
                'text_imlaei': 's$i',
                'text_uthmani_tajweed': '<rule class=ham_wasl>ٱ</rule>t$i',
              },
            {'char_type_name': 'end', 'text_qpc_hafs': '٢'},
          ],
        }
      ]);
      final v = verses.single;
      expect(v.ayah, 2);
      expect(v.page, 562);
      expect(v.wordCount, 3);
      for (final s in QuranScript.values) {
        expect(v.of(s).length, 3, reason: s.name);
      }
      expect(v.of(QuranScript.indopak).first, 'i1', reason: 'RTL mark stripped');
      final round = VerseText.fromJson(v.toJson());
      expect(round.of(QuranScript.tajweed), v.of(QuranScript.tajweed));
    });
  });

  group('timings', () {
    final t = QuranRepository.parseQdcTiming({
      'audio_url': 'https://x/67.mp3',
      'verse_timings': [
        {
          'timestamp_from': 0,
          'timestamp_to': 1000,
          'segments': [
            [1, 0, 300],
            [2, 300, 600],
            [3, 600, 1000],
            [30, 2466306], // malformed rows from the API are dropped
          ],
        },
        {'timestamp_from': 1000, 'timestamp_to': 1000, 'segments': [], 'left_out': true},
        {
          'timestamp_from': 1000,
          'timestamp_to': 2000,
          'segments': [
            [1, 1000, 1500],
            [2, 1500, 2000],
          ],
        },
      ],
    });

    test('drops malformed segments', () => expect(t.ayahs.first.segments.length, 3));

    test('finds the ayah playing at a time', () {
      expect(t.ayahAt(500), 0);
      expect(t.ayahAt(1200), 2, reason: 'zero-length (untimed) ayah is skipped');
    });

    test('maps time to the word being recited', () {
      final a = t.ayahs.first;
      expect(wordAt(a, -1, 3), -1);
      expect(wordAt(a, 0, 3), 0);
      expect(wordAt(a, 450, 3), 1);
      expect(wordAt(a, 999, 3), 2);
    });

    test('maps proportionally when a script splits words differently', () {
      expect(wordAt(t.ayahs.first, 650, 6), 4);
    });

    test('untimed ayah is shown fully lit', () => expect(wordAt(t.ayahs[1], 1000, 4), 4));

    test('json round trip', () {
      final r = SurahTiming.fromJson(t.toJson());
      expect(r.audioUrl, t.audioUrl);
      expect(r.ayahs.length, 3);
    });
  });

  group('tajweed', () {
    test('parses rule runs', () {
      final r = parseTajweed('وَ<rule class=ham_wasl>ٱ</rule>لۡحَيَ<rule class=slnt>و</rule>ةَ');
      expect(r.map((e) => e.rule).toList(), [null, 'ham_wasl', null, 'slnt', null]);
      expect(r.map((e) => e.text).join(), 'وَٱلۡحَيَوةَ');
    });
    test('splits words without breaking tags', () {
      final w = splitWords(bismillahByScript[QuranScript.tajweed]!);
      expect(w.length, 4);
      expect(w.every((x) => parseTajweed(x).every((r) => !r.text.contains('<'))), isTrue);
    });
    test('every script has a Bismillah', () {
      for (final s in QuranScript.values) {
        expect(bismillahByScript[s], isNotNull);
      }
    });
  });

  group('our streak algorithm', () {
    late ListeningLog log;
    setUp(() => log = ListeningLog(store: MemoryCacheStore()));
    final today = DateTime(2026, 10, 29, 9);

    test('counts consecutive days with a minute or more', () {
      for (var i = 0; i < 5; i++) {
        log.add(120, reciterId: 'ar.alafasy', surah: 67, at: today.subtract(Duration(days: i)));
      }
      expect(log.currentStreak(today), 5);
    });

    test('stays alive through today before the first listen', () {
      log.add(120, reciterId: 'a', surah: 1, at: DateTime(2026, 10, 28, 20));
      log.add(120, reciterId: 'a', surah: 1, at: DateTime(2026, 10, 27, 20));
      expect(log.currentStreak(today), 2);
    });

    test('a short listen does not count, a gap breaks the streak', () {
      log.add(30, reciterId: 'a', surah: 1, at: DateTime(2026, 10, 29, 8));
      log.add(120, reciterId: 'a', surah: 1, at: DateTime(2026, 10, 27, 8));
      expect(log.currentStreak(today), 0);
      log.add(120, reciterId: 'a', surah: 1, at: DateTime(2026, 10, 26, 8));
      expect(log.bestStreak(), 2);
    });

    test('series and top lists', () {
      log.add(600, reciterId: 'ar.alafasy', surah: 67, at: today);
      log.add(300, reciterId: 'ov.luhaidan', surah: 18, at: today);
      expect(log.series('day', today)[9].minutes, 15);
      expect(log.series('week', today).length, 7);
      expect(log.series('month', today).last.minutes, 15);
      expect(log.series('year', today).length, 12);
      expect(log.top('reciter', now: today).first.key, 'ar.alafasy');
      expect(log.top('surah', now: today).first.key, '67');
    });
  });

  group('special days and moments', () {
    test('finds Ramadan, the odd nights, Arafah and both Eids within a year', () {
      final days = upcomingSpecialDays(DateTime(2026, 10, 29));
      final titles = days.map((d) => d.title).toSet();
      expect(titles, containsAll(['Ramadan Mubarak', 'One of the last ten nights', 'Eid Mubarak', 'The Day of Arafah', 'Eid al-Adha Mubarak']));
      for (final d in days.where((d) => d.title == 'Ramadan Mubarak')) {
        final h = HijriCalendar.fromDate(d.date);
        expect((h.hMonth, h.hDay), (9, 1));
      }
      expect(days.where((d) => d.title == 'One of the last ten nights').length, 5);
    });

    test('Friday suggests Al-Kahf, night suggests Al-Mulk', () {
      final fridayNight = DateTime(2026, 10, 30, 22); // a Friday
      final m = momentsFor(fridayNight).map((m) => m.surah).toList();
      expect(m, contains(18));
      expect(m, contains(67));
      final thursdayMorning = DateTime(2026, 10, 29, 8);
      expect(momentsFor(thursdayMorning).map((m) => m.surah), contains(36));
    });
  });

  group('offline policy', () {
    test('Wi-Fi refreshes after 3 days, mobile data only after 30, offline never', () {
      expect(SyncPolicy.needsRefresh(const Duration(days: 2), NetKind.unmetered), isFalse);
      expect(SyncPolicy.needsRefresh(const Duration(days: 4), NetKind.unmetered), isTrue);
      expect(SyncPolicy.needsRefresh(const Duration(days: 10), NetKind.metered), isFalse);
      expect(SyncPolicy.needsRefresh(const Duration(days: 31), NetKind.metered), isTrue);
      expect(SyncPolicy.needsRefresh(const Duration(days: 90), NetKind.offline), isFalse);
    });

    test('cached data is served even when it is old and the device is offline', () async {
      final store = MemoryCacheStore();
      NetworkStatus.instance.debugSet(NetKind.offline);
      final repo = QuranRepository(store: store);
      await store.write(QuranRepository.trKey('en.sahih', 1), ['a', 'b'], fetchedAt: DateTime(2020));
      expect(await repo.translation('en.sahih', 1), ['a', 'b']);
      NetworkStatus.instance.debugSet(NetKind.unmetered);
    });
  });

  group('catalog', () {
    test('ids are unique and every reciter can play', () {
      final ids = [...reciters, ...translationVoices].map((r) => r.id).toList();
      expect(ids.toSet().length, ids.length);
      for (final r in reciters) {
        expect(r.ayahEdition != null || r.timing != null, isTrue, reason: r.id);
      }
      for (final v in translationVoices) {
        expect(v.ayahEdition, isNotNull);
        expect(v.textEdition, isNotNull);
      }
    });
  });
}
