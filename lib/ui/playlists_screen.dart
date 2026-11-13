import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../data/catalog.dart';
import '../data/downloads.dart';
import '../data/models.dart';
import '../data/repository.dart';
import '../state/playback.dart';
import '../state/playlists.dart';
import '../state/reminders.dart';
import '../state/settings.dart';
import 'sheets.dart';
import 'shell.dart';
import 'screens/surahs_screen.dart';
import 'widgets/common.dart';

String itemLabel(SurahInfo s, PlaylistItem it) =>
    it.from == 1 && it.to == s.ayahs ? 'Whole surah' : it.from == it.to ? 'Ayah ${it.from}' : 'Ayahs ${it.from}–${it.to}';

String remindLabel(BuildContext context, Playlist p) {
  if (!p.remind) return 'No reminder';
  final t = TimeOfDay(hour: p.remindAt ~/ 60, minute: p.remindAt % 60).format(context);
  if (p.daily) return 'Every day at $t';
  const names = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return '${(p.days.toList()..sort()).map((d) => names[d]).join(', ')} at $t';
}

class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  static void open(BuildContext context) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PlaylistsScreen()));

  Playlist _new(String name, {List<PlaylistItem>? items, int? at}) => Playlist(
        id: DateTime.now().microsecondsSinceEpoch.toRadixString(36),
        name: name,
        items: items == null ? null : List.of(items),
        remind: at != null,
        remindAt: at ?? 6 * 60,
      );

  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    final s = context.watch<Settings>();
    final repo = context.read<QuranRepository>();
    return Scaffold(
      appBar: AppBar(backgroundColor: c.bg, title: Text('Playlists', style: T.display(20, w: FontWeight.w700, color: c.fg))),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: c.gold,
        foregroundColor: c.goldInk,
        onPressed: () {
          final p = _new('My playlist');
          s.savePlaylist(p);
          PlaylistEditor.open(context, p.id);
        },
        icon: const Icon(Icons.add_rounded),
        label: Text('New playlist', style: T.ui(14.5, w: FontWeight.w700, color: c.goldInk)),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 110), children: [
        Text('Your own order of surahs and passages, with your reciter, and a reminder when you want it.',
            style: T.ui(13.5, color: c.fg2)),
        const SizedBox(height: 12),
        for (final p in s.playlists) ...[
          _PlaylistCard(p),
          const SizedBox(height: 10),
        ],
        const Label('Start from a ready list'),
        for (final (name, items, at) in playlistTemplates)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: c.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: c.line)),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: Text(name, style: T.ui(15, w: FontWeight.w700, color: c.fg)),
                subtitle: Text(items.map((it) => repo.surah(it.surah).nameEn).join(' · '), style: T.ui(12.5, color: c.fg2)),
                trailing: Icon(Icons.add_circle_outline_rounded, color: c.gold),
                onTap: () {
                  final p = _new(name, items: items, at: at);
                  s.savePlaylist(p);
                  Reminders.instance.requestReschedule?.call();
                  PlaylistEditor.open(context, p.id);
                },
              ),
            ),
          ),
      ]),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  final Playlist p;
  const _PlaylistCard(this.p);
  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    final repo = context.read<QuranRepository>();
    final pb = context.watch<Playback>();
    final playing = pb.run?.id == p.id;
    final reciter = p.reciterId == null ? 'Your chosen reciter' : reciterById(p.reciterId!).name;
    return Material(
      color: playing ? c.goldWash : c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: playing ? c.gold : c.line)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => PlaylistEditor.open(context, p.id),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.name, style: T.ui(16, w: FontWeight.w700, color: c.fg)),
                const SizedBox(height: 2),
                Text('${p.items.length} ${p.items.length == 1 ? 'item' : 'items'} · $reciter', style: T.ui(12.5, color: c.fg2)),
                if (p.items.isNotEmpty)
                  Text(p.items.map((it) => repo.surah(it.surah).nameEn).join(' · '),
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: T.ui(12, color: c.fg3)),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(p.remind ? Icons.notifications_active_rounded : Icons.notifications_off_outlined, size: 15, color: p.remind ? c.gold : c.fg3),
                  const SizedBox(width: 5),
                  Flexible(child: Text(remindLabel(context, p), style: T.ui(12, color: p.remind ? c.gold : c.fg3))),
                ]),
              ]),
            ),
            Material(
              color: c.gold,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: p.items.isEmpty
                    ? null
                    : () {
                        pb.playPlaylist(p);
                        Nav.nowPlaying(context);
                      },
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: Icon(Icons.play_arrow_rounded, size: 30, color: c.goldInk, semanticLabel: 'Play ${p.name}'),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class PlaylistEditor extends StatefulWidget {
  final String id;
  const PlaylistEditor({super.key, required this.id});

  static void open(BuildContext context, String id) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlaylistEditor(id: id)));

  @override
  State<PlaylistEditor> createState() => _PlaylistEditorState();
}

