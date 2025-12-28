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

    if (quranProvider.isAyahLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (quranProvider.ayahErrorMessage != null &&
        quranProvider.arabicAyah == null) {
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

    // --- REMOVED CARD COMPONENT HERE TO PREVENT NESTED BOXES ---
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      // Padding is now handled by the parent container in HomeScreen
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
              height: 1.8,
            ),
          ),
          const SizedBox(height: 18),
          if (quranProvider.translationAyah?.translationText != null)
            Text(
              quranProvider.translationAyah!.translationText!,
              textAlign: TextAlign.center,
              style: GoogleFonts.getFont(
                settings.translationFont,
                fontSize: settings.translationFontSize,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }
}
