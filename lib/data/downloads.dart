import 'dart:async';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api.dart';
import 'cache_store.dart';
import 'catalog.dart';
import 'models.dart';
import 'network.dart';
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
  final Set<String> taskIds = {}; // native downloads in flight
  bool cancelled = false;
  DownloadJob(this.surah);
}

/// Thrown when a download was cancelled (pause, cancel, or the network left).
class DownloadCancelled implements Exception {
  const DownloadCancelled();
}

/// What "Download complete Quran" saves: every surah with one reciter.
class QuranPlan {
  final String reciterId;
  final List<String> translations;
  final String? voiceId;
  final bool wifiOnly;
  const QuranPlan(this.reciterId, this.translations, this.voiceId, {this.wifiOnly = true});

  Map<String, dynamic> toJson() => {'r': reciterId, 't': translations, 'v': voiceId, 'w': wifiOnly};
  factory QuranPlan.fromJson(Map j) =>
      QuranPlan(j['r'] as String, List<String>.from(j['t'] as List), j['v'] as String?, wifiOnly: j['w'] as bool? ?? true);
}

enum QuranState { idle, running, waitingForNetwork, paused, done }

/// Saves recitations, text in every script and the chosen translations so a
/// surah plays and reads with no connection.
class Downloads extends ChangeNotifier {
  Downloads(this.repo, {NetworkStatus? net}) : net = net ?? NetworkStatus.instance;
  final QuranRepository repo;
  final NetworkStatus net;
  final Map<String, DownloadRecord> _records = {};
  final Map<int, DownloadJob> jobs = {};

  /// Called with null when the complete-Quran download stops, to tell the
  /// user when it has finished. (Progress is in the downloader's notification.)
  void Function(int done, String? current)? onQuranProgress;

