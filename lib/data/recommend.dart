import 'package:hijri/hijri_calendar.dart';

/// A suggestion for the Home screen: a whole surah, or a passage of it.
class Pick {
  final int surah, from, to; // to == 0: the whole surah
  final String kicker, title, why;
  final String kind; // special, friday, morning, day, evening, night, month, discover
  const Pick(this.surah, this.kicker, this.title, this.why, this.kind, {this.from = 1, this.to = 0});

  bool get passage => to != 0;
  String get key => '$surah:$from-$to';
}

/// Suggestions change with the time of day, the weekday, the Hijri month and
/// special days. Within a part of the day they stay the same; from day to
/// day they rotate through wide lists. No surah is shown twice, and surahs
/// heard in the last days give way to others in the "discover" slot.
class Recommender {
  const Recommender();

  // Parts of the day.
  static const _morning = [
    Pick(36, 'This morning', 'Ya-Sin', 'Begin the day with the heart of the Quran', 'morning'),
    Pick(55, 'This morning', 'Ar-Rahman', '"Which of the favours of your Lord would you deny?"', 'morning'),
    Pick(93, 'This morning', 'Ad-Duha', 'By the morning light: your Lord has not left you', 'morning'),
    Pick(48, 'This morning', 'Al-Fath', 'A surah of victory and calm', 'morning'),
    Pick(94, 'This morning', 'Ash-Sharh', 'With hardship comes ease', 'morning'),
    Pick(1, 'Morning adhkar', 'Al-Fatihah', 'The opening, for a good start', 'morning'),
    Pick(2, 'Morning adhkar', 'Ayat al-Kursi', 'Protection for the day', 'morning', from: 255, to: 255),
    Pick(112, 'Morning adhkar', 'Al-Ikhlas', 'With Al-Falaq and An-Nas, three times each morning', 'morning'),
    Pick(59, 'This morning', 'Al-Hashr, the last ayahs', 'The beautiful names of Allah', 'morning', from: 18, to: 24),
  ];
  static const _day = [
    Pick(31, 'This afternoon', 'Luqman', 'A father\'s wise advice to his son', 'day'),
    Pick(49, 'This afternoon', 'Al-Hujurat', 'Manners, brotherhood and good character', 'day'),
    Pick(12, 'This afternoon', 'Yusuf', 'The best of stories, of patience and trust', 'day'),
    Pick(19, 'This afternoon', 'Maryam', 'Mercy, family and the birth of Isa', 'day'),
    Pick(24, 'This afternoon', 'An-Nur', 'Allah is the light of the heavens and the earth', 'day'),
    Pick(57, 'This afternoon', 'Al-Hadid', 'The heart softened by the remembrance of Allah', 'day'),
    Pick(55, 'This afternoon', 'Ar-Rahman', 'Count the favours of your Lord', 'day'),
    Pick(25, 'This afternoon', 'Al-Furqan, the servants of the Merciful', 'How the servants of ar-Rahman live', 'day', from: 63, to: 77),
  ];
  static const _evening = [
    Pick(56, 'This evening', 'Al-Waqi\'ah', 'A surah many recite every evening', 'evening'),
    Pick(103, 'This evening', 'Al-Asr', 'By time: the whole of life in three ayahs', 'evening'),
    Pick(44, 'This evening', 'Ad-Dukhan', 'A surah of warning and mercy', 'evening'),
    Pick(78, 'This evening', 'An-Naba', 'The great news of the Last Day', 'evening'),
    Pick(87, 'This evening', 'Al-A\'la', 'Glorify the name of your Lord, the Most High', 'evening'),
    Pick(88, 'This evening', 'Al-Ghashiyah', 'Faces humbled, faces joyful', 'evening'),
    Pick(23, 'This evening', 'Al-Mu\'minun, the opening', 'The qualities of the successful believers', 'evening', from: 1, to: 11),
  ];
  static const _night = [
    Pick(67, 'Before sleep', 'Al-Mulk', 'Recited every night before sleeping', 'night'),
    Pick(32, 'Before sleep', 'As-Sajdah', 'With Al-Mulk, recited before sleep', 'night'),
    Pick(2, 'Before sleep', 'Ayat al-Kursi', 'Protection through the night', 'night', from: 255, to: 255),
    Pick(2, 'Before sleep', 'The last two ayahs of Al-Baqarah', 'Enough for the night', 'night', from: 285, to: 286),
    Pick(56, 'Tonight', 'Al-Waqi\'ah', 'A surah many recite at night', 'night'),
    Pick(17, 'Tonight', 'Al-Isra', 'The night journey', 'night'),
    Pick(39, 'Tonight', 'Az-Zumar', 'Do not despair of the mercy of Allah', 'night'),
    Pick(73, 'Tonight', 'Al-Muzzammil', 'Stand in the night and recite slowly', 'night'),
    Pick(3, 'Tonight', 'Ali \'Imran, the last ayahs', 'In the creation of the heavens and the earth', 'night', from: 190, to: 200),
    Pick(109, 'Before sleep', 'Al-Kafirun', 'Recited before sleeping', 'night'),
  ];

