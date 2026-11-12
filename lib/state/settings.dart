import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/catalog.dart';
import '../data/models.dart';
import '../data/tafsir.dart';

/// A saved ayah, with an optional note.
class Bookmark {
  final int surah, ayah;
  final String note;
  final DateTime at;
  const Bookmark(this.surah, this.ayah, {this.note = '', required this.at});

  Bookmark withNote(String n) => Bookmark(surah, ayah, note: n, at: at);

  Map<String, dynamic> toJson() => {'s': surah, 'a': ayah, 'n': note, 't': at.millisecondsSinceEpoch};
  factory Bookmark.fromJson(Map<String, dynamic> j) =>
      Bookmark(j['s'] as int, j['a'] as int, note: (j['n'] as String?) ?? '', at: DateTime.fromMillisecondsSinceEpoch(j['t'] as int));
}

/// Everything the user chooses, persisted immediately so a closed app comes
/// back exactly as it was left.
class Settings extends ChangeNotifier {
  late SharedPreferences _p;

  String reciterId = 'ar.alafasy';
  String translationVoiceId = 'en.walk';
  ListenMode listenMode = ListenMode.arabic;
  String translationId = 'en.sahih';
  ShowMode show = ShowMode.both;
  QuranScript script = QuranScript.hafs;
  double arabicSize = 27, focusSize = 36, translationSize = 15;
  double speed = 1;
  int repeat = 0; // extra plays per ayah; -1 = until stopped
  ThemeMode themeMode = ThemeMode.dark;
  int goalMinutes = 20;
  List<String> quickTranslations = List.of(defaultQuickTranslations);
  bool wifiPrefetch = true;
  bool autoNext = true; // play the next surah when one ends
  List<int> favSurahs = [];
  List<String> favReciters = [];
  List<Bookmark> bookmarks = []; // newest first
  int tafsirId = 0; // 0 = follow the translation's language
  Map<String, bool> reminders = {'daily': true, 'streak': true, 'kahf': true, 'mulk': true, 'special': true};
  TimeOfDay dailyTime = const TimeOfDay(hour: 21, minute: 30);

  Reciter get reciter => reciterById(reciterId);
  Reciter get translationVoice => reciterById(translationVoiceId);
  TafsirBook get tafsir => tafsirById(tafsirId != 0 ? tafsirId : defaultTafsirFor(translationId));

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    reciterId = _p.getString('reciter') ?? reciterId;
    translationVoiceId = _p.getString('trVoice') ?? translationVoiceId;
    listenMode = ListenMode.values[_p.getInt('listenMode') ?? 0];
    translationId = _p.getString('translation') ?? translationId;
    show = ShowMode.values[_p.getInt('show') ?? 0];
    script = QuranScript.byName(_p.getString('script'));
    arabicSize = _p.getDouble('arSize') ?? arabicSize;
    focusSize = _p.getDouble('focusSize') ?? focusSize;
    translationSize = _p.getDouble('trSize') ?? translationSize;
    speed = _p.getDouble('speed') ?? speed;
    repeat = _p.getInt('repeat') ?? repeat;
    themeMode = ThemeMode.values[_p.getInt('theme') ?? ThemeMode.dark.index];
    goalMinutes = _p.getInt('goal') ?? goalMinutes;
    quickTranslations = _p.getStringList('quickTr') ?? quickTranslations;
    wifiPrefetch = _p.getBool('wifiPrefetch') ?? wifiPrefetch;
    autoNext = _p.getBool('autoNext') ?? autoNext;
    favSurahs = [for (final x in _p.getStringList('favSurahs') ?? const <String>[]) ?int.tryParse(x)];
    favReciters = _p.getStringList('favReciters') ?? [];
    try {
      bookmarks = [for (final b in jsonDecode(_p.getString('bookmarks') ?? '[]') as List) Bookmark.fromJson(Map<String, dynamic>.from(b as Map))];
    } catch (_) {}
    tafsirId = _p.getInt('tafsir') ?? tafsirId;
    final rem = _p.getString('reminders');
    if (rem != null) reminders = Map<String, bool>.from(jsonDecode(rem) as Map);
    final dt = _p.getInt('dailyTime');
    if (dt != null) dailyTime = TimeOfDay(hour: dt ~/ 60, minute: dt % 60);
  }

  void _save() {
    _p.setString('reciter', reciterId);
    _p.setString('trVoice', translationVoiceId);
    _p.setInt('listenMode', listenMode.index);
    _p.setString('translation', translationId);
    _p.setInt('show', show.index);
    _p.setString('script', script.name);
    _p.setDouble('arSize', arabicSize);
    _p.setDouble('focusSize', focusSize);
    _p.setDouble('trSize', translationSize);
    _p.setDouble('speed', speed);
    _p.setInt('repeat', repeat);
    _p.setInt('theme', themeMode.index);
    _p.setInt('goal', goalMinutes);
    _p.setStringList('quickTr', quickTranslations);
    _p.setBool('wifiPrefetch', wifiPrefetch);
    _p.setBool('autoNext', autoNext);
    _p.setStringList('favSurahs', [for (final n in favSurahs) '$n']);
    _p.setStringList('favReciters', favReciters);
    _p.setString('bookmarks', jsonEncode([for (final b in bookmarks) b.toJson()]));
    _p.setInt('tafsir', tafsirId);
    _p.setString('reminders', jsonEncode(reminders));
    _p.setInt('dailyTime', dailyTime.hour * 60 + dailyTime.minute);
  }

  void update(void Function(Settings s) change) {
    change(this);
    _save();
    notifyListeners();
  }

  /// Picks a translation and, where one exists, the voice in its language, so
  /// the audio follows the text (Jalandhry text with Shamshad Ali Khan audio).
  void setTranslation(String id) => update((s) {
        s.translationId = id;
        final v = voiceFor(id);
        if (v != null) s.translationVoiceId = v.id;
        if (s.show == ShowMode.arabic) s.show = ShowMode.both;
        if (!s.quickTranslations.contains(id)) {
          s.quickTranslations = [id, ...s.quickTranslations].take(4).toList();
        }
      });

  bool isFavSurah(int n) => favSurahs.contains(n);
  bool isFavReciter(String id) => favReciters.contains(id);

  /// Adds or removes a favourite surah; returns whether it is now a favourite.
  bool toggleFavSurah(int n) {
    final on = !favSurahs.contains(n);
    update((s) => on ? s.favSurahs.add(n) : s.favSurahs.remove(n));
    return on;
  }

  bool toggleFavReciter(String id) {
    final on = !favReciters.contains(id);
    update((s) => on ? s.favReciters.add(id) : s.favReciters.remove(id));
    return on;
  }

  Bookmark? bookmarkOf(int surah, int ayah) {
    for (final b in bookmarks) {
      if (b.surah == surah && b.ayah == ayah) return b;
    }
    return null;
  }

  /// Saves the ayah, or updates its note when it is saved already.
  void saveBookmark(int surah, int ayah, {String? note}) => update((s) {
        final old = s.bookmarkOf(surah, ayah);
        if (old != null) {
          s.bookmarks[s.bookmarks.indexOf(old)] = old.withNote(note ?? old.note);
        } else {
          s.bookmarks.insert(0, Bookmark(surah, ayah, note: note ?? '', at: DateTime.now()));
        }
      });

  void removeBookmark(int surah, int ayah) => update((s) => s.bookmarks.removeWhere((b) => b.surah == surah && b.ayah == ayah));

  SharedPreferences get prefs => _p;
}
