import 'package:oneverse/models/edition_model.dart';
import 'package:oneverse/models/surah_model.dart';

class Ayah {
  final int number;
  final String? audioUrl;
  final String arabicText;
  final String? translationText;
  final int numberInSurah;
  final int juz;
  final int page;
  final Edition? edition;
  final Surah? surah;

  Ayah({
    required this.number,
    this.audioUrl,
    required this.arabicText,
    this.translationText,
    required this.numberInSurah,
    required this.juz,
    required this.page,
    this.edition,
    this.surah,
  });

  factory Ayah.fromJson(Map<String, dynamic> json) {
    return Ayah(
      number: json['number'],
      audioUrl: json['audio'],
      arabicText: json['text'],
      translationText: json['text'],
      numberInSurah: json['numberInSurah'],
      juz: json['juz'],
      page: json['page'],
      edition: json['edition'] != null ? Edition.fromJson(json['edition']) : null,
      surah: json['surah'] != null ? Surah.fromJson(json['surah']) : null,
    );
  }

  factory Ayah.fromSurahJson(Map<String, dynamic> json, Edition surahEdition, Surah surahInfo) {
    return Ayah(
      number: json['number'],
      audioUrl: json['audio'],
      arabicText: json['text'],
      translationText: json['text'],
      numberInSurah: json['numberInSurah'],
      juz: json['juz'],
      page: json['page'],
      edition: surahEdition,
      surah: surahInfo,
    );
  }
}