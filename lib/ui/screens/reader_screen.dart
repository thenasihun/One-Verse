import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/downloads.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../state/playback.dart';
import '../../state/settings.dart';
import '../sheets.dart';
import '../shell.dart';
import '../widgets/common.dart';
import '../widgets/quran_text.dart';

/// A surah as a list of ayah cards that follows the recitation: the list keeps
/// the current ayah in view and scrolls through a long ayah as it is recited.
class ReaderScreen extends StatefulWidget {
  final int surah;
  final int? scrollToAyah;
  const ReaderScreen({super.key, required this.surah, this.scrollToAyah});
  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> with SingleTickerProviderStateMixin {
  final controller = ScrollController();
  final keys = <int, GlobalKey>{};
  late final Ticker _ticker;
  bool follow = true;
  bool showPill = false;
  int? _jumpTo;
  final titleVisible = ValueNotifier(false);
  Future<_Data>? _future;
  String? _futureKey;

  static const _barHeight = 56.0, _trHeight = 60.0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) => _tick())..start();
    final pb = context.read<Playback>();
    _jumpTo = widget.scrollToAyah ?? (pb.hasSession && pb.surah == widget.surah ? pb.ayah : null);
    controller.addListener(() => titleVisible.value = controller.offset > 170);
  }

  @override
  void dispose() {
    _ticker.dispose();
    controller.dispose();
    super.dispose();
  }

  Future<_Data> _load(QuranRepository repo, Settings s) async {
    final verses = await repo.words(widget.surah);
    List<String>? tr;
    try {
      tr = await repo.translation(s.translationId, widget.surah);
    } catch (_) {}
    return _Data(verses, tr);
  }

  GlobalKey _key(int a) => keys.putIfAbsent(a, GlobalKey.new);

  double get _headerPad => MediaQuery.paddingOf(context).top + _barHeight + _trHeight + 8;

  /// Scroll offset that puts ayah [a] under the pinned headers, or an estimate
  /// when its card has not been built yet.
  (double, double)? _offsetOf(int a) {
    final ctx = keys[a]?.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return null;
    final reveal = RenderAbstractViewport.of(box).getOffsetToReveal(box, 0).offset;
    return (reveal - _headerPad, box.size.height);
  }

  double _estimate(int a) {
    final mounted = [for (final e in keys.entries) if (_offsetOf(e.key) != null) e.key]..sort();
    if (mounted.isEmpty) return a * 180.0;
    final first = mounted.first, last = mounted.last;
    final o1 = _offsetOf(first)!.$1;
    final avg = last > first ? (_offsetOf(last)!.$1 - o1) / (last - first) : 180.0;
    return o1 + (a - first) * avg;
  }

  void _tick() {
    if (!controller.hasClients) return;
    final pb = context.read<Playback>();
    final pos = controller.position;
    double? target;
    var smooth = true;
    if (_jumpTo != null) {
      final o = _offsetOf(_jumpTo!);
      if (o == null) {
        controller.jumpTo(_estimate(_jumpTo!).clamp(0, pos.maxScrollExtent));
        return;
      }
      target = o.$1 - 40;
      smooth = false;
      _jumpTo = null;
    } else if (follow && pb.playing && pb.surah == widget.surah) {
      final o = _offsetOf(pb.ayah);
      if (o == null) {
        controller.jumpTo(_estimate(pb.ayah).clamp(0, pos.maxScrollExtent));
        return;
      }
      final room = pos.viewportDimension - _headerPad - 24;
      final h = o.$2;
      final p = pb.ayahProgress.value;
      target = h > room ? o.$1 + (h - room) * ((p - 0.06) / 0.88).clamp(0.0, 1.0) : o.$1 - math.min(60.0, (room - h) * 0.18);
    }
    if (target == null) return;
    target = target.clamp(0.0, pos.maxScrollExtent);
    final d = target - pos.pixels;
    if (d.abs() < 0.6) return;
    controller.jumpTo(smooth ? pos.pixels + d * (d.abs() > 400 ? 0.22 : 0.085) : target);
  }

  bool _onScroll(ScrollNotification n) {
    final pb = context.read<Playback>();
    final user = (n is ScrollStartNotification && n.dragDetails != null) || (n is UserScrollNotification && n.direction != ScrollDirection.idle);
    if (user && pb.surah == widget.surah && pb.playing && follow) {
      setState(() {
        follow = false;
        showPill = true;
      });
    }
    return false;
  }

  void _resumeFollow() => setState(() {
        follow = true;
        showPill = false;
      });

  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    final repo = context.read<QuranRepository>();
    final settings = context.watch<Settings>();
    final pb = context.watch<Playback>();
    final info = repo.surah(widget.surah);
    final key = settings.translationId;
    if (_future == null || _futureKey != key) {
      _futureKey = key;
      _future = _load(repo, settings);
    }
    if (pb.surah == widget.surah && pb.playing && !follow && !showPill) showPill = true;

    return Scaffold(
      bottomNavigationBar: const SafeArea(top: false, child: MiniPlayer()),
      body: Stack(children: [
        NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: FutureBuilder<_Data>(
            future: _future,
            builder: (context, snap) {
              return CustomScrollView(controller: controller, slivers: [
                SliverAppBar(
                  pinned: true,
                  toolbarHeight: _barHeight,
                  backgroundColor: c.bg.withValues(alpha: 0.94),
                  surfaceTintColor: Colors.transparent,
                  title: ValueListenableBuilder<bool>(
                    valueListenable: titleVisible,
                    builder: (_, v, _) => AnimatedOpacity(
                      opacity: v ? 1 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: Text('${info.nameEn} · ${info.meaning}', style: T.ui(15, w: FontWeight.w700, color: c.fg)),
                    ),
                  ),
                  actions: [
                    RoundIcon(Icons.tag_rounded, tooltip: 'Go to ayah', onTap: () => showJumpSheet(context, widget.surah, _goTo)),
                    RoundIcon(Icons.text_fields_rounded, tooltip: 'Script and reading', onTap: () => showDisplaySheet(context)),
                    const SizedBox(width: 6),
                  ],
                ),
                SliverToBoxAdapter(child: _Hero(info: info)),
                SliverPersistentHeader(pinned: true, delegate: _TranslationBar(_trHeight)),
                if (snap.hasError)
                  SliverToBoxAdapter(child: _Offline(onRetry: () => setState(() => _future = _load(repo, settings))))
                else if (!snap.hasData)
                  const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(60), child: Center(child: CircularProgressIndicator(strokeWidth: 2))))
                else ...[
                  if (widget.surah != 1 && widget.surah != 9)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 22, 16, 6),
                        child: QuranText(
                          words: bismillahByScript[settings.script]!.split(' '),
                          script: settings.script,
                          fontSize: 26,
                          align: TextAlign.center,
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
                    sliver: SliverList.builder(
                      itemCount: snap.data!.verses.length,
                      itemBuilder: (_, i) {
                        final v = snap.data!.verses[i];
                        return _VerseCard(
                          key: _key(v.ayah),
                          surah: widget.surah,
                          verse: v,
                          translation: snap.data!.translation?[i],
                          edition: repo.translationById(settings.translationId),
                        );
                      },
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 160)),
                ],
              ]);
            },
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 16,
          child: Center(
            child: AnimatedSlide(
              offset: showPill && !follow ? Offset.zero : const Offset(0, 2),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: Material(
                color: c.fg,
                shape: const StadiumBorder(),
                elevation: 8,
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: _resumeFollow,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.arrow_downward_rounded, size: 17, color: c.bg),
                      const SizedBox(width: 8),
                      Text('Back to ayah ${pb.ayah}', style: T.ui(13, w: FontWeight.w700, color: c.bg)),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  void _goTo(int a) {
    final pb = context.read<Playback>();
    setState(() {
      _jumpTo = a;
      follow = true;
      showPill = false;
    });
    if (pb.surah == widget.surah && pb.hasSession) pb.seekToAyah(a, autoplay: pb.playing);
  }
}

class _Data {
  final List<VerseText> verses;
  final List<String>? translation;
  const _Data(this.verses, this.translation);
}

class _Hero extends StatelessWidget {
  final SurahInfo info;
  const _Hero({required this.info});
  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    final pb = context.watch<Playback>();
    final settings = context.watch<Settings>();
    final dl = context.watch<Downloads>();
    final current = pb.hasSession && pb.surah == info.number;
    final downloaded = dl.recordFor(info.number, settings.reciterId) != null;
    final busy = dl.jobs.containsKey(info.number);
    final r = settings.reciter;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Art(
          seed: info.number,
          radius: BorderRadius.circular(26),
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(info.nameAr, textAlign: TextAlign.right, style: T.kufi(44, color: Colors.white)),
            Text(info.nameEn, style: T.display(30, color: Colors.white)),
            const SizedBox(height: 4),
            Text('${info.meaning} · ${info.type} · ${info.ayahs} ayahs', style: T.ui(13, color: Colors.white70)),
          ]),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Row(children: [
          GoldButton(
            current && pb.playing ? 'Pause' : current ? 'Resume' : 'Play',
            icon: current && pb.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            onTap: () => current ? pb.toggle() : pb.play(info.number),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Material(
              color: c.raised,
              shape: StadiumBorder(side: BorderSide(color: c.line)),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () => showReciterSheet(context),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
                  child: Row(children: [
                    ReciterAvatar(r, size: 38),
                    const SizedBox(width: 8),
                    Expanded(child: Text(r.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.ui(13, w: FontWeight.w600, color: c.fg))),
                    Icon(Icons.expand_more_rounded, color: c.fg2),
                  ]),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: downloaded ? c.emeraldWash : c.raised,
            shape: CircleBorder(side: BorderSide(color: downloaded ? c.emerald.withValues(alpha: 0.4) : c.line)),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => showDownloadSheet(context, info.number),
              child: SizedBox(
                width: 46,
                height: 46,
                child: busy
                    ? ValueListenableBuilder<double>(
                        valueListenable: dl.jobs[info.number]!.progress,
                        builder: (_, v, _) => Padding(padding: const EdgeInsets.all(12), child: CircularProgressIndicator(value: v, strokeWidth: 2.4)),
                      )
                    : Icon(downloaded ? Icons.download_done_rounded : Icons.download_rounded, color: downloaded ? c.emerald : c.fg),
              ),
            ),
          ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Align(alignment: Alignment.centerLeft, child: SyncBadge(r.hasWordSync, suffix: ' · ${r.name}')),
      ),
      if (pb.error != null && current)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Text(pb.error!, style: T.ui(13, color: c.gold)),
        ),
      const SizedBox(height: 14),
    ]);
  }
}

