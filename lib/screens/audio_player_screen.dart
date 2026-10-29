import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:just_audio/just_audio.dart';
import 'package:oneverse/models/playback_config.dart';
import 'package:oneverse/models/surah_model.dart';
import 'package:oneverse/providers/audio_provider.dart';
import 'package:oneverse/providers/download_provider.dart';
import 'package:oneverse/providers/quran_provider.dart';
import 'package:oneverse/providers/settings_provider.dart';
import 'package:oneverse/screens/downloads_screen.dart';
import 'package:oneverse/services/offline_store.dart';
import 'package:provider/provider.dart';
import 'package:oneverse/widgets/quran_selection_helper.dart';
import 'package:oneverse/services/share_service.dart';

class AudioPlayerScreen extends StatefulWidget {
  const AudioPlayerScreen({Key? key}) : super(key: key);

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  int _viewMode = 0; // 0: Split, 1: Arabic, 2: Translation

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

    if (audioProvider.isLoading ||
        audioProvider.hasPlaylistFor(quranProvider.selectedSurahNumber)) {
      return;
    }
    audioProvider.loadSurahAndPlay(
      quranProvider.selectedSurahNumber,
      startingIndex: quranProvider.selectedAyahNumber - 1,
      autoPlay: false,
    );
  }

  void _cycleViewMode() {
    setState(() {
      _viewMode = (_viewMode + 1) % 3;
    });
  }

  void _showSurahSelection(BuildContext context) {
    final quranProvider = Provider.of<QuranProvider>(context, listen: false);
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);

    if (quranProvider.surahs.isEmpty) {
      quranProvider.fetchSurahList();
      return;
    }

    QuranSelectionHelper.showSurahSheet(
        context: context,
        surahs: quranProvider.surahs,
        onSelect: (surah) {
          audioProvider.loadSurahAndPlay(surah.number,
              startingIndex: 0, autoPlay: true);
          quranProvider.selectSurah(surah.number);
        });
  }

  void _showAyahSelection(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    final quranProvider = Provider.of<QuranProvider>(context, listen: false);

    if (audioProvider.currentAudioSurah == null) return;

    QuranSelectionHelper.showAyahSheet(
        context: context,
        totalAyahs: audioProvider.currentAudioSurah!.ayahs.length,
        selectedAyah: audioProvider.currentAyahIndex + 1,
        onSelect: (ayahNum) {
          audioProvider.playVerse(ayahNum - 1);
          quranProvider.selectAyah(ayahNum);
        });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Standard App Bar (No longer transparent over an image)
      appBar: AppBar(
        title: const Text('Audio Player'),
        centerTitle: true,
        elevation: 0,
      ),
      // Standard Theme Background
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: SafeArea(
        child: Consumer<AudioProvider>(
          builder: (context, audioProvider, child) {
            return Stack(
              children: [
                // Layer 1: The UI
                _PlayerContent(
                  audioProvider: audioProvider,
                  isDarkMode: isDarkMode,
                  viewMode: _viewMode,
                  onCycleViewMode: _cycleViewMode,
                  onSurahTap: () => _showSurahSelection(context),
                  onAyahTap: () => _showAyahSelection(context),
                ),

                // Layer 2: Loading Indicator
                if (audioProvider.isLoading)
                  Container(
                    color: Theme.of(context)
                        .scaffoldBackgroundColor
                        .withOpacity(0.8),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),

                // Layer 3: Error Overlay
                if (audioProvider.errorMessage != null &&
                    audioProvider.currentAudioSurah == null)
                  Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: _buildErrorState(context, audioProvider, isDarkMode),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(
      BuildContext context, AudioProvider audioProvider, bool isDarkMode) {
    final textColor = isDarkMode ? Colors.white : Colors.black;
    if (audioProvider.isOfflineError) {
      return _OfflineState(audioProvider: audioProvider, textColor: textColor);
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 80, color: textColor.withOpacity(0.5)),
            const SizedBox(height: 20),
            Text("Something Went Wrong",
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 10),
            Text(audioProvider.errorMessage ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(color: textColor.withOpacity(0.7))),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
              onPressed: audioProvider.retryLastPlaylist,
            ),
          ],
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
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;
    // Using standard Card Color from Theme instead of glassmorphism
    final Color cardBackgroundColor =
        Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor;
    final Color iconColor =
        Theme.of(context).iconTheme.color ?? Colors.grey.shade700;

    final settings = Provider.of<SettingsProvider>(context, listen: false);

    final hasData = audioProvider.currentAudioSurah != null;
    final englishName =
        hasData ? audioProvider.currentAudioSurah!.englishName : "Loading...";
    final surahNum =
        hasData ? "${audioProvider.currentAudioSurah!.number}" : "--";

    String ayahNumDisplay = "--";
    if (hasData &&
        audioProvider.currentAyahIndex <
            audioProvider.currentAudioSurah!.ayahs.length) {
      ayahNumDisplay =
          "${audioProvider.currentAudioSurah!.ayahs[audioProvider.currentAyahIndex].numberInSurah}";
    }

    final currentAyah = audioProvider.currentDisplayArabicAyah;
    final currentTranslationAyah = audioProvider.currentDisplayTranslationAyah;

    final bool isRtl =
        settings.findEdition(settings.translationLanguage)?.direction == 'rtl';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // MAIN TEXT DISPLAY CARD
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                decoration: BoxDecoration(
                    color: cardBackgroundColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                    border: Border.all(
                        color: (isDarkMode ? Colors.white : Colors.black)
                            .withOpacity(0.05))),
                child: Column(
                  children: [
                    _buildTitleBar(context, englishName, surahNum,
                        ayahNumDisplay, isDarkMode, textColor),
                    const SizedBox(height: 8),
                    _ReciterStrip(audioProvider: audioProvider),
                    const Divider(height: 20),
                    Expanded(
                      child: _buildTextContent(
                          context,
                          currentAyah?.arabicText,
                          currentTranslationAyah?.translationText,
                          textColor,
                          isRtl),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // INLINE SLIDER (00:00 --- 04:00)
          _buildInlineSeekBar(context, audioProvider, isDarkMode),

          const SizedBox(height: 8),

          // CONTROL PANEL
          _buildControlPanel(context, audioProvider, iconColor),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTextContent(BuildContext context, String? arabic,
      String? translation, Color textColor, bool isRtl) {
    // DEBUG (sirf current ayah ka short debug)
    debugArabicRenderIssues('Current Arabic Ayah', arabic);
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final cleanedArabic = arabic != null ? cleanArabicForDisplay(arabic) : null;
    double lineHeight(double fontSize, String fontFamily) {
      return settings.getLineHeight(fontSize, fontFamily);
    }

    final arabicText = Text(
        settings.arabicFont != "UthmanicHafs"
            ? arabic ?? 'Loading'
            : cleanedArabic ?? '',
        textAlign: TextAlign.center,
        locale: const Locale('ar'),
        textDirection: TextDirection.rtl,
        style: TextStyle(
            fontFamily: settings.arabicFont,
            fontFamilyFallback: const [
              'Amiri',
              'ScheherazadeNew',
              'Lateef',
              'NotoNaskhArabic',
              'UthmanicHafs'
            ],
            letterSpacing: 0,
            leadingDistribution: TextLeadingDistribution.even,
            wordSpacing: 2,
            fontSize: settings.arabicFontSize,
            color: textColor,
            height: lineHeight(settings.arabicFontSize, settings.arabicFont)));
    final transText = Text(translation ?? '',
        textAlign: isRtl ? TextAlign.right : TextAlign.left,
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        style: TextStyle(
            fontFamily: settings.translationFont,
            fontSize: settings.translationFontSize,
            color: textColor.withOpacity(0.9),
            letterSpacing: 0,
            height: lineHeight(
                settings.translationFontSize, settings.translationFont)));

    if (viewMode == 1)
      return Center(child: SingleChildScrollView(child: arabicText));
    else if (viewMode == 2)
      return Center(child: SingleChildScrollView(child: transText));
    else
      return Column(children: [
        Expanded(
            flex: 4,
            child: Center(child: SingleChildScrollView(child: arabicText))),
        const Divider(height: 20, thickness: 1),
        Expanded(
            flex: 3,
            child: Center(child: SingleChildScrollView(child: transText)))
      ]);
  }

  Widget _buildTitleBar(BuildContext context, String name, String surahNum,
      String ayahNum, bool isDarkMode, Color textColor) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      InkWell(
          onTap: onAyahTap,
          borderRadius: BorderRadius.circular(30),
          child: _buildInfoChip(context, "AYAH", ayahNum, isDarkMode)),
      Expanded(
          child: InkWell(
        onTap: onSurahTap,
        borderRadius: BorderRadius.circular(30),
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                    color: (isDarkMode ? Colors.white : Colors.black)
                        .withOpacity(0.05), // Subtle background
                    borderRadius: BorderRadius.circular(30)),
                child: Text(name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor),
                    overflow: TextOverflow.ellipsis))),
      )),
      InkWell(
          onTap: onSurahTap,
          borderRadius: BorderRadius.circular(30),
          child: _buildInfoChip(context, "SURAH", surahNum, isDarkMode)),
    ]);
  }

  Widget _buildInfoChip(
      BuildContext context, String label, String value, bool isDarkMode) {
    final Color chipTextColor = isDarkMode ? Colors.white : Colors.black87;
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: chipTextColor.withOpacity(0.6),
                  fontWeight: FontWeight.bold)),
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  color: chipTextColor,
                  fontWeight: FontWeight.bold))
        ]));
  }

  // --- NEW INLINE SLIDER ---
  Widget _buildInlineSeekBar(
      BuildContext context, AudioProvider audioProvider, bool isDarkMode) {
    final Color activeColor = Theme.of(context).primaryColor;
    final Color inactiveColor = isDarkMode ? Colors.white24 : Colors.black12;
    final Color textColor = isDarkMode ? Colors.white70 : Colors.black54;

    return StreamBuilder<Duration?>(
      stream: audioProvider.audioPlayer.durationStream,
      builder: (context, snapshot) {
        final duration = snapshot.data ?? Duration.zero;
        return StreamBuilder<Duration>(
          stream: audioProvider.audioPlayer.positionStream,
          builder: (context, snapshot) {
            var position = snapshot.data ?? Duration.zero;
            if (position > duration) position = duration;

            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                children: [
                  // Current Time
                  Text(_formatDuration(position),
                      style: TextStyle(
                          color: textColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),

                  // Slider (Expanded)
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        thumbColor: isDarkMode ? Colors.white : activeColor,
                        activeTrackColor: activeColor,
                        inactiveTrackColor: inactiveColor,
                        trackHeight:
                            3.0, // Slightly thicker than hairline for visibility
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6.0),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 14.0),
                        overlayColor: activeColor.withOpacity(0.15),
                        trackShape: const RectangularSliderTrackShape(),
                      ),
                      child: Slider(
                        value: position.inMilliseconds.toDouble(),
                        max: duration.inMilliseconds.toDouble(),
                        onChanged: (value) => audioProvider.audioPlayer
                            .seek(Duration(milliseconds: value.round())),
                      ),
                    ),
                  ),

                  // Total Duration
                  Text(_formatDuration(duration),
                      style: TextStyle(
                          color: textColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- CLUSTERED CONTROL PANEL ---
  Widget _buildControlPanel(
      BuildContext context, AudioProvider audioProvider, Color iconColor) {
    final primaryColor = Theme.of(context).primaryColor;

    Widget buildMiniBtn({
      required IconData icon,
      required VoidCallback? onTap,
      String? tooltip,
      Color? color,
      double size = 22,
    }) {
      return IconButton(
        icon: Icon(icon),
        iconSize: size,
        color: color ?? iconColor,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        style: IconButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap),
        onPressed: onTap,
      );
    }

    IconData viewIcon;
    if (viewMode == 1)
      viewIcon = Icons.text_fields_rounded;
    else if (viewMode == 2)
      viewIcon = Icons.translate_rounded;
    else
      viewIcon = Icons.vertical_split_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildMiniBtn(
                icon: Icons.share_outlined,
                onTap: () {
                  if (audioProvider.currentAudioSurah == null) return;
                  final settings =
                      Provider.of<SettingsProvider>(context, listen: false);
                  final playingEdition = audioProvider.isTranslationSegment ||
                          audioProvider.currentConfig?.mode ==
                              PlaybackMode.translation
                      ? audioProvider.currentConfig?.translationAudioEdition
                      : audioProvider.currentConfig?.audioEdition;
                  final reciter = settings.findEdition(playingEdition) ??
                      settings.findEdition(settings.audioEdition);
                  if (reciter == null) return;

                  final localFile = audioProvider.currentLocalFile;
                  ShareService.shareVerse(
                    context: context,
                    arabic:
                        audioProvider.currentDisplayArabicAyah?.arabicText ??
                            "",
                    translation: audioProvider
                            .currentDisplayTranslationAyah?.translationText ??
                        "",
                    surahName: audioProvider.currentAudioSurah!.englishName,
                    surahNum: audioProvider.currentAudioSurah!.number,
                    ayahNum: audioProvider.currentAudioSurah!
                        .ayahs[audioProvider.currentAyahIndex].numberInSurah,
                    audioUrl: audioProvider.currentlyPlayingUrl ?? "",
                    language: reciter.language,
                    reciterName: reciter.englishName,
                    localAudioPath: localFile,
                  );
                },
                tooltip: "Share",
              ),
              const SizedBox(width: 12),
              _SurahDownloadButton(
                  audioProvider: audioProvider, iconColor: iconColor),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildMiniBtn(
                icon: Icons.skip_previous_rounded,
                size: 26,
                onTap: audioProvider.playPrevious,
                tooltip: "Previous",
              ),
              const SizedBox(width: 8),
              StreamBuilder<PlayerState>(
                stream: audioProvider.audioPlayer.playerStateStream,
                builder: (context, snapshot) {
                  final playerState = snapshot.data;
                  final isPlaying = playerState?.playing ?? false;
                  return SizedBox(
                    width: 50,
                    height: 50,
                    child: FloatingActionButton(
                      elevation: 4,
                      backgroundColor: Theme.of(context).primaryColor,
                      onPressed: isPlaying
                          ? audioProvider.audioPlayer.pause
                          : audioProvider.audioPlayer.play,
                      child: Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 30,
                          color: Colors.white),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              buildMiniBtn(
                icon: Icons.skip_next_rounded,
                size: 26,
                onTap: audioProvider.playNext,
                tooltip: "Next",
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildMiniBtn(
                onTap: () => audioProvider.toggleLoopMode(),
                icon: audioProvider.loopMode == LoopMode.one
                    ? Icons.repeat_one_rounded
                    : Icons.repeat_rounded,
                color: audioProvider.loopMode == LoopMode.one
                    ? primaryColor
                    : null,
                tooltip: "Repeat",
              ),
              const SizedBox(width: 12),
              buildMiniBtn(
                icon: viewIcon,
                color: primaryColor,
                onTap: onCycleViewMode,
                tooltip: "Change View",
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}

String cleanArabicForDisplay(String s) {
  final buffer = StringBuffer();

  for (final r in s.runes) {
    // 1) Harakaat + superscript alif → keep
    if ((r >= 0x064B && r <= 0x0652) || r == 0x0670) {
      buffer.writeCharCode(r);
      continue;
    }

    // 2) Quranic decorative marks → REMOVE
    if (r >= 0x06D6 && r <= 0x06ED) {
      continue;
    }

    // 3) Everything else (Arabic letters, waqf letters, words) → keep
    buffer.writeCharCode(r);
  }

  return buffer.toString();
}

// ================= DEBUG HELPERS =================

bool _isArabicCombiningMark(int r) {
  // Harakaat / Quran marks commonly in these ranges
  // 064B-065F: Tashkeel, 0670: superscript alif, 06D6-06ED: Quranic marks
  return (r >= 0x064B && r <= 0x065F) ||
      r == 0x0670 ||
      (r >= 0x06D6 && r <= 0x06ED);
}

String _uHex(int r) => 'U+${r.toRadixString(16).toUpperCase().padLeft(4, '0')}';

/// Prints only the important debug info:
/// i) Does text contain dotted circle (U+25CC)?
/// ii) Any combining marks without a base letter nearby (likely cause)?
/// iii) Any weird non-Arabic / replacement characters?
void debugArabicRenderIssues(String label, String? text, {int context = 6}) {
  if (text == null || text.isEmpty) {
    debugPrint('$label: empty');
    return;
  }

  final runes = text.runes.toList();

  // 1) Dotted circle direct check
  final dotted = runes.contains(0x25CC);

  // 2) Find combining marks that are likely "floating"
  final floatingMarks = <Map<String, dynamic>>[];

  for (int i = 0; i < runes.length; i++) {
    final r = runes[i];
    if (_isArabicCombiningMark(r)) {
      // Look for a base letter just before
      final prev = i > 0 ? runes[i - 1] : null;
      final prevIsMark = prev != null && _isArabicCombiningMark(prev);
      final prevIsLikelyBase = prev != null && !prevIsMark;

      // If mark is at start or previous is also a mark, often floating
      if (i == 0 || !prevIsLikelyBase) {
        final start = (i - context) < 0 ? 0 : (i - context);
        final end =
            (i + context) >= runes.length ? runes.length - 1 : (i + context);

        final snippet = String.fromCharCodes(runes.sublist(start, end + 1));
        floatingMarks.add({
          'index': i,
          'cp': _uHex(r),
          'char': String.fromCharCode(r),
          'snippet': snippet,
        });
      }
    }
  }

  // 3) Print a short summary (avoid huge logs)
  debugPrint('--- Arabic Render Debug: $label ---');
  debugPrint('Length: ${text.length}, Runes: ${runes.length}');
  debugPrint('Has dotted circle (U+25CC): $dotted');

  if (dotted) {
    // show where it occurs (first few)
    final idxs = <int>[];
    for (int i = 0; i < runes.length && idxs.length < 5; i++) {
      if (runes[i] == 0x25CC) idxs.add(i);
    }
    debugPrint('Dotted circle positions (first 5): $idxs');
  }

  if (floatingMarks.isNotEmpty) {
    debugPrint(
        'Floating combining marks found: ${floatingMarks.length} (showing first 5)');
    for (final m in floatingMarks.take(5)) {
      debugPrint(
          'At #${m['index']} ${m['cp']} "${m['char']}" | snippet: "${m['snippet']}"');
    }
  } else {
    debugPrint('No obvious floating combining marks detected.');
  }

  debugPrint('--- end ---');
}

/// Optional cleanup if you want to test quickly:
String removeDottedCircle(String s) => s.replaceAll('\u25CC', '');

/// Shows which reciter(s) are playing; highlights the active one in
/// Arabic + Translation mode.
class _ReciterStrip extends StatelessWidget {
  final AudioProvider audioProvider;
  const _ReciterStrip({required this.audioProvider});

  @override
  Widget build(BuildContext context) {
    final config = audioProvider.currentConfig;
    if (config == null || audioProvider.currentAudioSurah == null) {
      return const SizedBox.shrink();
    }
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final primary = Theme.of(context).primaryColor;
    final muted = Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;

    Widget chip(String label, String name, bool active) {
      return Flexible(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: active ? primary.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: active ? primary.withOpacity(0.5) : muted.withOpacity(0.2)),
          ),
          child: Text(
            '$label · $name',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
              color: active ? primary : muted,
            ),
          ),
        ),
      );
    }

    final translationActive = audioProvider.isTranslationSegment ||
        config.mode == PlaybackMode.translation;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (config.needsArabicAudio)
          chip('Arabic', settings.editionName(config.audioEdition),
              !translationActive),
        if (config.isPaired)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(Icons.arrow_forward_rounded, size: 14, color: muted),
          ),
        if (config.needsTranslationAudio)
          chip('Translation',
              settings.editionName(config.translationAudioEdition), translationActive),
        if (audioProvider.isOfflinePlayback) ...[
          const SizedBox(width: 6),
          Tooltip(
            message: 'Playing from downloads',
            child: Icon(Icons.offline_pin_rounded, size: 18, color: primary),
          ),
        ],
      ],
    );
  }
}

/// Download button for the player. Tap: choose verse or complete surah.
/// Long-press: download the complete surah straight away. Shows progress
/// while a surah downloads and a check once it's available offline.
class _SurahDownloadButton extends StatelessWidget {
  final AudioProvider audioProvider;
  final Color iconColor;
  const _SurahDownloadButton(
      {required this.audioProvider, required this.iconColor});

  static Surah? _surahOf(AudioProvider audio) {
    final d = audio.currentAudioSurah;
    if (d == null) return null;
    return Surah(
      number: d.number,
      name: d.name,
      englishName: d.englishName,
      numberOfAyahs: d.numberOfAyahs,
      revelationType: d.revelationType,
    );
  }

  static void startSurahDownload(BuildContext context, AudioProvider audio) {
    final surah = _surahOf(audio);
    final settings = context.read<SettingsProvider>();
    final config = audio.currentConfig ?? settings.playbackConfig;
    if (surah == null) return;
    context.read<SurahDownloadProvider>().downloadSurah(
      surah,
      config,
      editionNames: {
        for (final e in config.requiredEditions) e: settings.editionName(e),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final downloads = context.watch<SurahDownloadProvider>();
    final store = context.watch<OfflineStore>();
    final surah = _surahOf(audioProvider);
    final config = audioProvider.currentConfig;
    final primary = Theme.of(context).primaryColor;

    final task = surah == null ? null : downloads.taskFor(surah.number);
    final isDownloading = task?.isActive ?? false;
    final isOffline = surah != null &&
        config != null &&
        store.isAvailable(surah.number, config);

    Widget icon;
    if (isDownloading) {
      icon = SizedBox(
        width: 22,
        height: 22,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
                value: task!.progress, strokeWidth: 2.5, color: primary),
            Icon(Icons.stop_rounded, size: 12, color: primary),
          ],
        ),
      );
    } else {
      icon = Icon(
        isOffline ? Icons.download_done_rounded : Icons.download_outlined,
        size: 22,
        color: isOffline ? primary : iconColor,
      );
    }

    return Tooltip(
      message: isOffline
          ? 'Available offline'
          : 'Download (long-press for complete surah)',
      child: InkResponse(
        radius: 22,
        onTap: surah == null ? null : () => _showSheet(context),
        onLongPress: surah == null
            ? null
            : () {
                if (isDownloading) {
                  _showSheet(context);
                } else if (isOffline) {
                  Fluttertoast.showToast(
                      msg: "${surah.englishName} is already available offline");
                } else {
                  startSurahDownload(context, audioProvider);
                }
              },
        child: icon,
      ),
    );
  }

  void _showSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DownloadSheet(audioProvider: audioProvider),
    );
  }
}

