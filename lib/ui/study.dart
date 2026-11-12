import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../data/models.dart';
import '../data/repository.dart';
import '../data/tafsir.dart';
import '../state/playback.dart';
import '../state/settings.dart';
import 'shell.dart';
import 'widgets/common.dart';
import 'widgets/quran_text.dart';

// ------------------------------------------------------------------ tafsir

void showTafsirSheet(BuildContext context, int surah, int ayah) {
  showOvSheet(context, title: 'Tafseer', scroll: false, builder: (_) => _TafsirSheet(surah: surah, ayah: ayah));
}

class _TafsirSheet extends StatefulWidget {
  final int surah, ayah;
  const _TafsirSheet({required this.surah, required this.ayah});
  @override
  State<_TafsirSheet> createState() => _TafsirSheetState();
}

class _TafsirSheetState extends State<_TafsirSheet> {
  late int ayah = widget.ayah;
  late Future<TafsirEntry> _entry;
  int _book = 0;
  int _groupEnd = 0; // last ayah the loaded commentary covers
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _book = context.read<Settings>().tafsir.id;
    _load();
  }

  void _load() {
    _groupEnd = ayah;
    _entry = context.read<QuranRepository>().tafsir(_book, widget.surah, ayah).then((e) {
      for (final k in e.verses) {
        final p = k.split(':');
        final a = int.tryParse(p.last) ?? 0;
        if (p.first == '${widget.surah}' && a > _groupEnd) _groupEnd = a;
      }
      return e;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _pickBook(int id) {
    setState(() {
      _book = id;
      _load();
    });
    context.read<Settings>().update((x) => x.tafsirId = id);
  }

  void _go(int a) => setState(() {
        ayah = a;
        _load();
      });

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    final repo = context.read<QuranRepository>();
    final info = repo.surah(widget.surah);
    final book = tafsirById(_book);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.72,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          height: 40,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            for (final b in tafsirBooks) ...[
              OvChip('${b.name} · ${b.languageName}', selected: b.id == _book, onTap: () => _pickBook(b.id)),
              const SizedBox(width: 8),
            ],
          ]),
        ),
        const SizedBox(height: 10),
        Row(children: [
          RoundIcon(Icons.chevron_left_rounded, tooltip: 'Previous ayah', onTap: ayah > 1 ? () => _go(ayah - 1) : null),
          Expanded(
            child: Column(children: [
              Text('${info.nameEn} ${widget.surah}:$ayah', style: T.ui(14.5, w: FontWeight.w700, color: c.fg)),
              Text('${book.name} · ${book.author}', maxLines: 1, overflow: TextOverflow.ellipsis, style: T.ui(12, color: c.fg3)),
            ]),
          ),
          // A commentary that covers a group of ayahs moves on past the group.
          RoundIcon(Icons.chevron_right_rounded, tooltip: 'Next ayah', onTap: _groupEnd < info.ayahs ? () => _go(_groupEnd + 1) : null),
        ]),
        const SizedBox(height: 6),
        Expanded(
          child: FutureBuilder<TafsirEntry>(
            future: _entry,
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.cloud_off_rounded, color: c.fg3, size: 34),
                    const SizedBox(height: 10),
                    Text('Tafseer needs the internet the first time.\nAfter that it stays on your phone.',
                        textAlign: TextAlign.center, style: T.ui(13.5, color: c.fg2)),
                    const SizedBox(height: 12),
                    GhostButton('Try again', icon: Icons.refresh_rounded, onTap: () => setState(_load)),
                  ]),
                );
              }
              if (!snap.hasData) return Center(child: CircularProgressIndicator(color: c.gold, strokeWidth: 2.4));
              final e = snap.data!;
              final others = e.verses.where((k) => k != '${widget.surah}:$ayah').toList();
              return ListView(controller: _scroll, padding: const EdgeInsets.only(bottom: 28), children: [
                if (others.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text('Explains ayahs ${e.verses.join(', ')} together', style: T.ui(12, color: c.gold)),
                  ),
                if (e.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: Text('This book explains this ayah together with the ayahs around it. Try the previous ayah.',
                        textAlign: TextAlign.center, style: T.ui(13.5, color: c.fg2)),
                  ),
                for (final b in e.blocks)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      b.text,
                      textDirection: _isRtl(b.text) ? TextDirection.rtl : TextDirection.ltr,
                      textAlign: _isRtl(b.text) ? TextAlign.right : TextAlign.left,
                      style: TextStyle(
                        fontFamily: book.urdu ? AppFonts.urdu : book.rtl ? 'NotoNaskhArabic' : AppFonts.ui,
                        fontSize: (book.urdu ? 15.5 : book.rtl ? 18 : 15) + (b.heading ? 1.5 : 0),
                        fontWeight: b.heading ? FontWeight.w700 : FontWeight.w400,
                        height: book.urdu ? 2.2 : book.rtl ? 1.9 : 1.6,
                        color: b.heading ? c.fg : c.fg2,
                      ),
                    ),
                  ),
              ]);
            },
          ),
        ),
      ]),
    );
  }

  static bool _isRtl(String s) {
    for (final r in s.runes) {
      if (r >= 0x0600 && r <= 0x06FF || r >= 0x0750 && r <= 0x077F || r >= 0xFB50 && r <= 0xFEFF) return true;
      if (r >= 0x41 && r <= 0x7A) return false;
    }
    return false;
  }
}

