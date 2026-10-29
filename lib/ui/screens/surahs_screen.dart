import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/downloads.dart';
import '../../data/repository.dart';
import '../../state/playback.dart';
import '../sheets.dart';
import '../shell.dart';
import '../widgets/common.dart';

class SurahsScreen extends StatefulWidget {
  const SurahsScreen({super.key});
  @override
  State<SurahsScreen> createState() => _SurahsScreenState();
}

class _SurahsScreenState extends State<SurahsScreen> {
  String q = '';
  String filter = 'all';

  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    final repo = context.watch<QuranRepository>();
    final dl = context.watch<Downloads>();
    final pb = context.watch<Playback>();
    final query = q.trim().toLowerCase();
    final list = repo.surahs.where((s) {
      if (filter == 'M' && !s.meccan) return false;
      if (filter == 'D' && s.meccan) return false;
      if (filter == 'off' && dl.recordFor(s.number) == null) return false;
      if (query.isEmpty) return true;
      return '${s.number}' == query ||
          s.nameEn.toLowerCase().replaceAll('-', '').contains(query.replaceAll('-', '').replaceAll(' ', '')) ||
          s.nameEn.toLowerCase().contains(query) ||
          s.meaning.toLowerCase().contains(query) ||
          s.nameAr.contains(q.trim());
    }).toList();

    return CustomScrollView(slivers: [
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 10, 8, 0),
          child: Row(children: [
            Expanded(child: Text('Surahs', style: T.display(26, color: c.fg))),
            RoundIcon(Icons.text_fields_rounded, tooltip: 'Script and reading', onTap: () => showDisplaySheet(context)),
          ]),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            onChanged: (v) => setState(() => q = v),
            decoration: InputDecoration(
              hintText: 'Search by name, meaning or number',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: c.raised,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c.line)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c.line)),
            ),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 56,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), children: [
            for (final (k, l) in [('all', 'All'), ('M', 'Meccan'), ('D', 'Medinan'), ('off', 'Downloaded')])
              Padding(padding: const EdgeInsets.only(right: 8), child: OvChip(l, selected: filter == k, onTap: () => setState(() => filter = k))),
          ]),
        ),
      ),
      if (list.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Text(filter == 'off' ? 'Nothing downloaded yet. Open a surah and tap the download button.' : 'No surah matches "$q".',
                textAlign: TextAlign.center, style: T.ui(14, color: c.fg3)),
          ),
        ),
      SliverList.builder(
        itemCount: list.length,
        itemBuilder: (_, i) {
          final s = list[i];
          final playing = pb.hasSession && pb.surah == s.number;
          return InkWell(
            onTap: () => Nav.surah(context, s.number),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(children: [
                StarNumber(s.number),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Flexible(child: Text(s.nameEn, overflow: TextOverflow.ellipsis, style: T.ui(15.5, w: FontWeight.w600, color: c.fg))),
                      if (dl.recordFor(s.number) != null) ...[
                        const SizedBox(width: 6),
                        CircleAvatar(radius: 8, backgroundColor: c.emerald, child: const Icon(Icons.check_rounded, size: 11, color: Colors.white)),
                      ],
                      if (playing) ...[const SizedBox(width: 8), _Eq(active: pb.playing)],
                    ]),
                    Text('${s.meaning} · ${s.type} · ${s.ayahs} ayahs', style: T.ui(12.5, color: c.fg3)),
                  ]),
                ),
                Text(s.nameAr, style: T.kufi(19, color: c.fg2)),
              ]),
            ),
          );
        },
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 24)),
    ]);
  }
}

class _Eq extends StatefulWidget {
  final bool active;
  const _Eq({required this.active});
  @override
  State<_Eq> createState() => _EqState();
}

class _EqState extends State<_Eq> with SingleTickerProviderStateMixin {
  late final AnimationController a = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  @override
  void initState() {
    super.initState();
    if (widget.active) a.repeat();
  }

  @override
  void didUpdateWidget(_Eq old) {
    super.didUpdateWidget(old);
    widget.active ? a.repeat() : a.stop();
  }

  @override
  void dispose() {
    a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    return AnimatedBuilder(
      animation: a,
      builder: (_, _) => Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (final p in [0.0, 0.4, 0.7])
          Container(
            margin: const EdgeInsets.only(right: 2),
            width: 3,
            height: 3 + 9 * (0.5 + 0.5 * (1 - ((a.value + p) % 1 * 2 - 1).abs())),
            decoration: BoxDecoration(color: c.gold, borderRadius: BorderRadius.circular(2)),
          ),
      ]),
    );
  }
}
