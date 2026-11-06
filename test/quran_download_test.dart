import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oneverse/data/cache_store_memory.dart';
import 'package:oneverse/data/downloads.dart';
import 'package:oneverse/data/models.dart';
import 'package:oneverse/data/network.dart';
import 'package:oneverse/data/repository.dart';

class _FilesStore extends MemoryCacheStore {
  @override
  String? get filesRoot => '/nonexistent/oneverse-test';
}

/// Downloads with the network replaced: every surah "downloads" at once,
/// except the ones told to fail or to wait.
class _FakeDownloads extends Downloads {
  _FakeDownloads(super.repo) : super(net: NetworkStatus.instance);
  final calls = <int>[];
  final failing = <int>{};
  int? holdAt;
  final hold = Completer<void>();
  final reached = Completer<void>();

  @override
  Future<DownloadRecord?> download({required int surah, required Reciter reciter, required List<String> translations, Reciter? voice}) async {
    calls.add(surah);
    if (failing.contains(surah)) throw Exception('server error');
    if (surah == holdAt) {
      reached.complete();
      await hold.future;
    }
    final r = DownloadRecord(surah, reciter.id, translations, voice?.id, 1000, DateTime(2026));
    debugAddRecord(r);
    return r;
  }
}

void main() {
  final net = NetworkStatus.instance;
  late _FakeDownloads dl;
  const plan = QuranPlan('ar.alafasy', ['en.sahih'], null);

  setUp(() async {
    net.debugSet(NetKind.unmetered);
    final repo = QuranRepository(store: _FilesStore())
      ..surahs = [for (var i = 1; i <= 114; i++) SurahInfo(i, '', 'Surah $i', '', 7, true)];
    dl = _FakeDownloads(repo)..retryDelay = Duration.zero;
    await dl.init();
  });
  tearDown(() => net.debugSet(NetKind.unmetered));

  test('downloads all 114 surahs and skips the ones already saved', () async {
    for (var n = 1; n <= 50; n++) {
      dl.debugAddRecord(DownloadRecord(n, 'ar.alafasy', const [], null, 1000, DateTime(2026)));
    }
    await dl.startQuran(plan);
    await dl.quranIdle;
    expect(dl.calls.first, 51);
    expect(dl.calls.length, 64);
    expect(dl.quranDone, 114);
    expect(dl.quranState, QuranState.done);
    expect(dl.completeReciters, {'ar.alafasy'});
  });

  test('pause keeps what is saved and resume carries on from there', () async {
    dl.holdAt = 5;
    await dl.startQuran(plan);
    await dl.reached.future;
    final paused = dl.pauseQuran();
    dl.hold.complete();
    await paused;
    expect(dl.quranState, QuranState.paused);
    expect(dl.quranDone, 5);
    await dl.resumeQuran();
    await dl.quranIdle;
    expect(dl.calls.where((n) => n <= 5).length, 5, reason: 'no surah downloaded twice');
    expect(dl.quranState, QuranState.done);
  });

  test('Wi-Fi only waits on mobile data and carries on when Wi-Fi returns', () async {
    net.debugSet(NetKind.metered);
    await dl.startQuran(plan);
    await dl.quranIdle;
    expect(dl.quranState, QuranState.waitingForNetwork);
    expect(dl.calls, isEmpty);
    net.debugSet(NetKind.unmetered);
    await Future.delayed(Duration.zero);
    await dl.quranIdle;
    expect(dl.quranState, QuranState.done);
  });

  test('losing Wi-Fi mid-way waits; "use mobile data" finishes it', () async {
    dl.holdAt = 10;
    await dl.startQuran(plan);
    await dl.reached.future;
    net.debugSet(NetKind.metered);
    dl.hold.complete();
    await dl.quranIdle;
    expect(dl.quranState, QuranState.waitingForNetwork);
    expect(dl.quranDone, 10);
    await dl.resumeQuran(allowMobileData: true);
    await dl.quranIdle;
    expect(dl.quranState, QuranState.done);
    expect(dl.quranPlan!.wifiOnly, isFalse);
  });

  test('a surah that keeps failing is retried, reported, and fetched on resume', () async {
    dl.failing.add(7);
    await dl.startQuran(plan);
    await dl.quranIdle;
    expect(dl.calls.where((n) => n == 7).length, 3);
    expect(dl.quranDone, 113);
    expect(dl.quranState, QuranState.paused);
    expect(dl.quranError, contains('1 surah could not be downloaded'));
    dl.failing.clear();
    await dl.resumeQuran();
    await dl.quranIdle;
    expect(dl.quranState, QuranState.done);
  });

  test('a plan left running when the app closed is picked up again', () async {
    await dl.repo.store.write('quran_download', {...plan.toJson(), 'active': true});
    final again = _FakeDownloads(dl.repo)..retryDelay = Duration.zero;
    await again.init();
    expect(again.quranPlan!.reciterId, 'ar.alafasy');
    expect(again.quranState, QuranState.paused);
  });
}