// ------------------------------------------------------------------ bookmarks

/// Saves the ayah, or opens its note when it is saved already.
void onBookmarkTap(BuildContext context, int surah, int ayah) {
  final s = context.read<Settings>();
  if (s.bookmarkOf(surah, ayah) == null) {
    s.saveBookmark(surah, ayah);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('Bookmarked $surah:$ayah'),
        duration: const Duration(milliseconds: 3200),
        action: SnackBarAction(label: 'Add note', onPressed: () => showBookmarkSheet(context, surah, ayah)),
      ));
  } else {
    showBookmarkSheet(context, surah, ayah);
  }
}

void showBookmarkSheet(BuildContext context, int surah, int ayah) {
  final info = context.read<QuranRepository>().surah(surah);
  showOvSheet(context, title: 'Bookmark · ${info.nameEn} $surah:$ayah', builder: (_) => _BookmarkSheet(surah: surah, ayah: ayah));
}

class _BookmarkSheet extends StatefulWidget {
  final int surah, ayah;
  const _BookmarkSheet({required this.surah, required this.ayah});
  @override
  State<_BookmarkSheet> createState() => _BookmarkSheetState();
}

class _BookmarkSheetState extends State<_BookmarkSheet> {
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    _note = TextEditingController(text: context.read<Settings>().bookmarkOf(widget.surah, widget.ayah)?.note ?? '');
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    final s = context.read<Settings>();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(
          controller: _note,
          minLines: 3,
          maxLines: 6,
          textCapitalization: TextCapitalization.sentences,
          style: T.ui(15, color: c.fg),
          decoration: InputDecoration(
            hintText: 'Your note (optional): a reflection, a lesson, why this ayah matters to you',
            hintStyle: T.ui(14, color: c.fg3),
            filled: true,
            fillColor: c.raised,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: GhostButton('Remove', icon: Icons.bookmark_remove_rounded, expand: true, onTap: () {
              s.removeBookmark(widget.surah, widget.ayah);
              Navigator.pop(context);
              toast(context, 'Bookmark removed');
            }),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GoldButton('Save', icon: Icons.check_rounded, expand: true, onTap: () {
              s.saveBookmark(widget.surah, widget.ayah, note: _note.text.trim());
              Navigator.pop(context);
            }),
          ),
        ]),
      ]),
    );
  }
}

