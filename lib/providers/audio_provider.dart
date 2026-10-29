import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:just_audio/just_audio.dart';
import 'package:oneverse/core/constants.dart';
import 'package:oneverse/models/ayah_model.dart';
import 'package:oneverse/models/playback_config.dart';
import 'package:oneverse/models/surah_detail_model.dart';
import 'package:oneverse/providers/settings_provider.dart';
import 'package:oneverse/services/offline_store.dart';
import 'package:oneverse/services/quran_api_service.dart';
import 'package:oneverse/utils/download_manager.dart';

class AudioProvider with ChangeNotifier {
  final QuranApiService _apiService = QuranApiService();
  final OfflineStore _store = OfflineStore.instance;
  final DownloadManager _downloadManager = DownloadManager();
  final AudioPlayer audioPlayer = AudioPlayer();

  // Timeline of the playlist: the Arabic reciter, or the translation reciter
  // in translation-only mode.
  SurahDetail? _currentAudioSurah;
  // Translation reciter played after each Arabic verse in paired mode.
  SurahDetail? _pairedAudioSurah;
  List<Ayah> _arabicTexts = const [];
  List<Ayah> _translationTexts = const [];

  PlaybackConfig? _config;
  int _segmentsPerAyah = 1;
  bool _isTranslationSegment = false;
  bool _isOfflinePlayback = false;
  bool _isOfflineError = false;

  int _currentAyahIndex = 0;
  int? _lastIndex;
  bool _userNavigating = false;
  bool _isLoading = false;
  bool _isPlaylistMode = false;
  String? _currentlyPlayingUrl;
  String? _errorMessage;
  int _loadToken = 0;

  int? _lastAttemptedSurahNumber;
  int _lastAttemptedStartIndex = 0;
  SettingsProvider? _settings;

  // Getters
  SurahDetail? get currentAudioSurah => _currentAudioSurah;
  Ayah? get currentDisplayArabicAyah => _currentAyahIndex < _arabicTexts.length
      ? _arabicTexts[_currentAyahIndex]
      : null;
  Ayah? get currentDisplayTranslationAyah =>
      _currentAyahIndex < _translationTexts.length
          ? _translationTexts[_currentAyahIndex]
          : null;
  int get currentAyahIndex => _currentAyahIndex;
  bool get isLoading => _isLoading;
  bool get isPlaylistMode => _isPlaylistMode;
  String? get errorMessage => _errorMessage;
  String? get currentlyPlayingUrl => _currentlyPlayingUrl;
  PlaybackConfig? get currentConfig => _config;

  /// True while the translation part of a verse is playing (paired mode).
  bool get isTranslationSegment => _isTranslationSegment;

  /// True when the whole playlist plays from downloaded files.
  bool get isOfflinePlayback => _isOfflinePlayback;

  /// True when the last load failed because there was no internet.
  bool get isOfflineError => _isOfflineError;
  int? get lastAttemptedSurahNumber => _lastAttemptedSurahNumber;

  LoopMode _loopMode = LoopMode.off;
  LoopMode get loopMode => _loopMode;

  bool get isPlaying {
    return audioPlayer.playing &&
        audioPlayer.processingState != ProcessingState.completed;
  }

  /// Whether the player already has (or is loading) the playlist for [surah].
  bool hasPlaylistFor(int surah) =>
      _isPlaylistMode &&
      (_currentAudioSurah?.number == surah ||
          (_isLoading && _lastAttemptedSurahNumber == surah));

  AudioProvider() {
    audioPlayer.currentIndexStream.listen(_onIndexChanged);

    audioPlayer.playerStateStream.listen((state) {
      // In paired mode "repeat verse" is handled manually; the last verse has
      // no next item to trigger it, so restart it when the playlist ends.
      if (state.processingState == ProcessingState.completed &&
          _isPlaylistMode &&
          _segmentsPerAyah > 1 &&
          _loopMode == LoopMode.one) {
        _seekToAyah(_currentAyahIndex, play: true);
      }
      notifyListeners();
    });

    audioPlayer.playbackEventStream.listen((_) {}, onError: (Object e, _) {
      debugPrint("Playback error: $e");
      Fluttertoast.showToast(
        msg: _isOfflinePlayback
            ? "Could not play this verse."
            : "Playback failed. Check your internet or download this surah for offline listening.",
        toastLength: Toast.LENGTH_LONG,
      );
    });
  }

