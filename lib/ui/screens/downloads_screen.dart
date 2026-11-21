import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/catalog.dart';
import '../../data/downloads.dart';
import '../../data/network.dart';
import '../../data/offline_sync.dart';
import '../../data/repository.dart';
import '../../state/playback.dart';
import '../../state/settings.dart';
import '../playlists_screen.dart';
import '../sheets.dart';
import '../shell.dart';
import '../study.dart';
import '../widgets/common.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});
  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  Future<(int, int)>? _sizes;
  bool _byReciter = false;
  bool _checking = false;

  Future<void> _check() async {
    setState(() => _checking = true);
    final dl = context.read<Downloads>();
    final n = await dl.verify();
    if (!mounted) return;
    setState(() {
      _checking = false;
      _sizes = null;
    });
    toast(context, n == 0 ? 'All saved files are complete' : '$n saved surahs were incomplete and were removed; download them again');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    final dl = context.watch<Downloads>();
    final sync = context.watch<OfflineSync>();
    final net = context.watch<NetworkStatus>();
    final s = context.watch<Settings>();
    final repo = context.read<QuranRepository>();
    _sizes ??= _loadSizes(dl);
    final complete = dl.completeReciters;
    final records = dl.records.where((r) => !complete.contains(r.reciterId)).toList()..sort((a, b) => a.surah.compareTo(b.surah));
    final until = sync.validUntil;

    return RefreshIndicator(
      onRefresh: () async {
        await sync.run(force: true);
        setState(() => _sizes = null);
      },
      child: ListView(padding: EdgeInsets.fromLTRB(0, MediaQuery.paddingOf(context).top + 10, 0, 28), children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('Library', style: T.display(26, color: c.fg))),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Material(
            color: c.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: BorderSide(color: c.line)),
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              leading: Icon(Icons.bookmarks_rounded, color: c.gold),
              title: Text('Bookmarks and notes', style: T.ui(16, w: FontWeight.w700, color: c.fg)),
              subtitle: Text(
                  context.watch<Settings>().bookmarks.isEmpty
                      ? 'Save ayahs from the reader'
                      : '${context.watch<Settings>().bookmarks.length} saved ayahs',
                  style: T.ui(12.5, color: c.fg3)),
              trailing: Icon(Icons.chevron_right_rounded, color: c.fg3),
              onTap: () => BookmarksScreen.open(context),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Material(
            color: c.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: BorderSide(color: c.line)),
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              leading: Icon(Icons.queue_music_rounded, color: c.gold),
              title: Text('Playlists', style: T.ui(16, w: FontWeight.w700, color: c.fg)),
              subtitle: Text(
                  context.watch<Settings>().playlists.isEmpty
                      ? 'Your own order, reciter and reminder'
                      : '${context.watch<Settings>().playlists.length} playlists',
                  style: T.ui(12.5, color: c.fg3)),
              trailing: Icon(Icons.chevron_right_rounded, color: c.fg3),
              onTap: () => PlaylistsScreen.open(context),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          // A Material, not a coloured box, so the switch row's ripple shows.
          child: Material(
            color: c.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: BorderSide(color: c.line)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  Icon(Icons.offline_pin_rounded, color: c.emerald),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Offline library', style: T.ui(16, w: FontWeight.w700, color: c.fg))),
                  Text(net.unmetered ? 'Wi-Fi' : net.online ? 'Mobile data' : 'Offline', style: T.ui(12, w: FontWeight.w600, color: c.fg3)),
                ]),
                const SizedBox(height: 12),
                Text('${sync.textSurahsReady} of 114 surahs', style: T.display(24, color: c.fg)),
                Text('Quran text in all five scripts and ${repo.translationById(s.translationId).englishName}', style: T.ui(12.5, color: c.fg2)),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: sync.running && sync.total > 0 ? sync.done / sync.total : sync.textSurahsReady / 114,
                    minHeight: 6,
                    color: c.emerald,
                    backgroundColor: c.raised2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  sync.running
                      ? 'Syncing ${sync.done} of ${sync.total}…'
                      : until != null
                          ? 'Available offline until at least ${_date(until)}${sync.lastComplete != null ? ' · last synced ${_ago(sync.lastComplete!)}' : ''}'
                          : 'Connect to Wi-Fi to save the whole Quran on this device.',
                  style: T.ui(12.5, color: c.fg3, height: 1.4),
                ),
                const SizedBox(height: 6),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: s.wifiPrefetch,
                  activeTrackColor: c.emerald,
                  onChanged: (v) {
                    s.update((x) => x.wifiPrefetch = v);
                    if (v) sync.run();
                  },
                  title: Text('Keep in sync on Wi-Fi', style: T.ui(14, w: FontWeight.w600, color: c.fg)),
                  subtitle: Text('Refreshes anything older than 3 days so it stays usable for 30 days without internet',
                      style: T.ui(12, color: c.fg3)),
                ),
                GhostButton(sync.running ? 'Syncing…' : 'Sync now', icon: Icons.sync_rounded, expand: true, onTap: sync.running || !net.online
                    ? null
                    : () async {
                        await sync.run(force: true);
                        if (mounted) setState(() => _sizes = null);
                      }),
              ]),
            ),
          ),
        ),
        if (dl.supported) const _QuranCard(),
        FutureBuilder<(int, int)>(
          future: _sizes,
          builder: (_, snap) {
            final audio = snap.data?.$1 ?? 0, text = snap.data?.$2 ?? 0;
            final total = audio + text;
            return Container(
              margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: c.line)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(fmtBytes(total), style: T.display(22, color: c.fg)),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: total == 0
                      ? Container(height: 8, color: c.line2)
                      : Row(children: [
                          Expanded(flex: (audio / 1024).round() + 1, child: Container(height: 8, color: c.gold)),
                          Expanded(flex: (text / 1024).round() + 1, child: Container(height: 8, color: c.emerald)),
                        ]),
                ),
                const SizedBox(height: 10),
                Wrap(spacing: 16, children: [
                  _Legend(c.gold, 'Recitations ${fmtBytes(audio)}'),
                  _Legend(c.emerald, 'Text and timings ${fmtBytes(text)}'),
                ]),
              ]),
            );
          },
        ),
        SectionTitle('Downloaded', action: dl.records.isEmpty ? null : '${dl.records.length}'),
        if (dl.supported && dl.records.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(children: [
              Expanded(
                child: Segmented<bool>(
                  options: const [(false, 'By surah'), (true, 'By reciter')],
                  value: _byReciter,
                  onChanged: (v) => setState(() => _byReciter = v),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Check saved files',
                child: Material(
                  color: c.raised,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _checking ? null : _check,
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: _checking
                          ? const Padding(padding: EdgeInsets.all(14), child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(Icons.fact_check_rounded, color: c.fg2),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        if (!dl.supported)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text('Audio downloads are available in the Android and iOS app.', style: T.ui(13.5, color: c.fg3)),
          )
        else if (dl.records.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text('Nothing downloaded yet. Open a surah and tap the download button to keep its recitation offline.',
                style: T.ui(13.5, color: c.fg3, height: 1.45)),
          )
        else if (_byReciter)
          for (final (id, count, bytes) in dl.reciterSummary())
            complete.contains(id)
                ? _CompleteRow(id, onRemoved: () {
                    if (mounted) setState(() => _sizes = null);
                  })
                : _ReciterGroup(id, count, bytes, onChanged: () {
                    if (mounted) setState(() => _sizes = null);
                  })
        else ...[
          for (final id in complete)
            _CompleteRow(id, onRemoved: () {
              if (mounted) setState(() => _sizes = null);
            }),
          for (final n in {for (final r in records) r.surah})
            _SurahGroup(n, [for (final r in records) if (r.surah == n) r], onChanged: () {
              if (mounted) setState(() => _sizes = null);
            }),
        ],
      ]),
    );
  }

  static Future<(int, int)> _loadSizes(Downloads dl) async => (await dl.audioBytes(), await dl.textBytes());

  static String _date(DateTime d) => '${d.day} ${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.month - 1]} ${d.year}';
  static String _ago(DateTime d) {
    final m = DateTime.now().difference(d).inMinutes;
    if (m < 2) return 'just now';
    if (m < 60) return '$m minutes ago';
    if (m < 60 * 24) return '${m ~/ 60} hours ago';
    return '${m ~/ (60 * 24)} days ago';
  }
}

/// "Download complete Quran": start, progress, pause and resume.
class _QuranCard extends StatelessWidget {
  const _QuranCard();

  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    final dl = context.watch<Downloads>();
    final s = context.watch<Settings>();
    final repo = context.read<QuranRepository>();
    final plan = dl.quranPlan;
    final state = dl.quranState;
    final reciter = plan != null ? reciterById(plan.reciterId) : s.reciter;
    final active = plan != null && state != QuranState.done;
    final done = active ? dl.quranDone : dl.records.where((r) => r.reciterId == reciter.id).length;
    final complete = done >= 114;
    final job = dl.quranCurrent == null ? null : dl.jobs[dl.quranCurrent];

    final String status;
    if (complete) {
      status = 'All 114 surahs play without internet · ${fmtBytes(dl.records.where((r) => r.reciterId == reciter.id).fold(0, (t, r) => t + r.bytes))}';
    } else if (state == QuranState.running) {
      status = dl.quranCurrent != null ? 'Now: ${repo.surah(dl.quranCurrent!).nameEn} · ${fmtBytes(dl.quranBytes)} saved' : 'Starting…';
    } else if (state == QuranState.waitingForNetwork) {
      status = plan!.wifiOnly ? 'Waiting for Wi-Fi. It carries on by itself when you connect.' : 'Waiting for a connection.';
    } else if (state == QuranState.paused) {
      status = dl.quranError ?? 'Paused · ${fmtBytes(dl.quranBytes)} saved';
    } else {
      status = 'All 114 surahs with ${reciter.name}, to listen anywhere without internet.';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [c.goldWash, c.surface], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.gold.withValues(alpha: 0.35)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: c.gold, borderRadius: BorderRadius.circular(12)),
            child: Icon(complete ? Icons.check_rounded : Icons.download_for_offline_rounded, color: c.goldInk),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(complete ? 'Complete Quran saved' : 'Complete Quran', style: T.ui(16, w: FontWeight.w700, color: c.fg)),
              Text(reciter.name, style: T.ui(12.5, color: c.fg3)),
            ]),
          ),
          ReciterAvatar(reciter, size: 40),
        ]),
        if (active || complete) ...[
          const SizedBox(height: 14),
          Text('$done of 114 surahs', style: T.display(22, color: c.fg)),
          const SizedBox(height: 8),
          ValueListenableBuilder<double>(
            valueListenable: job?.progress ?? ValueNotifier(0),
            builder: (_, p, _) => ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: ((done + p) / 114).clamp(0, 1), minHeight: 6, color: c.gold, backgroundColor: c.raised2),
            ),
          ),
        ],
        const SizedBox(height: 10),
        Text(status, style: T.ui(12.5, color: dl.quranError != null && state == QuranState.paused ? c.gold : c.fg2, height: 1.4)),
        const SizedBox(height: 12),
        if (!active && !complete)
          GoldButton('Download complete Quran', icon: Icons.download_rounded, expand: true, onTap: () => showQuranDownloadSheet(context))
        else if (complete)
          GhostButton('Download for another reciter', icon: Icons.person_add_alt_1_rounded, expand: true, onTap: () => showQuranDownloadSheet(context))
        else
          Row(children: [
            Expanded(
              child: state == QuranState.running
                  ? GhostButton('Pause', icon: Icons.pause_rounded, expand: true, onTap: dl.pauseQuran)
                  : state == QuranState.waitingForNetwork && plan!.wifiOnly
                      ? GhostButton('Use mobile data', icon: Icons.signal_cellular_alt_rounded, expand: true,
                          onTap: () => dl.resumeQuran(allowMobileData: true))
                      : GoldButton('Resume', icon: Icons.play_arrow_rounded, expand: true, onTap: dl.resumeQuran),
            ),
            const SizedBox(width: 10),
            Expanded(child: GhostButton('Cancel', icon: Icons.close_rounded, expand: true, onTap: dl.cancelQuran)),
          ]),
      ]),
    );
  }
}