class _PlaylistEditorState extends State<PlaylistEditor> {
  late final TextEditingController _name;

  Playlist? get p => context.read<Settings>().playlistById(widget.id);

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: context.read<Settings>().playlistById(widget.id)?.name ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    Reminders.instance.requestReschedule?.call();
    super.dispose();
  }

  void _save(void Function(Playlist p) change) {
    final list = p;
    if (list == null) return;
    change(list);
    context.read<Settings>().savePlaylist(list);
  }

  Future<void> _addSurah() async {
    final n = await showSurahPicker(context);
    if (n == null || !mounted) return;
    final s = context.read<QuranRepository>().surah(n);
    _save((x) => x.items.add(PlaylistItem(n, 1, s.ayahs)));
  }

  Reciter get _reciter {
    final id = p?.reciterId;
    return id == null ? context.read<Settings>().reciter : reciterById(id);
  }

  bool _downloading = false;

  /// Saves every surah of the list with its reciter (and the translation
  /// voice when it is heard), one after another.
  Future<void> _download() async {
    final list = p;
    if (list == null) return;
    final s = context.read<Settings>();
    final dl = context.read<Downloads>();
    final r = _reciter;
    final voice = s.listenMode == ListenMode.arabic ? null : s.translationVoice;
    setState(() => _downloading = true);
    try {
      for (final n in {for (final it in list.items) it.surah}) {
        if (!mounted || !_downloading) break;
        if (dl.recordFor(n, r.id) != null) continue;
        await dl.download(surah: n, reciter: r, translations: [s.translationId], voice: voice);
      }
      if (mounted && _downloading) toast(context, '${list.name} is saved on this phone');
    } catch (e) {
      if (mounted) toast(context, 'Download stopped: ${e.toString().split('\n').first}');
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _editItem(int i) async {
    final list = p!;
    final it = list.items[i];
    if (!_reciter.hasAyahSync) return toast(context, Playback.noAyahReason(_reciter));
    final s = context.read<QuranRepository>().surah(it.surah);
    final r = await showRangeSheet(context, s, it.from, it.to);
    if (r != null) _save((x) => x.items[i] = PlaylistItem(it.surah, r.$1, r.$2));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    context.watch<Settings>();
    final list = p;
    if (list == null) return const Scaffold();
    final repo = context.read<QuranRepository>();
    final dlw = context.watch<Downloads>();
    final reciter = list.reciterId == null ? null : reciterById(list.reciterId!);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: c.bg,
        title: Text('Edit playlist', style: T.display(19, w: FontWeight.w700, color: c.fg)),
        actions: [
          IconButton(
            tooltip: 'Delete playlist',
            icon: Icon(Icons.delete_outline_rounded, color: c.fg2),
            onPressed: () {
              context.read<Settings>().removePlaylist(list.id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      floatingActionButton: list.items.isEmpty
          ? null
          : FloatingActionButton.extended(
              backgroundColor: c.gold,
              foregroundColor: c.goldInk,
              onPressed: () {
                context.read<Playback>().playPlaylist(list);
                Nav.nowPlaying(context);
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text('Play', style: T.ui(15, w: FontWeight.w700, color: c.goldInk)),
            ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 110), children: [
        TextField(
          controller: _name,
          style: T.ui(18, w: FontWeight.w700, color: c.fg),
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: 'Name',
            filled: true,
            fillColor: c.raised,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
          onChanged: (v) => _save((x) => x.name = v.trim().isEmpty ? 'My playlist' : v.trim()),
        ),
        const Label('Reciter'),
        Material(
          color: c.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: c.line)),
          child: ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            leading: reciter == null ? CircleAvatar(backgroundColor: c.raised, child: Icon(Icons.person_rounded, color: c.fg2)) : ReciterAvatar(reciter, size: 44),
            title: Text(reciter?.name ?? 'Whoever is chosen in the player', style: T.ui(15, w: FontWeight.w700, color: c.fg)),
            subtitle: Text(reciter?.syncLabel ?? 'Pick one to always hear this list in that voice', style: T.ui(12, color: c.fg3)),
            trailing: Text('Change', style: T.ui(12.5, w: FontWeight.w700, color: c.gold)),
            onTap: () => showReciterSheet(context, selected: list.reciterId, onPick: (r) => _save((x) => x.reciterId = r.id)),
          ),
        ),
        Label('In this order · ${list.items.length}'),
        if (list.items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Add surahs, then drag them into the order you like.', style: T.ui(13.5, color: c.fg2)),
          ),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: list.items.length,
          onReorderItem: (a, b) => _save((x) => x.items.insert(b, x.items.removeAt(a))),
          itemBuilder: (_, i) {
            final it = list.items[i];
            final s = repo.surah(it.surah);
            return Padding(
              key: ValueKey('${it.surah}:${it.from}:${it.to}:$i'),
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: c.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: c.line)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _editItem(i),
                  child: SizedBox(
                    height: 64,
                    child: Row(children: [
                      ReorderableDragStartListener(
                        index: i,
                        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Icon(Icons.drag_indicator_rounded, color: c.fg3)),
                      ),
                      StarNumber(i + 1, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(s.nameEn, style: T.ui(15, w: FontWeight.w700, color: c.fg)),
                          Text(_reciter.hasAyahSync || (it.from == 1 && it.to == s.ayahs) ? itemLabel(s, it) : '${itemLabel(s, it)} · plays the whole surah with this reciter',
                              maxLines: 1, overflow: TextOverflow.ellipsis, style: T.ui(12.5, color: c.fg2)),
                        ]),
                      ),
                      if (dlw.recordFor(it.surah, _reciter.id) != null)
                        Padding(padding: const EdgeInsets.only(right: 2), child: Icon(Icons.download_done_rounded, size: 18, color: c.emerald)),
                      RoundIcon(Icons.close_rounded, tooltip: 'Remove ${s.nameEn}', size: 40, color: c.fg3, onTap: () => _save((x) => x.items.removeAt(i))),
                      const SizedBox(width: 6),
                    ]),
                  ),
                ),
              ),
            );
          },
        ),
        GhostButton('Add a surah', icon: Icons.add_rounded, expand: true, onTap: _addSurah),
        if (!_reciter.hasAyahSync)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text('${_reciter.name} has no ayah timings, so every item plays as a whole surah. To play chosen ayahs, pick a reciter marked Ayah sync or Word sync.',
                style: T.ui(12.5, color: c.fg2, height: 1.4)),
          ),
        if (dlw.supported && list.items.isNotEmpty) ...[
          const Label('Offline'),
          Builder(builder: (context) {
            final dl = dlw;
            final surahs = {for (final it in list.items) it.surah};
            final saved = surahs.where((n) => dl.recordFor(n, _reciter.id) != null).length;
            final job = dl.jobs.entries.where((e) => surahs.contains(e.key)).firstOrNull;
            return Material(
              color: saved == surahs.length ? c.emeraldWash : c.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: c.line)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    Icon(saved == surahs.length ? Icons.offline_pin_rounded : Icons.download_rounded, color: saved == surahs.length ? c.emerald : c.gold),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(saved == surahs.length ? 'Saved: plays at once, even offline' : '$saved of ${surahs.length} surahs saved with ${_reciter.name}',
                          style: T.ui(14, w: FontWeight.w700, color: c.fg)),
                    ),
                  ]),
                  if (job != null) ...[
                    const SizedBox(height: 10),
                    Text('${repo.surah(job.key).nameEn}…', style: T.ui(12, color: c.fg3)),
                    const SizedBox(height: 6),
                    ValueListenableBuilder<double>(
                      valueListenable: job.value.progress,
                      builder: (_, v, _) => LinearProgressIndicator(value: v, color: c.gold, backgroundColor: c.line),
                    ),
                  ],
                  if (saved < surahs.length) ...[
                    const SizedBox(height: 10),
                    _downloading
                        ? GhostButton('Stop', icon: Icons.stop_rounded, expand: true, onTap: () {
                            setState(() => _downloading = false);
                            if (job != null) dl.cancel(job.key);
                          })
                        : GoldButton('Download playlist', icon: Icons.download_rounded, expand: true, onTap: _download),
                    const SizedBox(height: 6),
                    Text('Then the next surah and the next reciter start at once, with no waiting.', style: T.ui(12, color: c.fg3)),
                  ],
                ]),
              ),
            );
          }),
        ],
        const Label('Reminder'),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeTrackColor: c.gold,
          value: list.remind,
          onChanged: (v) => _save((x) => x.remind = v),
          title: Text('Remind me to listen', style: T.ui(15, w: FontWeight.w700, color: c.fg)),
          subtitle: Text(remindLabel(context, list), style: T.ui(12.5, color: c.fg3)),
        ),
        if (list.remind) ...[
          Material(
            color: c.raised,
            borderRadius: BorderRadius.circular(16),
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              leading: Icon(Icons.schedule_rounded, color: c.gold),
              title: Text(TimeOfDay(hour: list.remindAt ~/ 60, minute: list.remindAt % 60).format(context), style: T.display(20, w: FontWeight.w700, color: c.fg)),
              subtitle: Text('Tap to change the time', style: T.ui(12, color: c.fg3)),
              onTap: () async {
                final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: list.remindAt ~/ 60, minute: list.remindAt % 60));
                if (t != null) _save((x) => x.remindAt = t.hour * 60 + t.minute);
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            for (final (d, n) in const [(1, 'M'), (2, 'T'), (3, 'W'), (4, 'T'), (5, 'F'), (6, 'S'), (7, 'S')])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Semantics(
                    button: true,
                    selected: list.days.contains(d),
                    label: const ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][d],
                    excludeSemantics: true,
                    child: Material(
                      color: list.days.contains(d) ? c.gold : c.raised,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _save((x) {
                          if (x.days.contains(d)) {
                            if (x.days.length > 1) x.days.remove(d);
                          } else {
                            x.days.add(d);
                          }
                        }),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Center(child: Text(n, style: T.ui(15, w: FontWeight.w800, color: list.days.contains(d) ? c.goldInk : c.fg))),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ]),
        ],
      ]),
    );
  }
}