  void _onIndexChanged(int? index) {
    if (index == null || !_isPlaylistMode || _currentAudioSurah == null) return;

    final ayahIndex = index ~/ _segmentsPerAyah;

    // Repeat verse in paired mode: when playback naturally moves on to the
    // next verse, jump back to the start of the current one.
    if (_segmentsPerAyah > 1 &&
        _loopMode == LoopMode.one &&
        !_userNavigating &&
        _lastIndex != null &&
        index == _lastIndex! + 1 &&
        ayahIndex != _currentAyahIndex) {
      _lastIndex = null;
      // Seeking synchronously inside the transition event is ignored by the
      // platform player, so defer it.
      final target = _currentAyahIndex * _segmentsPerAyah;
      Future.delayed(const Duration(milliseconds: 50),
          () => audioPlayer.seek(Duration.zero, index: target));
      return;
    }

    _userNavigating = false;
    _lastIndex = index;
    _currentAyahIndex = ayahIndex.clamp(0, _currentAudioSurah!.ayahs.length - 1);
    _isTranslationSegment = _segmentsPerAyah > 1 && index % _segmentsPerAyah == 1;

    final source = audioPlayer.sequence;
    if (source != null && index < source.length) {
      final tag = source[index].tag;
      if (tag is _SegmentTag) _currentlyPlayingUrl = tag.source;
    }
    notifyListeners();
  }

  void update(SettingsProvider settings) {
    _settings = settings;
    final config = settings.playbackConfig;
    if (_isPlaylistMode &&
        _lastAttemptedSurahNumber != null &&
        _config != null &&
        config.key != _config!.key) {
      loadSurahAndPlay(
        _lastAttemptedSurahNumber!,
        startingIndex: _currentAyahIndex,
        autoPlay: isPlaying,
      );
    }
  }

  Future<void> retryLastPlaylist() async {
    if (_lastAttemptedSurahNumber != null) {
      await loadSurahAndPlay(
        _lastAttemptedSurahNumber!,
        startingIndex: _lastAttemptedStartIndex,
        autoPlay: true,
      );
    }
  }

