

class Edition {
  final String identifier;
  final String language;
  final String name;
  final String englishName;
  final String? direction;

  Edition({
  required this.identifier,
  required this.language,
  required this.name,
  required this.englishName,
  this.direction,
  });

  factory Edition.fromJson(Map<String, dynamic> json) {
  return Edition(
  identifier: json['identifier'],
  language: json['language'],
  name: json['name'],
  englishName: json['englishName'],
  direction: json['direction'],
  );
  }
}