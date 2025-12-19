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
        final bool isText = selectionType == SelectionType.text;
        final List<Edition> editions = (isText
                ? settings.allTextEditions
                : settings.allAudioEditions)
            .where((e) => e.language == languageCode)
            .toList();

        final String? groupValue =
            isText ? settings.translationLanguage : settings.audioEdition;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Select Edition'),
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
                  if (isText) {
                    settings.setTranslationLanguage(value);
                  } else {
                    settings.setAudioEdition(value);
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
