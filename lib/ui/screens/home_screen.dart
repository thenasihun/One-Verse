import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/catalog.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../state/listening_log.dart';
import '../../state/playback.dart';
import '../../state/reminders.dart';
import '../../state/settings.dart';
import '../sheets.dart';
import '../shell.dart';
import '../widgets/common.dart';
import '../widgets/quran_text.dart';
import 'about_screen.dart';

class Moment {
  final int surah;
  final String kicker, title, subtitle;
  final IconData icon;
  const Moment(this.surah, this.kicker, this.title, this.subtitle, this.icon);
}

/// Suggestions for right now: special Hijri days, Friday Al-Kahf, Al-Mulk at
/// night, Ya-Sin in the morning.
List<Moment> momentsFor(DateTime now) {
  final out = <Moment>[];
  final special = specialDayOn(now);
  if (special != null) out.add(Moment(special.surah, 'Today', special.title, special.body, Icons.auto_awesome_rounded));
  final h = now.hour, d = now.weekday;
  if (d == DateTime.friday) {
    out.add(const Moment(18, 'Friday', 'Al-Kahf on Friday', 'Sunnah to recite on Jumu\'ah', Icons.star_rounded));
  } else if (d == DateTime.thursday && h >= 17) {
    out.add(const Moment(18, 'Tonight', 'Al-Kahf for Friday', 'Friday starts at maghrib', Icons.star_rounded));
  }
  if (h >= 20 || h < 4) {
    out.add(const Moment(67, 'Before sleep', 'Al-Mulk', 'Recited every night before sleeping', Icons.nightlight_round));
  } else if (h < 11) {
    out.add(const Moment(36, 'This morning', 'Ya-Sin', 'Start the day with the heart of the Quran', Icons.wb_sunny_rounded));
  } else if (h < 17) {
    out.add(const Moment(55, 'This afternoon', 'Ar-Rahman', 'Which of the favours of your Lord…', Icons.wb_sunny_rounded));
  } else {
    out.add(const Moment(56, 'This evening', 'Al-Waqi\'ah', 'A surah many recite each evening', Icons.wb_twilight_rounded));
  }
  if (out.length < 2) out.add(const Moment(67, 'Tonight', 'Al-Mulk', 'Recited every night before sleeping', Icons.nightlight_round));
  return out.take(2).toList();
}

const _verseOfDay = [(2, 255), (2, 286), (3, 190), (13, 28), (94, 5), (39, 53), (2, 152), (65, 3), (2, 186), (20, 114), (29, 69), (3, 139), (8, 46), (17, 82)];

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
      const SectionTitle('For this moment'),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          for (final (i, m) in momentsFor(DateTime.now()).indexed) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: _MomentCard(m)),
          ],
        ]),
      ),
      SectionTitle('Reciters', action: 'See all ${reciters.length}', onAction: () => showReciterSheet(context)),
      SizedBox(
        height: 150,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: 12,
          separatorBuilder: (_, _) => const SizedBox(width: 14),
          itemBuilder: (_, i) {
            final r = reciters[i];
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
                  Text(r.hasWordSync ? 'Word sync' : r.style, style: T.ui(11, color: r.hasWordSync ? c.emerald : c.fg3)),
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
  final Moment m;
  const _MomentCard(this.m);
  @override
  Widget build(BuildContext context) {
    final pb = context.read<Playback>();
    return GestureDetector(
      onTap: () {
        pb.play(m.surah);
        Nav.surah(context, m.surah);
      },
      child: Art(
        seed: m.surah,
        radius: BorderRadius.circular(18),
        padding: const EdgeInsets.all(14),
        child: SizedBox(
          height: 112,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Icon(m.icon, size: 14, color: Colors.white70),
              const SizedBox(width: 6),
              Text(m.kicker.toUpperCase(), style: T.label(Colors.white70).copyWith(fontSize: 10)),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(m.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.ui(15, w: FontWeight.w700, color: Colors.white)),
              Text(m.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: T.ui(11.5, color: Colors.white70, height: 1.3)),
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
    final day = DateTime.now().difference(DateTime(2024)).inDays;
    final (n, a) = _verseOfDay[day % _verseOfDay.length];
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
