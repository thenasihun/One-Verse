import 'package:dio/dio.dart';
import 'package:oneverse/core/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:oneverse/models/ayah_model.dart';
import 'package:oneverse/models/edition_model.dart';
import 'package:oneverse/models/surah_detail_model.dart';
import 'package:oneverse/models/surah_model.dart';
import 'package:oneverse/services/offline_store.dart';

/// Service class to handle all network requests to the Quran Cloud API.
class QuranApiService {
  final Dio _dio;

  QuranApiService()
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
        ));

  /// Fetches the metadata for all 114 Surahs.
  Future<List<Surah>> getSurahList() async {
    try {
      final response = await _dio.get('${AppConstants.baseUrl}/meta');
      if (response.statusCode == 200) {
        final surahsJson = response.data['data']['surahs']['references'] as List;
        return surahsJson.map((json) => Surah.fromJson(json)).toList();
      }
      throw Exception('Failed to load Surah list');
    } catch (_) {
      throw Exception('Failed to connect to the server');
    }
  }

  /// Fetches the data for a single Ayah from a specific edition.
  Future<Ayah> getAyah(int surahNumber, int ayahNumber, String edition) async {
    try {
      final response = await _dio.get('${AppConstants.ayahUrl}/$surahNumber:$ayahNumber/$edition');
      if (response.statusCode == 200) {
        return Ayah.fromJson(response.data['data']);
      }
      throw Exception('Failed to load Ayah');
    } catch (e) {
      if (isNetworkError(e)) throw const OfflineException();
      throw Exception('Failed to load Ayah details');
    }
  }

  /// Fetches the complete data for a Surah, including all its verses.
  Future<SurahDetail> getSurah(int surahNumber, String edition) async {
    final endpoint = '${AppConstants.baseUrl}/surah/$surahNumber/$edition';
    debugPrint("Requesting Playlist URL: $endpoint");
    try {
      final response = await _dio.get(endpoint);
      if (response.statusCode == 200) {
        if (response.data == null || response.data['data'] == null) {
          throw Exception('API returned null data for this edition. Please try another reciter.');
        }
        return SurahDetail.fromJson(response.data['data']);
      } else {
        throw Exception('Failed to load Surah (Status code: ${response.statusCode})');
      }
    } on DioException catch (e) {
      debugPrint("--- DioError on getSurah ---");
      debugPrint("Type: ${e.type} | Message: ${e.message}");
      throw Exception('Failed to connect to the server.');
    } catch (e) {
      debugPrint("--- Generic Error on getSurah ---: $e");
      throw Exception(e.toString());
    }
  }

  /// Fetches one surah in several editions with a single request. Returns
  /// the raw API surah objects keyed by edition identifier.
  Future<Map<String, Map<String, dynamic>>> getSurahEditionsRaw(
      int surahNumber, List<String> editions) async {
    final endpoint =
        '${AppConstants.baseUrl}/surah/$surahNumber/editions/${editions.join(',')}';
    try {
      final response = await _dio.get(endpoint);
      final data = response.data is Map ? response.data['data'] : null;
      if (response.statusCode != 200 || data is! List) {
        throw Exception(
            'This reciter or translation is not available. Please choose another.');
      }
      final result = <String, Map<String, dynamic>>{};
      for (int i = 0; i < data.length; i++) {
        final surah = Map<String, dynamic>.from(data[i]);
        final id = surah['edition']?['identifier'] ??
            (i < editions.length ? editions[i] : null);
        if (id != null) result[id] = surah;
      }
      return result;
    } on DioException catch (e) {
      debugPrint("DioError on getSurahEditions: ${e.type} | ${e.message}");
      if (isNetworkError(e)) throw const OfflineException();
      throw Exception('Failed to load Surah. Please try again.');
    }
  }

  static bool isNetworkError(Object e) =>
      e is DioException &&
      (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          (e.type == DioExceptionType.unknown && e.error is Exception));

  /// Fetches the list of available language codes for text editions.
  Future<List<String>> getAvailableLanguages() async {
    try {
      final response = await _dio.get('${AppConstants.baseUrl}/edition/language');
      if (response.statusCode == 200) {
        return List<String>.from(response.data['data']);
      }
      throw Exception('Failed to load language list');
    } catch (_) {
      throw Exception('Failed to connect to the server');
    }
  }

  /// Fetches the master list of all available text editions (translations).
  Future<List<Edition>> getAllTextEditions() async {
    try {
      final response = await _dio.get('${AppConstants.baseUrl}/edition');
      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data
            .where((e) => e['format'] == 'text')
            .map((json) => Edition.fromJson(json))
            .toList();
      }
      throw Exception('Failed to load editions');
    } catch (_) {
      throw Exception('Failed to connect to the server');
    }
  }

  /// Fetches all available audio editions.
  Future<List<Edition>> getAudioEditions() async {
    try {
      final response = await _dio.get(AppConstants.audioEditionsUrl);
      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data.map((json) => Edition.fromJson(json)).toList();
      }
      throw Exception('Failed to load audio editions');
    } catch (_) {
      throw Exception('Failed to connect to the server');
    }
  }
}
