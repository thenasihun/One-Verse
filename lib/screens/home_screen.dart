import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:just_audio/just_audio.dart';
import 'package:oneverse/models/surah_model.dart';
import 'package:oneverse/providers/audio_provider.dart';
import 'package:oneverse/providers/quran_provider.dart';
import 'package:oneverse/providers/settings_provider.dart';
import 'package:oneverse/screens/info_screen.dart';
import 'package:oneverse/screens/audio_player_screen.dart';
import 'package:oneverse/screens/settings_screen.dart';
import 'package:oneverse/utils/download_manager.dart';
import 'package:oneverse/widgets/verse_display.dart';
import 'package:provider/provider.dart';
import 'package:oneverse/services/share_service.dart';
import 'package:oneverse/widgets/quran_selection_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      VerseScreen(onSwitchTab: switchTab),
      const AudioPlayerScreen(),
      const SettingsScreen(),
      const InfoScreen(),
    ];
  }

  void switchTab(int index) {
    if (index == 1) {
      final quranProvider = Provider.of<QuranProvider>(context, listen: false);
      final audioProvider = Provider.of<AudioProvider>(context, listen: false);
      final settingsProvider =
          Provider.of<SettingsProvider>(context, listen: false);

      // FIX: Only load if it's a NEW Surah or the player is empty
      if (audioProvider.currentAudioSurah?.number !=
          quranProvider.selectedSurahNumber) {
        audioProvider.loadSurahAndPlay(quranProvider.selectedSurahNumber,
            settingsProvider.audioEdition, settingsProvider.translationLanguage,
            startingIndex: quranProvider.selectedAyahNumber - 1,
            autoPlay:
                true // When opening from playlist button, we usually want to play
            );
      }
    }
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withOpacity(.1),
            )
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: GNav(
              rippleColor: Theme.of(context).primaryColor.withOpacity(0.1),
              hoverColor: Theme.of(context).primaryColor.withOpacity(0.05),
              gap: 8,
              activeColor: Theme.of(context).primaryColor,
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor:
                  Theme.of(context).primaryColor.withOpacity(0.1),
              color: Colors.grey[600],
              tabs: const [
                GButton(icon: Icons.book_outlined, text: 'Verses'),
                GButton(icon: Icons.play_arrow_outlined, text: 'Player'),
                GButton(icon: Icons.settings_outlined, text: 'Settings'),
                GButton(icon: Icons.info_outline, text: 'About'),
              ],
              selectedIndex: _currentIndex,
              onTabChange: switchTab,
            ),
          ),
        ),
      ),
    );
  }
}

class VerseScreen extends StatefulWidget {
  final Function(int) onSwitchTab;
  const VerseScreen({Key? key, required this.onSwitchTab}) : super(key: key);
  @override
  State<VerseScreen> createState() => _VerseScreenState();
}

