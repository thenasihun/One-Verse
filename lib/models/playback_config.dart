enum PlaybackMode { arabic, arabicWithTranslation, translation }

extension PlaybackModeX on PlaybackMode {
  String get label => switch (this) {
        PlaybackMode.arabic => 'Arabic',
        PlaybackMode.arabicWithTranslation => 'Arabic + Translation',
        PlaybackMode.translation => 'Translation',
      };

  static PlaybackMode fromName(String? name) => PlaybackMode.values
      .firstWhere((m) => m.name == name, orElse: () => PlaybackMode.arabic);
}

/// Everything needed to build a playlist: which reciters to play, in what
/// order, and which texts to show.
class PlaybackConfig {
  static const String arabicTextEdition = 'quran-uthmani';

  final String audioEdition;
  final String? translationAudioEdition;
  final String textEdition;
  final PlaybackMode _mode;

  const PlaybackConfig({
    required this.audioEdition,
    required this.translationAudioEdition,
    required this.textEdition,
    required PlaybackMode mode,
  }) : _mode = mode;

  /// The mode that can actually be honoured: translation modes fall back to
  /// Arabic when no translation reciter is selected.
  PlaybackMode get mode =>
      translationAudioEdition == null ? PlaybackMode.arabic : _mode;

  bool get needsArabicAudio => mode != PlaybackMode.translation;
  bool get needsTranslationAudio => mode != PlaybackMode.arabic;
  bool get isPaired => mode == PlaybackMode.arabicWithTranslation;

  /// Audio editions in playback order.
  List<String> get audioEditions => [
        if (needsArabicAudio) audioEdition,
        if (needsTranslationAudio) translationAudioEdition!,
      ];

  /// Every edition (text + audio) needed to play and display a surah.
  List<String> get requiredEditions =>
      {arabicTextEdition, textEdition, ...audioEditions}.toList();

  String get key =>
      '${mode.name}|${needsArabicAudio ? audioEdition : ''}|${needsTranslationAudio ? translationAudioEdition : ''}|$textEdition';

}
