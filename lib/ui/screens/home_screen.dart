import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/catalog.dart';
import '../../data/models.dart';
import '../../data/recommend.dart';
import '../../data/repository.dart';
import '../../state/listening_log.dart';
import '../../state/playback.dart';
import '../../state/playlists.dart';
import '../../state/settings.dart';
import '../playlists_screen.dart';
import '../sheets.dart';
import '../shell.dart';
import '../study.dart';
import '../widgets/common.dart';
import '../widgets/quran_text.dart';
import 'about_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    final pb = context.watch<Playback>();
    final repo = context.watch<QuranRepository>();
    final settings = context.watch<Settings>();
    final log = context.watch<ListeningLog>();
    if (repo.surahs.isEmpty) return const SizedBox();
    final s = repo.surah(pb.surah);
    final top = MediaQuery.paddingOf(context).top;
    final hour = DateTime.now().hour;
    final greet = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    final shown = [
      for (final id in settings.favReciters.reversed) reciterById(id),
      ...reciters.where((r) => !settings.isFavReciter(r.id)),
    ].take(14).toList();

    return ListView(padding: EdgeInsets.only(top: top, bottom: 24), children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 6, 0),
        child: Row(children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: c.gold, borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.menu_book_rounded, size: 17, color: c.goldInk),
          ),
          const SizedBox(width: 9),
          Expanded(child: Text('One Verse', style: T.display(22, color: c.fg))),
          _StreakPill(days: log.currentStreak()),
          RoundIcon(Icons.text_fields_rounded, tooltip: 'Script and reading', onTap: () => showDisplaySheet(context)),
          RoundIcon(Icons.info_outline_rounded, tooltip: 'About and credits',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutScreen()))),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Assalamu alaikum · $greet', style: T.ui(13, color: c.fg2)),
          const SizedBox(height: 2),
          Text('What will you listen to today?', style: T.display(28, color: c.fg)),
        ]),
      ),
      const SizedBox(height: 18),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _ContinueCard(surah: s, ayah: pb.ayah, reciter: pb.leadVoice, playing: pb.playing, onPlay: pb.toggle),
      ),
      Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 0), child: _TodayCard(log: log, goal: settings.goalMinutes)),
      const SectionTitle('For this moment'),
      SizedBox(
        height: 140,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          children: [
            for (final p in const Recommender().picksFor(DateTime.now(), recent: {
              for (final e in log.top('surah', daysBack: 7)) int.tryParse(e.key) ?? 0,
            }))
              Padding(padding: const EdgeInsets.only(right: 10), child: SizedBox(width: 176, child: _MomentCard(p))),
          ],
        ),
      ),
      if (settings.favSurahs.isNotEmpty) ...[
        SectionTitle('Your favourites', action: '${settings.favSurahs.length}', onAction: () => goToTab(1)),
        SizedBox(
          height: 112,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: settings.favSurahs.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) => SizedBox(width: 168, child: _SurahTile(repo.surah(settings.favSurahs[settings.favSurahs.length - 1 - i]))),
          ),
        ),
      ],
      SectionTitle('Your playlists', action: settings.playlists.isEmpty ? 'Create' : 'See all', onAction: () => PlaylistsScreen.open(context)),
      SizedBox(
        height: 84,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          children: [
            for (final p in settings.playlists) ...[_PlaylistTile(p), const SizedBox(width: 10)],
            if (settings.playlists.isEmpty)
              for (final (name, items, _) in playlistTemplates.take(3)) ...[
                _PlaylistTile(null, name: name, subtitle: items.map((it) => repo.surah(it.surah).nameEn).join(' · ')),
                const SizedBox(width: 10),
              ],
          ],
        ),
      ),
      if (settings.bookmarks.isNotEmpty) ...[
        SectionTitle('Bookmarks', action: 'See all ${settings.bookmarks.length}', onAction: () => BookmarksScreen.open(context)),
        SizedBox(
          height: 84,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: settings.bookmarks.length.clamp(0, 8),
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _BookmarkTile(settings.bookmarks[i]),
          ),
        ),
      ],
      SectionTitle('Reciters', action: 'See all ${reciters.length}', onAction: () => showReciterSheet(context)),
      // Favourite reciters first, then the best known.
      SizedBox(
        height: 150,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: shown.length,
          separatorBuilder: (_, _) => const SizedBox(width: 14),
          itemBuilder: (_, i) {
            final r = shown[i];
            final on = r.id == settings.reciterId;
            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                settings.update((x) => x.reciterId = r.id);
                pb.reload();
                toast(context, 'Now reciting: ${r.name}');
              },
              child: SizedBox(
                width: 92,
                child: Column(children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: on ? c.gold : Colors.transparent, width: 2)),
                    child: ReciterAvatar(r, size: 80),
                  ),
                  const SizedBox(height: 8),
                  Text(r.name, maxLines: 2, textAlign: TextAlign.center, style: T.ui(12.5, w: FontWeight.w600, color: c.fg, height: 1.2)),
                  Text(r.hasWordSync || r.timing != null ? r.syncLabel : r.style, style: T.ui(11, color: r.hasWordSync ? c.emerald : c.fg3)),
                ]),
              ),
            );
          },
        ),
      ),
      SectionTitle('Start here', action: 'All 114', onAction: () => goToTab(1)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.5,
          children: [
            for (final n in [1, 18, 36, 55, 67, 2])
              _SurahTile(repo.surah(n)),
          ],
        ),
      ),
      const SectionTitle('Verse of the day'),
      const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: _VerseOfDay()),
    ]);
  }
}

