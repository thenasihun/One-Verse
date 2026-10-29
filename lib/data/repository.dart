import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'api.dart';
import 'cache_store.dart';
import 'catalog.dart';
import 'models.dart';
import 'network.dart';

/// How long data stays usable offline, and when it is refreshed.
class SyncPolicy {
  /// Everything downloaded stays usable offline for at least this long.
  static const keep = Duration(days: 30);

  /// On Wi-Fi, anything older than this is refreshed in the background, so the
  /// 30-day window keeps moving forward.
  static const wifiRefresh = Duration(days: 3);

  static bool needsRefresh(Duration age, NetKind net) => switch (net) {
        NetKind.unmetered => age > wifiRefresh,
        NetKind.metered => age > keep,
        NetKind.offline => false,
      };
}

/// All Quran data, offline first: every read comes from [CacheStore]; the
/// network only fills or refreshes it.
class QuranRepository extends ChangeNotifier {
  QuranRepository({CacheStore? store, Api? api, NetworkStatus? net})
      : store = store ?? CacheStore.instance,
        api = api ?? Api.instance,
        net = net ?? NetworkStatus.instance;

  final CacheStore store;
  final Api api;
  final NetworkStatus net;

  List<SurahInfo> surahs = const [];
  Map<String, ReciterProfile> profiles = const {};
  List<TranslationEdition> translationList = knownTranslations;
  final Map<String, Set<int>> _githubChapters = {};
  final Map<String, Future> _inflight = {};

  SurahInfo surah(int n) => surahs[n - 1];

  Future<void> init() async {
    final raw = await rootBundle.loadString('assets/data/surahs.json');
    surahs = [for (final j in jsonDecode(raw) as List) SurahInfo.fromJson(j as Map<String, dynamic>)];
    unawaited(loadProfiles());
    unawaited(loadTranslationList());
  }

  // ---------------------------------------------------------------- generic

  /// Returns cached data at once when present (refreshing it in the background
  /// when the policy says so); otherwise fetches it.
  Future<T> _cached<T>(String key, Future<Object?> Function() fetch, T Function(Object? json) parse,
      {bool force = false}) async {
    final entry = await store.read(key);
    if (entry != null && !force) {
      if (SyncPolicy.needsRefresh(entry.age, net.kind)) {
        unawaited(_refresh(key, fetch).catchError((_) => null));
      }
      return parse(entry.data);
    }
    try {
      final data = await _refresh(key, fetch);
      return parse(data);
    } catch (e) {
      if (entry != null) return parse(entry.data);
      rethrow;
    }
  }

  Future<Object?> _refresh(String key, Future<Object?> Function() fetch) {
    return (_inflight[key] ??= () async {
      try {
        final data = await fetch();
        await store.write(key, data);
        return data;
      } finally {
        _inflight.remove(key);
      }
    }());
  }

  Future<bool> isCached(String key) async => await store.read(key) != null;

  // ---------------------------------------------------------------- words

  static String wordsKey(int n) => 'words_$n';

  /// Every ayah of surah [n] in all five scripts (Quran.com word data).
  Future<List<VerseText>> words(int n, {bool force = false}) => _cached(
        wordsKey(n),
        () => fetchWords(n),
        (j) => [for (final v in j as List) VerseText.fromJson(Map<String, dynamic>.from(v as Map))],
        force: force,
      );

  Future<Object?> fetchWords(int n) async {
    const fields = 'text_qpc_hafs,text_indopak,text_uthmani,text_imlaei,text_uthmani_tajweed';
    final verses = <dynamic>[];
    var page = 1;
    while (true) {
      final d = await api.getJson('${Endpoints.quranCom}/verses/by_chapter/$n',
          query: {'words': 'true', 'word_fields': fields, 'per_page': 50, 'page': page});
      verses.addAll(d['verses'] as List);
      final next = d['pagination']?['next_page'];
      if (next == null) break;
      page = next as int;
    }
    return [for (final v in parseQuranComVerses(verses)) v.toJson()];
  }

  static List<VerseText> parseQuranComVerses(List verses) {
    return [
      for (final v in verses)
        () {
          final ws = [for (final w in v['words'] as List) if (w['char_type_name'] == 'word') w];
          String clean(Object? s) => (s as String? ?? '').replaceAll('‏', '').trim();
          return VerseText(
            v['verse_number'] as int,
            v['page_number'] as int? ?? 0,
            v['juz_number'] as int? ?? 0,
            {
              QuranScript.hafs: [for (final w in ws) clean(w['text_qpc_hafs'])],
              QuranScript.indopak: [for (final w in ws) clean(w['text_indopak'])],
              QuranScript.uthmani: [for (final w in ws) clean(w['text_uthmani'])],
              QuranScript.simple: [for (final w in ws) clean(w['text_imlaei'])],
              QuranScript.tajweed: [for (final w in ws) clean(w['text_uthmani_tajweed'])],
            },
          );
        }(),
    ];
  }

  // ---------------------------------------------------------------- translations

  static String trKey(String ed, int n) => 'tr_${ed}_$n';

  Future<List<String>> translation(String edition, int n, {bool force = false}) => _cached(
        trKey(edition, n),
        () async {
          final d = await api.getJson('${Endpoints.alquran}/surah/$n/$edition');
          return [for (final a in d['data']['ayahs'] as List) (a['text'] as String).trim()];
        },
        (j) => List<String>.from(j as List),
        force: force,
      );

