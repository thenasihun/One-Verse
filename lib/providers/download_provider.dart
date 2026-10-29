import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:oneverse/models/playback_config.dart';
import 'package:oneverse/models/surah_model.dart';
import 'package:oneverse/services/offline_store.dart';
import 'package:oneverse/services/quran_api_service.dart';

enum DownloadStatus { queued, downloading, completed, failed, cancelled }

class SurahDownloadTask {
  final Surah surah;
  final PlaybackConfig config;
  final Map<String, String> editionNames;
  final CancelToken cancelToken = CancelToken();

  DownloadStatus status = DownloadStatus.queued;
  int totalFiles = 0;
  int doneFiles = 0;
  String? error;

  SurahDownloadTask(this.surah, this.config, this.editionNames);

  double? get progress => totalFiles == 0 ? null : doneFiles / totalFiles;
  bool get isActive =>
      status == DownloadStatus.queued || status == DownloadStatus.downloading;
}

/// Downloads complete surahs (text + selected reciters' audio) into app
/// storage for offline playback. Surahs are processed one at a time; files
/// within a surah download in parallel.
class SurahDownloadProvider with ChangeNotifier {
  static const int _parallelFiles = 4;
  static const int _maxAttempts = 3;

  final OfflineStore _store = OfflineStore.instance;
  final QuranApiService _api = QuranApiService();
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 60),
  ));

  final Map<int, SurahDownloadTask> _tasks = {};
  final Queue<SurahDownloadTask> _queue = Queue();
  bool _running = false;

  SurahDownloadTask? taskFor(int surahNumber) => _tasks[surahNumber];

  List<SurahDownloadTask> get activeTasks =>
      _tasks.values.where((t) => t.isActive).toList();

  bool isDownloading(int surahNumber) => _tasks[surahNumber]?.isActive ?? false;

  /// Queues [surah] for download with [config]. Returns false if it's already
  /// downloading or already available offline.
  bool downloadSurah(Surah surah, PlaybackConfig config,
      {Map<String, String> editionNames = const {}}) {
    if (isDownloading(surah.number)) {
      Fluttertoast.showToast(msg: "${surah.englishName} is already downloading");
      return false;
    }
    if (_store.isAvailable(surah.number, config)) {
      Fluttertoast.showToast(
          msg: "${surah.englishName} is already available offline");
      return false;
    }
    final task = SurahDownloadTask(surah, config, editionNames);
    _tasks[surah.number] = task;
    _queue.add(task);
    notifyListeners();
    Fluttertoast.showToast(
        msg: "Downloading ${surah.englishName} for offline listening");
    _pump();
    return true;
  }

  void cancel(int surahNumber) {
    final task = _tasks[surahNumber];
    if (task == null || !task.isActive) return;
    task.cancelToken.cancel();
    if (task.status == DownloadStatus.queued) {
      _queue.remove(task);
      task.status = DownloadStatus.cancelled;
      _tasks.remove(surahNumber);
    }
    notifyListeners();
  }

  void dismiss(int surahNumber) {
    final task = _tasks[surahNumber];
    if (task != null && !task.isActive) {
      _tasks.remove(surahNumber);
      notifyListeners();
    }
  }

  Future<void> _pump() async {
    if (_running) return;
    _running = true;
    while (_queue.isNotEmpty) {
      await _run(_queue.removeFirst());
    }
    _running = false;
  }

  Future<void> _run(SurahDownloadTask task) async {
    final surahNumber = task.surah.number;
    task.status = DownloadStatus.downloading;
    notifyListeners();

    try {
      await _store.init();

      // 1. Text and audio URLs for every edition, in as few requests as possible.
      final editions = task.config.requiredEditions;
      final surahJson = <String, Map<String, dynamic>>{};
      final missing = <String>[];
      for (final e in editions) {
        final local = await _store.loadSurahJson(e, surahNumber);
        if (local != null && local['ayahs'] is List) {
          surahJson[e] = local;
        } else {
          missing.add(e);
        }
      }
      if (missing.isNotEmpty) {
        final fetched = await _api.getSurahEditionsRaw(surahNumber, missing);
        for (final entry in fetched.entries) {
          surahJson[entry.key] = entry.value;
          await _store.saveSurahJson(entry.key, surahNumber, entry.value);
        }
      }
      for (final e in editions) {
        if (!surahJson.containsKey(e)) {
          throw Exception('Could not load "$e" for this surah.');
        }
      }
      _throwIfCancelled(task);

      // 2. Work out which audio files are still needed.
      final jobs = <_FileJob>[];
      int alreadyDone = 0;
      for (final edition in task.config.audioEditions) {
        for (final ayah in surahJson[edition]!['ayahs'] as List) {
          final url = ayah['audio'] as String?;
          if (url == null || url.isEmpty) {
            throw Exception(
                'This reciter does not support verse-by-verse download.');
          }
          final file =
              _store.audioFile(edition, surahNumber, ayah['numberInSurah']);
          if (await file.exists() && await file.length() > 0) {
            alreadyDone++;
          } else {
            final secondary = (ayah['audioSecondary'] as List?)
                    ?.whereType<String>()
                    .toList() ??
                const <String>[];
            jobs.add(_FileJob(file, [url, ...secondary]));
          }
        }
      }
      task.totalFiles = alreadyDone + jobs.length;
      task.doneFiles = alreadyDone;
      notifyListeners();

      // 3. Download in parallel.
      final pending = Queue<_FileJob>.from(jobs);
      bool aborted = false;
      Future<void> worker() async {
        while (pending.isNotEmpty && !aborted) {
          _throwIfCancelled(task);
          final job = pending.removeFirst();
          try {
            await _downloadFile(job, task.cancelToken);
          } catch (_) {
            aborted = true; // stop the other workers too
            rethrow;
          }
          task.doneFiles++;
          notifyListeners();
        }
      }

      await Future.wait(List.generate(_parallelFiles, (_) => worker()));
      _throwIfCancelled(task);

      // 4. Register in the offline library.
      final mode = task.config.mode;
      final size = await _store.audioBytes(task.config.audioEditions, surahNumber);
      await _store.addPackage(
        OfflinePackage(
          surahNumber: surahNumber,
          englishName: task.surah.englishName,
          arabicName: task.surah.name,
          numberOfAyahs: task.surah.numberOfAyahs,
          mode: mode,
          audioEdition:
              task.config.needsArabicAudio ? task.config.audioEdition : null,
          translationAudioEdition: task.config.needsTranslationAudio
              ? task.config.translationAudioEdition
              : null,
          textEdition: task.config.textEdition,
          sizeBytes: size,
          downloadedAt: DateTime.now(),
        ),
        editionNames: task.editionNames,
      );

      task.status = DownloadStatus.completed;
      Fluttertoast.showToast(
          msg: "${task.surah.englishName} is now available offline");
    } on _Cancelled {
      task.status = DownloadStatus.cancelled;
      _tasks.remove(surahNumber);
      await _store.cleanupSurah(surahNumber);
      Fluttertoast.showToast(msg: "Download cancelled");
    } catch (e) {
      if (task.cancelToken.isCancelled) {
        task.status = DownloadStatus.cancelled;
        _tasks.remove(surahNumber);
        await _store.cleanupSurah(surahNumber);
        Fluttertoast.showToast(msg: "Download cancelled");
      } else {
        debugPrint("Surah download failed: $e");
        task.status = DownloadStatus.failed;
        task.error = e is OfflineException || QuranApiService.isNetworkError(e)
            ? "No internet connection. Downloaded files are kept — retry to continue."
            : e.toString().replaceFirst('Exception: ', '');
        Fluttertoast.showToast(
          msg: "Download failed: ${task.error}",
          toastLength: Toast.LENGTH_LONG,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
    notifyListeners();
  }

  Future<void> _downloadFile(_FileJob job, CancelToken token) async {
    final tmp = File('${job.file.path}.part');
    await job.file.parent.create(recursive: true);
    Object? lastError;
    for (int attempt = 0; attempt < _maxAttempts; attempt++) {
      // Rotate through mirrors on retry.
      final url = job.urls[attempt % job.urls.length];
      try {
        await _dio.download(url, tmp.path, cancelToken: token);
        if (await tmp.length() == 0) throw Exception('Empty file');
        await tmp.rename(job.file.path);
        return;
      } catch (e) {
        if (token.isCancelled) throw _Cancelled();
        lastError = e;
        await Future.delayed(Duration(milliseconds: 600 * (attempt + 1)));
      }
    }
    if (await tmp.exists()) await tmp.delete();
    throw lastError ?? Exception('Download failed');
  }

  void _throwIfCancelled(SurahDownloadTask task) {
    if (task.cancelToken.isCancelled) throw _Cancelled();
  }
}

class _FileJob {
  final File file;
  final List<String> urls;
  _FileJob(this.file, this.urls);
}

class _Cancelled implements Exception {}
