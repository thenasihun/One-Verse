import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:oneverse/utils/download_manager.dart';

class ShareService {
  static Future<void> shareVerse({
    required BuildContext context,
    required String arabic,
    required String translation,
    required String surahName,
    required int surahNum,
    required int ayahNum,
    required String audioUrl,
    required String language, // Needed for download
    required String reciterName, // Needed for download
  }) async {
    // 1. Construct the formatted text
    final String verseText = "$arabic\n\n"
        "$translation\n\n"
        "📖 Surah $surahName ($surahNum:$ayahNum)\n"
        "Shared via One Verse App";

    // 2. Construct the local file path (Logic matches DownloadManager)
    final sanitizedLanguage = language.toLowerCase();
    final sanitizedReciter =
        reciterName.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    final sanitizedSurah =
        "${surahNum.toString().padLeft(3, '0')}_${surahName.replaceAll(RegExp(r'[^\w\s-]'), '').trim()}";

    // Note: We are assuming the standard path.
    // Ideally, DownloadManager should have a static helper for this path, but this works for now.
    final String path =
        '/storage/emulated/0/Music/OneVerse/$sanitizedLanguage/$sanitizedReciter/$sanitizedSurah/$ayahNum.mp3';
    final bool fileExists = File(path).existsSync();

    // 3. Show Choice Dialog
    final String? action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Share Verse"),
        content: Text(fileExists
            ? "Would you like to share the text or the audio file?"
            : "Audio file is not downloaded. Would you like to download and share it?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, 'text'),
              child: const Text("Text Only")),
          ElevatedButton.icon(
            icon: const Icon(Icons.audiotrack),
            label: Text(fileExists ? "Share Audio" : "Download & Share"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, 'audio'),
          ),
        ],
      ),
    );

    if (action == null) return; // User clicked outside

    // 4. Handle Text Share
    if (action == 'text') {
      await Share.share(verseText);
      return;
    }

    // 5. Handle Audio Share
    if (action == 'audio') {
      if (fileExists) {
        // Share existing file
        await Share.shareXFiles(
          [XFile(path)],
          text: "Surah $surahName ($surahNum:$ayahNum)", // Caption only
        );
      } else {
        // DOWNLOAD THEN SHARE
        Fluttertoast.showToast(msg: "Downloading audio for sharing...");

        final downloadManager = DownloadManager();
        await downloadManager.downloadAudio(
            url: audioUrl,
            language: language,
            reciterName: reciterName,
            surahName: surahName,
            surahNumber: surahNum,
            ayahNumber: ayahNum);

        // Check again if download was successful
        if (File(path).existsSync()) {
          await Share.shareXFiles(
            [XFile(path)],
            text: "Surah $surahName ($surahNum:$ayahNum)",
          );
        } else {
          Fluttertoast.showToast(msg: "Download failed. Sharing text instead.");
          await Share.share(verseText);
        }
      }
    }
  }
}