class _VerseScreenState extends State<VerseScreen> {
  late SettingsProvider _settingsProvider;
  String? _lastFetchedTranslation;
  String? _lastFetchedAudio;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _lastFetchedTranslation = _settingsProvider.translationLanguage;
    _lastFetchedAudio = _settingsProvider.audioEdition;
    _settingsProvider.addListener(_onSettingsChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchSurahList();
    });
  }

  @override
  void dispose() {
    _settingsProvider.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    final newTranslation = _settingsProvider.translationLanguage;
    final newAudio = _settingsProvider.audioEdition;
    if (newTranslation != _lastFetchedTranslation ||
        newAudio != _lastFetchedAudio) {
      setState(() {
        _lastFetchedTranslation = newTranslation;
        _lastFetchedAudio = newAudio;
      });
      _fetchVerse();
    }
  }

  Future<void> _fetchSurahList() async {
    final quranProvider = Provider.of<QuranProvider>(context, listen: false);
    if (quranProvider.surahs.isEmpty) {
      await quranProvider.fetchSurahList();
    }
    _fetchVerse();
  }

  void _fetchVerse() {
    Provider.of<QuranProvider>(context, listen: false).fetchAyah(
      _settingsProvider.translationLanguage,
      _settingsProvider.audioEdition,
    );
  }

  void _goToNextVerse() {
    final quranProvider = Provider.of<QuranProvider>(context, listen: false);
    if (quranProvider.surahs.isEmpty) return;
    final currentSurah = quranProvider.surahs
        .firstWhere((s) => s.number == quranProvider.selectedSurahNumber);
    if (quranProvider.selectedAyahNumber < currentSurah.numberOfAyahs) {
      quranProvider.selectAyah(quranProvider.selectedAyahNumber + 1);
      _fetchVerse();
    }
  }

  void _goToPreviousVerse() {
    final quranProvider = Provider.of<QuranProvider>(context, listen: false);
    if (quranProvider.selectedAyahNumber > 1) {
      quranProvider.selectAyah(quranProvider.selectedAyahNumber - 1);
      _fetchVerse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("OneVerse")),
      body: SafeArea(
        child: Consumer<QuranProvider>(
          builder: (context, quranProvider, child) {
            if (quranProvider.isSurahListLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (quranProvider.surahs.isEmpty &&
                quranProvider.surahListErrorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.signal_wifi_off,
                        size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(quranProvider.surahListErrorMessage!,
                          textAlign: TextAlign.center),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchSurahList,
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              );
            }

            final Surah? selectedSurah = quranProvider.surahs.isNotEmpty
                ? quranProvider.surahs.firstWhere(
                    (s) => s.number == quranProvider.selectedSurahNumber,
                    orElse: () => quranProvider.surahs.first)
                : null;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _buildVerseSelectorBar(context, selectedSurah, quranProvider),
                  const SizedBox(height: 20),
                  Expanded(
                    child: VerseDisplay(onRetry: _fetchVerse),
                  ),
                  const SizedBox(height: 20),
                  _buildControlPanel(context, selectedSurah, quranProvider),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildVerseSelectorBar(
      BuildContext context, Surah? selectedSurah, QuranProvider quranProvider) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showSurahSelectionBottomSheet(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("SURAH",
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold)),
                    Text(
                      selectedSurah != null
                          ? "${selectedSurah.number}. ${selectedSurah.englishName}"
                          : "Select Surah",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () =>
                    _showAyahSelectionBottomSheet(context, selectedSurah),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text("AYAH",
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold)),
                      Text("${quranProvider.selectedAyahNumber}",
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UPDATED CONTROL PANEL ---
  Widget _buildControlPanel(
      BuildContext context, Surah? selectedSurah, QuranProvider quranProvider) {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);
    final downloadManager = DownloadManager();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: _goToPreviousVerse,
            tooltip: "Previous Verse",
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              if (selectedSurah == null) return;

              // Get details for download path generation
              final settings =
                  Provider.of<SettingsProvider>(context, listen: false);
              final reciter = settings.allAudioEditions.firstWhere(
                  (e) => e.identifier == settings.audioEdition,
                  orElse: () => settings.allAudioEditions.first);

              ShareService.shareVerse(
                context: context,
                arabic: quranProvider.arabicAyah?.arabicText ?? "",
                translation:
                    quranProvider.translationAyah?.translationText ?? "",
                surahName: selectedSurah.englishName,
                surahNum: quranProvider.selectedSurahNumber,
                ayahNum: quranProvider.selectedAyahNumber,
                audioUrl: quranProvider.audioUrl ?? "",
                language: reciter.language,
                reciterName: reciter.englishName,
              );
            },
            tooltip: "Share Verse",
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: quranProvider.audioUrl != null && selectedSurah != null
                ? () {
                    final reciter = settingsProvider.allAudioEditions
                        .firstWhere(
                            (ed) =>
                                ed.identifier == settingsProvider.audioEdition,
                            orElse: () =>
                                settingsProvider.allAudioEditions.first);

                    downloadManager.downloadAudio(
                      url: quranProvider.audioUrl!,
                      language: reciter.language,
                      reciterName: reciter.englishName,
                      surahNumber: selectedSurah.number,
                      surahName: selectedSurah.englishName,
                      ayahNumber: quranProvider.selectedAyahNumber,
                    );
                  }
                : null,
            tooltip: "Download Verse",
          ),
          Consumer<AudioProvider>(
            builder: (context, audioConsumer, child) {
              // FIX: Use the smart getter we added to AudioProvider
              final isPlaying = audioConsumer.isPlaying;

              // Only show stop button if playing AND it's the current verse on screen
              final isCurrentVerse =
                  quranProvider.audioUrl == audioConsumer.currentlyPlayingUrl;
              final showStopButton =
                  isPlaying && isCurrentVerse && !audioConsumer.isPlaylistMode;

              return FloatingActionButton(
                elevation: 2,
                backgroundColor: showStopButton
                    ? Colors.red.shade700
                    : Theme.of(context).primaryColor,
                onPressed: () {
                  if (showStopButton) {
                    audioConsumer.stop();
                  } else if (quranProvider.audioUrl != null) {
                    audioConsumer.playSingleVerse(quranProvider.audioUrl!);
                  }
                },
                child: Icon(
                    showStopButton
                        ? Icons.stop_rounded
                        : Icons.play_arrow_rounded,
                    size: 36,
                    color: Colors.white),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.queue_music_rounded),
            onPressed: () {
              // --- FIX IS HERE ---
              // Logic:
              // 1. If Surah is different -> LOAD NEW SURAH
              // 2. If Surah is same but verse is different -> SEEK TO VERSE

              bool isDifferentSurah = audioProvider.currentAudioSurah?.number !=
                  quranProvider.selectedSurahNumber;
              bool isSameSurahButDifferentVerse = !isDifferentSurah &&
                  (audioProvider.currentAyahIndex !=
                      quranProvider.selectedAyahNumber - 1);

              if (isDifferentSurah || audioProvider.currentAudioSurah == null) {
                // Load New Playlist
                audioProvider.loadSurahAndPlay(
                    quranProvider.selectedSurahNumber,
                    settingsProvider.audioEdition,
                    settingsProvider.translationLanguage,
                    startingIndex: quranProvider.selectedAyahNumber - 1,
                    autoPlay: true);
              } else if (isSameSurahButDifferentVerse) {
                // Just Seek in Current Playlist
                audioProvider.playVerse(quranProvider.selectedAyahNumber - 1);
              }
              // If same surah AND same verse, just switch tab (do nothing to audio)

              widget.onSwitchTab(1);
            },
            tooltip: "Open in Player",
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded),
            onPressed: _goToNextVerse,
            tooltip: "Next Verse",
          ),
        ],
      ),
    );
  }

  void _showSurahSelectionBottomSheet(BuildContext context) {
    final quranProvider = Provider.of<QuranProvider>(context, listen: false);
    QuranSelectionHelper.showSurahSheet(
        context: context,
        surahs: quranProvider.surahs,
        onSelect: (surah) {
          quranProvider.selectSurah(surah.number);
          // quranProvider.selectAyah(1);
          _fetchVerse();
          // Navigator.of(context).pop();
        });
  }

  void _showAyahSelectionBottomSheet(
      BuildContext context, Surah? selectedSurah) {
    if (selectedSurah == null) return;
    final quranProvider = Provider.of<QuranProvider>(context, listen: false);
    QuranSelectionHelper.showAyahSheet(
      context: context,
      totalAyahs: selectedSurah.numberOfAyahs,
      selectedAyah: quranProvider.selectedAyahNumber,
      onSelect: (ayahNum) {
        quranProvider.selectAyah(ayahNum);
        _fetchVerse();
      },
    );
  }
}
