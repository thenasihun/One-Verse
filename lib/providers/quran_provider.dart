import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oneverse/models/ayah_model.dart';
import 'package:oneverse/models/playback_config.dart';
import 'package:oneverse/models/surah_model.dart';
import 'package:oneverse/services/offline_store.dart';
import 'package:oneverse/services/quran_api_service.dart';

/// One reciter's audio for the selected verse.
class VerseAudio {
  final String edition;
  final String source; // URL or local file path
  const VerseAudio(this.edition, this.source);
}

class QuranProvider with ChangeNotifier {
  final QuranApiService _apiService = QuranApiService();
  final OfflineStore _store = OfflineStore.instance;

  List<Surah> _surahs = [];
  bool _isSurahListLoading = false;
  String? _surahListErrorMessage;

  Ayah? _arabicAyah;
  Ayah? _translationAyah;
  List<VerseAudio> _verseAudio = const [];
  bool _isAyahLoading = false;
  String? _ayahErrorMessage;
  bool _isAyahOfflineError = false;
  int _fetchToken = 0;

  int _selectedSurahNumber = 1;
  int _selectedAyahNumber = 1;

  List<Surah> get surahs => _surahs;
  bool get isSurahListLoading => _isSurahListLoading;
  String? get surahListErrorMessage => _surahListErrorMessage;

  Ayah? get arabicAyah => _arabicAyah;
  Ayah? get translationAyah => _translationAyah;

  /// Audio for the selected verse in playback order.
  List<VerseAudio> get verseAudio => _verseAudio;
  String? get audioUrl => _verseAudio.isEmpty ? null : _verseAudio.first.source;
  bool get isAyahLoading => _isAyahLoading;
  String? get ayahErrorMessage => _ayahErrorMessage;
  bool get isAyahOfflineError => _isAyahOfflineError;

  int get selectedSurahNumber => _selectedSurahNumber;
  int get selectedAyahNumber => _selectedAyahNumber;

  Surah? get selectedSurah {
    for (final s in _surahs) {
      if (s.number == _selectedSurahNumber) return s;
    }
    return null;
  }

  void selectSurah(int surahNumber) {
    _selectedSurahNumber = surahNumber;
    _selectedAyahNumber = 1;
    notifyListeners();
  }

  void selectAyah(int ayahNumber) {
    _selectedAyahNumber = ayahNumber;
    notifyListeners();
  }

  /// The surah list never changes, so it ships with the app and works offline.
  Future<void> fetchSurahList() async {
    if (_surahs.isNotEmpty) return;

    _surahListErrorMessage = null;
    _isSurahListLoading = true;
    notifyListeners();

    try {
      final raw = await rootBundle.loadString('assets/data/surahs.json');
      _surahs = (jsonDecode(raw) as List)
          .map((json) => Surah.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      debugPrint("Bundled surah list failed, using API: $e");
      try {
        _surahs = await _apiService.getSurahList();
      } catch (_) {
        _surahListErrorMessage =
            "No Internet Connection.\nPlease connect to the internet and try again.";
      }
    }
    _isSurahListLoading = false;
    notifyListeners();
  }

  /// Loads the selected verse. Downloaded/cached surah data is used first;
  /// whatever is missing comes from the API (with retries).
  Future<void> fetchAyah(PlaybackConfig config) async {
    final token = ++_fetchToken;
    final surah = _selectedSurahNumber;
    final ayahNum = _selectedAyahNumber;

    _ayahErrorMessage = null;
    _isAyahOfflineError = false;
    _isAyahLoading = true;
    notifyListeners();

    int attempts = 0;
    while (attempts < 4) {
      try {
        await _store.init();
        // Local first.
        final texts = <String, Ayah?>{};
        for (final edition in config.requiredEditions) {
          texts[edition] = await _localAyah(edition, surah, ayahNum);
        }
        // Then the network for anything missing.
        final missing = texts.keys.where((e) => texts[e] == null).toList();
        if (missing.isNotEmpty) {
          final fetched = await Future.wait(
              missing.map((e) => _apiService.getAyah(surah, ayahNum, e)));
          for (int i = 0; i < missing.length; i++) {
            texts[missing[i]] = fetched[i];
          }
        }
        if (token != _fetchToken) return;

        final audio = <VerseAudio>[];
        for (final edition in config.audioEditions) {
          final file = _store.audioFile(edition, surah, ayahNum);
          final url = texts[edition]?.audioUrl;
          if (await file.exists()) {
            audio.add(VerseAudio(edition, file.path));
          } else if (url != null) {
            audio.add(VerseAudio(edition, url));
          }
        }
        if (token != _fetchToken) return;

        _arabicAyah = texts[PlaybackConfig.arabicTextEdition];
        _translationAyah = texts[config.textEdition];
        _verseAudio = audio;
        _isAyahLoading = false;
        notifyListeners();
        return; // Success, exit loop
      } on OfflineException {
        if (token != _fetchToken) return;
        // No point retrying without internet.
        _arabicAyah = null;
        _translationAyah = null;
        _verseAudio = const [];
        _isAyahOfflineError = true;
        _ayahErrorMessage =
            "You're offline.\nThis verse isn't downloaded yet.";
        _isAyahLoading = false;
        notifyListeners();
        return;
      } catch (e) {
        if (token != _fetchToken) return;
        attempts++;
        if (attempts >= 4) {
          // Only show error after 4 failed attempts
          _ayahErrorMessage = "Failed to load verse. Check internet.";
          _isAyahLoading = false;
          notifyListeners();
        } else {
          // Wait 1 second before silent retry
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }
  }

  Future<Ayah?> _localAyah(String edition, int surah, int ayahNum) async {
    final json = await _store.loadSurahJson(edition, surah);
    final ayahs = json?['ayahs'];
    if (ayahs is! List) return null;
    for (final a in ayahs) {
      if (a['numberInSurah'] == ayahNum) {
        return Ayah.fromJson(Map<String, dynamic>.from(a));
      }
    }
    return null;
  }
}
