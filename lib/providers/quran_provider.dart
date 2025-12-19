import 'dart:io';
import 'package:flutter/material.dart';
import 'package:oneverse/models/ayah_model.dart';
import 'package:oneverse/models/surah_model.dart';
import 'package:oneverse/services/quran_api_service.dart';

class QuranProvider with ChangeNotifier {
  final QuranApiService _apiService = QuranApiService();

  List<Surah> _surahs = [];
  bool _isSurahListLoading = false;
  String? _surahListErrorMessage;
  
  Ayah? _arabicAyah;
  Ayah? _translationAyah;
  Ayah? _audioAyah;
  bool _isAyahLoading = false;
  String? _ayahErrorMessage;

  int _selectedSurahNumber = 1;
  int _selectedAyahNumber = 1;

  List<Surah> get surahs => _surahs;
  bool get isSurahListLoading => _isSurahListLoading;
  String? get surahListErrorMessage => _surahListErrorMessage;
  
  Ayah? get arabicAyah => _arabicAyah;
  Ayah? get translationAyah => _translationAyah;
  String? get audioUrl => _audioAyah?.audioUrl;
  bool get isAyahLoading => _isAyahLoading;
  String? get ayahErrorMessage => _ayahErrorMessage;

  int get selectedSurahNumber => _selectedSurahNumber;
  int get selectedAyahNumber => _selectedAyahNumber;

  void selectSurah(int surahNumber) {
    _selectedSurahNumber = surahNumber;
    _selectedAyahNumber = 1;
    notifyListeners();
  }

  void selectAyah(int ayahNumber) {
    _selectedAyahNumber = ayahNumber;
    notifyListeners();
  }

  // --- Robust Fetch for Surah List ---
  Future<void> fetchSurahList() async {
    if (_surahs.isNotEmpty) return;
    
    _surahListErrorMessage = null;
    _isSurahListLoading = true;
    notifyListeners();

    int attempts = 0;
    while (attempts < 5) {
      try {
        _surahs = await _apiService.getSurahList();
        _isSurahListLoading = false;
        notifyListeners();
        return; 
      } catch (e) {
        attempts++;
        if (attempts >= 5) {
          if (e.toString().contains("SocketException") || e.toString().contains("Failed host")) {
             _surahListErrorMessage = "No Internet Connection.\nPlease connect to the internet and try again.";
          } else {
             _surahListErrorMessage = "Failed to load Surahs. Server might be busy.";
          }
          _isSurahListLoading = false;
          notifyListeners();
        } else {
          await Future.delayed(const Duration(milliseconds: 800));
        }
      }
    }
  }

  // --- FIX: Auto-Retry added for Ayah Text ---
  Future<void> fetchAyah(String translationEdition, String audioEdition) async {
    _ayahErrorMessage = null;
    _isAyahLoading = true;
    // Don't notifyLoading here if it's just a retry to prevent flickering
    notifyListeners();

    int attempts = 0;
    // Try up to 4 times (Increased persistence)
    while (attempts < 4) {
      try {
        final responses = await Future.wait([
          _apiService.getAyah(_selectedSurahNumber, _selectedAyahNumber, 'quran-uthmani'),
          _apiService.getAyah(_selectedSurahNumber, _selectedAyahNumber, translationEdition),
          _apiService.getAyah(_selectedSurahNumber, _selectedAyahNumber, audioEdition),
        ]);
        
        _arabicAyah = responses[0];
        _translationAyah = responses[1];
        _audioAyah = responses[2];
        
        _isAyahLoading = false;
        notifyListeners();
        return; // Success, exit loop
      } catch (e) {
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
}