import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../data/offline_sync.dart';
import '../data/repository.dart';
import '../state/listening_log.dart';
import '../state/playback.dart';
import '../state/reminders.dart';
import '../state/settings.dart';
import 'screens/downloads_screen.dart';
import 'screens/focus_screen.dart';
import 'screens/home_screen.dart';
import 'screens/now_playing.dart';
import 'screens/progress_screen.dart';
import 'screens/reader_screen.dart';
import 'screens/surahs_screen.dart';
import 'sheets.dart';
import 'widgets/common.dart';

/// Navigation helpers used across screens.
class Nav {
  static void surah(BuildContext context, int n, {int? ayah}) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReaderScreen(surah: n, scrollToAyah: ayah)));

  static void nowPlaying(BuildContext context) => Navigator.of(context).push(SlideUpRoute(const NowPlayingScreen()));

  static void focus(BuildContext context) => Navigator.of(context).push(SlideUpRoute(const FocusScreen()));
}

class SlideUpRoute<R> extends PageRouteBuilder<R> {
  SlideUpRoute(Widget page)
      : super(
          transitionDuration: const Duration(milliseconds: 380),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (_, _, _) => page,
          transitionsBuilder: (_, a, _, child) => SlideTransition(
            position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
            child: child,
          ),
        );
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> with WidgetsBindingObserver {
  int tab = 0;
  static final tabIndex = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    tabIndex.addListener(() => setState(() => tab = tabIndex.value));
    WidgetsBinding.instance.addPostFrameCallback((_) => _afterLaunch());
  }

  Future<void> _afterLaunch() async {
    final pb = context.read<Playback>();
    Reminders.instance.onOpen = _openPayload;
    final launch = await Reminders.instance.launchPayload();
    if (!mounted) return;
    if (launch != null) {
      _openPayload(launch);
    } else if (pb.hasSession && !pb.playing) {
      showResumeSheet(context);
    }
    _reschedule();
  }

  void _openPayload(String p) {
    final parts = p.split(':');
    final n = int.tryParse(parts.first);
    if (n == null || !mounted) return;
    Nav.surah(context, n, ayah: int.tryParse(parts.length > 1 ? parts[1] : '1'));
  }

  void _reschedule() {
    final pb = context.read<Playback>();
    final s = context.read<Settings>();
    final log = context.read<ListeningLog>();
    final repo = context.read<QuranRepository>();
    unawaited(Reminders.instance.reschedule(
      s,
      continueLabel: 'Continue ${repo.surah(pb.surah).nameEn}, ayah ${pb.ayah}.',
      continuePayload: '${pb.surah}:${pb.ayah}',
      goalMetToday: log.minutesOn(DateTime.now()) >= s.goalMinutes,
    ));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final pb = context.read<Playback>();
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      pb.saveSession();
      context.read<ListeningLog>().flush();
      _reschedule();
    }
    if (state == AppLifecycleState.resumed && context.read<Settings>().wifiPrefetch) {
      unawaited(context.read<OfflineSync>().run());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    return Scaffold(
      body: IndexedStack(index: tab, children: const [HomeScreen(), SurahsScreen(), ProgressScreen(), DownloadsScreen()]),
      bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [
        const MiniPlayer(),
        NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: c.bg,
            indicatorColor: c.goldWash,
            labelTextStyle: WidgetStateProperty.resolveWith((s) =>
                T.ui(11.5, w: FontWeight.w600, color: s.contains(WidgetState.selected) ? c.fg : c.fg3)),
            iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(color: s.contains(WidgetState.selected) ? c.gold : c.fg3)),
          ),
          child: NavigationBar(
            height: 66,
            selectedIndex: tab,
            onDestinationSelected: (i) => tabIndex.value = i,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book_rounded), label: 'Surahs'),
              NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights_rounded), label: 'Progress'),
              NavigationDestination(icon: Icon(Icons.download_for_offline_outlined), selectedIcon: Icon(Icons.download_for_offline_rounded), label: 'Library'),
            ],
          ),
        ),
      ]),
    );
  }
}

void goToTab(int i) => _ShellState.tabIndex.value = i;

/// Compact player docked above the navigation bar.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final pb = context.watch<Playback>();
    final repo = context.read<QuranRepository>();
    if (!pb.hasSession || repo.surahs.isEmpty) return const SizedBox.shrink();
    final c = context.ov;
    final s = repo.surah(pb.surah);
    final r = pb.leadVoice;
    final settings = context.read<Settings>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
      child: Material(
        color: c.raised2,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Nav.nowPlaying(context),
          child: Stack(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 4, 10),
              child: Row(children: [
                ReciterAvatar(r, size: 42, radius: 10),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${s.nameEn} · Ayah ${pb.ayah}', maxLines: 1, overflow: TextOverflow.ellipsis, style: T.ui(13.5, w: FontWeight.w700, color: c.fg)),
                    Text(
                      pb.error ?? (r.name + (settings.listenMode.index == 1 ? ' + ${settings.translationVoice.name}' : '')),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: T.ui(12, color: pb.error != null ? c.gold : c.fg2),
                    ),
                  ]),
                ),
                if (pb.loading)
                  const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))
                else
                  RoundIcon(pb.playing ? Icons.pause_rounded : Icons.play_arrow_rounded, tooltip: pb.playing ? 'Pause' : 'Play', size: 44, onTap: pb.toggle),
                RoundIcon(Icons.skip_next_rounded, tooltip: 'Next ayah', size: 44, onTap: pb.next),
              ]),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 3,
              child: ValueListenableBuilder<double>(
                valueListenable: pb.ayahProgress,
                builder: (_, v, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(value: v, minHeight: 2, color: c.fg, backgroundColor: c.line2),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
