import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Saves single verses to the public Music/OneVerse folder so users can find
/// and share them outside the app. Offline surah downloads live in app
/// storage instead (see SurahDownloadProvider).
class DownloadManager {
  static const String _androidMusicDir = '/storage/emulated/0/Music';

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 60),
  ));

  /// Robust permission request that checks Android version
  Future<bool> _requestPermission() async {
    if (!Platform.isAndroid) return true;

    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdk = androidInfo.version.sdkInt;

    // Android 11+ lets apps create audio files in Music/ without a permission.
    // We still ask (it lets us see files from a previous install) but don't
    // block the download if the user says no.
    if (sdk >= 30) {
      if (sdk >= 33) {
        await Permission.audio.request();
      } else {
        await Permission.storage.request();
      }
      return true;
    }

    final status = await Permission.storage.request();
    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      Fluttertoast.showToast(
        msg: "Permission denied. Please enable storage access in app settings.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
      );
      await openAppSettings();
      return false;
    }

    Fluttertoast.showToast(msg: "Storage permission is required to save files.");
    return false;
  }

  static String _sanitize(String s) =>
      s.replaceAll(RegExp(r'[^\w\s-]'), '').trim();

  /// Path of a verse saved to Music/OneVerse/<language>/<reciter>/<surah>/.
  static String publicVersePath({
    required String language,
    required String reciterName,
    required String surahName,
    required int surahNumber,
    required int ayahNumber,
    String? baseDir,
  }) {
    final base = baseDir ?? _androidMusicDir;
    final surahFolder =
        "${surahNumber.toString().padLeft(3, '0')}_${_sanitize(surahName)}";
    return '$base/OneVerse/${language.toLowerCase()}/${_sanitize(reciterName)}/$surahFolder/$ayahNumber.mp3';
  }

  Future<String> _baseDir() async {
    if (Platform.isAndroid) return _androidMusicDir;
    return (await getApplicationDocumentsDirectory()).path;
  }

  /// Downloads (or copies, when [url] is a local file path) one verse.
  /// Returns the saved path, or null on failure.
  Future<String?> downloadAudio({
    required String url,
    required String language,
    required String reciterName,
    required String surahName,
    required int surahNumber,
    required int ayahNumber,
    bool showToasts = true,
  }) async {
    // 1. Check Permissions
    final hasPermission = await _requestPermission();
    if (!hasPermission) return null;

    try {
      final savePath = publicVersePath(
        language: language,
        reciterName: reciterName,
        surahName: surahName,
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        baseDir: await _baseDir(),
      );
      final file = File(savePath);

      if (await file.exists() && await file.length() > 0) {
        if (showToasts) {
          Fluttertoast.showToast(
            msg: "Already saved in Music/OneVerse",
            toastLength: Toast.LENGTH_SHORT,
          );
        }
        return savePath;
      }

      await file.parent.create(recursive: true);

      if (showToasts) {
        Fluttertoast.showToast(
          msg: "Downloading...",
          toastLength: Toast.LENGTH_SHORT,
        );
      }

      if (url.startsWith('/')) {
        await File(url).copy(savePath);
      } else {
        // Download to app cache first so a failed download never leaves a
        // broken mp3 behind (Music/ only accepts audio files, so the temp
        // file can't live there).
        final tmp = File(
            '${(await getTemporaryDirectory()).path}/verse_${DateTime.now().microsecondsSinceEpoch}.mp3');
        try {
          await _dio.download(url, tmp.path);
          await tmp.copy(savePath);
        } finally {
          if (await tmp.exists()) await tmp.delete();
        }
      }

      if (showToasts) {
        Fluttertoast.showToast(
          msg: "Saved to Music/OneVerse",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
      }
      return savePath;
    } catch (e) {
      debugPrint("Download Error: $e");
      if (showToasts) {
        Fluttertoast.showToast(
          msg: e is DioException
              ? "Download failed. Please check your internet connection."
              : "Download failed. Please try again.",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
      return null;
    }
  }
}