class _DownloadSheet extends StatelessWidget {
  final AudioProvider audioProvider;
  const _DownloadSheet({required this.audioProvider});

  @override
  Widget build(BuildContext context) {
    final downloads = context.watch<SurahDownloadProvider>();
    final store = context.watch<OfflineStore>();
    final settings = context.watch<SettingsProvider>();
    final surah = _SurahDownloadButton._surahOf(audioProvider);
    final config = audioProvider.currentConfig ?? settings.playbackConfig;
    final primary = Theme.of(context).primaryColor;

    if (surah == null) return const SizedBox.shrink();

    final ayahNumber = audioProvider.currentAyahIndex + 1;
    final task = downloads.taskFor(surah.number);
    final package = store.findPackage(surah.number, config);

    Widget surahTrailing;
    String surahSubtitle;
    VoidCallback? surahTap;
    if (task != null && task.isActive) {
      final p = task.progress;
      surahSubtitle = p == null
          ? 'Preparing…'
          : 'Downloading… ${task.doneFiles}/${task.totalFiles} files (${(p * 100).toStringAsFixed(0)}%)';
      surahTrailing = TextButton(
        onPressed: () => downloads.cancel(surah.number),
        child: const Text('Cancel'),
      );
    } else if (package != null) {
      surahSubtitle =
          'Available offline · ${formatBytes(package.sizeBytes)}';
      surahTrailing = IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: 'Remove download',
        onPressed: () => store.deletePackage(package),
      );
    } else {
      surahSubtitle =
          '${surah.numberOfAyahs} verses · ${describeDownloadContents(config, settings)}';
      if (task?.status == DownloadStatus.failed && task?.error != null) {
        surahSubtitle = '${task!.error}\n$surahSubtitle';
      }
      surahTrailing = Icon(Icons.download_for_offline_rounded, color: primary);
      surahTap = () {
        _SurahDownloadButton.startSurahDownload(context, audioProvider);
      };
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Download',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
              const SizedBox(height: 4),
              Text('${surah.number}. ${surah.englishName}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
              Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.music_note_outlined),
                      title: Text('This Verse (Ayah $ayahNumber)'),
                      subtitle: const Text('Save the audio to Music/OneVerse'),
                      onTap: () {
                        Navigator.pop(context);
                        audioProvider.downloadCurrentVerse();
                      },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: Icon(
                          package != null
                              ? Icons.offline_pin_rounded
                              : Icons.library_music_outlined,
                          color: package != null ? primary : null),
                      title: const Text('Complete Surah (offline)'),
                      subtitle: Text(surahSubtitle),
                      isThreeLine: true,
                      trailing: surahTrailing,
                      onTap: surahTap,
                    ),
                    if (task != null && task.isActive)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: LinearProgressIndicator(value: task.progress),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Tip: long-press the download button to download the complete surah.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const DownloadsScreen()));
                    },
                    child: const Text('Manage'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown when the player can't load because there's no internet: lists the
/// surahs that can be played offline.
class _OfflineState extends StatelessWidget {
  final AudioProvider audioProvider;
  final Color textColor;
  const _OfflineState({required this.audioProvider, required this.textColor});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<OfflineStore>();
    final hasDownloads = store.packages.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 16),
        Icon(Icons.wifi_off_rounded, size: 72, color: textColor.withOpacity(0.5)),
        const SizedBox(height: 16),
        Text("You're Offline",
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 8),
        Text(
          hasDownloads
              ? "This surah isn't downloaded. These surahs are available offline — tap one to play:"
              : "Connect to the internet to listen, or download surahs while online to listen anytime.",
          textAlign: TextAlign.center,
          style: TextStyle(color: textColor.withOpacity(0.7)),
        ),
        const SizedBox(height: 16),
        if (hasDownloads) const OfflineLibraryList(allowDelete: false),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text("Retry"),
            onPressed: audioProvider.retryLastPlaylist,
          ),
        ),
      ],
    );
  }
}