  // Strong surahs to discover, any time.
  static const _discover = [
    Pick(18, 'Discover', 'Al-Kahf', 'Four stories of trial and faith', 'discover'),
    Pick(20, 'Discover', 'Taha', 'Musa, and a Quran sent not to burden you', 'discover'),
    Pick(21, 'Discover', 'Al-Anbiya', 'The prophets and their duas', 'discover'),
    Pick(12, 'Discover', 'Yusuf', 'The best of stories', 'discover'),
    Pick(19, 'Discover', 'Maryam', 'Mercy upon mercy', 'discover'),
    Pick(49, 'Discover', 'Al-Hujurat', 'The surah of manners', 'discover'),
    Pick(31, 'Discover', 'Luqman', 'Wisdom for every age', 'discover'),
    Pick(50, 'Discover', 'Qaf', 'Closer to you than your jugular vein', 'discover'),
    Pick(81, 'Discover', 'At-Takwir', 'When the sun is folded up', 'discover'),
    Pick(82, 'Discover', 'Al-Infitar', 'What has deceived you about your Lord?', 'discover'),
    Pick(91, 'Discover', 'Ash-Shams', 'Successful is the one who purifies the soul', 'discover'),
    Pick(92, 'Discover', 'Al-Layl', 'By the night as it covers', 'discover'),
    Pick(99, 'Discover', 'Az-Zalzalah', 'An atom\'s weight of good', 'discover'),
    Pick(71, 'Discover', 'Nuh', 'Ask forgiveness of your Lord', 'discover'),
    Pick(76, 'Discover', 'Al-Insan', 'The reward of the righteous', 'discover'),
    Pick(89, 'Discover', 'Al-Fajr', 'O reassured soul, return to your Lord', 'discover'),
    Pick(60, 'Discover', 'Al-Mumtahanah', 'Loyalty, kindness and justice', 'discover'),
    Pick(61, 'Discover', 'As-Saff', 'Why do you say what you do not do?', 'discover'),
    Pick(47, 'Discover', 'Muhammad', 'Rivers of milk and honey', 'discover'),
    Pick(35, 'Discover', 'Fatir', 'You are the ones in need of Allah', 'discover'),
    Pick(29, 'Discover', 'Al-Ankabut', 'Do people think they will be left without trial?', 'discover'),
    Pick(14, 'Discover', 'Ibrahim', 'If you are grateful, I will give you more', 'discover'),
    Pick(13, 'Discover', 'Ar-Ra\'d', 'In the remembrance of Allah hearts find rest', 'discover'),
  ];