class BookmarkButton extends StatelessWidget {
  final int surah, ayah;
  final double size;
  final Color? color;
  const BookmarkButton(this.surah, this.ayah, {super.key, this.size = 36, this.color});
  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    final saved = context.select<Settings, bool>((s) => s.bookmarkOf(surah, ayah) != null);
    return RoundIcon(saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
        tooltip: saved ? 'Bookmarked: edit note' : 'Bookmark ayah', size: size, color: saved ? c.gold : color, onTap: () => onBookmarkTap(context, surah, ayah));
  }
}

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  static void open(BuildContext context) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BookmarksScreen()));

  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    final s = context.watch<Settings>();
    final repo = context.read<QuranRepository>();
    final list = s.bookmarks;
    return Scaffold(
      appBar: AppBar(title: Text('Bookmarks', style: T.display(20, w: FontWeight.w700, color: c.fg)), backgroundColor: c.bg),
      body: list.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.bookmark_border_rounded, size: 44, color: c.fg3),
                  const SizedBox(height: 12),
                  Text('No bookmarks yet', style: T.ui(16, w: FontWeight.w700, color: c.fg)),
                  const SizedBox(height: 6),
                  Text('Tap the bookmark on any ayah in the reader to keep it here, with your own note.',
                      textAlign: TextAlign.center, style: T.ui(13.5, color: c.fg2)),
                ]),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final b = list[i];
                final info = repo.surah(b.surah);
                return Material(
                  color: c.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: c.line)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => Nav.surah(context, b.surah, ayah: b.ayah),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 6, 12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Row(children: [
                          Expanded(
                            child: Text('${info.nameEn} · ${b.surah}:${b.ayah}', style: T.ui(15, w: FontWeight.w700, color: c.fg)),
                          ),
                          RoundIcon(Icons.play_arrow_rounded, tooltip: 'Play from this ayah', size: 36, color: c.gold,
                              onTap: () => context.read<Playback>().playAyah(b.surah, b.ayah)),
                          RoundIcon(Icons.edit_note_rounded, tooltip: 'Edit note', size: 36, color: c.fg2,
                              onTap: () => showBookmarkSheet(context, b.surah, b.ayah)),
                        ]),
                        _BookmarkPreview(b),
                        if (b.note.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, right: 8),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: c.goldWash, borderRadius: BorderRadius.circular(12)),
                              child: Text(b.note, style: T.ui(13.5, color: c.fg)),
                            ),
                          ),
                      ]),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _BookmarkPreview extends StatelessWidget {
  final Bookmark b;
  const _BookmarkPreview(this.b);
  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    final repo = context.read<QuranRepository>();
    final s = context.read<Settings>();
    return FutureBuilder<(List<VerseText>, List<String>?)>(
      future: () async {
        final v = await repo.words(b.surah);
        List<String>? tr;
        try {
          tr = await repo.translation(s.translationId, b.surah);
        } catch (_) {}
        return (v, tr);
      }(),
      builder: (context, snap) {
        if (!snap.hasData || b.ayah > snap.data!.$1.length) return const SizedBox(height: 6);
        final v = snap.data!.$1[b.ayah - 1];
        final tr = snap.data!.$2;
        return Padding(
          padding: const EdgeInsets.only(top: 4, right: 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(v.plain(QuranScript.uthmani),
                textDirection: TextDirection.rtl, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: 'UthmanicHafs', fontSize: 19, height: 1.8, color: c.fg)),
            if (tr != null && b.ayah <= tr.length)
              TranslationText(tr[b.ayah - 1], repo.translationById(s.translationId), size: 13, maxLines: 2),
          ]),
        );
      },
    );
  }
}

// ------------------------------------------------------------------ memorise

void showLoopSheet(BuildContext context) {
  final pb = context.read<Playback>();
  showOvSheet(context, title: 'Memorise · ${pb.info.nameEn}', builder: (_) => const _LoopSheet());
}

class _LoopSheet extends StatefulWidget {
  const _LoopSheet();
  @override
  State<_LoopSheet> createState() => _LoopSheetState();
}

class _LoopSheetState extends State<_LoopSheet> {
  late int from, to, times;
  late Duration gap;

  @override
  void initState() {
    super.initState();
    final pb = context.read<Playback>();
    from = pb.loopFrom ?? pb.ayah;
    to = pb.loopTo ?? (pb.ayah + 2).clamp(1, pb.info.ayahs);
    times = pb.looping ? pb.loopTimes : 5;
    gap = pb.looping ? pb.loopGap : Duration.zero;
  }