/// A searchable list of surahs; returns the number picked.
Future<int?> showSurahPicker(BuildContext context) => showOvSheet<int>(context, title: 'Add a surah', scroll: false, builder: (_) => const _SurahPicker());

class _SurahPicker extends StatefulWidget {
  const _SurahPicker();
  @override
  State<_SurahPicker> createState() => _SurahPickerState();
}

class _SurahPickerState extends State<_SurahPicker> {
  String q = '';
  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    final repo = context.read<QuranRepository>();
    final key = surahKey(q);
    final list = repo.surahs.where((s) => q.isEmpty || '${s.number}' == q.trim() || surahKey(s.nameEn).contains(key) || surahKey(s.meaning).contains(key)).toList();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.7,
      child: Column(children: [
        TextField(
          autofocus: true,
          onChanged: (v) => setState(() => q = v),
          decoration: InputDecoration(
            hintText: 'Search surah, e.g. Yaseen, Mulk, 67',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: c.raised,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (_, i) {
              final s = list[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: StarNumber(s.number, size: 36),
                title: Text(s.nameEn, style: T.ui(15, w: FontWeight.w700, color: c.fg)),
                subtitle: Text('${s.meaning} · ${s.ayahs} ayahs', style: T.ui(12, color: c.fg3)),
                trailing: Text(s.nameAr, style: T.kufi(18, color: c.fg2)),
                onTap: () => Navigator.pop(context, s.number),
              );
            },
          ),
        ),
      ]),
    );
  }
}