  // Friday.
  static const _fridayMorning = [
    Pick(18, 'Friday', 'Al-Kahf', 'Sunnah to recite on Jumu\'ah', 'friday'),
    Pick(32, 'Friday Fajr', 'As-Sajdah', 'Recited in Fajr on Friday', 'friday'),
    Pick(76, 'Friday Fajr', 'Al-Insan', 'Recited in Fajr on Friday', 'friday'),
  ];
  static const _fridayLater = [
    Pick(18, 'Friday', 'Al-Kahf', 'Before maghrib, the Friday sunnah', 'friday'),
    Pick(62, 'Friday', 'Al-Jumu\'ah', 'The surah of the Friday prayer', 'friday'),
    Pick(50, 'Friday', 'Qaf', 'Often recited in the Friday sermon', 'friday'),
    Pick(41, 'This Friday', 'Ha-Mim As-Sajdah (Fussilat)', 'A Ha-Mim surah to reflect on', 'friday'),
  ];

  /// Picks for the Hijri month or a special day.
  List<Pick> special(DateTime now) {
    final h = HijriCalendar.fromDate(now);
    final m = h.hMonth, d = h.hDay;
    return [
      if (m == 9 && d == 1) const Pick(2, 'Ramadan Mubarak', 'Al-Baqarah', 'A new month with the Quran', 'special'),
      if (m == 9 && d >= 21 && d.isOdd) const Pick(97, 'The last ten nights', 'Al-Qadr', 'Laylat al-Qadr may be tonight', 'special'),
      if (m == 9) const Pick(2, 'Ramadan', 'The ayahs of fasting', 'O you who believe, fasting is prescribed for you', 'month', from: 183, to: 187),
      if (m == 10 && d == 1) const Pick(87, 'Eid Mubarak', 'Al-A\'la', 'Recited in the Eid prayer', 'special'),
      if (m == 10 && d == 1) const Pick(88, 'Eid Mubarak', 'Al-Ghashiyah', 'Recited in the Eid prayer', 'special'),
      if (m == 12 && d <= 8) const Pick(89, 'The ten days of Dhul Hijjah', 'Al-Fajr', 'By the dawn and the ten nights', 'month'),
      if (m == 12 && d == 9) const Pick(22, 'The Day of Arafah', 'Al-Hajj', 'The best day for dua', 'special'),
      if (m == 12 && d == 10) const Pick(108, 'Eid al-Adha Mubarak', 'Al-Kawthar', 'For the day of sacrifice', 'special'),
      if (m == 12 && d > 10) const Pick(37, 'Dhul Hijjah', 'As-Saffat', 'Ibrahim and the sacrifice of his son', 'month', from: 99, to: 113),
      if (m == 1 && d == 10) const Pick(20, 'The Day of Ashura', 'Taha', 'Remember the story of Musa', 'special'),
      if (m == 1 && d <= 9) const Pick(9, 'A new Hijri year', 'The Hijrah', '"Do not grieve, Allah is with us"', 'month', from: 40, to: 40),
      if (m == 7) const Pick(17, 'Rajab', 'Al-Isra', 'The night journey of the Prophet ﷺ', 'month'),
      if (m == 8) const Pick(44, 'Sha\'ban', 'Ad-Dukhan', 'We sent it down on a blessed night', 'month'),
      if (m == 3) const Pick(33, 'Rabi\' al-Awwal', 'Blessings on the Prophet ﷺ', 'Allah and His angels send blessings on the Prophet', 'month', from: 56, to: 56),
      if (m == 3) const Pick(68, 'Rabi\' al-Awwal', 'Al-Qalam', 'And you are of a great character', 'month', from: 1, to: 4),
    ];
  }

