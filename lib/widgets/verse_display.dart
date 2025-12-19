import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oneverse/providers/quran_provider.dart';
import 'package:oneverse/providers/settings_provider.dart';
import 'package:provider/provider.dart';

class VerseDisplay extends StatelessWidget {
  final VoidCallback onRetry;
  const VerseDisplay({Key? key, required this.onRetry}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final quranProvider = Provider.of<QuranProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (quranProvider.isAyahLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (quranProvider.ayahErrorMessage != null && quranProvider.arabicAyah == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(quranProvider.ayahErrorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    if (quranProvider.arabicAyah == null) {
      return const Center(child: Text('Select a verse to display.'));
    }

    return Card(
      elevation: 2,
      color: isDarkMode ? Colors.grey[900] : const Color(0xFFF0FFF8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              quranProvider.arabicAyah!.arabicText,
              textAlign: TextAlign.center,
              style: GoogleFonts.getFont(
                settings.arabicFont,
                fontSize: settings.arabicFontSize,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 24),
            if (quranProvider.translationAyah?.translationText != null)
              Text(
                quranProvider.translationAyah!.translationText!,
                textAlign: TextAlign.center,
                style: GoogleFonts.getFont(
                  settings.translationFont,
                  fontSize: settings.translationFontSize,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }
}