import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:oneverse/models/ayah_model.dart';
import 'package:oneverse/models/surah_model.dart'; 
import 'package:oneverse/providers/audio_provider.dart';
import 'package:oneverse/providers/quran_provider.dart'; 
import 'package:oneverse/providers/settings_provider.dart';
import 'package:oneverse/utils/download_manager.dart';
import 'package:provider/provider.dart';

class AudioPlayerScreen extends StatefulWidget {
  const AudioPlayerScreen({Key? key}) : super(key: key);

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  int _viewMode = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initPlayerIfNeeded();
    });
  }

  void _initPlayerIfNeeded() {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    final quranProvider = Provider.of<QuranProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    bool needsSync = false;
    int targetSurah = 1;
    int targetAyah = 0;

    if (quranProvider.surahs.isNotEmpty) {
      if (audioProvider.currentAudioSurah == null || 
          audioProvider.currentAudioSurah!.number != quranProvider.selectedSurahNumber) {
        needsSync = true;
        targetSurah = quranProvider.selectedSurahNumber;
        targetAyah = quranProvider.selectedAyahNumber - 1;
      }
    } else if (audioProvider.currentAudioSurah == null) {
      needsSync = true;
      targetSurah = 1;
      targetAyah = 0;
    }

    if (needsSync && !audioProvider.isLoading) {
      final edition = settingsProvider.audioEdition.isNotEmpty 
          ? settingsProvider.audioEdition 
          : 'ar.abdurrahmaansudais';
      final trans = settingsProvider.translationLanguage.isNotEmpty 
          ? settingsProvider.translationLanguage 
          : 'en.asad';

      audioProvider.loadSurahAndPlay(
        targetSurah, 
        edition, 
        trans, 
        startingIndex: targetAyah,
        autoPlay: false, 
      );
    }
  }

  void _cycleViewMode() {
    setState(() {
      _viewMode = (_viewMode + 1) % 3;
    });
  }

  // --- Surah Selection Logic ---
  void _showSurahSelection(BuildContext context) {
    final quranProvider = Provider.of<QuranProvider>(context, listen: false);
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    if (quranProvider.surahs.isEmpty) {
      quranProvider.fetchSurahList();
      return; 
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollController) => _SurahSearchDelegate(
          scrollController: scrollController,
          allSurahs: quranProvider.surahs,
          onSelect: (surah) {
            Navigator.pop(context);
            audioProvider.loadSurahAndPlay(
              surah.number,
              settingsProvider.audioEdition,
              settingsProvider.translationLanguage,
              startingIndex: 0,
              autoPlay: true
            );
            quranProvider.selectSurah(surah.number);
          },
        ),
      ),
    );
  }

  // --- Ayah Selection Logic ---
  void _showAyahSelection(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    final quranProvider = Provider.of<QuranProvider>(context, listen: false);
    
    if (audioProvider.currentAudioSurah == null) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            childAspectRatio: 1.5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: audioProvider.currentAudioSurah!.ayahs.length,
          itemBuilder: (context, index) {
            final ayahNum = index + 1;
            final isCurrent = audioProvider.currentAyahIndex == index;
            return InkWell(
              onTap: () {
                Navigator.pop(context);
                audioProvider.playVerse(index);
                quranProvider.selectAyah(ayahNum);
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  color: isCurrent ? Theme.of(context).primaryColor : Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    "$ayahNum",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isCurrent ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Audio Player'),
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
        backgroundColor: Colors.transparent,
        elevation: 0,
        // --- REMOVED PLAYLIST ICON HERE ---
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _StaticBackground(),
          
          SafeArea(
            child: Consumer<AudioProvider>(
              builder: (context, audioProvider, child) {
                // FIXED: We now ALWAYS return the Player UI (Stack Layer 1)
                // We overlay loader or error on top if needed (Stack Layer 2)
                return Stack(
                  children: [
                    // Layer 1: The UI (Always Visible, even with null data)
                    _PlayerContent(
                      audioProvider: audioProvider,
                      isDarkMode: isDarkMode,
                      viewMode: _viewMode,
                      onCycleViewMode: _cycleViewMode,
                      onSurahTap: () => _showSurahSelection(context),
                      onAyahTap: () => _showAyahSelection(context),
                    ),

                    // Layer 2: Loading Indicator Overlay
                    if (audioProvider.isLoading)
                      Container(
                        color: Colors.black.withOpacity(0.3),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: isDarkMode ? Colors.white : Theme.of(context).primaryColor,
                          ),
                        ),
                      ),

                    // Layer 3: Error Overlay (Only if truly empty and error exists)
                    if (audioProvider.errorMessage != null && audioProvider.currentAudioSurah == null)
                      Container(
                        color: Colors.black.withOpacity(0.7),
                        child: _buildErrorState(context, audioProvider, isDarkMode),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, AudioProvider audioProvider, bool isDarkMode) {
    final Color textColor = Colors.white; // Always white on dark overlay
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, size: 80, color: textColor.withOpacity(0.7)),
          const SizedBox(height: 20),
          Text("Something Went Wrong", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 10),
          TextButton.icon(
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text("Retry", style: TextStyle(color: Colors.white)),
            onPressed: audioProvider.retryLastPlaylist,
          ),
        ],
      ),
    );
  }
}

class _StaticBackground extends StatelessWidget {
  const _StaticBackground({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const NetworkImage("https://images.pexels.com/photos/949587/pexels-photo-949587.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2"),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black.withOpacity(isDarkMode ? 0.6 : 0.05), BlendMode.darken),
        ),
      ),
    );
  }
}

