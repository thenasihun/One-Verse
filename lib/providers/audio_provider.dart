import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:oneverse/models/ayah_model.dart';
import 'package:oneverse/models/surah_detail_model.dart';
import 'package:oneverse/providers/settings_provider.dart';
import 'package:oneverse/services/quran_api_service.dart';
import 'package:oneverse/utils/download_manager.dart';

class AudioProvider with ChangeNotifier {
  final QuranApiService _apiService = QuranApiService();
  final DownloadManager _downloadManager = DownloadManager();
  final AudioPlayer audioPlayer = AudioPlayer();

  SurahDetail? _currentAudioSurah;

  final Map<int, Ayah> _arabicCache = {};
  final Map<int, Ayah> _translationCache = {};

  Ayah? _currentDisplayArabicAyah;
  Ayah? _currentDisplayTranslationAyah;

  int _currentAyahIndex = 0;
  bool _isLoading = false;
  bool _isPlaylistMode = false;
  String? _currentlyPlayingUrl;
  String? _currentAudioEdition;
  String? _errorMessage;

  int? _lastAttemptedSurahNumber;
  String? _lastAttemptedAudioEdition;
  String? _lastAttemptedTranslationEdition;
  SettingsProvider? _settings;

  // Getters
  SurahDetail? get currentAudioSurah => _currentAudioSurah;
  Ayah? get currentDisplayArabicAyah => _currentDisplayArabicAyah;
  Ayah? get currentDisplayTranslationAyah => _currentDisplayTranslationAyah;
  int get currentAyahIndex => _currentAyahIndex;
  bool get isLoading => _isLoading;
  bool get isPlaylistMode => _isPlaylistMode;
  String? get errorMessage => _errorMessage;
  String? get currentlyPlayingUrl => _currentlyPlayingUrl;

  LoopMode _loopMode = LoopMode.off;
  LoopMode get loopMode => _loopMode;

  bool get isPlaying {
    return audioPlayer.playing &&
        audioPlayer.processingState != ProcessingState.completed;
  }

  AudioProvider() {
    audioPlayer.currentIndexStream.listen((index) {
      if (index != null && _isPlaylistMode && _currentAudioSurah != null) {
        _currentAyahIndex = index;

        if (index < _currentAudioSurah!.ayahs.length) {
          _currentlyPlayingUrl = _currentAudioSurah!.ayahs[index].audioUrl;
        }

        _updateDisplayTextForIndex(index);
        _preFetchText(index + 1);
        _preFetchText(index + 2);

        notifyListeners();
      }
    });

    audioPlayer.playerStateStream.listen((state) {
      notifyListeners();
    });
  }

  void update(SettingsProvider settings) {
    _settings = settings;
    if (_isPlaylistMode &&
        _currentAudioSurah != null &&
        settings.audioEdition != _currentAudioEdition) {
      loadSurahAndPlay(
        _currentAudioSurah!.number,
        settings.audioEdition,
        settings.translationLanguage,
        startingIndex: _currentAyahIndex,
        autoPlay: isPlaying,
      );
    }
  }

  void _clearError() {
    _errorMessage = null;
  }

  Future<void> retryLastPlaylist() async {
    if (_lastAttemptedSurahNumber != null &&
        _lastAttemptedAudioEdition != null &&
        _lastAttemptedTranslationEdition != null) {
      await loadSurahAndPlay(
        _lastAttemptedSurahNumber!,
        _lastAttemptedAudioEdition!,
        _lastAttemptedTranslationEdition!,
        autoPlay: true,
      );
    }
  }