/// Plays a saved surah with the reciter it was saved with, so it plays
/// offline whichever reciter was chosen before.
void _playSaved(BuildContext context, String reciterId, int surah) {
  final s = context.read<Settings>();
  final pb = context.read<Playback>();
  if (s.reciterId != reciterId) {
    s.update((x) => x.reciterId = reciterId);
    toast(context, 'Playing with ${reciterById(reciterId).name}, saved on this phone');
  }
  pb.play(surah);
  Nav.surah(context, surah);
}

/// One row for a reciter whose whole Quran is saved.
class _CompleteRow extends StatelessWidget {
  final String reciterId;
  final VoidCallback onRemoved;
  const _CompleteRow(this.reciterId, {required this.onRemoved});

  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    final dl = context.watch<Downloads>();
    final r = reciterById(reciterId);
    final bytes = dl.records.where((x) => x.reciterId == reciterId).fold(0, (t, x) => t + x.bytes);
    final current = context.watch<Settings>().reciterId == reciterId;
    return InkWell(
      onTap: () {
        context.read<Settings>().update((x) => x.reciterId = reciterId);
        toast(context, '${r.name} chosen · every surah plays offline');
        goToTab(1);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Art(seed: 'quran', radius: BorderRadius.circular(14), child: const Center(child: Icon(Icons.menu_book_rounded, color: Colors.white))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Complete Quran', style: T.ui(15, w: FontWeight.w600, color: c.fg)),
              Text('114 surahs · ${fmtBytes(bytes)}${current ? ' · in use' : ' · tap to use'}', style: T.ui(12.5, color: c.fg3)),
              const SizedBox(height: 6),
              _Tag(r.name, c.raised, c.fg3),
            ]),
          ),
          IconButton(
            tooltip: 'Remove the complete Quran',
            icon: Icon(Icons.delete_outline_rounded, color: c.fg3),
            onPressed: () async {
              final yes = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Remove the complete Quran?'),
                  content: Text('This deletes ${fmtBytes(bytes)} of ${r.name} recitations from this phone. The Quran text stays.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
                  ],
                ),
              );
              if (yes == true) {
                await dl.removeReciter(reciterId);
                onRemoved();
              }
            },
          ),
        ]),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String text;
  const _Legend(this.color, this.text);
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        CircleAvatar(radius: 4, backgroundColor: color),
        const SizedBox(width: 6),
        Text(text, style: T.ui(12, color: context.ov.fg2)),
      ]);
}