  /// Files go through the system downloader on phones (Android WorkManager,
  /// iOS URLSession): they keep going in the background, several at a time.
  @visibleForTesting
  bool useNativeDownloader = true;
  bool get _native => !kIsWeb && useNativeDownloader && (Platform.isAndroid || Platform.isIOS);
  static const _group = 'oneverse';

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
    final plan = await repo.store.read(_planKey);
    if (supported && plan?.data is Map) {
      quranPlan = QuranPlan.fromJson(plan!.data as Map);
      quranState = quranDone >= 114 ? QuranState.done : QuranState.paused;
      // It was stopped by the app closing, not by the user: carry on.
      if ((plan.data as Map)['active'] == true && quranState != QuranState.done) {
        unawaited(Future.delayed(const Duration(seconds: 6), resumeQuran));
      }
    }
    net.addListener(_onNetwork);
    if (_native) await _configureNative();
    notifyListeners();
  }

  Future<void> _configureNative() async {
    try {
      await FileDownloader().configure(
        globalConfig: [
          (Config.holdingQueue, (6, 4, null)), // six files at once, four per server
          (Config.checkAvailableSpace, 150), // fail rather than fill the phone
        ],
        androidConfig: [(Config.runInForeground, Config.always)], // no 9-minute limit in the background
      );
      FileDownloader().configureNotificationForGroup(
        _group,
        running: const TaskNotification('Downloading recitations', '{numFinished} of {numTotal} files'),
        complete: const TaskNotification('Recitations saved', 'Ready to play offline'),
        error: const TaskNotification('A download stopped', 'Open One Verse to try again'),
        progressBar: true,
        groupNotificationId: 'ov-downloads',
      );
      // Tasks left over from a closed app; finished files are kept and the
      // plan carries on from them.
      await FileDownloader().cancelAll(group: _group);
    } catch (e) {
      debugPrint('Native downloader unavailable: $e');
      useNativeDownloader = false;
    }
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
        bytes += await _fetchAyahs(urls, _audioDir(reciter.ayahEdition!), surah, job, 0.15, voice == null ? 1 : 0.7,
            (i) => 'Recitation · ayah $i of $count');
      }
      if (voice?.ayahEdition != null) {
        final urls = await repo.ayahAudio(voice!.ayahEdition!, surah);
        bytes += await _fetchAyahs(urls, _audioDir(voice.ayahEdition!), surah, job, 0.7, 1, (i) => 'Translation audio · ayah $i of $count');
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
    if (job.cancelled) throw const DownloadCancelled();
    final f = File(path);
    if (await f.exists() && await f.length() > 0) {
      job.progress.value = to;
      return f.length();
    }
    await f.parent.create(recursive: true);
    void progress(double p) {
      if (p >= 0) job.progress.value = from + (to - from) * p;
    }

    if (_native) {
      await _fetchNative(url, path, job, progress);
    } else {
      final tmp = '$path.part';
      try {
        await Api.instance.dio.download(url, tmp, cancelToken: job.cancel, onReceiveProgress: (r, t) {
          if (t > 0) progress(r / t);
        });
      } on DioException catch (e) {
        if (e.type == DioExceptionType.cancel) throw const DownloadCancelled();
        rethrow;
      }
      await File(tmp).rename(path);
    }
    job.progress.value = to;
    return File(path).length();
  }

  Future<void> _fetchNative(String url, String path, DownloadJob job, void Function(double) progress) async {
    // The downloader takes a folder relative to the app support folder,
    // where the store keeps its files ('oneverse/files').
    final root = repo.store.filesRoot!;
    final i = path.lastIndexOf('/');
    final task = DownloadTask(
      url: url,
      filename: path.substring(i + 1),
      directory: 'oneverse/files${path.substring(root.length, i)}',
      baseDirectory: BaseDirectory.applicationSupport,
      group: _group,
      updates: Updates.statusAndProgress,
      retries: 3,
      displayName: repo.surah(job.surah).nameEn,
    );
    job.taskIds.add(task.taskId);
    try {
      final r = await FileDownloader().download(task, onProgress: progress);
      switch (r.status) {
        case TaskStatus.complete:
          return;
        case TaskStatus.canceled:
          throw const DownloadCancelled();
        default:
          if (r.exception is TaskFileSystemException) throw FileSystemException(r.exception!.description, path);
          throw Exception('Download ${r.status.name}${r.responseStatusCode != null ? ' (${r.responseStatusCode})' : ''}');
      }
    } finally {
      job.taskIds.remove(task.taskId);
    }
  }

  /// Ayah files, a few at a time; progress counts finished files.
  Future<int> _fetchAyahs(List<String> urls, String dir, int surah, DownloadJob job, double from, double to,
      String Function(int done) step) async {
    var next = 0, done = 0, bytes = 0;
    Future<void> worker() async {
      while (next < urls.length) {
        if (job.cancelled) throw const DownloadCancelled();
        final i = next++;
        // Await first: `bytes += await …` would read bytes before the await and
        // lose what the other workers added meanwhile.
        final n = await _fetch(urls[i], '$dir/$surah/${i + 1}.mp3', job, job.progress.value, job.progress.value);
        bytes += n;
        done++;
        job.step.value = step(done);
        job.progress.value = from + (to - from) * done / urls.length;
      }
    }

    await Future.wait([for (var w = 0; w < 4; w++) worker()]);
    return bytes;
  }

  void cancel(int surah) {
    final j = jobs[surah];
    if (j == null) return;
    j.cancelled = true;
    j.cancel.cancel();
    if (j.taskIds.isNotEmpty) unawaited(FileDownloader().cancelTasksWithIds(j.taskIds.toList()));
  }

  /// Length in ms of each ayah file of [edition] in surah [n], worked out from
  /// the file sizes: alquran.cloud files are constant bitrate, named in the URL.
  /// Null where a size could not be read.
  Future<List<int?>> ayahDurations(String edition, int n) async {
    final key = 'dur_${edition}_$n';
    final e = await repo.store.read(key);
    if (e?.data is List) return [for (final x in e!.data as List) (x as num?)?.toInt()];
    final urls = await repo.ayahAudio(edition, n);
    final out = List<int?>.filled(urls.length, null);
    var next = 0;
    Future<void> worker() async {
      while (next < urls.length) {
        final i = next++;
        try {
          final local = ayahFile(edition, n, i + 1);
          final bytes = local != null ? await File(local).length() : await _headSize(urls[i]);
          if (bytes > 0) out[i] = bytes * 8 ~/ _kbps(urls[i]);
        } catch (_) {}
      }
    }

    await Future.wait([for (var w = 0; w < 6; w++) worker()]);
    if (!out.contains(null)) await repo.store.write(key, out);
    return out;
  }

  static int _kbps(String url) => int.tryParse(RegExp(r'/audio/(\d+)/').firstMatch(url)?.group(1) ?? '') ?? 128;

  // ---------------------------------------------------------------- complete Quran

  static const _planKey = 'quran_download';
  QuranPlan? quranPlan;
  QuranState quranState = QuranState.idle;
  int? quranCurrent;
  String? quranError;
  final Set<int> quranFailed = {};
  bool _stop = false;
  Future<void>? _run;

  /// Surahs downloaded at the same time.
  @visibleForTesting
  int quranParallel = 3;
  final Set<int> _quranActive = {};

  void _cancelActive() {
    for (final n in _quranActive.toList()) {
      cancel(n);
    }
  }

  /// First wait before retrying a surah that failed; doubles each attempt.
  @visibleForTesting
  Duration retryDelay = const Duration(seconds: 2);

  /// Completes when the complete-Quran run in progress has stopped.
  @visibleForTesting
  Future<void> get quranIdle => _run ?? Future.value();

  @visibleForTesting
  void debugAddRecord(DownloadRecord r) => _records['${r.surah}_${r.reciterId}'] = r;

  /// Surahs of the plan's reciter that are fully saved.
  int get quranDone => quranPlan == null ? 0 : _quranRecords(quranPlan!).length;

  int get quranBytes => _quranRecords(quranPlan).fold(0, (t, r) => t + r.bytes);

  Iterable<DownloadRecord> _quranRecords(QuranPlan? p) =>
      p == null ? const [] : _records.values.where((r) => r.reciterId == p.reciterId && (p.voiceId == null || r.voiceId == p.voiceId));

  /// Reciters with all 114 surahs saved.
  Set<String> get completeReciters {
    final count = <String, int>{};
    for (final r in _records.values) {
      count[r.reciterId] = (count[r.reciterId] ?? 0) + 1;
    }
    return {for (final e in count.entries) if (e.value >= 114) e.key};
  }

  bool _networkAllows(QuranPlan p) => p.wifiOnly ? net.unmetered : net.online;

  /// Starts (or restarts with new options) the complete Quran download.
  Future<void> startQuran(QuranPlan plan) async {
    if (!supported) return;
    if (_run != null) await pauseQuran();
    quranPlan = plan;
    quranFailed.clear();
    quranError = null;
    await resumeQuran();
  }

  Future<void> resumeQuran({bool allowMobileData = false}) async {
    final p = quranPlan;
    if (p == null || _run != null || !supported) return;
    if (allowMobileData && p.wifiOnly) quranPlan = QuranPlan(p.reciterId, p.translations, p.voiceId, wifiOnly: false);
    quranError = null;
    _stop = false;
    await _savePlan(active: true);
    _run = _runQuran().whenComplete(() => _run = null);
  }

  /// Stops after cancelling the surah in progress; what is saved stays.
  Future<void> pauseQuran() async {
    _stop = true;
    _cancelActive();
    await _run;
    if (quranPlan != null && quranState != QuranState.done) quranState = QuranState.paused;
    await _savePlan(active: false);
    notifyListeners();
  }

  /// Stops and forgets the plan. Surahs already saved stay downloaded.
  Future<void> cancelQuran() async {
    await pauseQuran();
    quranPlan = null;
    quranState = QuranState.idle;
    quranFailed.clear();
    await repo.store.delete(_planKey);
    notifyListeners();
  }

  Future<void> _savePlan({required bool active}) async {
    final p = quranPlan;
    if (p != null) await repo.store.write(_planKey, {...p.toJson(), 'active': active});
  }

  void _onNetwork() {
    final p = quranPlan;
    if (p == null) return;
    if (quranState == QuranState.running && !_networkAllows(p)) {
      _cancelActive();
    } else if (quranState == QuranState.waitingForNetwork && _networkAllows(p) && _run == null) {
      resumeQuran();
    }
  }

  Future<void> _runQuran() async {
    final p = quranPlan!;
    final reciter = reciterById(p.reciterId);
    final voice = p.voiceId == null ? null : reciterById(p.voiceId);
    quranState = QuranState.running;
    notifyListeners();
    var next = 1;

    int? take() {
      while (next <= 114) {
        final n = next++;
        final have = recordFor(n, p.reciterId);
        if (have == null || (voice != null && have.voiceId != voice.id)) return n;
      }
      return null;
    }

    Future<void> worker() async {
      while (!_stop && quranState == QuranState.running) {
        if (!_networkAllows(p)) {
          quranState = QuranState.waitingForNetwork;
          return;
        }
        final n = take();
        if (n == null) return;
        _quranActive.add(n);
        quranCurrent = _quranActive.reduce((a, b) => a < b ? a : b);
        notifyListeners();
        var ok = false;
        for (var attempt = 0; attempt < 3 && !ok && !_stop && _networkAllows(p); attempt++) {
          try {
            ok = await download(surah: n, reciter: reciter, translations: p.translations, voice: voice) != null;
          } on DownloadCancelled {
            break;
          } on FileSystemException catch (e) {
            quranError = 'Not enough storage on this device (${e.osError?.message ?? e.message}).';
            _stop = true;
          } catch (_) {
            await Future.delayed(retryDelay * (1 << attempt));
          }
        }
        _quranActive.remove(n);
        quranCurrent = _quranActive.isEmpty ? null : _quranActive.reduce((a, b) => a < b ? a : b);
        if (!ok && !_stop && _networkAllows(p)) quranFailed.add(n);
        if (ok) quranFailed.remove(n);
        notifyListeners();
      }
    }

    await Future.wait([for (var w = 0; w < quranParallel; w++) worker()]);
    if (quranState == QuranState.running && !_networkAllows(p)) quranState = QuranState.waitingForNetwork;
    quranCurrent = null;
    if (quranState == QuranState.running) {
      quranState = _stop ? QuranState.paused : quranDone >= 114 ? QuranState.done : QuranState.paused;
      if (quranState == QuranState.paused && !_stop && quranFailed.isNotEmpty) {
        quranError = '${quranFailed.length} surah${quranFailed.length == 1 ? '' : 's'} could not be downloaded. Tap Resume to try again.';
      }
    }
    await _savePlan(active: quranState == QuranState.waitingForNetwork);
    onQuranProgress?.call(quranDone, null);
    notifyListeners();
  }

  /// Bytes of the whole Quran for [r], and for the translation voice when
  /// given: exact for Quran.com recitations, otherwise measured on Surah
  /// Ya-Sin and scaled to the whole Quran.
  Future<int?> estimateQuranBytes(Reciter r, {Reciter? voice}) async {
    final key = '${r.id}|${voice?.id}';
    final cached = _estimates[key];
    if (cached != null) return cached;
    try {
      var total = await _estimateFor(r);
      if (voice != null) total += await _estimateFor(voice, ayahOnly: true);
      return _estimates[key] = total;
    } catch (_) {
      return null;
    }
  }

  final Map<String, int> _estimates = {};

  /// Surah Ya-Sin is about 1/101 of the whole Quran's recitation time.
  static const _yasinShare = 101.5;

  Future<int> _estimateFor(Reciter r, {bool ayahOnly = false}) async {
    final t = r.timing;
    if (!ayahOnly && t != null && t.kind == TimingKind.qdc) {
      final d = await repo.api.getJson('${Endpoints.qdc}/audio/reciters/${t.qdcId}/audio_files');
      return [for (final f in d['audio_files'] as List) (f['file_size'] as num? ?? 0).toInt()].fold<int>(0, (a, b) => a + b);
    }
    if (!ayahOnly && t != null) {
      final timing = await repo.timing(r, 36);
      if (timing != null) return ((await _headSize(timing.audioUrl)) * _yasinShare).round();
    }
    final urls = await repo.ayahAudio(r.ayahEdition!, 36);
    var sum = 0, next = 0;
    Future<void> worker() async {
      while (next < urls.length) {
        final n = await _headSize(urls[next++]);
        sum += n;
      }
    }

    await Future.wait([for (var w = 0; w < 6; w++) worker()]);
    return (sum * _yasinShare).round();
  }

  /// File size from a HEAD request, or from a one-byte range request when the
  /// server leaves the length out of HEAD replies.
  Future<int> _headSize(String url) async {
    final plain = Options(headers: {'accept-encoding': 'identity'});
    final r = await repo.api.dio.head<void>(url, options: plain);
    final n = int.tryParse(r.headers.value(Headers.contentLengthHeader) ?? '') ?? 0;
    if (n > 0) return n;
    final g = await repo.api.dio.get<List<int>>(url,
        options: Options(headers: {'accept-encoding': 'identity', 'range': 'bytes=0-0'}, responseType: ResponseType.bytes));
    return int.tryParse((g.headers.value('content-range') ?? '').split('/').last) ?? 0;
  }

  /// Removes every saved surah of one reciter.
  Future<void> removeReciter(String reciterId) async {
    if (quranPlan?.reciterId == reciterId) await cancelQuran();
    for (final r in _records.values.where((r) => r.reciterId == reciterId).toList()) {
      await remove(r);
    }
  }

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