  Future<void> loadSurahAndPlay(
      int surahNumber, String audioEdition, String translationEdition,
      {int startingIndex = 0, bool autoPlay = true}) async {
    if (isPlaying) await audioPlayer.stop();

    _clearError();
    _arabicCache.clear();
    _translationCache.clear();

    _isLoading = true;
    _isPlaylistMode = true;

    _lastAttemptedSurahNumber = surahNumber;
    _lastAttemptedAudioEdition = audioEdition;
    _lastAttemptedTranslationEdition = translationEdition;
    _currentAudioEdition = audioEdition;
    notifyListeners();

    try {
      _currentAudioSurah =
          await _apiService.getSurah(surahNumber, audioEdition);

      if (_currentAudioSurah == null || _currentAudioSurah!.ayahs.isEmpty) {
        throw Exception("Surah data is empty.");
      }

      final playlist = ConcatenatingAudioSource(
        useLazyPreparation: true,
        children: _currentAudioSurah!.ayahs.map((ayah) {
          return AudioSource.uri(Uri.parse(ayah.audioUrl!), tag: ayah);
        }).toList(),
      );

      await audioPlayer.setAudioSource(playlist, initialIndex: startingIndex);

      if (startingIndex < _currentAudioSurah!.ayahs.length) {
        _currentlyPlayingUrl =
            _currentAudioSurah!.ayahs[startingIndex].audioUrl;
      }

      _isLoading = false;
      notifyListeners();

      _updateDisplayTextForIndex(startingIndex);

      if (autoPlay) {
        audioPlayer.play();
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst("Exception: ", "");
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- NEW: Toggle Loop Function ---
  Future<void> toggleLoopMode() async {
    // Toggle between "Repeat One" and "Off"
    if (_loopMode == LoopMode.off) {
      _loopMode = LoopMode.one;
    } else {
      _loopMode = LoopMode.off;
    }

    // Set it in the player
    await audioPlayer.setLoopMode(_loopMode);
    notifyListeners();
  }

  // --- FIX: Auto-Retry Logic Added Here ---
  Future<void> _updateDisplayTextForIndex(int index) async {
    if (_currentAudioSurah == null ||
        index >= _currentAudioSurah!.ayahs.length ||
        _settings == null) return;

    if (_arabicCache.containsKey(index) &&
        _translationCache.containsKey(index)) {
      _currentDisplayArabicAyah = _arabicCache[index];
      _currentDisplayTranslationAyah = _translationCache[index];
      notifyListeners();
      return;
    }

    // Temporary clear
    _currentDisplayArabicAyah = null;
    _currentDisplayTranslationAyah = null;
    notifyListeners();

    final ayahNumberInSurah = _currentAudioSurah!.ayahs[index].numberInSurah;
    final surahNumber = _currentAudioSurah!.number;

    // Retry Loop for Text
    int attempts = 0;
    bool success = false;

    while (attempts < 3 && !success) {
      try {
        final responses = await Future.wait([
          _apiService.getAyah(surahNumber, ayahNumberInSurah, 'quran-uthmani'),
          _apiService.getAyah(
              surahNumber, ayahNumberInSurah, _settings!.translationLanguage),
        ]);

        _currentDisplayArabicAyah = responses[0];
        _currentDisplayTranslationAyah = responses[1];

        _arabicCache[index] = responses[0];
        _translationCache[index] = responses[1];

        success = true;
        notifyListeners();
      } catch (e) {
        attempts++;
        debugPrint("Text fetch attempt $attempts failed: $e");
        await Future.delayed(const Duration(seconds: 1)); // Wait before retry
      }
    }
  }

  Future<void> _preFetchText(int index) async {
    if (_currentAudioSurah == null ||
        index >= _currentAudioSurah!.ayahs.length ||
        _arabicCache.containsKey(index) ||
        _settings == null) {
      return;
    }

    final ayahNumberInSurah = _currentAudioSurah!.ayahs[index].numberInSurah;
    final surahNumber = _currentAudioSurah!.number;

    Future.wait([
      _apiService.getAyah(surahNumber, ayahNumberInSurah, 'quran-uthmani'),
      _apiService.getAyah(
          surahNumber, ayahNumberInSurah, _settings!.translationLanguage),
    ]).then((responses) {
      _arabicCache[index] = responses[0];
      _translationCache[index] = responses[1];
    }).catchError((_) {});
  }

  void playNext() {
    if (audioPlayer.hasNext) audioPlayer.seekToNext();
  }

  void playPrevious() {
    if (audioPlayer.hasPrevious) audioPlayer.seekToPrevious();
  }

  Future<void> playVerse(int index) async {
    if (_isPlaylistMode && _currentAudioSurah != null) {
      _currentDisplayArabicAyah = null;
      _currentDisplayTranslationAyah = null;
      notifyListeners();

      audioPlayer.seek(Duration.zero, index: index);
      audioPlayer.play();
    }
  }

  Future<void> playSingleVerse(String audioUrl) async {
    await audioPlayer.stop();
    _isPlaylistMode = false;
    _currentlyPlayingUrl = audioUrl;
    try {
      await audioPlayer.setUrl(audioUrl);
      audioPlayer.play();
    } catch (e) {
      debugPrint("Error setting single audio URL: $e");
    }
    notifyListeners();
  }

  Future<void> stop() async {
    await audioPlayer.stop();
    notifyListeners();
  }

  Future<void> downloadCurrentVerse() async {
    if (_currentAudioSurah == null) return;
    final ayah = _currentAudioSurah!.ayahs[_currentAyahIndex];
    if (ayah.audioUrl == null) return;

    await _downloadManager.downloadAudio(
      url: ayah.audioUrl!,
      language: ayah.edition?.language ?? 'ar',
      reciterName: ayah.edition?.englishName ?? 'Unknown',
      surahNumber: _currentAudioSurah!.number,
      surahName: _currentAudioSurah!.englishName,
      ayahNumber: ayah.numberInSurah,
    );
  }

  Future<void> downloadSurah() async {
    if (_currentAudioSurah == null) return;
    final reciterName =
        _currentAudioSurah!.ayahs.first.edition?.englishName ?? 'Unknown';
    final language = _currentAudioSurah!.ayahs.first.edition?.language ?? 'ar';
    final surahNumber = _currentAudioSurah!.number;
    final surahName = _currentAudioSurah!.englishName;

    for (final ayah in _currentAudioSurah!.ayahs) {
      if (ayah.audioUrl != null) {
        await _downloadManager.downloadAudio(
          url: ayah.audioUrl!,
          language: language,
          reciterName: reciterName,
          surahNumber: surahNumber,
          surahName: surahName,
          ayahNumber: ayah.numberInSurah,
        );
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }
}
