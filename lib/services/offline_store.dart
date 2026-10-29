import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:oneverse/models/playback_config.dart';
import 'package:path_provider/path_provider.dart';

/// A surah saved for offline use with one specific set of editions.
class OfflinePackage {
  final int surahNumber;
  final String englishName;
  final String arabicName;
  final int numberOfAyahs;
  final PlaybackMode mode;
  final String? audioEdition;
  final String? translationAudioEdition;
  final String textEdition;
  final int sizeBytes;
  final DateTime downloadedAt;

  const OfflinePackage({
    required this.surahNumber,
    required this.englishName,
    required this.arabicName,
    required this.numberOfAyahs,
    required this.mode,
    required this.audioEdition,
    required this.translationAudioEdition,
    required this.textEdition,
    required this.sizeBytes,
    required this.downloadedAt,
  });

  String get key =>
      '$surahNumber|${audioEdition ?? ''}|${translationAudioEdition ?? ''}|$textEdition';

  List<String> get audioEditions => [
        if (audioEdition != null) audioEdition!,
        if (translationAudioEdition != null) translationAudioEdition!,
      ];

  List<String> get textEditions => {
        PlaybackConfig.arabicTextEdition,
        textEdition,
        ...audioEditions,
      }.toList();

  /// Whether this download contains everything [config] needs.
  bool satisfies(PlaybackConfig config) {
    if (config.textEdition != textEdition) return false;
    if (config.needsArabicAudio && config.audioEdition != audioEdition) {
      return false;
    }
    if (config.needsTranslationAudio &&
        config.translationAudioEdition != translationAudioEdition) {
      return false;
    }
    return true;
  }

  /// The config to use when playing this download. [fallbackAudio] fills in
  /// the Arabic reciter for translation-only downloads.
  PlaybackConfig toConfig(String fallbackAudio) => PlaybackConfig(
        audioEdition: audioEdition ?? fallbackAudio,
        translationAudioEdition: translationAudioEdition,
        textEdition: textEdition,
        mode: mode,
      );

  factory OfflinePackage.fromJson(Map<String, dynamic> json) => OfflinePackage(
        surahNumber: json['surahNumber'],
        englishName: json['englishName'],
        arabicName: json['arabicName'] ?? '',
        numberOfAyahs: json['numberOfAyahs'],
        mode: PlaybackModeX.fromName(json['mode']),
        audioEdition: json['audioEdition'],
        translationAudioEdition: json['translationAudioEdition'],
        textEdition: json['textEdition'],
        sizeBytes: json['sizeBytes'] ?? 0,
        downloadedAt: DateTime.tryParse(json['downloadedAt'] ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'surahNumber': surahNumber,
        'englishName': englishName,
        'arabicName': arabicName,
        'numberOfAyahs': numberOfAyahs,
        'mode': mode.name,
        'audioEdition': audioEdition,
        'translationAudioEdition': translationAudioEdition,
        'textEdition': textEdition,
        'sizeBytes': sizeBytes,
        'downloadedAt': downloadedAt.toIso8601String(),
      };
}

/// Thrown when content is not available locally and there is no internet.
class OfflineException implements Exception {
  final String message;
  const OfflineException(
      [this.message = "You're offline and this content isn't downloaded."]);
  @override
  String toString() => message;
}

/// App-private storage for offline surahs, cached API responses and the
/// library index. Layout under <app documents>/offline:
///   audio/<edition>/<surah>/<ayah>.mp3
///   text/<edition>/<surah>.json   (raw API surah object)
///   cache/<key>.json
///   library.json
class OfflineStore with ChangeNotifier {
  OfflineStore._();
  static final OfflineStore instance = OfflineStore._();

  late String _root;
  bool _initialized = false;
  final List<OfflinePackage> _packages = [];
  final Map<String, String> _editionNames = {};

  List<OfflinePackage> get packages {
    final list = List<OfflinePackage>.from(_packages);
    list.sort((a, b) => a.surahNumber.compareTo(b.surahNumber));
    return list;
  }

  int get totalBytes => _packages.fold(0, (sum, p) => sum + p.sizeBytes);

  String? editionName(String? id) => id == null ? null : _editionNames[id];

