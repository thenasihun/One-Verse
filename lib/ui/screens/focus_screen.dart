import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../state/playback.dart';
import '../../state/settings.dart';
import '../sheets.dart';
import '../widgets/common.dart';
import '../widgets/quran_text.dart';

/// One ayah, full screen. Words light up as they are recited and a long ayah
/// scrolls itself in step with the recitation.
class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});
  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> with SingleTickerProviderStateMixin {
  final scroll = ScrollController();
  final verseKey = GlobalKey();
  late final Ticker _ticker;
  DateTime _manual = DateTime(2000);
  int _shownAyah = -1;
  Future<List<String>>? _tr;
  String? _trKey;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable().catchError((_) {});
    _ticker = createTicker((_) => _tick())..start();
  }

  @override
  void dispose() {
    WakelockPlus.disable().catchError((_) {});
    _ticker.dispose();
    scroll.dispose();
    super.dispose();
  }

  void _tick() {
    final pb = context.read<Playback>();
    if (!scroll.hasClients) return;
    if (_shownAyah != pb.ayah) {
      _shownAyah = pb.ayah;
      scroll.jumpTo(0);
      return;
    }
    if (!pb.playing || DateTime.now().difference(_manual).inMilliseconds < 2500) return;
    final box = verseKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final room = scroll.position.viewportDimension - 40;
    final h = box.size.height;
    final target = h > room ? (h - room) * ((pb.ayahProgress.value - 0.05) / 0.9).clamp(0.0, 1.0) + 20 : 0.0;
    final d = target.clamp(0.0, scroll.position.maxScrollExtent) - scroll.offset;
    if (d.abs() > 0.6) scroll.jumpTo(scroll.offset + d * 0.08);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    final pb = context.watch<Playback>();
    final s = context.watch<Settings>();
    final repo = context.read<QuranRepository>();
    final v = pb.verse;
    final info = pb.info;
    final k = '${pb.surah}|${s.translationId}';
    if (_trKey != k) {
      _trKey = k;
      _tr = repo.translation(s.translationId, pb.surah);
    }

    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          onHorizontalDragEnd: (d) {
            final vx = d.primaryVelocity ?? 0;
            if (vx.abs() < 250) return;
            // Swipe left for the next ayah, right for the previous one.
            vx < 0 ? pb.next() : pb.previous();
          },
          child: Column(children: [
            SizedBox(
              height: 58,
              child: Row(children: [
                const SizedBox(width: 6),
                RoundIcon(Icons.keyboard_arrow_down_rounded, tooltip: 'Close focus view', onTap: () => Navigator.pop(context)),
                Expanded(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(info.nameEn, style: T.ui(14, w: FontWeight.w700, color: c.fg)),
                    Text('${info.meaning} · Ayah ${pb.ayah} of ${info.ayahs}', style: T.ui(11.5, color: c.fg3)),
                  ]),
                ),
                RoundIcon(Icons.text_fields_rounded, tooltip: 'Script and size', onTap: () => showDisplaySheet(context)),
                const SizedBox(width: 6),
              ]),
            ),
            Expanded(
              child: NotificationListener<ScrollStartNotification>(
                onNotification: (n) {
                  if (n.dragDetails != null) _manual = DateTime.now();
                  return false;
                },
                child: ListView(controller: scroll, padding: const EdgeInsets.fromLTRB(22, 10, 22, 40), children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(99), border: Border.all(color: c.gold.withValues(alpha: 0.45))),
                      child: Text('${pb.surah}:${pb.ayah}', style: T.display(13, w: FontWeight.w800, color: c.gold).copyWith(letterSpacing: 2)),
                    ),
                    const SizedBox(width: 8),
                    SyncBadge(pb.wordExact),
                  ]),
                  const SizedBox(height: 18),
                  if (v == null)
                    const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                  else
                    Column(key: verseKey, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      if (s.show != ShowMode.translation)
                        ValueListenableBuilder<int>(
                          valueListenable: pb.word,
                          builder: (_, h, _) => QuranText(
                            words: v.of(s.script),
                            script: s.script,
                            fontSize: s.focusSize,
                            ayahNumber: v.ayah,
                            highlight: h,
                            active: true,
                            align: TextAlign.center,
                          ),
                        ),
                      if (s.show != ShowMode.arabic)
                        FutureBuilder<List<String>>(
                          future: _tr,
                          builder: (_, snap) => snap.hasData && pb.ayah - 1 < snap.data!.length
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 24),
                                  child: TranslationText(
                                    snap.data![pb.ayah - 1],
                                    repo.translationById(s.translationId),
                                    size: s.translationSize + 2,
                                    align: TextAlign.center,
                                    color: pb.phase == Phase.translation ? c.fg : c.fg2,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                    ]),
                ]),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
              child: Column(children: [
                ValueListenableBuilder<double>(
                  valueListenable: pb.ayahProgress,
                  builder: (_, p, _) => LinearProgressIndicator(value: p, minHeight: 3, color: c.gold, backgroundColor: c.line2),
                ),
                const SizedBox(height: 10),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  RoundIcon(Icons.subject_rounded, tooltip: 'Change what is shown', onTap: () {
                    s.update((x) => x.show = ShowMode.values[(x.show.index + 1) % 3]);
                  }),
                  RoundIcon(Icons.skip_previous_rounded, tooltip: 'Previous ayah', size: 50, onTap: pb.previous),
                  Material(
                    color: c.fg,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: pb.toggle,
                      child: SizedBox(width: 64, height: 64, child: Icon(pb.playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 34, color: c.bg)),
                    ),
                  ),
                  RoundIcon(Icons.skip_next_rounded, tooltip: 'Next ayah', size: 50, onTap: pb.next),
                  RoundIcon(s.repeat == 0 ? Icons.repeat_rounded : Icons.repeat_one_rounded,
                      tooltip: 'Repeat ayah', color: s.repeat == 0 ? c.fg : c.gold, onTap: pb.cycleRepeat),
                ]),
                const SizedBox(height: 4),
                Text('${s.script.short} · ${['Arabic + translation', 'Arabic only', 'Translation only'][s.show.index]} · swipe to change ayah',
                    style: T.ui(11.5, color: c.fg3)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
