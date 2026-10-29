import 'package:flutter/material.dart';
import 'package:oneverse/models/edition_model.dart';
import 'package:oneverse/models/selection_type.dart';
import 'package:oneverse/providers/settings_provider.dart';
import 'package:provider/provider.dart';

class EditionSelectionScreen extends StatelessWidget {
  final String languageCode;
  final SelectionType selectionType;

  const EditionSelectionScreen({
    Key? key,
    required this.languageCode,
    required this.selectionType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        final List<Edition> editions = switch (selectionType) {
          SelectionType.text => settings.allTextEditions,
          SelectionType.audio => settings.arabicAudioEditions,
          SelectionType.translationAudio => settings.translationAudioEditions,
        }
            .where((e) => e.language == languageCode)
            .toList();

        final String? groupValue = switch (selectionType) {
          SelectionType.text => settings.translationLanguage,
          SelectionType.audio => settings.audioEdition,
          SelectionType.translationAudio => settings.translationAudioEdition,
        };

        return Scaffold(
          appBar: AppBar(
            title: Text(switch (selectionType) {
              SelectionType.text => 'Select Translation',
              SelectionType.audio => 'Select Arabic Reciter',
              SelectionType.translationAudio => 'Select Translation Reciter',
            }),
          ),
          body: ListView.builder(
            itemCount: editions.length,
            itemBuilder: (context, index) {
              final edition = editions[index];
              return RadioListTile<String>(
                title: Text(edition.englishName),
                subtitle: Text(edition.name),
                value: edition.identifier,
                groupValue: groupValue,
                onChanged: (value) {
                  if (value == null) return;
                  switch (selectionType) {
                    case SelectionType.text:
                      settings.setTranslationLanguage(value);
                    case SelectionType.audio:
                      settings.setAudioEdition(value);
                    case SelectionType.translationAudio:
                      settings.setTranslationAudioEdition(value);
                      // Back to Settings, past the language list.
                      Navigator.of(context).pop();
                  }
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        );
      },
    );
  }
}
