import 'package:flutter/material.dart';
import 'package:oneverse/core/app_navigation.dart';
import 'package:oneverse/models/playback_config.dart';
import 'package:oneverse/providers/audio_provider.dart';
import 'package:oneverse/providers/download_provider.dart';
import 'package:oneverse/providers/quran_provider.dart';
import 'package:oneverse/providers/settings_provider.dart';
import 'package:oneverse/services/offline_store.dart';
import 'package:provider/provider.dart';

String formatBytes(int bytes) {
  if (bytes < 1000 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  if (bytes < 1000 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}

/// Starts playing a downloaded surah and shows the Player tab.
void playOfflinePackage(BuildContext context, OfflinePackage package) {
  context.read<QuranProvider>().selectSurah(package.surahNumber);
  context.read<AudioProvider>().playOfflinePackage(package);
  Navigator.of(context).popUntil((route) => route.isFirst);
  AppNavigation.tabIndex.value = AppNavigation.playerTab;
}

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final store = context.watch<OfflineStore>();
    final downloads = context.watch<SurahDownloadProvider>();
    final active = downloads.activeTasks;

    return Scaffold(
      appBar: AppBar(title: const Text('Offline Downloads')),
      body: store.packages.isEmpty && active.isEmpty
          ? const _EmptyState()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                if (active.isNotEmpty) ...[
                  const _SectionHeader('DOWNLOADING'),
                  ...active.map((t) => _ActiveDownloadTile(task: t)),
                  const SizedBox(height: 16),
                ],
                if (store.packages.isNotEmpty) ...[
                  _SectionHeader(
                      'AVAILABLE OFFLINE · ${store.packages.length} · ${formatBytes(store.totalBytes)}'),
                  const OfflineLibraryList(),
                ],
              ],
            ),
    );
  }
}

/// List of downloaded surahs; tap to play, trailing button to delete.
class OfflineLibraryList extends StatelessWidget {
  final bool allowDelete;
  const OfflineLibraryList({Key? key, this.allowDelete = true})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final store = context.watch<OfflineStore>();
    final settings = context.watch<SettingsProvider>();
    final primary = Theme.of(context).primaryColor;

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (i, p) in store.packages.indexed) ...[
            if (i > 0) const Divider(height: 1, indent: 72),
            ListTile(
              onTap: () => playOfflinePackage(context, p),
              leading: CircleAvatar(
                backgroundColor: primary.withValues(alpha: 0.12),
                child: Text('${p.surahNumber}',
                    style: TextStyle(
                        color: primary, fontWeight: FontWeight.bold)),
              ),
              title: Row(
                children: [
                  Expanded(
                      child: Text(p.englishName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis)),
                  Text(p.arabicName,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                          fontFamily: 'NotoNaskhArabic', fontSize: 15)),
                ],
              ),
              subtitle: Text(
                [
                  _describe(p, settings),
                  '${p.numberOfAyahs} verses · ${formatBytes(p.sizeBytes)}',
                ].join('\n'),
                style: const TextStyle(fontSize: 12),
              ),
              isThreeLine: true,
              trailing: allowDelete
                  ? IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Delete download',
                      onPressed: () => _confirmDelete(context, p),
                    )
                  : Icon(Icons.play_circle_fill_rounded,
                      color: primary, size: 32),
            ),
          ],
        ],
      ),
    );
  }

  static String _describe(OfflinePackage p, SettingsProvider settings) {
    final parts = <String>[
      if (p.audioEdition != null) settings.editionName(p.audioEdition),
      if (p.translationAudioEdition != null)
        settings.editionName(p.translationAudioEdition),
    ];
    return '${parts.join(' → ')} · ${p.mode.label}';
  }

  Future<void> _confirmDelete(BuildContext context, OfflinePackage p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete download?'),
        content: Text(
            '${p.englishName} will no longer be available offline. This frees ${formatBytes(p.sizeBytes)}.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<OfflineStore>().deletePackage(p);
    }
  }
}

class _ActiveDownloadTile extends StatelessWidget {
  final SurahDownloadTask task;
  const _ActiveDownloadTile({required this.task});

  @override
  Widget build(BuildContext context) {
    final progress = task.progress;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${task.surah.number}. ${task.surah.englishName}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 6),
                  Text(
                    task.status == DownloadStatus.queued
                        ? 'Waiting…'
                        : progress == null
                            ? 'Preparing…'
                            : '${task.doneFiles} / ${task.totalFiles} files · ${(progress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Cancel',
              onPressed: () => context
                  .read<SurahDownloadProvider>()
                  .cancel(task.surah.number),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0, top: 16.0),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.download_for_offline_outlined,
                size: 72, color: Theme.of(context).disabledColor),
            const SizedBox(height: 16),
            const Text('No offline surahs yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Open the Player and tap the download button, then choose "Complete Surah". '
              'Tip: long-press the download button to start right away.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Short description of what a surah download for [config] contains.
String describeDownloadContents(
    PlaybackConfig config, SettingsProvider settings) {
  final parts = <String>[
    if (config.needsArabicAudio)
      'Arabic audio (${settings.editionName(config.audioEdition)})',
    if (config.needsTranslationAudio)
      'Translation audio (${settings.editionName(config.translationAudioEdition)})',
    'Arabic text',
    'Translation text (${settings.editionName(config.textEdition)})',
  ];
  return parts.join(' + ');
}
