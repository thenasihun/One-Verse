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

    double lineHeight =
        settings.lineheight(settings.arabicFontSize, settings.arabicFont);

    final cleanedArabic = quranProvider.arabicAyah?.arabicText != null
        ? cleanArabicForDisplay(quranProvider.arabicAyah!.arabicText)
        : null;

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
              settings.arabicFont != "UthmanicHafs"
                  ? quranProvider.arabicAyah!.arabicText
                  : cleanedArabic ?? 'Loading',
              textAlign: TextAlign.center,
              locale: const Locale('ar'),
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: settings.arabicFont,
                fontFamilyFallback: const [
                  'Amiri',
                  'ScheherazadeNew',
                  'UthmanicHafs',
                  'Lateef',
                  'NotoNaskhArabic'
                ],
                letterSpacing: 0,
                wordSpacing: 2,
                fontSize: settings.arabicFontSize,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                height: lineHeight,
              )),
          const SizedBox(height: 18),
          if (quranProvider.translationAyah?.translationText != null)
            Text(
              quranProvider.translationAyah!.translationText!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: settings.translationFont,
                fontSize: settings.translationFontSize,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                height: lineHeight,
                letterSpacing: 0,
              ),
            ),
        ],
      ),
    );
  }
}

String cleanArabicForDisplay(String s) {
  final buffer = StringBuffer();

  for (final r in s.runes) {
    // 1) Harakaat + superscript alif → keep
    if ((r >= 0x064B && r <= 0x0652) || r == 0x0670) {
      buffer.writeCharCode(r);
      continue;
    }

    // 2) Quranic decorative marks → REMOVE
    if (r >= 0x06D6 && r <= 0x06ED) {
      continue;
    }

    // 3) Everything else (Arabic letters, waqf letters, words) → keep
    buffer.writeCharCode(r);
  }

  return buffer.toString();
}