class _TranslationBar extends SliverPersistentHeaderDelegate {
  final double height;
  _TranslationBar(this.height);
  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;
  @override
  bool shouldRebuild(covariant _TranslationBar old) => false;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final c = context.ov;
    final s = context.watch<Settings>();
    final repo = context.watch<QuranRepository>();
    final pb = context.read<Playback>();
    void pick(String id) {
      s.setTranslation(id);
      pb.reload();
    }

    return Container(
      decoration: BoxDecoration(color: c.bg.withValues(alpha: 0.96), border: Border(bottom: BorderSide(color: c.line))),
      child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), children: [
        OvChip(s.script.short, tint: c.gold, trailing: Icon(Icons.expand_more_rounded, size: 16, color: c.gold), onTap: () => showDisplaySheet(context)),
        const SizedBox(width: 12),
        Center(child: Text('TRANSLATION', style: T.label(c.fg3))),
        const SizedBox(width: 8),
        for (final id in s.quickTranslations) ...[
          OvChip(
            repo.translationById(id).urdu ? 'اردو · ${repo.translationById(id).englishName.split(' ').last}' : repo.translationById(id).englishName,
            urdu: false,
            selected: s.show != ShowMode.arabic && s.translationId == id,
            onTap: () => pick(id),
          ),
          const SizedBox(width: 8),
        ],
        OvChip('Arabic only', selected: s.show == ShowMode.arabic, onTap: () => s.update((x) => x.show = ShowMode.arabic)),
        const SizedBox(width: 8),
        OvChip('+ ${repo.translationList.length > 3 ? repo.translationList.length - 3 : 40} more', onTap: () => showTranslationSheet(context)),
      ]),
    );
  }
}

