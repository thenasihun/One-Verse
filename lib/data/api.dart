import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Endpoints. All public, no keys.
class Endpoints {
  static const alquran = 'https://api.alquran.cloud/v1';
  static const quranCom = 'https://api.quran.com/api/v4';
  static const qdc = 'https://api.qurancdn.com/api/qdc';
  static const wordAudio = 'https://audio.qurancdn.com/';
  static const quranHub = 'https://api.quranhub.com/v1';
  static const baklarrrr = 'https://baklarrrr.github.io/quran-timings';
  static const luhaidan = 'https://its3li.github.io/quran-word-timings/data/muhammad-al-luhaidan/quran-com';
}

class NetworkException implements Exception {
  final String message;
  final bool offline;
  const NetworkException(this.message, {this.offline = false});
  @override
  String toString() => message;
}

/// Thin Dio wrapper with a real User-Agent (some CDNs block default ones),
/// timeouts and two retries for flaky mobile networks.
class Api {
  Api._();
  static final Api instance = Api._();

  final Dio dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 12),
    receiveTimeout: const Duration(seconds: 40),
    headers: kIsWeb ? null : {'User-Agent': 'OneVerse/2.0 (Flutter)'},
    responseType: ResponseType.json,
  ));

  Future<dynamic> getJson(String url, {Map<String, dynamic>? query}) async {
    DioException? last;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final r = await dio.get(url, queryParameters: query);
        if (r.statusCode == 200) return r.data;
        throw NetworkException('Server answered ${r.statusCode}');
      } on DioException catch (e) {
        last = e;
        final code = e.response?.statusCode;
        if (code != null && code >= 400 && code < 500 && code != 429) break;
        await Future.delayed(Duration(milliseconds: 400 * (attempt + 1) * (attempt + 1)));
      }
    }
    throw NetworkException(
      _isOffline(last) ? 'No internet connection' : 'Could not reach the server',
      offline: _isOffline(last),
    );
  }

  static bool _isOffline(DioException? e) =>
      e != null &&
      (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          (e.type == DioExceptionType.unknown && e.error != null));
}
