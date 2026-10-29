import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'data/cache_store.dart';
import 'data/downloads.dart';
import 'data/network.dart';
import 'data/offline_sync.dart';
import 'data/repository.dart';
import 'state/audio_handler.dart';
import 'state/listening_log.dart';
import 'state/playback.dart';
import 'state/reminders.dart';
import 'state/settings.dart';
import 'ui/shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent, systemNavigationBarColor: Colors.transparent));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Lets browser-based UI tests find widgets by their labels (web only).
  if (kIsWeb && Uri.base.queryParameters['a11y'] == '1') SemanticsBinding.instance.ensureSemantics();

  final services = await AppServices.create();
  runApp(OneVerseApp(services: services));
}

/// Every long-lived object, created once at start-up.
class AppServices {
  final Settings settings;
  final QuranRepository repo;
  final Downloads downloads;
  final OfflineSync sync;
  final ListeningLog log;
  final Playback playback;

  AppServices._(this.settings, this.repo, this.downloads, this.sync, this.log, this.playback);

  static Future<AppServices> create({OvAudioHandler? handler}) async {
    await CacheStore.instance.init().catchError((Object e) => debugPrint('Storage: $e'));
    await NetworkStatus.instance.init();
    final settings = Settings();
    await settings.load();
    final repo = QuranRepository();
    await repo.init();
    final downloads = Downloads(repo);
    await downloads.init();
    final sync = OfflineSync(repo, translationId: settings.translationId, reciterId: settings.reciterId);
    await sync.init();
    final log = ListeningLog();
    await log.init();

    var h = handler;
    if (h == null) {
      final player = AudioPlayer();
      try {
        final session = await AudioSession.instance;
        await session.configure(const AudioSessionConfiguration.music());
        h = await AudioService.init(
          builder: () => OvAudioHandler(player),
          config: const AudioServiceConfig(
            androidNotificationChannelId: 'com.nasihun.oneverse.playback',
            androidNotificationChannelName: 'Recitation',
            androidNotificationIcon: 'drawable/ic_ov_notification',
            androidNotificationOngoing: true,
            androidStopForegroundOnPause: true,
            notificationColor: Color(0xFF064E3B),
            artDownscaleWidth: 512,
            artDownscaleHeight: 512,
          ),
        );
      } catch (e) {
        debugPrint('Audio service unavailable: $e');
        h = OvAudioHandler(player);
      }
    }

    final playback = Playback(repo: repo, settings: settings, downloads: downloads, log: log, sync: sync, handler: h);
    await playback.restore();

    settings.addListener(() {
      sync.translationId = settings.translationId;
      sync.reciterId = settings.reciterId;
    });
    if (settings.wifiPrefetch) unawaited(Future.delayed(const Duration(seconds: 4), sync.run));
    unawaited(Reminders.instance.init());
    return AppServices._(settings, repo, downloads, sync, log, playback);
  }
}

class OneVerseApp extends StatelessWidget {
  final AppServices services;
  const OneVerseApp({super.key, required this.services});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: services.settings),
        ChangeNotifierProvider.value(value: services.repo),
        ChangeNotifierProvider.value(value: services.downloads),
        ChangeNotifierProvider.value(value: services.sync),
        ChangeNotifierProvider.value(value: services.log),
        ChangeNotifierProvider.value(value: services.playback),
        ChangeNotifierProvider.value(value: NetworkStatus.instance),
      ],
      child: Selector<Settings, ThemeMode>(
        selector: (_, s) => s.themeMode,
        builder: (context, mode, _) => MaterialApp(
          title: 'One Verse',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.build(Brightness.light),
          darkTheme: AppTheme.build(Brightness.dark),
          themeMode: mode,
          home: const Shell(),
        ),
      ),
    );
  }
}
