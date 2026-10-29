import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/catalog.dart';
import '../../data/downloads.dart';
import '../../data/network.dart';
import '../../data/offline_sync.dart';
import '../../data/repository.dart';
import '../../state/settings.dart';
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
    final records = dl.records.toList()..sort((a, b) => a.surah.compareTo(b.surah));
    final until = sync.validUntil;

    return RefreshIndicator(
      onRefresh: () async {
        await sync.run(force: true);
        setState(() => _sizes = null);
      },
      child: ListView(padding: EdgeInsets.fromLTRB(0, MediaQuery.paddingOf(context).top + 10, 0, 28), children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('Library', style: T.display(26, color: c.fg))),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: c.line)),
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
                  child: Row(children: [
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
        if (!dl.supported)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text('Audio downloads are available in the Android and iOS app.', style: T.ui(13.5, color: c.fg3)),
          )
        else if (records.isEmpty)
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