class _VerseCard extends StatelessWidget {
  final int surah;
  final VerseText verse;
  final String? translation;
  final TranslationEdition edition;
  const _VerseCard({super.key, required this.surah, required this.verse, required this.translation, required this.edition});

  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    final s = context.watch<Settings>();
    final pb = context.watch<Playback>();
    final active = pb.hasSession && pb.surah == surah && pb.ayah == verse.ayah;
    final words = verse.of(s.script);
    Widget arabic(int h) => QuranText(words: words, script: s.script, fontSize: s.arabicSize, ayahNumber: verse.ayah, highlight: h, active: active);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: active ? c.surface : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: active ? c.line2 : Colors.transparent)),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => active ? pb.toggle() : pb.playAyah(surah, verse.ayah),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Container(
                  height: 26,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: active ? c.goldWash : c.raised, borderRadius: BorderRadius.circular(99)),
                  child: Text('$surah:${verse.ayah}', style: T.ui(12, w: FontWeight.w700, color: active ? c.gold : c.fg3)),
                ),
                const Spacer(),
                RoundIcon(Icons.open_in_full_rounded, tooltip: 'Open in focus view', size: 36, color: c.fg2, onTap: () {
                  if (!active) pb.playAyah(surah, verse.ayah);
                  Nav.focus(context);
                }),
                RoundIcon(Icons.ios_share_rounded, tooltip: 'Share ayah', size: 36, color: c.fg2, onTap: () => shareAyah(context, surah, verse.ayah)),
              ]),
              if (s.show != ShowMode.translation)
                Padding(
                  padding: const EdgeInsets.only(top: 6, right: 6),
                  child: active
                      ? ValueListenableBuilder<int>(valueListenable: pb.word, builder: (_, h, _) => arabic(h))
                      : arabic(-2),
                ),
              if (s.show != ShowMode.arabic && translation != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10, right: 6),
                  child: TranslationText(translation!, edition, size: s.translationSize, color: active ? c.fg : c.fg2),
                ),
              if (active)
                Padding(
                  padding: const EdgeInsets.only(top: 12, right: 6),
                  child: ValueListenableBuilder<double>(
                    valueListenable: pb.ayahProgress,
                    builder: (_, v, _) => ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(value: v, minHeight: 3, color: c.gold, backgroundColor: c.line),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Offline extends StatelessWidget {
  final VoidCallback onRetry;
  const _Offline({required this.onRetry});
  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(children: [
        Icon(Icons.cloud_off_rounded, size: 40, color: c.fg3),
        const SizedBox(height: 12),
        Text('This surah is not on your device yet', style: T.ui(16, w: FontWeight.w700, color: c.fg)),
        const SizedBox(height: 6),
        Text('Connect to the internet once. After that it stays available offline for at least 30 days.',
            textAlign: TextAlign.center, style: T.ui(13.5, color: c.fg2)),
        const SizedBox(height: 16),
        GhostButton('Try again', icon: Icons.refresh_rounded, onTap: onRetry),
      ]),
    );
  }
}
