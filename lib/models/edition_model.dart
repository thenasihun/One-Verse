class Edition {
  final String identifier;
  final String language;
  final String name;
  final String englishName;
  final String? direction;
  final String? format;
  // 'versebyverse', 'surahbysurah', 'translation', 'quran', ...
  final String? type;

  Edition({
    required this.identifier,
    required this.language,
    required this.name,
    required this.englishName,
    this.direction,
    this.format,
    this.type,
  });

  /// Audio editions of type 'surahbysurah' have no per-verse audio, so they
  /// can't be used for verse-by-verse playback.
  bool get hasVerseAudio => type != 'surahbysurah';

  factory Edition.fromJson(Map<String, dynamic> json) {
    return Edition(
      identifier: json['identifier'],
      language: json['language'],
      name: json['name'],
      englishName: json['englishName'],
      direction: json['direction'],
      format: json['format'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() => {
        'identifier': identifier,
        'language': language,
        'name': name,
        'englishName': englishName,
        'direction': direction,
        'format': format,
        'type': type,
      };
}
