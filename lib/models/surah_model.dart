class Surah {
  final int number;
  final String name;
  final String englishName;
  final int numberOfAyahs;
  final String revelationType;

  const Surah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.numberOfAyahs,
    required this.revelationType,
  });

  factory Surah.fromJson(Map<String, dynamic> json) => Surah(
        number: json['number'] as int,
        name: json['name'] as String,
        englishName: json['englishName'] as String,
        numberOfAyahs: json['numberOfAyahs'] as int,
        revelationType: json['revelationType'] as String,
      );
}
