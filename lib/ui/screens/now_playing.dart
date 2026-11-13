import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/downloads.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../state/playback.dart';
import '../../state/settings.dart';
import '../sheets.dart';
import '../shell.dart';
import '../player_controls.dart';
import '../study.dart';
import '../widgets/common.dart';
import '../widgets/quran_text.dart';

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    final pb = context.watch<Playback>();
    final s = context.watch<Settings>();
    final repo = context.read<QuranRepository>();
    final dl = context.watch<Downloads>();
    final info = repo.surah(pb.surah);
    final lead = pb.leadVoice;
    final art = artFor(pb.surah);
    final downloaded = dl.recordFor(pb.surah, s.reciterId) != null;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0, 0.55],
            colors: [Color.lerp(art[0], c.bg, 0.45)!, c.bg],
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            SizedBox(
              height: 58,
              child: Row(children: [
                const SizedBox(width: 6),
                RoundIcon(Icons.keyboard_arrow_down_rounded, tooltip: 'Close', onTap: () => Navigator.pop(context)),
                Expanded(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('PLAYING FROM SURAH', style: T.label(c.fg2).copyWith(fontSize: 10)),
                    Text('${info.nameEn} · ${info.meaning}', maxLines: 1, overflow: TextOverflow.ellipsis, style: T.ui(13.5, w: FontWeight.w700, color: c.fg)),
                  ]),
                ),
                RoundIcon(Icons.menu_book_rounded, tooltip: 'Open surah', onTap: () {
                  Navigator.pop(context);
                  Nav.surah(context, pb.surah, ayah: pb.ayah);
                }),
                const SizedBox(width: 6),
              ]),
            ),
            Expanded(
              child: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 28), children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: Art(
                    seed: pb.surah,
                    radius: BorderRadius.circular(24),
                    padding: const EdgeInsets.all(18),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(info.nameAr, textAlign: TextAlign.right, style: T.kufi(54, color: Colors.white)),
                      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Container(
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                          padding: const EdgeInsets.all(2),
                          child: ReciterAvatar(lead, size: 54),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(lead.name, style: T.ui(14.5, w: FontWeight.w700, color: Colors.white)),
                            Text(
                                [lead.style, repo.profileOf(lead)?.country ?? lead.language].whereType<String>().join(' · '),
                                style: T.ui(12, color: Colors.white70)),
                          ]),
                        ),
                        Text('${pb.ayah}', style: T.display(74, color: Colors.white).copyWith(height: 0.9)),
                      ]),
                    ]),
                  ),
                ),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: Text('${info.nameEn}, Ayah ${pb.ayah}', style: T.display(24, w: FontWeight.w700, color: c.fg))),
                  FavButton.surah(pb.surah, size: 40),
                ]),
                InkWell(
                  onTap: () => showReciterSheet(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(children: [
                      Flexible(
                        child: Text(
                          s.listenMode == ListenMode.arabic ? s.reciter.name : '${s.reciter.name} · ${s.translationVoice.name}',
                          overflow: TextOverflow.ellipsis,
                          style: T.ui(14, color: c.fg2),
                        ),
                      ),
                      Icon(Icons.expand_more_rounded, size: 18, color: c.fg2),
                    ]),
                  ),
                ),
                const SizedBox(height: 6),
                Align(alignment: Alignment.centerLeft, child: SyncBadge(pb.leadVoice)),
                const SizedBox(height: 14),
                const _Seek(),
                if (info.ayahs <= 80) ...[const SizedBox(height: 10), const _AyahStrip()],
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  _RepeatButton(repeat: s.repeat, onTap: () => showRepeatSheet(context)),
                  RoundIcon(Icons.skip_previous_rounded, tooltip: 'Previous ayah', size: 54, onTap: pb.previous),
                  Material(
                    color: c.fg,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: pb.toggle,
                      child: SizedBox(
                        width: 76,
                        height: 76,
                        child: pb.loading
                            ? Padding(padding: const EdgeInsets.all(26), child: CircularProgressIndicator(strokeWidth: 2.4, color: c.bg))
                            : Icon(pb.playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 40, color: c.bg),
                      ),
                    ),
                  ),
                  RoundIcon(Icons.skip_next_rounded, tooltip: 'Next ayah', size: 54, onTap: pb.next),
                  Tooltip(
                    message: 'Speed',
                    child: InkResponse(
                      onTap: () => showSpeedSheet(context),
                      radius: 28,
                      child: SizedBox(
                        width: 52,
                        height: 52,
                        child: Center(child: Text('${s.speed}×', style: T.ui(15, w: FontWeight.w800, color: s.speed == 1 ? c.fg : c.gold))),
                      ),
                    ),
                  ),
                ]),
                if (pb.error != null)
                  Padding(padding: const EdgeInsets.only(top: 12), child: Text(pb.error!, textAlign: TextAlign.center, style: T.ui(13, color: c.gold))),
                if (pb.looping) const Padding(padding: EdgeInsets.only(top: 12), child: LoopBanner()),
                if (pb.runItem != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Material(
                      color: c.goldWash,
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
                        child: Row(children: [
                          Icon(Icons.queue_music_rounded, color: c.gold, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text('${pb.run!.name} · ${pb.runIndex + 1} of ${pb.run!.items.length}'
                                '${pb.runIndex + 1 < pb.run!.items.length ? ' · next: ${repo.surah(pb.run!.items[pb.runIndex + 1].surah).nameEn}' : ''}',
                                maxLines: 1, overflow: TextOverflow.ellipsis, style: T.ui(13, w: FontWeight.w700, color: c.fg)),
                          ),
                          RoundIcon(Icons.close_rounded, tooltip: 'Leave playlist', size: 34, onTap: pb.stopPlaylist),
                        ]),
                      ),
                    ),
                  ),
                const SizedBox(height: 22),
                const PlayerDeck(),
                const SizedBox(height: 22),
                const _Lyric(),
                const Label('More'),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.05,
                  children: [
                  for (final (icon, label, lit, onTap) in [
                    (Icons.all_inclusive_rounded, pb.looping ? 'Memorising' : 'Memorise', pb.looping, () => showLoopSheet(context)),
                    (Icons.menu_book_rounded, 'Tafseer', false, () => showTafsirSheet(context, pb.surah, pb.ayah)),
                    (s.bookmarkOf(pb.surah, pb.ayah) != null ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, 'Bookmark',
                        s.bookmarkOf(pb.surah, pb.ayah) != null, () => onBookmarkTap(context, pb.surah, pb.ayah)),
                    (Icons.bedtime_rounded, pb.sleepAt != null ? 'Sleep ${fmtDur(pb.sleepAt!.difference(DateTime.now()))}' : pb.sleepEndOfSurah ? 'End of surah' : 'Sleep timer',
                        pb.sleepAt != null || pb.sleepEndOfSurah, () => showSleepSheet(context)),
                    (downloaded ? Icons.download_done_rounded : Icons.download_rounded, downloaded ? 'Offline' : 'Download', downloaded,
                        () => showDownloadSheet(context, pb.surah)),
                    (Icons.ios_share_rounded, 'Share', false, () => shareAyah(context, pb.surah, pb.ayah)),
                    (Icons.open_in_full_rounded, 'Focus', false, () => Nav.focus(context)),
                    (Icons.tag_rounded, 'Go to ayah', false, () => showJumpSheet(context, pb.surah, (a) => pb.seekToAyah(a, autoplay: true))),
                  ])
                      Material(
                        color: c.surface,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: c.line)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: onTap,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(icon, color: lit ? c.gold : c.fg),
                              const SizedBox(height: 6),
                              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.ui(11.5, w: FontWeight.w600, color: c.fg2)),
                            ]),
                          ),
                        ),
                      ),
                ]),
                const Label('Up next'),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: s.autoNext,
                  activeTrackColor: c.gold,
                  onChanged: (v) => s.update((x) => x.autoNext = v),
                  title: Text('Play the next surah', style: T.ui(14, w: FontWeight.w600, color: c.fg)),
                  subtitle: Text(
                      pb.surah < 114 ? 'When ${pb.info.nameEn} ends, ${repo.surah(pb.surah + 1).nameEn} starts by itself' : 'An-Nas is the last surah',
                      style: T.ui(12, color: c.fg3)),
                ),
                const _UpNext(),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// The player bar: time across the whole surah. Each ayah card in the reader