/// One downloaded surah, with every reciter it is saved with.
class _SurahGroup extends StatelessWidget {
  final int surah;
  final List<DownloadRecord> recs;
  final VoidCallback onChanged;
  const _SurahGroup(this.surah, this.recs, {required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    final repo = context.read<QuranRepository>();
    final dl = context.read<Downloads>();
    final s = repo.surah(surah);
    final bytes = recs.fold(0, (t, r) => t + r.bytes);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: c.line)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              SizedBox(
                width: 48,
                height: 48,
                child: Art(seed: surah, radius: BorderRadius.circular(12), child: Center(child: Text('$surah', style: T.display(18, color: Colors.white)))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.nameEn, style: T.ui(15, w: FontWeight.w700, color: c.fg)),
                  Text('${recs.length} ${recs.length == 1 ? 'reciter' : 'reciters'} · ${fmtBytes(bytes)}', style: T.ui(12.5, color: c.fg3)),
                ]),
              ),
              RoundIcon(Icons.delete_outline_rounded, tooltip: 'Remove ${s.nameEn}', color: c.fg3, onTap: () async {
                final which = recs.length == 1 ? recs.first : await _pickCopy(context, recs);
                if (which == null) return;
                await dl.remove(which);
                onChanged();
              }),
            ]),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final r in recs) _ReciterChip(r.reciterId, onTap: () => _playSaved(context, r.reciterId, surah)),
            ]),
          ]),
        ),
      ),
    );
  }

  static Future<DownloadRecord?> _pickCopy(BuildContext context, List<DownloadRecord> recs) => showOvSheet<DownloadRecord>(context,
      title: 'Remove which recitation?',
      builder: (ctx) => Column(children: [
            for (final r in recs)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: ReciterAvatar(reciterById(r.reciterId), size: 40),
                title: Text(reciterById(r.reciterId).name, style: T.ui(15, w: FontWeight.w700, color: ctx.ov.fg)),
                subtitle: Text(fmtBytes(r.bytes), style: T.ui(12, color: ctx.ov.fg3)),
                trailing: Icon(Icons.delete_outline_rounded, color: ctx.ov.fg3),
                onTap: () => Navigator.pop(ctx, r),
              ),
          ]));
}