class _PlayerContent extends StatelessWidget {
  final AudioProvider audioProvider;
  final bool isDarkMode;
  final int viewMode; 
  final VoidCallback onCycleViewMode;
  final VoidCallback onSurahTap;
  final VoidCallback onAyahTap;

  const _PlayerContent({
    Key? key, 
    required this.audioProvider, 
    required this.isDarkMode, 
    required this.viewMode, 
    required this.onCycleViewMode,
    required this.onSurahTap,
    required this.onAyahTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color textColor = isDarkMode ? Colors.white : Colors.black.withOpacity(0.8);
    final Color cardBackgroundColor = isDarkMode ? Colors.black.withOpacity(0.4) : Colors.white.withOpacity(0.75);
    final Color iconColor = isDarkMode ? Colors.white : Colors.grey.shade800;

    final settings = Provider.of<SettingsProvider>(context, listen: false);
    
    // SAFE ACCESS: Handle nulls for UI stability
    final hasData = audioProvider.currentAudioSurah != null;
    final englishName = hasData ? audioProvider.currentAudioSurah!.englishName : "Loading...";
    final surahNum = hasData ? "${audioProvider.currentAudioSurah!.number}" : "--";
    
    // Determine Ayah Number safely
    String ayahNumDisplay = "--";
    if (hasData && audioProvider.currentAyahIndex < audioProvider.currentAudioSurah!.ayahs.length) {
       ayahNumDisplay = "${audioProvider.currentAudioSurah!.ayahs[audioProvider.currentAyahIndex].numberInSurah}";
    }

    final currentAyah = audioProvider.currentDisplayArabicAyah;
    final currentTranslationAyah = audioProvider.currentDisplayTranslationAyah;

    String direction = 'ltr';
    try {
      final edition = settings.allTextEditions.firstWhere((e) => e.identifier == settings.translationLanguage, orElse: () => settings.allTextEditions.isNotEmpty ? settings.allTextEditions.first : null as dynamic);
      if (edition != null) { direction = edition.direction ?? 'ltr'; }
    } catch (e) {}
    final bool isRtl = direction == 'rtl';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(color: cardBackgroundColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.1))),
                    child: Column(
                      children: [
                        _buildTitleBar(context, englishName, surahNum, ayahNumDisplay, isDarkMode, textColor),
                        const Divider(height: 24),
                        Expanded(
                          child: _buildTextContent(currentAyah?.arabicText, currentTranslationAyah?.translationText, textColor, isRtl),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          _buildSeekBar(context, audioProvider, isDarkMode),
          const SizedBox(height: 10),
          _buildPlayerControls(context, audioProvider, iconColor),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTextContent(String? arabic, String? translation, Color textColor, bool isRtl) {
    final arabicText = Text(arabic ?? 'Loading...', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'UthmanicHafs', fontSize: 32, color: textColor, height: 1.8));
    final transText = Text(translation ?? '', textAlign: isRtl ? TextAlign.right : TextAlign.left, textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr, style: TextStyle(fontSize: 18, color: textColor.withOpacity(0.9), fontStyle: FontStyle.italic, height: 1.5));

    if (viewMode == 1) return Center(child: SingleChildScrollView(child: arabicText));
    else if (viewMode == 2) return Center(child: SingleChildScrollView(child: transText));
    else return Column(children: [Expanded(flex: 4, child: Center(child: SingleChildScrollView(child: arabicText))), const Divider(height: 20, thickness: 1), Expanded(flex: 3, child: Center(child: SingleChildScrollView(child: transText)))]);
  }

  // Updated Title Bar to accept Strings (Safe)
  Widget _buildTitleBar(BuildContext context, String name, String surahNum, String ayahNum, bool isDarkMode, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
      children: [
        InkWell(
          onTap: onAyahTap,
          borderRadius: BorderRadius.circular(30),
          child: _buildInfoChip(context, "AYAH", ayahNum, isDarkMode)
        ),
        
        Expanded(
          child: InkWell(
            onTap: onSurahTap,
            borderRadius: BorderRadius.circular(30),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0), 
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), 
                decoration: BoxDecoration(color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.1), borderRadius: BorderRadius.circular(30)), 
                child: Text(name, textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor), overflow: TextOverflow.ellipsis)
              )
            ),
          )
        ),
        
        InkWell(
          onTap: onSurahTap,
          borderRadius: BorderRadius.circular(30),
          child: _buildInfoChip(context, "SURAH", surahNum, isDarkMode)
        ),
      ]
    );
  }

  Widget _buildInfoChip(BuildContext context, String label, String value, bool isDarkMode) {
    final Color chipTextColor = isDarkMode ? Colors.white : Colors.black;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), child: Column(children: [Text(label, style: TextStyle(fontSize: 10, color: chipTextColor.withOpacity(0.7), fontWeight: FontWeight.bold)), Text(value, style: TextStyle(fontSize: 16, color: chipTextColor, fontWeight: FontWeight.bold))]));
  }

  Widget _buildPlayerControls(BuildContext context, AudioProvider audioProvider, Color iconColor) {
    IconData viewIcon;
    if (viewMode == 1) viewIcon = Icons.text_fields_rounded; else if (viewMode == 2) viewIcon = Icons.translate_rounded; else viewIcon = Icons.vertical_split_rounded;

    return Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        IconButton(icon: Icon(viewIcon, color: Theme.of(context).primaryColor), onPressed: onCycleViewMode, tooltip: "Change View"),
        IconButton(icon: Icon(Icons.skip_previous_rounded, size: 40, color: iconColor), onPressed: audioProvider.playPrevious),
        StreamBuilder<PlayerState>(stream: audioProvider.audioPlayer.playerStateStream, builder: (context, snapshot) {
            final playerState = snapshot.data; final processingState = playerState?.processingState; final isPlaying = playerState?.playing ?? false;
            // Removed buffering check here to prevent button flickering, loader is now in Stack
            return FloatingActionButton(onPressed: isPlaying ? audioProvider.audioPlayer.pause : audioProvider.audioPlayer.play, child: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 40, color: Colors.white), backgroundColor: Theme.of(context).primaryColor, elevation: 4);
          }),
        IconButton(icon: Icon(Icons.skip_next_rounded, size: 40, color: iconColor), onPressed: audioProvider.playNext),
        IconButton(icon: Icon(Icons.download_outlined, color: iconColor), onPressed: audioProvider.downloadCurrentVerse, tooltip: "Download"),
      ]);
  }

  Widget _buildSeekBar(BuildContext context, AudioProvider audioProvider, bool isDarkMode) {
    final Color activeColor = Theme.of(context).primaryColor; final Color inactiveColor = isDarkMode ? Colors.white38 : Colors.black26; final Color textColor = isDarkMode ? Colors.white70 : Colors.black54;
    return StreamBuilder<Duration?>(stream: audioProvider.audioPlayer.durationStream, builder: (context, snapshot) {
        final duration = snapshot.data ?? Duration.zero;
        return StreamBuilder<Duration>(stream: audioProvider.audioPlayer.positionStream, builder: (context, snapshot) {
            var position = snapshot.data ?? Duration.zero; if (position > duration) position = duration;
            return Column(children: [
                SliderTheme(data: SliderTheme.of(context).copyWith(thumbColor: isDarkMode ? Colors.white : activeColor, activeTrackColor: activeColor, inactiveTrackColor: inactiveColor, trackHeight: 4, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6), overlayColor: activeColor.withOpacity(0.2)), child: Slider(value: position.inMilliseconds.toDouble(), max: duration.inMilliseconds.toDouble(), onChanged: (value) => audioProvider.audioPlayer.seek(Duration(milliseconds: value.round())))),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(_formatDuration(position), style: TextStyle(color: textColor, fontSize: 12)), Text(_formatDuration(duration), style: TextStyle(color: textColor, fontSize: 12))])),
              ]);
          });
      });
  }
  String _formatDuration(Duration d) { final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0'); final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0'); return "$minutes:$seconds"; }
}

