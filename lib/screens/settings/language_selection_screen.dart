import 'package:flutter/material.dart';
import 'package:oneverse/models/selection_type.dart';
import 'package:oneverse/providers/settings_provider.dart';
import 'package:oneverse/screens/settings/edition_selection_screen.dart';
import 'package:provider/provider.dart';

class LanguageSelectionScreen extends StatelessWidget {
  final SelectionType selectionType;

  const LanguageSelectionScreen({Key? key, required this.selectionType}) : super(key: key);

  static const Map<String, String> _languageNames = {
    'en': 'English',
    'ur': 'Urdu',
    'ar': 'Arabic',
    'fr': 'French',
    'zh': 'Chinese',
    'ru': 'Russian',
  };

  String _getLanguageName(String code) => _languageNames[code] ?? code.toUpperCase();

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