  /// Loads [surahNumber] as a playlist using [config] (defaults to the current
  /// settings). Downloaded content is used first; anything missing is
  /// fetched from the API.
  Future<void> loadSurahAndPlay(int surahNumber,
      {int startingIndex = 0,
      bool autoPlay = true,
      PlaybackConfig? config}) async {
    final cfg = config ??
        _settings?.playbackConfig ??
        const PlaybackConfig(
          audioEdition: AppConstants.defaultAudio,
          translationAudioEdition: null,
          textEdition: AppConstants.defaultTranslation,
          mode: PlaybackMode.arabic,
        );
    final token = ++_loadToken;

    // Set synchronously so a settings update triggered by this load is a no-op.
    _config = cfg;
    _lastAttemptedSurahNumber = surahNumber;
    _lastAttemptedStartIndex = startingIndex;
    _errorMessage = null;
    _isOfflineError = false;
    _isLoading = true;
    _isPlaylistMode = true;
    notifyListeners();

    try {
      await audioPlayer.stop();
      await _store.init();

      final surahs = await _loadEditions(surahNumber, cfg.requiredEditions);
      if (token != _loadToken) return;

      final primaryEdition =
          cfg.needsArabicAudio ? cfg.audioEdition : cfg.translationAudioEdition!;
      final primary = surahs[primaryEdition]!;
      final paired = cfg.isPaired ? surahs[cfg.translationAudioEdition!] : null;

      if (primary.ayahs.isEmpty) throw Exception("Surah data is empty.");
      if (primary.ayahs.any((a) => a.audioUrl == null) ||
          (paired != null && paired.ayahs.any((a) => a.audioUrl == null))) {
        throw Exception(
            "This reciter doesn't support verse-by-verse playback. Please choose another reciter.");
      }

      final segments = paired != null ? 2 : 1;
      final children = <AudioSource>[];
      final sources = <String>[];
      bool allLocal = true;
      for (int i = 0; i < primary.ayahs.length; i++) {
        final parts = [
          (primaryEdition, primary.ayahs[i]),
          if (paired != null && i < paired.ayahs.length)
            (cfg.translationAudioEdition!, paired.ayahs[i]),
        ];
        // Keep both segments per verse even if the translation is short,
        // so index math stays simple.
        if (paired != null && parts.length < 2) parts.add(parts.first);
        for (final (edition, ayah) in parts) {
          final file =
              _store.audioFile(edition, surahNumber, ayah.numberInSurah);
          if (await file.exists()) {
            sources.add(file.path);
            children.add(AudioSource.file(file.path,
                tag: _SegmentTag(ayah, file.path)));
          } else {
            allLocal = false;
            sources.add(ayah.audioUrl!);
            children.add(AudioSource.uri(Uri.parse(ayah.audioUrl!),
                tag: _SegmentTag(ayah, ayah.audioUrl!)));
          }
        }
      }
      if (token != _loadToken) return;

      if (!allLocal && !await hasInternet()) {
        throw const OfflineException(
            "You're offline and this surah's audio isn't downloaded.");
      }
      if (token != _loadToken) return;

      final start = startingIndex.clamp(0, primary.ayahs.length - 1);
      _currentAudioSurah = primary;
      _pairedAudioSurah = paired;
      _arabicTexts = surahs[PlaybackConfig.arabicTextEdition]!.ayahs;
      _translationTexts = surahs[cfg.textEdition]!.ayahs;
      _segmentsPerAyah = segments;
      _isOfflinePlayback = allLocal;
      _currentAyahIndex = start;
      _isTranslationSegment = false;
      _lastIndex = null;

      await audioPlayer.setAudioSource(
        ConcatenatingAudioSource(useLazyPreparation: true, children: children),
        initialIndex: start * segments,
      );
      if (token != _loadToken) return;
      await _applyLoopMode();

      _currentlyPlayingUrl = sources[start * segments];
      _isLoading = false;
      notifyListeners();

      if (autoPlay) {
        audioPlayer.play();
      }
    } catch (e) {
      if (token != _loadToken) return;
      _isOfflineError =
          e is OfflineException || QuranApiService.isNetworkError(e);
      _errorMessage = e.toString().replaceFirst("Exception: ", "");
      _currentAudioSurah = null;
      _pairedAudioSurah = null;
      _arabicTexts = const [];
      _translationTexts = const [];
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Plays a downloaded surah with the editions it was downloaded with, and
  /// makes those the current settings so everything stays in sync.
  Future<void> playOfflinePackage(OfflinePackage package,
      {int startingIndex = 0}) async {
    final config =
        package.toConfig(_settings?.audioEdition ?? AppConstants.defaultAudio);
    final future = loadSurahAndPlay(package.surahNumber,
        startingIndex: startingIndex, autoPlay: true, config: config);
    _settings?.applyPlaybackConfig(config);
    await future;
  }

  /// Loads [editions] of a surah: local copies first, one API request for
  /// whatever is missing (which is then cached for next time).
  Future<Map<String, SurahDetail>> _loadEditions(
      int surahNumber, List<String> editions) async {
    final result = <String, SurahDetail>{};
    final missing = <String>[];
    for (final e in editions) {
      final json = await _store.loadSurahJson(e, surahNumber);
      if (json != null) {
        try {
          result[e] = SurahDetail.fromJson(json);
          continue;
        } catch (_) {}
      }
      missing.add(e);
    }
    if (missing.isEmpty) return result;

    final fetched = await _apiService.getSurahEditionsRaw(surahNumber, missing);
    for (final e in missing) {
      final json = fetched[e];
      if (json == null) {
        throw Exception(
            'Edition "$e" is not available. Please choose another in Settings.');
      }
      result[e] = SurahDetail.fromJson(json);
      _store.saveSurahJson(e, surahNumber, json).catchError((err) {
        debugPrint("Could not cache $e/$surahNumber: $err");
      });
    }
    return result;
  }

  Future<void> _applyLoopMode() async {
    LoopMode mode = _loopMode;
    if (_loopMode == LoopMode.one) {
      if (_isPlaylistMode && _segmentsPerAyah > 1) {
        mode = LoopMode.off; // handled manually in _onIndexChanged
      } else if (!_isPlaylistMode && (audioPlayer.sequence?.length ?? 1) > 1) {
        mode = LoopMode.all; // single verse made of Arabic + translation
      }
    }
    await audioPlayer.setLoopMode(mode);
  }

  Future<void> toggleLoopMode() async {
    // Toggle between "Repeat One" and "Off"
    _loopMode = _loopMode == LoopMode.off ? LoopMode.one : LoopMode.off;
    await _applyLoopMode();
    notifyListeners();
  }

  void _seekToAyah(int ayahIndex, {bool play = false}) {
    _userNavigating = true;
    audioPlayer.seek(Duration.zero, index: ayahIndex * _segmentsPerAyah);
    if (play) audioPlayer.play();
  }

  void playNext() {
    if (!_isPlaylistMode || _currentAudioSurah == null) return;
    if (_currentAyahIndex + 1 < _currentAudioSurah!.ayahs.length) {
      _seekToAyah(_currentAyahIndex + 1);
    }
  }

  void playPrevious() {
    if (!_isPlaylistMode || _currentAudioSurah == null) return;
    // Like most players: go to the start of this verse first.
    if (audioPlayer.position > const Duration(seconds: 3) ||
        _isTranslationSegment ||
        _currentAyahIndex == 0) {
      _seekToAyah(_currentAyahIndex);
    } else {
      _seekToAyah(_currentAyahIndex - 1);
    }
  }

  Future<void> playVerse(int index) async {
    if (_isPlaylistMode && _currentAudioSurah != null) {
      _currentAyahIndex = index.clamp(0, _currentAudioSurah!.ayahs.length - 1);
      notifyListeners();
      _seekToAyah(_currentAyahIndex, play: true);
    }
  }

  /// Plays one verse outside the playlist. [sources] are URLs or local file
  /// paths played in order (e.g. Arabic then translation).
  Future<void> playSingleVerse(List<String> sources) async {
    if (sources.isEmpty) return;
    _loadToken++; // abandon any playlist that's still loading
    await audioPlayer.stop();
    _isPlaylistMode = false;
    _isLoading = false;
    _currentlyPlayingUrl = sources.first;
    notifyListeners();
    try {
      await audioPlayer.setAudioSource(ConcatenatingAudioSource(
        children: sources
            .map((s) => s.startsWith('/')
                ? AudioSource.file(s, tag: s)
                : AudioSource.uri(Uri.parse(s), tag: s))
            .toList(),
      ));
      await _applyLoopMode();
      audioPlayer.play();
    } catch (e) {
      debugPrint("Error setting single audio source: $e");
      Fluttertoast.showToast(msg: "Could not play this verse.");
    }
    notifyListeners();
  }

  Future<void> stop() async {
    await audioPlayer.stop();
    notifyListeners();
  }

  /// Saves the current verse (each reciter that plays it) to Music/OneVerse.
  Future<void> downloadCurrentVerse() async {
    final surah = _currentAudioSurah;
    final config = _config;
    if (surah == null || config == null || _settings == null) return;

    final parts = <(String, Ayah)>[
      (
        config.needsArabicAudio ? config.audioEdition : config.translationAudioEdition!,
        surah.ayahs[_currentAyahIndex]
      ),
      if (_pairedAudioSurah != null &&
          _currentAyahIndex < _pairedAudioSurah!.ayahs.length)
        (config.translationAudioEdition!, _pairedAudioSurah!.ayahs[_currentAyahIndex]),
    ];

    int saved = 0;
    for (final (edition, ayah) in parts) {
      final local = _store.audioFile(edition, surah.number, ayah.numberInSurah);
      final source = await local.exists() ? local.path : ayah.audioUrl;
      if (source == null) continue;
      final path = await _downloadManager.downloadAudio(
        url: source,
        language: _settings!.findEdition(edition)?.language ??
            edition.split('.').first,
        reciterName: _settings!.editionName(edition),
        surahNumber: surah.number,
        surahName: surah.englishName,
        ayahNumber: ayah.numberInSurah,
        showToasts: parts.length == 1,
      );
      if (path != null) saved++;
    }
    if (parts.length > 1) {
      Fluttertoast.showToast(
        msg: saved == parts.length
            ? "Verse saved to Music/OneVerse (Arabic + translation)"
            : "Some files could not be saved. Please try again.",
      );
    }
  }

  /// Local path of the currently playing segment if it's downloaded.
  String? get currentLocalFile {
    final url = _currentlyPlayingUrl;
    if (url == null) return null;
    return url.startsWith('/') && File(url).existsSync() ? url : null;
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }
}

class _SegmentTag {
  final Ayah ayah;
  final String source;
  const _SegmentTag(this.ayah, this.source);
}