class _StreakPill extends StatelessWidget {
  final int days;
  const _StreakPill({required this.days});
  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    return Tooltip(
      message: '$days-day listening streak',
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: () => goToTab(2),
        child: Container(
          height: 34,
          padding: const EdgeInsets.fromLTRB(8, 0, 12, 0),
          decoration: BoxDecoration(color: c.goldWash, borderRadius: BorderRadius.circular(99)),
          child: Row(children: [
            Icon(Icons.local_fire_department_rounded, size: 18, color: c.gold),
            const SizedBox(width: 3),
            Text('$days', style: T.ui(13, w: FontWeight.w800, color: c.gold)),
          ]),
        ),
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  final SurahInfo surah;
  final int ayah;
  final Reciter reciter;
  final bool playing;
  final VoidCallback onPlay;
  const _ContinueCard({required this.surah, required this.ayah, required this.reciter, required this.playing, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Nav.surah(context, surah.number, ayah: ayah),
      child: Art(
        seed: surah.number,
        radius: BorderRadius.circular(24),
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('CONTINUE LISTENING', style: T.label(Colors.white70)),
                const SizedBox(height: 6),
                Text(surah.nameAr, style: T.kufi(34, color: Colors.white)),
                Text(surah.nameEn, style: T.display(22, w: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 6),
                Row(children: [
                  ReciterAvatar(reciter, size: 22),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text('${reciter.name} · Ayah $ayah of ${surah.ayahs}',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: T.ui(13, color: Colors.white.withValues(alpha: 0.85))),
                  ),
                ]),
              ]),
            ),
            Semantics(
              button: true,
              label: playing ? 'Pause' : 'Play',
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 6,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onPlay,
                  child: SizedBox(
                    width: 58,
                    height: 58,
                    child: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 32, color: const Color(0xFF0A1F18)),
                  ),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (ayah - 1) / surah.ayahs,
              minHeight: 4,
              color: Colors.white,
              backgroundColor: Colors.white24,
            ),
          ),
        ]),
      ),
    );
  }
}

class _MomentCard extends StatelessWidget {
  final Pick m;
  const _MomentCard(this.m);