  Future<void> init() async {
    if (_initialized) return;
    final docs = await getApplicationDocumentsDirectory();
    _root = '${docs.path}/offline';
    await Directory(_root).create(recursive: true);
    _initialized = true;

    final index = File('$_root/library.json');
    if (await index.exists()) {
      try {
        final json = jsonDecode(await index.readAsString());
        _packages.addAll((json['packages'] as List)
            .map((p) => OfflinePackage.fromJson(p)));
        _editionNames.addAll(
            Map<String, String>.from(json['editionNames'] ?? const {}));
      } catch (e) {
        debugPrint('Offline library index unreadable: $e');
      }
    }
    notifyListeners();
  }

  // --- Paths ---

  File audioFile(String edition, int surah, int ayah) =>
      File('$_root/audio/$edition/$surah/$ayah.mp3');

  File _textFile(String edition, int surah) =>
      File('$_root/text/$edition/$surah.json');

  File _cacheFile(String key) => File('$_root/cache/$key.json');

  // --- Surah JSON (text + audio URLs per edition) ---

  Future<void> saveSurahJson(
      String edition, int surah, Map<String, dynamic> json) async {
    await _writeAtomic(_textFile(edition, surah), jsonEncode(json));
  }

  Future<Map<String, dynamic>?> loadSurahJson(String edition, int surah) async {
    final file = _textFile(edition, surah);
    if (!await file.exists()) return null;
    try {
      return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // --- Generic response cache ---

  Future<void> writeCache(String key, Object json) =>
      _writeAtomic(_cacheFile(key), jsonEncode(json));

  Future<dynamic> readCache(String key) async {
    final file = _cacheFile(key);
    if (!await file.exists()) return null;
    try {
      return jsonDecode(await file.readAsString());
    } catch (_) {
      return null;
    }
  }

  // --- Library ---

  OfflinePackage? findPackage(int surah, PlaybackConfig config) {
    for (final p in _packages) {
      if (p.surahNumber == surah && p.satisfies(config)) return p;
    }
    return null;
  }

  bool isAvailable(int surah, PlaybackConfig config) =>
      findPackage(surah, config) != null;

  Future<void> addPackage(OfflinePackage package,
      {Map<String, String> editionNames = const {}}) async {
    _packages.removeWhere((p) => p.key == package.key);
    _packages.add(package);
    _editionNames.addAll(editionNames);
    await _saveIndex();
    notifyListeners();
  }

  Future<void> deletePackage(OfflinePackage package) async {
    _packages.removeWhere((p) => p.key == package.key);
    await _saveIndex();
    await cleanupSurah(package.surahNumber);
    notifyListeners();
  }

  /// Deletes audio for [surah] that no remaining download refers to
  /// (e.g. leftovers from a cancelled download).
  Future<void> cleanupSurah(int surah) async {
    final keep = _packages
        .where((p) => p.surahNumber == surah)
        .expand((p) => p.audioEditions)
        .toSet();
    final audioRoot = Directory('$_root/audio');
    if (!await audioRoot.exists()) return;
    await for (final editionDir in audioRoot.list()) {
      if (editionDir is! Directory) continue;
      final edition = editionDir.path.split('/').last;
      if (keep.contains(edition)) continue;
      final surahDir = Directory('${editionDir.path}/$surah');
      if (await surahDir.exists()) await surahDir.delete(recursive: true);
    }
  }

  Future<int> audioBytes(List<String> editions, int surah) async {
    int total = 0;
    for (final edition in editions) {
      final dir = Directory('$_root/audio/$edition/$surah');
      if (!await dir.exists()) continue;
      await for (final f in dir.list()) {
        if (f is File) total += await f.length();
      }
    }
    return total;
  }

  Future<void> _saveIndex() => _writeAtomic(
        File('$_root/library.json'),
        jsonEncode({
          'packages': _packages.map((p) => p.toJson()).toList(),
          'editionNames': _editionNames,
        }),
      );

  Future<void> _writeAtomic(File file, String content) async {
    await file.parent.create(recursive: true);
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(content, flush: true);
    await tmp.rename(file.path);
  }
}

/// Cheap reachability check for the Quran API host.
Future<bool> hasInternet() async {
  try {
    final result = await InternetAddress.lookup('api.alquran.cloud')
        .timeout(const Duration(seconds: 3));
    return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
  } catch (_) {
    return false;
  }
}
