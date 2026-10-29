import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'api.dart';
import 'catalog.dart';
import 'network.dart';
import 'repository.dart';

/// Keeps a complete offline library on the device: the whole Quran in every
/// script, the chosen translation, word timings for the chosen reciter and
/// reciter photos. Runs on Wi-Fi; anything older than [SyncPolicy.wifiRefresh]
/// is fetched again so the 30-day offline window keeps moving forward.
class OfflineSync extends ChangeNotifier {
  OfflineSync(this.repo, {this.translationId, this.reciterId});
  final QuranRepository repo;
  String? translationId, reciterId;

  bool running = false;
  int done = 0, total = 0;
  DateTime? lastComplete;
  DateTime? oldestData;
  int textSurahsReady = 0;
  bool _again = false;

  Future<void> init() async {
    final e = await repo.store.read('sync_state');
    if (e?.data is Map) {
      final t = (e!.data as Map)['last'] as int?;
      if (t != null) lastComplete = DateTime.fromMillisecondsSinceEpoch(t);
    }
    await refreshStats();
    NetworkStatus.instance.addListener(_onNet);
  }

  void _onNet() {
    if (NetworkStatus.instance.unmetered) run();
  }

  /// Date until which everything on the device stays usable offline.
  DateTime? get validUntil => oldestData?.add(SyncPolicy.keep);

  Future<void> refreshStats() async {
    var ready = 0;
    DateTime? oldest;
    for (var n = 1; n <= 114; n++) {
      final e = await repo.store.read(QuranRepository.wordsKey(n));
      if (e != null) {
        ready++;
        if (oldest == null || e.fetchedAt.isBefore(oldest)) oldest = e.fetchedAt;
      }
    }
    textSurahsReady = ready;
    oldestData = oldest;
    notifyListeners();
  }

  /// Runs one pass. [force] ignores Wi-Fi (used by the "Sync now" button).
  Future<void> run({bool force = false}) async {
    final net = NetworkStatus.instance;
    if (!net.online || (!net.unmetered && !force)) return;
    if (running) {
      _again = true;
      return;
    }
    running = true;
    done = 0;
    final tasks = <Future<void> Function()>[];
    for (var n = 1; n <= 114; n++) {
      tasks.add(() => _ensure(QuranRepository.wordsKey(n), () => repo.words(n, force: true)));
      final tr = translationId;
      if (tr != null) tasks.add(() => _ensure(QuranRepository.trKey(tr, n), () => repo.translation(tr, n, force: true)));
      final r = reciterById(reciterId);
      if (r.timing != null) {
        tasks.add(() => _ensure(QuranRepository.timingKey(r.id, n), () => repo.timing(r, n, force: true)));
      }
    }
    for (final r in reciters) {
      tasks.add(() => cachePhoto(r.id));
    }
    total = tasks.length;
    notifyListeners();
    var i = 0;
    Future<void> worker() async {
      while (i < tasks.length) {
        final t = tasks[i++];
        try {
          await t();
        } catch (_) {}
        done++;
        if (done % 10 == 0) notifyListeners();
        if (!NetworkStatus.instance.online) return;
      }
    }

    await Future.wait([worker(), worker(), worker()]);
    running = false;
    if (done >= total) {
      lastComplete = DateTime.now();
      await repo.store.write('sync_state', {'last': lastComplete!.millisecondsSinceEpoch});
    }
    await refreshStats();
    if (_again) {
      _again = false;
      unawaited(run());
    }
  }

  Future<void> _ensure(String key, Future<Object?> Function() fetch) async {
    final e = await repo.store.read(key);
    if (e != null && !SyncPolicy.needsRefresh(e.age, NetworkStatus.instance.kind)) return;
    await fetch();
  }

  // ---------------------------------------------------------------- photos

  String? photoPath(String reciterId) {
    final root = repo.store.filesRoot;
    if (root == null) return null;
    final f = File('$root/photos/$reciterId.jpg');
    return f.existsSync() ? f.path : null;
  }

  Future<void> cachePhoto(String reciterId) async {
    final root = repo.store.filesRoot;
    final url = repo.profileOf(reciterById(reciterId))?.imageUrl;
    if (root == null || url == null) return;
    final f = File('$root/photos/$reciterId.jpg');
    if (await f.exists()) return;
    await f.parent.create(recursive: true);
    await Api.instance.dio.download(url, '${f.path}.part');
    await File('${f.path}.part').rename(f.path);
  }

  @override
  void dispose() {
    NetworkStatus.instance.removeListener(_onNet);
    super.dispose();
  }
}
