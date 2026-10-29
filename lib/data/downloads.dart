import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api.dart';
import 'cache_store.dart';
import 'catalog.dart';
import 'models.dart';
import 'repository.dart';

/// One downloaded surah.
class DownloadRecord {
  final int surah;
  final String reciterId;
  final List<String> translations;
  final String? voiceId;
  final int bytes;
  final DateTime at;
  const DownloadRecord(this.surah, this.reciterId, this.translations, this.voiceId, this.bytes, this.at);

  Map<String, dynamic> toJson() =>
      {'s': surah, 'r': reciterId, 't': translations, 'v': voiceId, 'b': bytes, 'at': at.millisecondsSinceEpoch};
  factory DownloadRecord.fromJson(Map j) => DownloadRecord(j['s'] as int, j['r'] as String, List<String>.from(j['t'] as List),
      j['v'] as String?, j['b'] as int, DateTime.fromMillisecondsSinceEpoch(j['at'] as int));
}

class DownloadJob {
  final int surah;
  final ValueNotifier<double> progress = ValueNotifier(0);
  final ValueNotifier<String> step = ValueNotifier('Preparing');
  final CancelToken cancel = CancelToken();
  DownloadJob(this.surah);
}

/// Saves recitations, text in every script and the chosen translations so a
/// surah plays and reads with no connection.
class Downloads extends ChangeNotifier {
  Downloads(this.repo);
  final QuranRepository repo;
  final Map<String, DownloadRecord> _records = {};
  final Map<int, DownloadJob> jobs = {};

  bool get supported => !kIsWeb && repo.store.filesRoot != null;
  Iterable<DownloadRecord> get records => _records.values;

  DownloadRecord? recordFor(int surah, [String? reciterId]) {
    for (final r in _records.values) {
      if (r.surah == surah && (reciterId == null || r.reciterId == reciterId)) return r;
    }
    return null;
  }

  Future<void> init() async {
    final e = await repo.store.read('downloads_index');
    if (e?.data is Map) {
      for (final v in (e!.data as Map).values) {
        final r = DownloadRecord.fromJson(v as Map);
        _records['${r.surah}_${r.reciterId}'] = r;
      }
    }
    notifyListeners();
  }

  Future<void> _saveIndex() =>
      repo.store.write('downloads_index', {for (final e in _records.entries) e.key: e.value.toJson()});

  String _audioDir(String folder) => '${repo.store.filesRoot}/audio/$folder';

  /// Local file for a full-surah recording, if downloaded.
  String? chapterFile(String reciterId, int n) {
    if (!supported) return null;
    final f = File('${_audioDir(reciterId)}/$n.mp3');
    return f.existsSync() ? f.path : null;
  }

  /// Local file for one ayah of an edition, if downloaded.
  String? ayahFile(String edition, int n, int ayah) {
    if (!supported) return null;
    final f = File('${_audioDir(edition)}/$n/$ayah.mp3');
    return f.existsSync() ? f.path : null;
  }

  Future<DownloadRecord?> download({
    required int surah,
    required Reciter reciter,
    required List<String> translations,
    Reciter? voice,
  }) async {
    if (!supported || jobs.containsKey(surah)) return null;
    final job = DownloadJob(surah);
    jobs[surah] = job;
    notifyListeners();
    var bytes = 0;
    try {
      job.step.value = 'Quran text in all scripts';
      await repo.words(surah);
      for (final t in translations) {
        job.step.value = 'Translation · ${repo.translationById(t).englishName}';
        await repo.translation(t, surah);
      }
      final timing = await repo.timing(reciter, surah);
      final count = repo.surah(surah).ayahs;
      if (timing != null) {
        job.step.value = 'Recitation · full surah';
        bytes += await _fetch(timing.audioUrl, '${_audioDir(reciter.id)}/$surah.mp3', job, 0.15, voice == null ? 1 : 0.7);
      } else if (reciter.ayahEdition != null) {
        final urls = await repo.ayahAudio(reciter.ayahEdition!, surah);
        for (var i = 0; i < urls.length; i++) {
          job.step.value = 'Recitation · ayah ${i + 1} of $count';
          bytes += await _fetch(urls[i], '${_audioDir(reciter.ayahEdition!)}/$surah/${i + 1}.mp3', job,
              0.15 + (voice == null ? 0.85 : 0.55) * i / urls.length, 0.15 + (voice == null ? 0.85 : 0.55) * (i + 1) / urls.length);
        }
      }
      if (voice?.ayahEdition != null) {
        final urls = await repo.ayahAudio(voice!.ayahEdition!, surah);
        for (var i = 0; i < urls.length; i++) {
          job.step.value = 'Translation audio · ayah ${i + 1} of $count';
          bytes += await _fetch(urls[i], '${_audioDir(voice.ayahEdition!)}/$surah/${i + 1}.mp3', job,
              0.7 + 0.3 * i / urls.length, 0.7 + 0.3 * (i + 1) / urls.length);
        }
      }
      final rec = DownloadRecord(surah, reciter.id, translations, voice?.id, bytes, DateTime.now());
      _records['${surah}_${reciter.id}'] = rec;
      await _saveIndex();
      job.progress.value = 1;
      return rec;
    } finally {
      jobs.remove(surah);
      notifyListeners();
    }
  }

  Future<int> _fetch(String url, String path, DownloadJob job, double from, double to) async {
    final f = File(path);
    if (await f.exists() && await f.length() > 0) {
      job.progress.value = to;
      return f.length();
    }
    await f.parent.create(recursive: true);
    final tmp = '$path.part';
    await Api.instance.dio.download(url, tmp, cancelToken: job.cancel, onReceiveProgress: (r, t) {
      if (t > 0) job.progress.value = from + (to - from) * r / t;
    });
    await File(tmp).rename(path);
    job.progress.value = to;
    return File(path).length();
  }

  void cancel(int surah) => jobs[surah]?.cancel.cancel();

  Future<void> remove(DownloadRecord r) async {
    final reciter = reciterById(r.reciterId);
    for (final dir in [
      '${_audioDir(reciter.id)}/${r.surah}.mp3',
      if (reciter.ayahEdition != null) '${_audioDir(reciter.ayahEdition!)}/${r.surah}',
      if (r.voiceId != null) '${_audioDir(reciterById(r.voiceId).ayahEdition!)}/${r.surah}',
    ]) {
      final t = FileSystemEntity.typeSync(dir);
      if (t == FileSystemEntityType.file) await File(dir).delete();
      if (t == FileSystemEntityType.directory) await Directory(dir).delete(recursive: true);
    }
    _records.remove('${r.surah}_${r.reciterId}');
    await _saveIndex();
    notifyListeners();
  }

  Future<int> audioBytes() async {
    if (!supported) return 0;
    final d = Directory('${repo.store.filesRoot}/audio');
    if (!await d.exists()) return 0;
    var t = 0;
    await for (final f in d.list(recursive: true)) {
      if (f is File) t += await f.length();
    }
    return t;
  }

  Future<int> textBytes() => CacheStore.instance.sizeOf('');
}