  Widget _stepper(String label, int value, int max, void Function(int) set) {
    final c = context.ov;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(color: c.raised, borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          Text(label.toUpperCase(), style: T.label(c.fg3).copyWith(fontSize: 10.5)),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            RoundIcon(Icons.remove_rounded, tooltip: '$label: one less', size: 38, onTap: value > 1 ? () => setState(() => set(value - 1)) : null),
            SizedBox(width: 44, child: Text('$value', textAlign: TextAlign.center, style: T.display(22, w: FontWeight.w700, color: c.fg))),
            RoundIcon(Icons.add_rounded, tooltip: '$label: one more', size: 38, onTap: value < max ? () => setState(() => set(value + 1)) : null),
          ]),
        ]),
      ),
    );
  }

  static Widget _row(List<Widget> chips) => Row(children: [
        for (final (i, w) in chips.indexed) ...[if (i > 0) const SizedBox(width: 6), Expanded(child: w)],
      ]);

  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    final pb = context.watch<Playback>();
    final n = pb.info.ayahs;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Plays a few ayahs again and again, so they stay with you.', style: T.ui(13.5, color: c.fg2)),
      const SizedBox(height: 14),
      Row(children: [
        _stepper('From ayah', from, n, (v) {
          from = v;
          if (to < from) to = from;
        }),
        const SizedBox(width: 10),
        _stepper('To ayah', to, n, (v) {
          to = v;
          if (from > to) from = to;
        }),
      ]),
      if (n > 1)
        RangeSlider(
          values: RangeValues(from.toDouble(), to.toDouble()),
          min: 1,
          max: n.toDouble(),
          divisions: n - 1,
          activeColor: c.gold,
          labels: RangeLabels('$from', '$to'),
          onChanged: (r) => setState(() {
            from = r.start.round();
            to = r.end.round();
          }),
        ),
      const Label('How many times'),
      _row([
        for (final t in const [3, 5, 7, 10, 20, 0])
          Semantics(
            label: t == 0 ? 'Until I stop' : '$t times',
            child: OvChip(t == 0 ? '∞' : '$t×', selected: times == t, onTap: () => setState(() => times = t)),
          ),
      ]),
      const Label('Pause between rounds'),
      _row([
        for (final g in const [0, 3, 5, 10])
          OvChip(g == 0 ? 'None' : '${g}s', selected: gap.inSeconds == g, onTap: () => setState(() => gap = Duration(seconds: g))),
      ]),
      const SizedBox(height: 8),
      Text('Tip: the repeat button repeats each ayah on its own inside the loop as well.', style: T.ui(12, color: c.fg3)),
      const SizedBox(height: 16),
      Row(children: [
        if (pb.looping) ...[
          Expanded(
            child: GhostButton('Stop loop', icon: Icons.stop_rounded, expand: true, onTap: () {
              pb.clearLoop();
              Navigator.pop(context);
            }),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: GoldButton(pb.looping ? 'Update loop' : 'Start', icon: Icons.all_inclusive_rounded, expand: true, onTap: () {
            pb.setLoop(from, to, times: times, gap: gap);
            Navigator.pop(context);
          }),
        ),
      ]),
    ]);
  }
}

/// A small banner showing the running loop, with a way to stop it.
class LoopBanner extends StatelessWidget {
  const LoopBanner({super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    final pb = context.watch<Playback>();
    if (!pb.looping) return const SizedBox.shrink();
    final range = pb.loopFrom == pb.loopTo ? 'Ayah ${pb.loopFrom}' : 'Ayahs ${pb.loopFrom}–${pb.loopTo}';
    final round = pb.loopTimes == 0 ? 'round ${pb.loopRound}' : 'round ${pb.loopRound} of ${pb.loopTimes}';
    return Material(
      color: c.goldWash,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => showLoopSheet(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
          child: Row(children: [
            Icon(Icons.all_inclusive_rounded, color: c.gold, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text('Memorising · $range · $round', style: T.ui(13, w: FontWeight.w700, color: c.fg))),
            RoundIcon(Icons.close_rounded, tooltip: 'Stop loop', size: 34, onTap: pb.clearLoop),
          ]),
        ),
      ),
    );
  }
}