/// shows the ayah's own progress.
class _Seek extends StatefulWidget {
  const _Seek();
  @override
  State<_Seek> createState() => _SeekState();
}

class _SeekState extends State<_Seek> {
  double? _drag;

  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    final pb = context.read<Playback>();
    final s = context.watch<Settings>();
    return ValueListenableBuilder<Duration>(
      valueListenable: pb.surahLength,
      builder: (_, len, _) => ValueListenableBuilder<Duration>(
        valueListenable: pb.surahPosition,
        builder: (_, pos, _) {
          final total = len.inMilliseconds;
          final v = _drag ?? (total > 0 ? pos.inMilliseconds / total : 0.0);
          final shown = _drag != null ? Duration(milliseconds: (_drag! * total).round()) : pos;
          return Column(children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 5,
                activeTrackColor: c.fg,
                thumbColor: c.fg,
                inactiveTrackColor: c.line2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: SliderComponentShape.noOverlay,
              ),
              child: Slider(
                value: v.clamp(0.0, 1.0),
                onChanged: total == 0 ? null : (x) => setState(() => _drag = x),
                onChangeEnd: (x) async {
                  await pb.seekInSurah(Duration(milliseconds: (x * total).round()));
                  if (mounted) setState(() => _drag = null);
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Text(fmtDur(shown), style: T.ui(11.5, color: c.fg3)),
              Expanded(
                child: Text(
                  s.listenMode == ListenMode.arabicTranslation ? (pb.phase == Phase.translation ? 'Translation' : 'Arabic') : '',
                  textAlign: TextAlign.center,
                  style: T.ui(11.5, w: FontWeight.w600, color: c.fg3),
                ),
              ),
              Text('-${fmtDur(len - shown)}', style: T.ui(11.5, color: c.fg3)),
            ]),
          ]);
        },
      ),
    );
  }
}

