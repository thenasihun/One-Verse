import 'package:oneverse/models/ayah_model.dart';
import 'package:oneverse/models/edition_model.dart';
import 'package:oneverse/models/surah_model.dart';

class SurahDetail {
  final int number;
  final String name;
  final String englishName;
  final int numberOfAyahs;
  final List<Ayah> ayahs;
  final Edition edition;
  final String revelationType;

  SurahDetail({
    required this.number,
    required this.name,
    required this.englishName,
    required this.numberOfAyahs,
    required this.ayahs,
    required this.edition,
    required this.revelationType,
  });

  factory SurahDetail.fromJson(Map<String, dynamic> json) {
    final Edition surahEdition = Edition.fromJson(json['edition']);
    final Surah surahInfo = Surah(
      number: json['number'],
      name: json['name'],
      englishName: json['englishName'],
      numberOfAyahs: json['numberOfAyahs'],
      revelationType: json['revelationType'],
    );

    var ayahsJson = json['ayahs'] as List;
    List<Ayah> ayahsList = ayahsJson
        .map((i) => Ayah.fromSurahJson(i, surahEdition, surahInfo))
        .toList();

    return SurahDetail(
      number: json['number'],
      name: json['name'],
      englishName: json['englishName'],
      numberOfAyahs: json['numberOfAyahs'],
      ayahs: ayahsList,
      edition: surahEdition,
      revelationType: json['revelationType'],
    );
  }
}
