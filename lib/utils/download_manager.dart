import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:device_info_plus/device_info_plus.dart';

class DownloadManager {
  final Dio _dio = Dio();

  /// Robust permission request that checks Android version
  Future<bool> _requestPermission() async {
    PermissionStatus status;

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      // Android 13 (SDK 33) and above require READ_MEDIA_AUDIO
      if (androidInfo.version.sdkInt >= 33) {
        status = await Permission.audio.request();
      } else {
        status = await Permission.storage.request();
      }
    } else {
      // iOS and others
      status = await Permission.storage.request();
    }

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

  /// Returns the visible public Download directory
  Directory _getDownloadDirectory() {
    if (Platform.isAndroid) {
      // Direct path to the user's public download folder
      return Directory('/storage/emulated/0/Music');
    }
    // Fallback for iOS (Documents directory)
    return Directory.systemTemp; 
  }

  Future<void> downloadAudio({
    required String url,
    required String language,
    required String reciterName,
    required String surahName,
    required int surahNumber,
    required int ayahNumber,
  }) async {
    // 1. Check Permissions
    final hasPermission = await _requestPermission();
    if (!hasPermission) return;

    try {
      // 2. Prepare the public download path
      final baseDir = _getDownloadDirectory();
      
      if (!await baseDir.exists()) {
        // Just in case the Download folder doesn't exist (rare)
        await baseDir.create(recursive: true);
      }

      // 3. Create structure: Downloads/OneVerse/Language/Reciter/Surah/
      final sanitizedLanguage = language.toLowerCase();
      // Remove special characters from names to avoid file system errors
      final sanitizedReciter = reciterName.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
      final sanitizedSurah = "${surahNumber.toString().padLeft(3, '0')}_${surahName.replaceAll(RegExp(r'[^\w\s-]'), '').trim()}";

      final targetDir = Directory('${baseDir.path}/OneVerse/$sanitizedLanguage/$sanitizedReciter/$sanitizedSurah');

      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      // 4. Check if file exists
      final savePath = '${targetDir.path}/$ayahNumber.mp3';
      final file = File(savePath);

      if (await file.exists()) {
        Fluttertoast.showToast(
          msg: "File already exists in Downloads/OneVerse",
          toastLength: Toast.LENGTH_SHORT,
        );
        return;
      }

      // 5. Download
      Fluttertoast.showToast(
        msg: "Downloading...",
        toastLength: Toast.LENGTH_SHORT,
      );

      await _dio.download(url, savePath);

      Fluttertoast.showToast(
        msg: "Saved to: Downloads/OneVerse/...",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );

    } catch (e) {
      debugPrint("Download Error: $e");
      Fluttertoast.showToast(
        msg: "Download failed: ${e.toString()}",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }
}