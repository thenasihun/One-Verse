import 'package:flutter/material.dart';
import 'package:oneverse/models/selection_type.dart';
import 'package:oneverse/providers/settings_provider.dart';
import 'package:oneverse/screens/settings/edition_selection_screen.dart';
import 'package:provider/provider.dart';

class LanguageSelectionScreen extends StatelessWidget {
  final SelectionType selectionType;

  const LanguageSelectionScreen({Key? key, required this.selectionType})
      : super(key: key);

  static const Map<String, String> _languageNames = {
    "ar": "Arabic",
    "am": "Amharic",
    "az": "Azerbaijani",
    "ber": "Berber (Amazigh)",
    "bn": "Bengali",
    "cs": "Czech",
    "ce": "Chechen",
    "de": "German",
    "dv": "Divehi (Maldivian)",
    "en": "English",
    "es": "Spanish",
    "fa": "Persian (Farsi)",
    "fr": "French",
    "ha": "Hausa",
    "hi": "Hindi",
    "id": "Indonesian",
    "it": "Italian",
    "ja": "Japanese",
    "ko": "Korean",
    "ku": "Kurdish",
    "ml": "Malayalam",
    "nl": "Dutch",
    "no": "Norwegian",
    "pl": "Polish",
    "ps": "Pashto",
    "pt": "Portuguese",
    "ro": "Romanian",
    "ru": "Russian",
    "sd": "Sindhi",
    "so": "Somali",
    "sq": "Albanian",
    "sv": "Swedish",
    "sw": "Swahili",
    "ta": "Tamil",
    "tg": "Tajik",
    "th": "Thai",
    "tr": "Turkish",
    "tt": "Tatar",
    "ug": "Uyghur",
    "ur": "Urdu",
    "uz": "Uzbek",
    "zh": "Chinese",
  };

  String _getLanguageName(String code) =>
      _languageNames[code] ?? code.toUpperCase();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final languages = selectionType == SelectionType.text
        ? settings.availableTextLanguages
        : settings.availableAudioLanguages;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Language'),
      ),
      body: ListView.builder(
        itemCount: languages.length,
        itemBuilder: (context, index) {
          final langCode = languages[index];
          return ListTile(
            title: Text(_getLanguageName(langCode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EditionSelectionScreen(
                    languageCode: langCode,
                    selectionType: selectionType,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
