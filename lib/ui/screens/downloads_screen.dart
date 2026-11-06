import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/catalog.dart';
import '../../data/downloads.dart';
import '../../data/network.dart';
import '../../data/offline_sync.dart';
import '../../data/repository.dart';
import '../../state/settings.dart';
import '../sheets.dart';
import '../shell.dart';
import '../widgets/common.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});
  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  Future<(int, int)>? _sizes;

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
        SectionTitle('Downloaded surahs', action: records.isEmpty ? null : '${records.length}'),
        for (final id in complete)
          _CompleteRow(id, onRemoved: () {
            if (mounted) setState(() => _sizes = null);
          }),
        if (!dl.supported)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text('Audio downloads are available in the Android and iOS app.', style: T.ui(13.5, color: c.fg3)),
          )
        else if (records.isEmpty && complete.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text('Nothing downloaded yet. Open a surah and tap the download button to keep its recitation offline.',
                style: T.ui(13.5, color: c.fg3, height: 1.45)),
          ),
        for (final r in records)
          Dismissible(
            key: ValueKey('${r.surah}_${r.reciterId}'),
            direction: DismissDirection.endToStart,
            background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 24), color: Colors.red.shade700,
                child: const Icon(Icons.delete_rounded, color: Colors.white)),
            onDismissed: (_) async {
              await dl.remove(r);
              if (mounted) setState(() => _sizes = null);
            },
            child: _DownloadRow(r, repo),
          ),
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
    return Padding(
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
            Text('114 surahs · ${fmtBytes(bytes)}', style: T.ui(12.5, color: c.fg3)),
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

class _DownloadRow extends StatelessWidget {
  final DownloadRecord r;
  final QuranRepository repo;
  const _DownloadRow(this.r, this.repo);
  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    final s = repo.surah(r.surah);
    return InkWell(
      onTap: () => Nav.surah(context, r.surah),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          SizedBox(width: 56, height: 56, child: Art(seed: r.surah, radius: BorderRadius.circular(14), child: Center(child: Text('${r.surah}', style: T.display(20, color: Colors.white))))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.nameEn, style: T.ui(15, w: FontWeight.w600, color: c.fg)),
              Text('${s.ayahs} ayahs · ${fmtBytes(r.bytes)}', style: T.ui(12.5, color: c.fg3)),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 4, children: [
                _Tag(reciterById(r.reciterId).name, c.raised, c.fg3),
                for (final t in r.translations) _Tag(repo.translationById(t).englishName, c.emeraldWash, c.emerald),
                _Tag('All scripts', c.emeraldWash, c.emerald),
                if (r.voiceId != null) _Tag('${reciterById(r.voiceId).name} audio', c.raised, c.fg3),
              ]),
            ]),
          ),
        ]),
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
