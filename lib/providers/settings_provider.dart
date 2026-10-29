import 'package:flutter/material.dart';
import 'package:oneverse/core/constants.dart';
import 'package:oneverse/models/edition_model.dart';
import 'package:oneverse/models/playback_config.dart';
import 'package:oneverse/services/offline_store.dart';
import 'package:oneverse/services/quran_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  late final SharedPreferences _prefs;
  final QuranApiService _apiService = QuranApiService();

  // --- Stored Preferences ---
  String _translationLanguage = AppConstants.defaultTranslation;
  String _audioEdition = AppConstants.defaultAudio;
  String? _translationAudioEdition;
  PlaybackMode _playbackMode = PlaybackMode.arabic;
  ThemeMode _themeMode = ThemeMode.system;
  double _arabicFontSize = AppConstants.defaultArabicFontSize;
  double _translationFontSize = AppConstants.defaultTranslationFontSize;
  String _arabicFont = 'UthmanicHafs';
  String _translationFont = 'NotoSans';

  // --- Dynamic Data for Edition Selection ---
  List<String> _availableTextLanguages = [];
  List<Edition> _allTextEditions = [];
  List<Edition> _allAudioEditions = [];
  bool _isEditionsLoading = false;
  String? _editionErrorMessage;

  // --- Getters ---
  String get translationLanguage => _translationLanguage;
  String get audioEdition => _audioEdition;
  String? get translationAudioEdition => _translationAudioEdition;
  PlaybackMode get playbackMode => _playbackMode;

  PlaybackConfig get playbackConfig => PlaybackConfig(
        audioEdition: _audioEdition,
        translationAudioEdition: _translationAudioEdition,
        textEdition: _translationLanguage,
        mode: _playbackMode,
      );
  ThemeMode get themeMode => _themeMode;
  double get arabicFontSize => _arabicFontSize;
  double get translationFontSize => _translationFontSize;
  String get arabicFont => _arabicFont;
  String get translationFont => _translationFont;

  List<String> get availableTextLanguages => _availableTextLanguages;
  List<Edition> get allTextEditions => _allTextEditions;
  List<Edition> get allAudioEditions => _allAudioEditions;
  bool get isEditionsLoading => _isEditionsLoading;
  String? get editionErrorMessage => _editionErrorMessage;

  /// Arabic reciters that have per-verse audio.
  List<Edition> get arabicAudioEditions => _allAudioEditions
      .where((e) => e.language == 'ar' && e.hasVerseAudio)
      .toList();

  /// Translation recitations that have per-verse audio.
  List<Edition> get translationAudioEditions => _allAudioEditions
      .where((e) => e.language != 'ar' && e.hasVerseAudio)
      .toList();

  List<String> get translationAudioLanguages =>
      translationAudioEditions.map((e) => e.language).toSet().toList();

  Edition? findEdition(String? identifier) {
    if (identifier == null) return null;
    for (final e in [..._allAudioEditions, ..._allTextEditions]) {
      if (e.identifier == identifier) return e;
    }
    return null;
  }

  /// Human readable name for an edition, falling back to names saved with
  /// offline downloads, then the identifier itself.
  String editionName(String? identifier) {
    if (identifier == null) return 'None';
    return findEdition(identifier)?.englishName ??
        OfflineStore.instance.editionName(identifier) ??
        identifier;
  }

  double getLineHeight(double fontSize, String fontFamily) {
    // check for Urdu fonts
    bool isUrduFont =
        fontFamily == 'NotoUrdu' || fontFamily == 'JameelNooriNastaleeq';

    bool isArabicFont = fontFamily == 'Amiri' ||
        fontFamily == 'UthmanicHafs' ||
        fontFamily == 'ScheherazadeNew' ||
        fontFamily == 'Kitab';

    // Adjust line height based on font size for better readability
    if (isUrduFont) {
      if (fontSize <= 18) {
        return 2.6;
      } else if (fontSize <= 20) {
        return 2.4;
      } else if (fontSize <= 24) {
        return 2.2;
      } else {
        return 2.0;
      }
    }

    if (isArabicFont) {
      if (fontSize <= 22) {
        return 2.6;
      } else if (fontSize <= 28) {
        return 2.4;
      } else if (fontSize <= 32) {
        return 2.2;
      } else {
        return 2.0;
      }
    }

    return 1.5;
  }

  // --- Initialization ---
  Future<void> loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _translationLanguage =
        _prefs.getString('translation') ?? AppConstants.defaultTranslation;
    _audioEdition = _prefs.getString('audio') ?? AppConstants.defaultAudio;
    _translationAudioEdition = _prefs.getString('translationAudio');
    _playbackMode = PlaybackModeX.fromName(_prefs.getString('playbackMode'));

    // Older versions let a translation recitation be the main reciter. Move it
    // to the translation slot so the Arabic reciter is always Arabic.
    if (!_audioEdition.startsWith('ar.')) {
      _translationAudioEdition = _audioEdition;
      _playbackMode = PlaybackMode.translation;
      _audioEdition = AppConstants.defaultAudio;
      _prefs.setString('audio', _audioEdition);
      _prefs.setString('translationAudio', _translationAudioEdition!);
      _prefs.setString('playbackMode', _playbackMode.name);
    }
    _arabicFontSize =
        _prefs.getDouble('arabicSize') ?? AppConstants.defaultArabicFontSize;
    _translationFontSize = _prefs.getDouble('translationSize') ??
        AppConstants.defaultTranslationFontSize;
    _arabicFont =
        _prefs.getString('arabicFont') ?? AppConstants.defaultArabicFont;
    _translationFont = _prefs.getString('translationFont') ??
        AppConstants.defaultTranslationFont;

    final theme = _prefs.getString('theme') ?? 'system';
    _themeMode = switch (theme) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    notifyListeners();
  }

  // --- Edition Fetching (With Smart Auto-Retry) ---
  Future<void> fetchAvailableEditions() async {
    // If data is already loaded, don't waste time fetching again
    if (_allTextEditions.isNotEmpty && _allAudioEditions.isNotEmpty) return;

    // Prevent double-loading
    if (_isEditionsLoading) return;

    _clearError();
    await _loadCachedEditions();
    final hasCache = _allTextEditions.isNotEmpty && _allAudioEditions.isNotEmpty;
    // With a cache the settings screen stays usable while we refresh quietly.
    _isEditionsLoading = !hasCache;
    notifyListeners();

    int attempts = 0;
    const maxAttempts = 3; // Will try 3 times automatically

    while (attempts < maxAttempts) {
      try {
        final responses = await Future.wait([
          _apiService.getAvailableLanguages(),
          _apiService.getAllTextEditions(),
          _apiService.getAudioEditions(),
        ]);

        _availableTextLanguages = responses[0] as List<String>;
        _allTextEditions = responses[1] as List<Edition>;
        _allAudioEditions = responses[2] as List<Edition>;
        _saveEditionsCache();

        // Success! Stop loading and return.
        _isEditionsLoading = false;
        notifyListeners();
        return;
      } catch (e) {
        attempts++;
        debugPrint("Settings Load Attempt $attempts failed: $e");

        if (attempts >= maxAttempts) {
          // If we failed 3 times, THEN show the error message.
          if (!hasCache) {
            _editionErrorMessage =
                "Failed to load editions. Please check your connection and try again.";
          }
          _isEditionsLoading = false;
          notifyListeners();
        } else {
          // Wait 1 second before auto-retrying
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }
  }

  Future<void> _loadCachedEditions() async {
    try {
      final cached = await OfflineStore.instance.readCache('editions');
      if (cached is! Map) return;
      _availableTextLanguages = List<String>.from(cached['languages'] ?? []);
      _allTextEditions = (cached['text'] as List)
          .map((e) => Edition.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _allAudioEditions = (cached['audio'] as List)
          .map((e) => Edition.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint("Editions cache unreadable: $e");
    }
  }

  void _saveEditionsCache() {
    OfflineStore.instance.writeCache('editions', {
      'languages': _availableTextLanguages,
      'text': _allTextEditions.map((e) => e.toJson()).toList(),
      'audio': _allAudioEditions.map((e) => e.toJson()).toList(),
    }).catchError((e) => debugPrint("Editions cache write failed: $e"));
  }

  void _clearError() {
    if (_editionErrorMessage != null) {
      _editionErrorMessage = null;
    }
  }

  // --- Setters ---
  void setTranslationLanguage(String value) {
    _translationLanguage = value;
    _prefs.setString('translation', value);

    if (value.toLowerCase().contains('ur.')) {
      _translationFont = 'NotoUrdu'; // Aapka Urdu Font jo pubspec mein hai
      _prefs.setString('translationFont', 'NotoUrdu');
    }

    // 2. Check for Arabic (If translation is in Arabic text)
    if (value.toLowerCase().contains('ar.')) {
      _translationFont =
          'UthmanicHafs'; // Arabic translation ke liye Amiri ya Uthmanic
      _prefs.setString('translationFont', 'UthmanicHafs');
    }

    notifyListeners();
  }

  void setAudioEdition(String value) {
    _audioEdition = value;
    _prefs.setString('audio', value);
    notifyListeners();
  }

  /// Selecting a translation reciter turns on Arabic + Translation playback
  /// if only Arabic was playing before. Passing null turns translation off.
  void setTranslationAudioEdition(String? value) {
    _translationAudioEdition = value;
    if (value == null) {
      _prefs.remove('translationAudio');
      _playbackMode = PlaybackMode.arabic;
    } else {
      _prefs.setString('translationAudio', value);
      if (_playbackMode == PlaybackMode.arabic) {
        _playbackMode = PlaybackMode.arabicWithTranslation;
      }
    }
    _prefs.setString('playbackMode', _playbackMode.name);
    notifyListeners();
  }

  void setPlaybackMode(PlaybackMode value) {
    _playbackMode = value;
    _prefs.setString('playbackMode', value.name);
    notifyListeners();
  }

  /// Applies a whole config at once (e.g. when playing an offline download),
  /// notifying listeners only once.
  void applyPlaybackConfig(PlaybackConfig config) {
    _audioEdition = config.audioEdition;
    _playbackMode = config.mode;
    _prefs.setString('audio', _audioEdition);
    // Keep the user's translation reciter when the download has none.
    if (config.translationAudioEdition != null) {
      _translationAudioEdition = config.translationAudioEdition;
      _prefs.setString('translationAudio', _translationAudioEdition!);
    }
    _prefs.setString('playbackMode', _playbackMode.name);
    if (config.textEdition != _translationLanguage) {
      setTranslationLanguage(config.textEdition); // notifies
      return;
    }
    notifyListeners();
  }

  void setThemeMode(ThemeMode value) {
    _themeMode = value;
    final theme = switch (value) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    };
    _prefs.setString('theme', theme);
    notifyListeners();
  }

  void setArabicFontSize(double value) {
    _arabicFontSize = value;
    _prefs.setDouble('arabicSize', value);
    notifyListeners();
  }

  void setTranslationFontSize(double value) {
    _translationFontSize = value;
    _prefs.setDouble('translationSize', value);
    notifyListeners();
  }

  void setArabicFont(String value) {
    _arabicFont = value;
    _prefs.setString('arabicFont', value);
    notifyListeners();
  }

  void setTranslationFont(String value) {
    _translationFont = value;
    _prefs.setString('translationFont', value);
    notifyListeners();
  }
}