// --- Surah Search Delegate (Same as used in Home Screen, included here for player access) ---
class _SurahSearchDelegate extends StatefulWidget {
  final ScrollController scrollController;
  final List<Surah> allSurahs;
  final Function(Surah) onSelect;

  const _SurahSearchDelegate({Key? key, required this.scrollController, required this.allSurahs, required this.onSelect}) : super(key: key);
  @override
  __SurahSearchDelegateState createState() => __SurahSearchDelegateState();
}

class __SurahSearchDelegateState extends State<_SurahSearchDelegate> {
  List<Surah> _filteredSurahs = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredSurahs = widget.allSurahs;
    _searchController.addListener(_filterSurahs);
  }

  void _filterSurahs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSurahs = widget.allSurahs.where((surah) {
        return surah.englishName.toLowerCase().contains(query) || surah.name.contains(query) || surah.number.toString() == query;
      }).toList();
    });
  }

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(16.0), child: Column(children: [TextField(controller: _searchController, decoration: InputDecoration(hintText: "Search Surah...", prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))), const SizedBox(height: 16), Expanded(child: ListView.separated(controller: widget.scrollController, itemCount: _filteredSurahs.length, separatorBuilder: (context, index) => const Divider(height: 1), itemBuilder: (context, index) { final surah = _filteredSurahs[index]; return ListTile(title: Text("${surah.number}. ${surah.englishName}"), subtitle: Text(surah.name), onTap: () => widget.onSelect(surah)); }))]));
  }
}