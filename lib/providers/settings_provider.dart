import 'dart:math';

import 'package:flutter/material.dart';
import 'package:oneverse/core/constants.dart';
import 'package:oneverse/models/edition_model.dart';
import 'package:oneverse/services/quran_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  late final SharedPreferences _prefs;
  final QuranApiService _apiService = QuranApiService();

  // --- Stored Preferences ---
  String _translationLanguage = AppConstants.defaultTranslation;
  String _audioEdition = AppConstants.defaultAudio;
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

  final List<String> availableAudioLanguages = const [
    'ar',
    'en',
    'ur',
    'fr',
    'zh',
    'ru'
  ];

  // --- Getters ---
  String get translationLanguage => _translationLanguage;
  String get audioEdition => _audioEdition;
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
    _isEditionsLoading = true;
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

        // Success! Stop loading and return.
        _isEditionsLoading = false;
        notifyListeners();
        return;
      } catch (e) {
        attempts++;
        debugPrint("Settings Load Attempt $attempts failed: $e");

        if (attempts >= maxAttempts) {
          // If we failed 3 times, THEN show the error message.
          _editionErrorMessage =
              "Failed to load editions. Please check your connection and try again.";
          _isEditionsLoading = false;
          notifyListeners();
        } else {
          // Wait 1 second before auto-retrying
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }
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
