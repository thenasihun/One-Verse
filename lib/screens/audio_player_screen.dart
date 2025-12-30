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
    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);
    bool needsSync = false;
    int targetSurah = 1;
    int targetAyah = 0;

    if (quranProvider.surahs.isNotEmpty) {
      if (audioProvider.currentAudioSurah == null ||
          audioProvider.currentAudioSurah!.number !=
              quranProvider.selectedSurahNumber) {
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

  void _showSurahSelection(BuildContext context) {
    final quranProvider = Provider.of<QuranProvider>(context, listen: false);
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);

    if (quranProvider.surahs.isEmpty) {
      quranProvider.fetchSurahList();
      return;
    }

    QuranSelectionHelper.showSurahSheet(
        context: context,
        surahs: quranProvider.surahs,
        onSelect: (surah) {
          audioProvider.loadSurahAndPlay(
              surah.number,
              settingsProvider.audioEdition,
              settingsProvider.translationLanguage,
              startingIndex: 0,
              autoPlay: true);
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
    return Center(
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
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text("Retry"),
            onPressed: audioProvider.retryLastPlaylist,
          ),
        ],
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

    String direction = 'ltr';
    try {
      final edition = settings.allTextEditions.firstWhere(
          (e) => e.identifier == settings.translationLanguage,
          orElse: () => settings.allTextEditions.isNotEmpty
              ? settings.allTextEditions.first
              : null as dynamic);
      if (edition != null) {
        direction = edition.direction ?? 'ltr';
      }
    } catch (e) {}
    final bool isRtl = direction == 'rtl';

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
                    const Divider(height: 24),
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
                  final reciter = settings.allAudioEditions.firstWhere(
                      (e) => e.identifier == settings.audioEdition,
                      orElse: () => settings.allAudioEditions.first);

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
                  );
                },
                tooltip: "Share",
              ),
              const SizedBox(width: 12),
              buildMiniBtn(
                icon: Icons.download_outlined,
                onTap: audioProvider.downloadCurrentVerse,
                tooltip: "Download",
              ),
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