class _AyahStrip extends StatelessWidget {
  const _AyahStrip();
  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    final pb = context.watch<Playback>();
    final n = pb.info.ayahs;
    return SizedBox(
      height: 18,
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (var a = 1; a <= n; a++)
          Expanded(
            child: GestureDetector(
              onTap: () => pb.seekToAyah(a, autoplay: true),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                height: a == pb.ayah ? 18 : 6,
                decoration: BoxDecoration(
                  color: a == pb.ayah ? c.gold : a < pb.ayah ? c.fg.withValues(alpha: 0.55) : c.line2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

class _RepeatButton extends StatelessWidget {
  final int repeat;
  final VoidCallback onTap;
  const _RepeatButton({required this.repeat, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    return Tooltip(
      message: 'Repeat ayah',
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: SizedBox(
          width: 52,
          height: 52,
          child: Stack(alignment: Alignment.center, children: [
            Icon(repeat == 0 ? Icons.repeat_rounded : Icons.repeat_one_rounded, size: 28, color: repeat == 0 ? c.fg : c.gold),
            if (repeat != 0)
              Positioned(
                right: 2,
                bottom: 4,
                child: Text(repeat < 0 ? '∞' : '$repeat×', style: T.ui(10.5, w: FontWeight.w800, color: c.gold)),
              ),
          ]),
        ),
      ),
    );
  }
}

class _Lyric extends StatefulWidget {
  const _Lyric();
  @override
  State<_Lyric> createState() => _LyricState();
}

class _LyricState extends State<_Lyric> {
  Future<List<String>>? _tr;
  String? _key;

  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    final pb = context.watch<Playback>();
    final s = context.watch<Settings>();
    final repo = context.read<QuranRepository>();
    final v = pb.verse;
    final k = '${pb.surah}|${s.translationId}';
    if (_key != k) {
      _key = k;
      _tr = repo.translation(s.translationId, pb.surah);
    }
    if (v == null) return const SizedBox.shrink();
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: c.line)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Nav.focus(context),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: Text('${pb.info.nameEn} ${pb.surah}:${pb.ayah}', style: T.ui(12, w: FontWeight.w600, color: c.fg3))),
              Icon(Icons.open_in_full_rounded, size: 14, color: c.gold),
              const SizedBox(width: 4),
              Text('Focus view', style: T.ui(12, w: FontWeight.w600, color: c.gold)),
            ]),
            const SizedBox(height: 8),
            if (s.show != ShowMode.translation)
              ValueListenableBuilder<int>(
                valueListenable: pb.word,
                builder: (_, h, _) =>
                    QuranText(words: v.of(s.script), script: s.script, fontSize: 23, ayahNumber: v.ayah, highlight: h, active: true),
              ),
            if (s.show != ShowMode.arabic)
              FutureBuilder<List<String>>(
                future: _tr,
                builder: (_, snap) => snap.hasData && pb.ayah - 1 < snap.data!.length
                    ? Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: TranslationText(snap.data![pb.ayah - 1], repo.translationById(s.translationId), size: 14),
                      )
                    : const SizedBox.shrink(),
              ),
          ]),
        ),
      ),
    );
  }
}

class _UpNext extends StatelessWidget {
  const _UpNext();
  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    final pb = context.watch<Playback>();
    final s = context.watch<Settings>();
    final next = [for (var a = pb.ayah + 1; a <= pb.verses.length && a <= pb.ayah + 5; a++) pb.verses[a - 1]];
    if (next.isEmpty) return Text('Last ayah of ${pb.info.nameEn}.', style: T.ui(13, color: c.fg3));
    return Column(children: [
      for (final v in next)
        InkWell(
          onTap: () => pb.seekToAyah(v.ayah, autoplay: true),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
            child: Row(children: [
              StarNumber(v.ayah, size: 34),
              const SizedBox(width: 12),
              Expanded(
                child: QuranText(words: v.of(s.script), script: s.script, fontSize: 18, maxLines: 1),
              ),
            ]),
          ),
        ),
    ]);
  }
}