/// Picks ayahs [from]..[to] of [s]; returns the range, or null.
Future<(int, int)?> showRangeSheet(BuildContext context, SurahInfo s, int from, int to) {
  var a = from, b = to;
  return showOvSheet<(int, int)>(context, title: s.nameEn, builder: (ctx) {
    return StatefulBuilder(builder: (ctx, set) {
      final c = ctx.ov;
      Widget stepper(String label, int v, void Function(int) on) => Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(color: c.raised, borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                Text(label, style: T.label(c.fg3).copyWith(fontSize: 10.5)),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  RoundIcon(Icons.remove_rounded, tooltip: '$label one less', size: 40, onTap: v > 1 ? () => set(() => on(v - 1)) : null),
                  SizedBox(width: 48, child: Text('$v', textAlign: TextAlign.center, style: T.display(22, w: FontWeight.w700, color: c.fg))),
                  RoundIcon(Icons.add_rounded, tooltip: '$label one more', size: 40, onTap: v < s.ayahs ? () => set(() => on(v + 1)) : null),
                ]),
              ]),
            ),
          );
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          stepper('FROM AYAH', a, (v) {
            a = v;
            if (b < a) b = a;
          }),
          const SizedBox(width: 10),
          stepper('TO AYAH', b, (v) {
            b = v;
            if (a > b) a = b;
          }),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 8, children: [
          OvChip('Whole surah', selected: a == 1 && b == s.ayahs, onTap: () => set(() => (a, b) = (1, s.ayahs))),
        ]),
        const SizedBox(height: 16),
        GoldButton('Done', icon: Icons.check_rounded, expand: true, onTap: () => Navigator.pop(ctx, (a, b))),
      ]);
    });
  });
}