/// One reciter, with the surahs saved in that voice.
class _ReciterGroup extends StatelessWidget {
  final String reciterId;
  final int count, bytes;
  final VoidCallback onChanged;
  const _ReciterGroup(this.reciterId, this.count, this.bytes, {required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    final repo = context.read<QuranRepository>();
    final dl = context.read<Downloads>();
    final r = reciterById(reciterId);
    final surahs = [for (final x in dl.records) if (x.reciterId == reciterId) x.surah]..sort();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: c.line)),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            shape: const Border(),
            leading: ReciterAvatar(r, size: 44),
            title: Text(r.name, style: T.ui(15, w: FontWeight.w700, color: c.fg)),
            subtitle: Text('$count ${count == 1 ? 'surah' : 'surahs'} · ${fmtBytes(bytes)}', style: T.ui(12.5, color: c.fg3)),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            children: [
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final n in surahs)
                  OvChip('$n · ${repo.surah(n).nameEn}', leading: Icon(Icons.play_arrow_rounded, size: 16, color: c.gold), onTap: () => _playSaved(context, reciterId, n)),
              ]),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () async {
                    await dl.removeReciter(reciterId);
                    onChanged();
                  },
                  icon: Icon(Icons.delete_outline_rounded, color: c.fg3),
                  label: Text('Remove all of ${r.name}', style: T.ui(13, w: FontWeight.w700, color: c.fg2)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A reciter a surah is saved with: tap to play it in that voice.
class _ReciterChip extends StatelessWidget {
  final String reciterId;
  final VoidCallback onTap;
  const _ReciterChip(this.reciterId, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    final r = reciterById(reciterId);
    return Material(
      color: c.emeraldWash,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            ReciterAvatar(r, size: 26),
            const SizedBox(width: 6),
            Text(r.name, style: T.ui(12.5, w: FontWeight.w700, color: c.fg)),
            const SizedBox(width: 4),
            Icon(Icons.download_done_rounded, size: 15, color: c.emerald),
          ]),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color bg, fg;
  const _Tag(this.text, this.bg, this.fg);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
        child: Text(text, style: T.ui(10.5, w: FontWeight.w700, color: fg)),
      );
}