  /// Up to [count] suggestions for [now]. [recent] are surahs heard in the
  /// last days; they are passed over in the discover slot.
  List<Pick> picksFor(DateTime now, {Set<int> recent = const {}, int count = 4}) {
    final hour = now.hour;
    final slot = hour >= 20 || hour < 4
        ? 3
        : hour < 11
            ? 0
            : hour < 16
                ? 1
                : 2;
    final seed = now.year * 10000 + now.month * 100 + now.day;
    final pool = [_morning, _day, _evening, _night][slot];
    final out = <Pick>[];
    final used = <String>{};
    final surahs = <int>{};
    void add(Pick p) {
      if (out.length >= count || used.contains(p.key)) return;
      // The same surah twice only when the passages differ (Ayat al-Kursi and
      // the end of Al-Baqarah).
      if (!p.passage && surahs.contains(p.surah)) return;
      used.add(p.key);
      surahs.add(p.surah);
      out.add(p);
    }

    // 1. Today's special day or the month.
    for (final p in special(now)) {
      add(p);
    }
    // 2. Friday, and Thursday night for Al-Kahf.
    if (now.weekday == DateTime.friday) {
      final f = hour < 11 ? _fridayMorning : _fridayLater;
      add(f[0]);
      add(f[1 + seed % (f.length - 1)]);
    } else if (now.weekday == DateTime.thursday && hour >= 17) {
      add(const Pick(18, 'Tonight', 'Al-Kahf for Friday', 'Friday begins at maghrib', 'friday'));
    }
    // 3. Two from the part of the day, rotating by date.
    final start = seed % pool.length;
    for (var i = 0; i < pool.length && out.length < count - 1; i++) {
      add(pool[(start + i * 3) % pool.length]);
      if (out.where((p) => p.kind == pool.first.kind).length >= 2) break;
    }
    // 4. One to discover, not heard lately.
    final fresh = _discover.where((p) => !recent.contains(p.surah)).toList();
    final list = fresh.isEmpty ? _discover : fresh;
    for (var i = 0; i < list.length && out.length < count; i++) {
      add(list[(seed + i) % list.length]);
      if (out.any((p) => p.kind == 'discover')) break;
    }
    // Fill up from the day's pool if anything is missing.
    for (var i = 0; i < pool.length && out.length < count; i++) {
      add(pool[(start + i) % pool.length]);
    }
    return out;
  }

  /// Verse of the day: a wide list of well-known ayahs, one a day, with a
  /// fitting one on Fridays, in Ramadan and on special days.
  (int, int) verseOfTheDay(DateTime now) {
    final h = HijriCalendar.fromDate(now);
    if (h.hMonth == 9 && h.hDay == 1) return (2, 185);
    if (h.hMonth == 9 && h.hDay >= 21 && h.hDay.isOdd) return (97, 3);
    if (h.hMonth == 12 && h.hDay == 9) return (5, 3);
    if (h.hMonth == 1 && h.hDay == 10) return (20, 77);
    if (now.weekday == DateTime.friday && now.day % 2 == 0) return (62, 9);
    final day = DateTime(now.year, now.month, now.day).difference(DateTime(2024)).inDays;
    return verses[day % verses.length];
  }

  static const verses = [
    (2, 255), (2, 286), (2, 152), (2, 153), (2, 186), (2, 201), (3, 8), (3, 26), (3, 139), (3, 173),
    (3, 190), (3, 191), (7, 23), (9, 51), (9, 129), (11, 6), (12, 86), (12, 87), (13, 11), (13, 28),
    (14, 7), (16, 97), (17, 23), (17, 24), (17, 80), (18, 10), (18, 46), (20, 25), (20, 114), (21, 87),
    (23, 118), (24, 35), (25, 74), (28, 24), (29, 69), (33, 41), (35, 15), (39, 53), (40, 60), (49, 13),
    (50, 16), (51, 56), (55, 13), (57, 4), (59, 22), (64, 11), (65, 2), (65, 3), (67, 2), (93, 5),
    (94, 5), (94, 6), (103, 3), (112, 1), (2, 45), (8, 46), (17, 82), (20, 46), (39, 10), (42, 19),
  ];
}
