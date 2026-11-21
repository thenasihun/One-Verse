import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../state/playback.dart';
import '../../state/playlists.dart';
import '../../state/settings.dart';
import '../playlists_screen.dart';
import '../player_controls.dart';
import '../sheets.dart';
import '../study.dart';
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
            // One slim row, so the ayah gets the screen.
            SizedBox(
              height: 46,
              child: Row(children: [
                const SizedBox(width: 2),
                RoundIcon(Icons.keyboard_arrow_down_rounded, tooltip: 'Close focus view', size: 40, onTap: () => Navigator.pop(context)),
                RoundIcon(Icons.chevron_left_rounded, tooltip: 'Previous surah', size: 38, onTap: pb.surah > 1 ? () => pb.play(pb.surah - 1) : null),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      final n = await showSurahPicker(context, title: 'Play a surah');
                      if (n != null) pb.play(n);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text.rich(
                        TextSpan(children: [
                          TextSpan(text: info.nameEn, style: T.ui(14, w: FontWeight.w700, color: c.fg)),
                          if (pb.ayahWise) TextSpan(text: '  ${pb.surah}:${pb.ayah}', style: T.ui(13, w: FontWeight.w800, color: c.gold)),
                          if (pb.ayahWise) TextSpan(text: ' / ${info.ayahs}', style: T.ui(12, color: c.fg3)),
                          WidgetSpan(alignment: PlaceholderAlignment.middle, child: Icon(Icons.expand_more_rounded, size: 18, color: c.fg3)),
                        ]),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                RoundIcon(Icons.chevron_right_rounded, tooltip: 'Next surah', size: 38, onTap: pb.surah < 114 ? () => pb.play(pb.surah + 1) : null),
                RoundIcon(Icons.text_fields_rounded, tooltip: 'Script and size', size: 40, onTap: () => showDisplaySheet(context)),
                const SizedBox(width: 2),
              ]),
            ),
            Expanded(
              child: NotificationListener<ScrollStartNotification>(
                onNotification: (n) {
                  if (n.dragDetails != null) _manual = DateTime.now();
                  return false;
                },
                child: ListView(controller: scroll, padding: const EdgeInsets.fromLTRB(20, 6, 20, 40), children: [
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
                ValueListenableBuilder<Duration>(
                  valueListenable: pb.surahPosition,
                  builder: (_, _, _) => LinearProgressIndicator(value: pb.surahFraction, minHeight: 3, color: c.gold, backgroundColor: c.line2),
                ),
                const SizedBox(height: 10),
                // Everything else, one tap away, in a strip that scrolls sideways.
                SizedBox(
                  height: 44,
                  child: ListView(scrollDirection: Axis.horizontal, children: [
                    _Chip(
                      leading: ReciterAvatar(s.reciter, size: 30),
                      label: s.reciter.name,
                      onTap: () => showReciterSheet(context),
                    ),
                    _Chip(
                      icon: Icons.translate_rounded,
                      label: s.show == ShowMode.arabic ? 'Translation off' : repo.translationById(s.translationId).englishName,
                      onTap: () => showTranslationQuickSheet(context),
                    ),
                    _Chip(
                      icon: s.listenMode == ListenMode.arabic ? Icons.record_voice_over_rounded : Icons.headphones_rounded,
                      label: switch (s.listenMode) {
                        ListenMode.arabic => 'Hear: Arabic',
                        ListenMode.arabicTranslation => 'Hear: Arabic + meaning',
                        ListenMode.translation => 'Hear: meaning only',
                      },
                      onTap: () => showListenSheet(context),
                    ),
                    _Chip(
                      icon: Icons.format_list_numbered_rounded,
                      label: 'Ayahs',
                      onTap: () => pb.ayahWise
                          ? showJumpSheet(context, pb.surah, (a) => pb.playAyah(pb.surah, a))
                          : toast(context, Playback.noAyahReason(s.reciter)),
                    ),
                    _Chip(icon: Icons.menu_book_rounded, label: 'Tafseer', onTap: () => showTafsirSheet(context, pb.surah, pb.ayah)),
                    _Chip(
                      icon: s.bookmarkOf(pb.surah, pb.ayah) != null ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      label: 'Bookmark',
                      onTap: () => onBookmarkTap(context, pb.surah, pb.ayah),
                    ),
                    _Chip(icon: Icons.ios_share_rounded, label: 'Share', onTap: () => shareAyah(context, pb.surah, pb.ayah)),
                    _Chip(
                      icon: Icons.playlist_add_rounded,
                      label: 'Add to playlist',
                      onTap: () => showAddToPlaylist(context, pb.ayahWise ? PlaylistItem(pb.surah, pb.ayah, pb.ayah) : PlaylistItem(pb.surah, 1, info.ayahs)),
                    ),
                  ]),
                ),
                const SizedBox(height: 8),
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
                      tooltip: 'Repeat ayah', color: s.repeat == 0 ? c.fg : c.gold, onTap: () => showRepeatSheet(context)),
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

class _Chip extends StatelessWidget {
  final IconData? icon;
  final Widget? leading;
  final String label;
  final VoidCallback onTap;
  const _Chip({this.icon, this.leading, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: c.raised,
        shape: StadiumBorder(side: BorderSide(color: c.line)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.fromLTRB(leading != null ? 6 : 12, 0, 14, 0),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              leading ?? Icon(icon, size: 18, color: c.gold),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 170),
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.ui(13, w: FontWeight.w700, color: c.fg)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