  IconData get icon => switch (m.kind) {
        'special' => Icons.auto_awesome_rounded,
        'month' => Icons.calendar_month_rounded,
        'friday' => Icons.star_rounded,
        'morning' => Icons.wb_sunny_rounded,
        'day' => Icons.light_mode_rounded,
        'evening' => Icons.wb_twilight_rounded,
        'night' => Icons.nightlight_round,
        _ => Icons.explore_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final pb = context.read<Playback>();
    return GestureDetector(
      onTap: () {
        if (m.passage) {
          // A passage plays as a one-item playlist, so it stops at its end.
          pb.playPlaylist(Playlist(id: 'pick-${m.key}', name: m.title, items: [PlaylistItem(m.surah, m.from, m.to)]));
          Nav.surah(context, m.surah, ayah: m.from);
        } else {
          pb.play(m.surah);
          Nav.surah(context, m.surah);
        }
      },
      child: Art(
        seed: m.surah,
        radius: BorderRadius.circular(18),
        padding: const EdgeInsets.all(14),
        child: SizedBox(
          height: 112,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Icon(icon, size: 14, color: Colors.white70),
              const SizedBox(width: 6),
              Text(m.kicker.toUpperCase(), style: T.label(Colors.white70).copyWith(fontSize: 10)),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(m.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: T.ui(15, w: FontWeight.w700, color: Colors.white, height: 1.2)),
              if (m.passage) Text('${m.surah}:${m.from}${m.to > m.from ? '–${m.to}' : ''}', style: T.ui(11, w: FontWeight.w700, color: Colors.white)),
              Text(m.why, maxLines: 2, overflow: TextOverflow.ellipsis, style: T.ui(11.5, color: Colors.white70, height: 1.3)),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _SurahTile extends StatelessWidget {
  final SurahInfo s;
  const _SurahTile(this.s);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Nav.surah(context, s.number),
      child: Art(
        seed: s.number,
        radius: BorderRadius.circular(18),
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(s.nameAr, textAlign: TextAlign.right, style: T.kufi(22, color: Colors.white)),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.nameEn, style: T.ui(14.5, w: FontWeight.w700, color: Colors.white)),
            Text('${s.meaning} · ${s.ayahs} ayahs', maxLines: 1, overflow: TextOverflow.ellipsis, style: T.ui(11.5, color: Colors.white70)),
          ]),
        ]),
      ),
    );
  }
}

class _VerseOfDay extends StatefulWidget {
  const _VerseOfDay();
  @override
  State<_VerseOfDay> createState() => _VerseOfDayState();
}

class _VerseOfDayState extends State<_VerseOfDay> {
  Future<(VerseText, String)>? _future;
  String? _forTranslation;

  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    final repo = context.read<QuranRepository>();
    final settings = context.watch<Settings>();
    final (n, a) = const Recommender().verseOfTheDay(DateTime.now());
    if (_future == null || _forTranslation != settings.translationId) {
      _forTranslation = settings.translationId;
      _future = () async {
        final w = await repo.words(n);
        final t = await repo.translation(settings.translationId, n);
        return (w[a - 1], t[a - 1]);
      }();
    }
    return FutureBuilder<(VerseText, String)>(
      future: _future,
      builder: (context, snap) {
        final info = repo.surah(n);
        return Material(
          color: c.surface,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () {
              context.read<Playback>().playAyah(n, a);
              Nav.focus(context);
            },
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), border: Border.all(color: c.line)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (snap.hasData) ...[
                  QuranText(words: snap.data!.$1.of(settings.script), script: settings.script, fontSize: 22, maxLines: 3),
                  const SizedBox(height: 8),
                  TranslationText(snap.data!.$2, repo.translationById(settings.translationId), size: 13.5, maxLines: 3),
                ] else
                  SizedBox(
                    height: 90,
                    child: Center(
                      child: snap.hasError
                          ? Text('Connect once to load today\'s verse', style: T.ui(13, color: c.fg3))
                          : const CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: Text('${info.nameEn} $n:$a', style: T.ui(12.5, color: c.fg3))),
                  Icon(Icons.open_in_full_rounded, size: 15, color: c.gold),
                  const SizedBox(width: 6),
                  Text('Play in focus', style: T.ui(12.5, w: FontWeight.w600, color: c.gold)),
                ]),
              ]),
            ),
          ),
        );
      },
    );
  }
}

