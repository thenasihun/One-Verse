import 'package:flutter/material.dart';
import 'package:oneverse/models/edition_model.dart';
import 'package:oneverse/models/playback_config.dart';
import 'package:oneverse/models/selection_type.dart';
import 'package:oneverse/providers/settings_provider.dart';
import 'package:oneverse/screens/downloads_screen.dart';
import 'package:oneverse/screens/settings/edition_selection_screen.dart';
import 'package:oneverse/screens/settings/language_selection_screen.dart';
import 'package:oneverse/services/offline_store.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      // Only fetch if empty AND not already loading to avoid double calls
      if (settings.allTextEditions.isEmpty && !settings.isEditionsLoading) {
        settings.fetchAvailableEditions();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          if (settings.isEditionsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final currentTextEdition = _getCurrentEdition(
            settings.allTextEditions,
            settings.translationLanguage,
          );
          final currentAudioEdition = _getCurrentEdition(
            settings.allAudioEditions,
            settings.audioEdition,
          );

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            children: [
              const SizedBox(height: 16),
              _buildSectionHeader(context, "DISPLAY"),
              _buildThemeSelector(context, settings),
              const SizedBox(height: 24),
              _buildSectionHeader(context, "CONTENT"),
              // Theme, offline downloads and fonts stay usable offline.
              if (settings.editionErrorMessage != null)
                Card(child: _buildErrorState(context, settings))
              else ...[
                _buildContentCard(
                    context, settings, currentTextEdition, currentAudioEdition),
                const SizedBox(height: 24),
                _buildSectionHeader(context, "PLAYBACK"),
                _buildPlaybackModeCard(context, settings),
              ],
              const SizedBox(height: 24),
              _buildSectionHeader(context, "OFFLINE"),
              _buildOfflineCard(context),
              const SizedBox(height: 24),
              _buildSectionHeader(context, "TYPOGRAPHY"),
              _buildTypographyCard(context, settings),
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, SettingsProvider settings) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              settings.editionErrorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
              onPressed: settings.fetchAvailableEditions,
            ),
          ],
        ),
      ),
    );
  }

  Edition? _getCurrentEdition(List<Edition> editions, String? identifier) {
    if (editions.isEmpty) return null;
    return editions.firstWhere(
      (e) => e.identifier == identifier,
      orElse: () => editions.first,
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
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

  Widget _buildThemeSelector(BuildContext context, SettingsProvider settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("App Theme", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.computer_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode_outlined),
                ),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (newSelection) {
                settings.setThemeMode(newSelection.first);
              },
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.2),
                selectedForegroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentCard(BuildContext context, SettingsProvider settings,
      Edition? currentTextEdition, Edition? currentAudioEdition) {
    final translationAudio =
        settings.findEdition(settings.translationAudioEdition);
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.translate),
            title: const Text("Translation"),
            subtitle: Text(
              currentTextEdition?.englishName ?? "Default",
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const LanguageSelectionScreen(
                  selectionType: SelectionType.text,
                ),
              ),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.mic_none),
            title: const Text("Arabic Reciter"),
            subtitle: Text(
              currentAudioEdition?.englishName ?? "Default",
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const EditionSelectionScreen(
                  languageCode: 'ar',
                  selectionType: SelectionType.audio,
                ),
              ),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.record_voice_over_outlined),
            title: const Text("Translation Audio"),
            subtitle: Text(
              translationAudio != null
                  ? "${translationAudio.englishName} (${translationAudio.language.toUpperCase()})"
                  : "None",
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const LanguageSelectionScreen(
                  selectionType: SelectionType.translationAudio,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackModeCard(
      BuildContext context, SettingsProvider settings) {
    final hasTranslationAudio = settings.translationAudioEdition != null;
    final mode = settings.playbackConfig.mode;
    final description = switch (mode) {
      PlaybackMode.arabic => "Plays the Arabic recitation only.",
      PlaybackMode.arabicWithTranslation =>
        "Verse by verse: each Arabic verse is followed by its translation.",
      PlaybackMode.translation => "Plays the translation recitation only.",
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Playback Mode", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<PlaybackMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: PlaybackMode.arabic,
                    label: Text('Arabic'),
                  ),
                  ButtonSegment(
                    value: PlaybackMode.arabicWithTranslation,
                    label: Text('Arabic + Trans.'),
                  ),
                  ButtonSegment(
                    value: PlaybackMode.translation,
                    label: Text('Translation'),
                  ),
                ],
                selected: {mode},
                onSelectionChanged: (newSelection) {
                  final selected = newSelection.first;
                  if (selected != PlaybackMode.arabic && !hasTranslationAudio) {
                    // Need a translation reciter first.
                    settings.setPlaybackMode(selected);
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const LanguageSelectionScreen(
                        selectionType: SelectionType.translationAudio,
                      ),
                    ));
                    return;
                  }
                  settings.setPlaybackMode(selected);
                },
                style: SegmentedButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 12),
                  selectedBackgroundColor:
                      Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  selectedForegroundColor:
                      Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              hasTranslationAudio
                  ? description
                  : "Choose a Translation Audio reciter to hear each verse's translation after the Arabic.",
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineCard(BuildContext context) {
    final store = context.watch<OfflineStore>();
    final count = store.packages.length;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.download_for_offline_outlined),
        title: const Text("Offline Downloads"),
        subtitle: Text(
          count == 0
              ? "No surahs downloaded yet"
              : "$count surah${count == 1 ? '' : 's'} · ${formatBytes(store.totalBytes)}",
          style: TextStyle(color: Theme.of(context).primaryColor),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DownloadsScreen()),
        ),
      ),
    );
  }

  Widget _buildTypographyCard(BuildContext context, SettingsProvider settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: _buildTypographySelector(context, settings),
      ),
    );
  }

  Widget _buildTypographySelector(
      BuildContext context, SettingsProvider settings) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: settings.arabicFont,
          decoration: const InputDecoration(labelText: 'Arabic Font Style'),
          items: [
            'Amiri',
            'Lateef',
            'UthmanicHafs',
            'NotoNaskhArabic',
            'ScheherazadeNew',
            'Kitab',
          ]
              .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)))
              .toList(),
          onChanged: (value) {
            if (value != null) settings.setArabicFont(value);
            debugPrint("Selected Arabic Font: $value");
          },
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: settings.translationFont,
          decoration:
              const InputDecoration(labelText: 'Translation Font Style'),
          items: [
            'NotoSans',
            'Roboto',
            'Montserrat',
            'OpenSans',
            'NotoUrdu',
            'UthmanicHafs'
          ]
              .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)))
              .toList(),
          onChanged: (value) {
            if (value != null) settings.setTranslationFont(value);
          },
        ),
        const SizedBox(height: 20),
        _buildFontSlider(context, settings, isArabic: true),
        const SizedBox(height: 10),
        _buildFontSlider(context, settings, isArabic: false),
      ],
    );
  }

  Widget _buildFontSlider(BuildContext context, SettingsProvider settings,
      {required bool isArabic}) {
    final fontSize =
        isArabic ? settings.arabicFontSize : settings.translationFontSize;
    final min = isArabic ? 18.0 : 14.0;
    final max = isArabic ? 32.0 : 24.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isArabic ? "Arabic Font Size" : "Translation Font Size",
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Row(
          children: [
            const Icon(Icons.format_size, size: 20, color: Colors.grey),
            Expanded(
              child: Slider(
                value: fontSize,
                min: min,
                max: max,
                divisions: (max - min).toInt(),
                label: fontSize.round().toString(),
                onChanged: (value) {
                  if (isArabic) {
                    settings.setArabicFontSize(value);
                  } else {
                    settings.setTranslationFontSize(value);
                  }
                },
              ),
            ),
            Text(
              '${fontSize.toInt()}px',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
