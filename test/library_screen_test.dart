import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oneverse/core/theme.dart';
import 'package:oneverse/data/cache_store.dart';
import 'package:oneverse/data/cache_store_memory.dart';
import 'package:oneverse/data/downloads.dart';
import 'package:oneverse/data/models.dart';
import 'package:oneverse/data/network.dart';
import 'package:oneverse/data/offline_sync.dart';
import 'package:oneverse/data/repository.dart';
import 'package:oneverse/state/settings.dart';
import 'package:oneverse/ui/screens/downloads_screen.dart';
import 'package:oneverse/ui/widgets/common.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FilesStore extends MemoryCacheStore {
  @override
  String? get filesRoot => '/nonexistent/oneverse-test';
}

class _FakeDownloads extends Downloads {
  _FakeDownloads(super.repo) : super(net: NetworkStatus.instance);
  int? holdAt;
  /// Made inside each test, so it completes in the test's fake-async zone.
  late Completer<void> hold;

  @override
  Future<DownloadRecord?> download({required int surah, required Reciter reciter, required List<String> translations, Reciter? voice}) async {
    if (surah == holdAt) await hold.future;
    final r = DownloadRecord(surah, reciter.id, translations, voice?.id, 15 << 20, DateTime(2026));
    debugAddRecord(r);
    return r;
  }
}

void main() {
  late _FakeDownloads dl;
  late Widget app;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    NetworkStatus.instance.debugSet(NetKind.unmetered);
    final store = _FilesStore();
    CacheStore.instance = store;
    final settings = Settings();
    await settings.load();
    final repo = QuranRepository(store: store)
      ..surahs = [for (var i = 1; i <= 114; i++) SurahInfo(i, '', 'Surah $i', '', 7, true)];
    dl = _FakeDownloads(repo)
      ..retryDelay = Duration.zero
      ..quranParallel = 1;
    await dl.init();
    app = MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: repo),
        ChangeNotifierProvider<Downloads>.value(value: dl),
        ChangeNotifierProvider.value(value: OfflineSync(repo)),
        ChangeNotifierProvider.value(value: NetworkStatus.instance),
      ],
      child: MaterialApp(theme: AppTheme.build(Brightness.dark), home: const Scaffold(body: DownloadsScreen())),
    );
  });

  void phone(WidgetTester t) {
    t.view.physicalSize = const Size(1179, 3300);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
  }

  testWidgets('complete Quran: start, pause, resume, saved', (t) async {
    phone(t);
    await t.pumpWidget(app);
    expect(find.text('Complete Quran'), findsOneWidget);
    expect(find.text('Download complete Quran'), findsOneWidget);

    dl
      ..holdAt = 40
      ..hold = Completer();
    unawaited(dl.startQuran(const QuranPlan('ar.alafasy', ['en.sahih'], null)));
    await t.pump();
    await t.pump();
    expect(find.text('39 of 114 surahs'), findsOneWidget);
    expect(find.text('Pause'), findsOneWidget);
    expect(find.textContaining('Now: Surah 40'), findsOneWidget);

    await t.tap(find.text('Pause'));
    dl.hold.complete();
    await t.pumpAndSettle();
    expect(find.text('40 of 114 surahs'), findsOneWidget);
    expect(find.text('Resume'), findsOneWidget);
    expect(find.textContaining('Paused'), findsOneWidget);

    await t.tap(find.text('Resume'));
    await t.pumpAndSettle();
    await t.runAsync(() => dl.quranIdle);
    await t.pumpAndSettle();
    expect(find.text('Complete Quran saved'), findsOneWidget);
    expect(find.textContaining('114 surahs · 1.7 GB'), findsOneWidget, reason: 'one row for the whole Quran, not 114');
    expect(find.text('Download for another reciter'), findsOneWidget);
  });

  testWidgets('waiting for Wi-Fi offers mobile data', (t) async {
    phone(t);
    NetworkStatus.instance.debugSet(NetKind.metered);
    await t.pumpWidget(app);
    await dl.startQuran(const QuranPlan('ar.alafasy', ['en.sahih'], null));
    await t.runAsync(() => dl.quranIdle);
    await t.pump();
    expect(find.textContaining('Waiting for Wi-Fi'), findsOneWidget);
    await t.tap(find.text('Use mobile data'));
    await t.runAsync(() => dl.quranIdle);
    await t.pumpAndSettle();
    expect(find.text('Complete Quran saved'), findsOneWidget);
  });

  testWidgets('the sheet starts the complete Quran with the chosen options', (t) async {
    phone(t);
    await t.pumpWidget(app);
    await t.tap(find.text('Download complete Quran'));
    await t.pumpAndSettle();
    expect(find.text('114 surahs · 6,236 ayahs'), findsOneWidget);
    expect(find.text('Wi-Fi only'), findsOneWidget);
    expect(find.text('Quran text'), findsOneWidget);

    await t.tap(find.text('Wi-Fi only'));
    await t.pump();
    final start = find.widgetWithIcon(GoldButton, Icons.download_for_offline_rounded);
    await t.ensureVisible(start);
    await t.pumpAndSettle();
    await t.tap(start);
    await t.pumpAndSettle();
    await t.runAsync(() => dl.quranIdle);
    await t.pumpAndSettle();
    expect(dl.quranPlan!.reciterId, 'ar.alafasy');
    expect(dl.quranPlan!.wifiOnly, isFalse);
    expect(dl.quranPlan!.translations, ['en.sahih']);
    expect(find.text('Complete Quran saved'), findsOneWidget);
  });
}
