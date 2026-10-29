import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oneverse/models/playback_config.dart';
import 'package:oneverse/models/surah_model.dart';
import 'package:oneverse/providers/download_provider.dart';
import 'package:oneverse/providers/quran_provider.dart';
import 'package:oneverse/services/offline_store.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String dir;
  _FakePathProvider(this.dir);
  @override
  Future<String?> getApplicationDocumentsPath() async => dir;
}

/// Makes every HTTP connection fail, like a phone with no internet.
class _NoInternet extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      throw const SocketException('offline');
}

const _paired = PlaybackConfig(
  audioEdition: 'ar.alafasy',
  translationAudioEdition: 'ur.khan',
  textEdition: 'ur.jalandhry',
  mode: PlaybackMode.arabicWithTranslation,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final dir = await Directory.systemTemp.createTemp('oneverse_test');
    PathProviderPlatform.instance = _FakePathProvider(dir.path);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('PonnamKarthik/fluttertoast'), (_) async => true);
    await OfflineStore.instance.init();
  });

  group('PlaybackConfig', () {
    test('paired mode plays Arabic then translation', () {
      expect(_paired.audioEditions, ['ar.alafasy', 'ur.khan']);
      expect(_paired.requiredEditions,
          ['quran-uthmani', 'ur.jalandhry', 'ar.alafasy', 'ur.khan']);
    });

    test('translation modes fall back to Arabic without a reciter', () {
      const c = PlaybackConfig(
        audioEdition: 'ar.alafasy',
        translationAudioEdition: null,
        textEdition: 'en.asad',
        mode: PlaybackMode.arabicWithTranslation,
      );
      expect(c.mode, PlaybackMode.arabic);
      expect(c.audioEditions, ['ar.alafasy']);
    });

    test('Arabic-only key ignores the translation reciter', () {
      const a = PlaybackConfig(
          audioEdition: 'ar.alafasy',
          translationAudioEdition: 'ur.khan',
          textEdition: 'en.asad',
          mode: PlaybackMode.arabic);
      const b = PlaybackConfig(
          audioEdition: 'ar.alafasy',
          translationAudioEdition: null,
          textEdition: 'en.asad',
          mode: PlaybackMode.arabic);
      expect(a.key, b.key);
    });
  });

  test('a paired download also satisfies Arabic-only playback', () {
    final p = OfflinePackage(
      surahNumber: 1,
      englishName: 'Al-Faatiha',
      arabicName: '',
      numberOfAyahs: 7,
      mode: PlaybackMode.arabicWithTranslation,
      audioEdition: 'ar.alafasy',
      translationAudioEdition: 'ur.khan',
      textEdition: 'ur.jalandhry',
      sizeBytes: 0,
      downloadedAt: DateTime(2026),
    );
    expect(p.satisfies(_paired), isTrue);
    expect(
        p.satisfies(const PlaybackConfig(
            audioEdition: 'ar.alafasy',
            translationAudioEdition: null,
            textEdition: 'ur.jalandhry',
            mode: PlaybackMode.arabic)),
        isTrue);
    expect(
        p.satisfies(const PlaybackConfig(
            audioEdition: 'ar.husary',
            translationAudioEdition: 'ur.khan',
            textEdition: 'ur.jalandhry',
            mode: PlaybackMode.arabicWithTranslation)),
        isFalse);
  });

  test('downloads a full surah and then loads its verses offline', () async {
    HttpOverrides.global = null; // real network for the download
    final store = OfflineStore.instance;
    final downloads = SurahDownloadProvider();
    const ikhlas = Surah(
        number: 112,
        name: 'سُورَةُ الإِخۡلَاصِ',
        englishName: 'Al-Ikhlaas',
        numberOfAyahs: 4,
        revelationType: 'Meccan');

    final done = Completer<void>();
    downloads.addListener(() {
      final t = downloads.taskFor(112);
      if (t != null && !t.isActive && !done.isCompleted) done.complete();
    });
    expect(downloads.downloadSurah(ikhlas, _paired), isTrue);
    await done.future.timeout(const Duration(minutes: 2));

    final task = downloads.taskFor(112)!;
    expect(task.status, DownloadStatus.completed, reason: task.error);
    expect(task.totalFiles, 8); // 4 Arabic + 4 Urdu
    for (final e in ['ar.alafasy', 'ur.khan']) {
      for (int a = 1; a <= 4; a++) {
        final f = store.audioFile(e, 112, a);
        expect(await f.exists(), isTrue, reason: f.path);
        expect(await f.length(), greaterThan(1000));
      }
    }
    final pkg = store.findPackage(112, _paired);
    expect(pkg, isNotNull);
    expect(pkg!.sizeBytes, greaterThan(8000));

    // Now cut the internet: the verse must come entirely from storage.
    HttpOverrides.global = _NoInternet();
    final quran = QuranProvider();
    quran.selectSurah(112);
    quran.selectAyah(2);
    await quran.fetchAyah(_paired);
    expect(quran.ayahErrorMessage, isNull);
    expect(quran.arabicAyah?.arabicText, isNotEmpty);
    expect(quran.translationAyah?.translationText, isNotEmpty);
    expect(quran.verseAudio.map((a) => a.edition), ['ar.alafasy', 'ur.khan']);
    expect(quran.verseAudio.every((a) => File(a.source).existsSync()), isTrue);

    // A surah that isn't downloaded reports offline instead of hanging.
    quran.selectSurah(2);
    await quran.fetchAyah(_paired);
    expect(quran.isAyahOfflineError, isTrue);

    // Deleting removes the files.
    await store.deletePackage(pkg);
    expect(store.findPackage(112, _paired), isNull);
    expect(await store.audioFile('ur.khan', 112, 1).exists(), isFalse);
    HttpOverrides.global = null;
  });
}