  Future<void> loadTranslationList() async {
    try {
      translationList = await _cached(
        'translation_list',
        () async {
          final d = await api.getJson('${Endpoints.alquran}/edition', query: {'format': 'text', 'type': 'translation'});
          return [for (final e in d['data'] as List) TranslationEdition.fromJson(e as Map<String, dynamic>).toJson()];
        },
        (j) => [for (final e in j as List) TranslationEdition.fromJson(Map<String, dynamic>.from(e as Map))],
      );
      notifyListeners();
    } catch (_) {}
  }

  TranslationEdition translationById(String id) => translationList.firstWhere((t) => t.id == id,
      orElse: () => knownTranslations.firstWhere((t) => t.id == id,
          orElse: () => TranslationEdition(id, id, id, id.split('.').first)));

  // ---------------------------------------------------------------- audio

  static String ayahAudioKey(String ed, int n) => 'audio_${ed}_$n';

  /// Ayah-by-ayah audio URLs (alquran.cloud) for an edition.
  Future<List<String>> ayahAudio(String edition, int n) => _cached(
        ayahAudioKey(edition, n),
        () async {
          final d = await api.getJson('${Endpoints.alquran}/surah/$n/$edition');
          return [for (final a in d['data']['ayahs'] as List) a['audio'] as String];
        },
        (j) => List<String>.from(j as List),
      );

  static String timingKey(String reciter, int n) => 'timing_${reciter}_$n';

  /// Full-surah audio with word timings, or null when this reciter has none
  /// for surah [n].
  Future<SurahTiming?> timing(Reciter r, int n, {bool force = false}) async {
    final t = r.timing;
    if (t == null) return null;
    if (t.kind == TimingKind.github && t.slug != 'luhaidan') {
      final chapters = await githubChapters(t.slug!);
      if (chapters != null && !chapters.contains(n)) return null;
    }
    try {
      return await _cached(timingKey(r.id, n), () => fetchTiming(t, n), (j) => SurahTiming.fromJson(Map<String, dynamic>.from(j as Map)),
          force: force);
    } on NetworkException catch (e) {
      if (e.offline) rethrow;
      return null;
    }
  }

  Future<Object?> fetchTiming(TimingSource t, int n) async {
    if (t.kind == TimingKind.qdc) {
      final d = await api.getJson('${Endpoints.qdc}/audio/reciters/${t.qdcId}/audio_files', query: {'chapter': n, 'segments': 'true'});
      return parseQdcTiming((d['audio_files'] as List).first as Map).toJson();
    }
    if (t.slug == 'luhaidan') {
      final d = await api.getJson('${Endpoints.luhaidan}/${n.toString().padLeft(3, '0')}.json');
      return parseQdcTiming(d as Map).toJson();
    }
    final d = await api.getJson('${Endpoints.baklarrrr}/timings/${t.slug}/$n.json');
    return parseQdcTiming(d['audio_file'] as Map).toJson();
  }

  /// Parses Quran.com's chapter-recitation shape (also used by the GitHub
  /// timing projects). Malformed segments are dropped.
  static SurahTiming parseQdcTiming(Map j) {
    final list = (j['verse_timings'] ?? j['timestamps']) as List;
    return SurahTiming(j['audio_url'] as String, [
      for (final v in list)
        AyahTiming(
          (v['timestamp_from'] as num).toInt(),
          (v['timestamp_to'] as num).toInt(),
          [
            for (final s in (v['segments'] as List? ?? const []))
              if (s is List && s.length == 3 && s.every((x) => x is num)) [for (final x in s) (x as num).toInt()]
          ],
        ),
    ]);
  }

  Future<Set<int>?> githubChapters(String slug) async {
    final c = _githubChapters[slug];
    if (c != null) return c;
    try {
      final all = await _cached('baklarrrr_reciters', () => api.getJson('${Endpoints.baklarrrr}/reciters.json'), (j) => j);
      for (final r in (all as Map)['reciters'] as List) {
        _githubChapters[r['id'] as String] = {for (final c in r['chapters'] as List) c as int};
      }
    } catch (_) {
      return null;
    }
    return _githubChapters[slug];
  }

  // ---------------------------------------------------------------- reciter profiles

  Future<void> loadProfiles() async {
    try {
      profiles = await _cached('quranhub_profiles', () async {
        final d = await api.getJson('${Endpoints.quranHub}/edition/format/audio');
        return parseQuranHub(d['data'] as List);
      }, (j) => {
            for (final e in (j as Map).entries)
              e.key as String: ReciterProfile(
                country: e.value['country'] as String?,
                bio: e.value['bio'] as String?,
                nameAr: e.value['nameAr'] as String?,
                imageUrl: e.value['image'] as String?,
              ),
          });
      notifyListeners();
    } catch (_) {}
  }

  static Map<String, dynamic> parseQuranHub(List editions) => {
        for (final e in editions)
          if (e is Map && e['identifier'] != null)
            e['identifier'] as String: {
              'country': (e['nationality'] as Map?)?['en'],
              'bio': (e['shortDescription'] as Map?)?['en'],
              'nameAr': e['name'],
              'image': e['imageUrl'],
            },
      };

  ReciterProfile? profileOf(Reciter r) => r.quranHubId == null ? null : profiles[r.quranHubId];
}