class _BookmarkTile extends StatelessWidget {
  final Bookmark b;
  const _BookmarkTile(this.b);
  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    final info = context.read<QuranRepository>().surah(b.surah);
    return SizedBox(
      width: 190,
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: c.line)),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Nav.surah(context, b.surah, ayah: b.ayah),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Row(children: [
                Icon(Icons.bookmark_rounded, size: 16, color: c.gold),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('${info.nameEn} ${b.surah}:${b.ayah}',
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: T.ui(13.5, w: FontWeight.w700, color: c.fg)),
                ),
              ]),
              const SizedBox(height: 4),
              Text(b.note.isNotEmpty ? b.note : info.meaning, maxLines: 2, overflow: TextOverflow.ellipsis, style: T.ui(12, color: c.fg2)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _PlaylistTile extends StatelessWidget {
  final Playlist? p;
  final String? name, subtitle;
  const _PlaylistTile(this.p, {this.name, this.subtitle});
  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    final repo = context.read<QuranRepository>();
    final list = p;
    return SizedBox(
      width: 200,
      child: Material(
        color: list == null ? c.surface : c.goldWash,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: list == null ? c.line : c.gold.withValues(alpha: 0.4))),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            if (list == null) return PlaylistsScreen.open(context);
            context.read<Playback>().playPlaylist(list);
            Nav.nowPlaying(context);
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
            child: Row(children: [
              Icon(list == null ? Icons.playlist_add_rounded : Icons.play_circle_fill_rounded, color: c.gold, size: 30),
              const SizedBox(width: 10),
              Expanded(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(list?.name ?? name!, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.ui(14, w: FontWeight.w700, color: c.fg)),
                  Text(list == null ? subtitle! : list.items.map((it) => repo.surah(it.surah).nameEn).join(' · '),
                      maxLines: 2, overflow: TextOverflow.ellipsis, style: T.ui(11.5, color: c.fg2)),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Today at a glance: minutes listened against the goal, and whether today
/// already counts for the streak. Gentle words, no countdowns.
class _TodayCard extends StatelessWidget {
  final ListeningLog log;
  final int goal;
  const _TodayCard({required this.log, required this.goal});

  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    final now = DateTime.now();
    final minutes = log.minutesOn(now);
    final streak = log.currentStreak();
    final counted = log.counts(now);
    final frac = goal <= 0 ? 0.0 : (minutes / goal).clamp(0.0, 1.0);
    final done = frac >= 1;
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: c.line)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => goToTab(2),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            SizedBox(
              width: 58,
              height: 58,
              child: Stack(alignment: Alignment.center, children: [
                SizedBox.expand(child: CircularProgressIndicator(value: frac, strokeWidth: 6, color: done ? c.emerald : c.gold, backgroundColor: c.line2)),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('${minutes.floor()}', style: T.display(18, w: FontWeight.w700, color: c.fg).copyWith(height: 1)),
                  Text('min', style: T.ui(10, color: c.fg3)),
                ]),
              ]),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('TODAY', style: T.label(c.fg3).copyWith(fontSize: 10.5)),
                const SizedBox(height: 2),
                Text(done ? 'Daily goal reached, masha\'Allah' : '${minutes.floor()} of $goal minutes',
                    style: T.ui(15, w: FontWeight.w700, color: c.fg)),
                const SizedBox(height: 2),
                Text(
                    counted
                        ? 'Today counts for your streak'
                        : streak > 0
                            ? 'One minute today keeps your $streak-day streak going'
                            : 'One minute today starts a streak',
                    style: T.ui(12.5, color: counted ? c.emerald : c.fg2)),
              ]),
            ),
            Column(children: [
              Icon(Icons.local_fire_department_rounded, color: counted ? c.gold : c.fg3),
              Text('$streak', style: T.ui(14, w: FontWeight.w800, color: counted ? c.gold : c.fg2)),
              Text(streak == 1 ? 'day' : 'days', style: T.ui(10, color: c.fg3)),
            ]),
          ]),
        ),
      ),
    );
  }
}
