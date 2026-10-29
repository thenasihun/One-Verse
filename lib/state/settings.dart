import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/catalog.dart';
import '../data/models.dart';

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
  Map<String, bool> reminders = {'daily': true, 'streak': true, 'kahf': true, 'mulk': true, 'special': true};
  TimeOfDay dailyTime = const TimeOfDay(hour: 21, minute: 30);

  Reciter get reciter => reciterById(reciterId);
  Reciter get translationVoice => reciterById(translationVoiceId);

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
    _p.setString('reminders', jsonEncode(reminders));
    _p.setInt('dailyTime', dailyTime.hour * 60 + dailyTime.minute);
  }

  void update(void Function(Settings s) change) {
    change(this);
    _save();
    notifyListeners();
  }

  void setTranslation(String id) => update((s) {
        s.translationId = id;
        if (s.show == ShowMode.arabic) s.show = ShowMode.both;
        if (!s.quickTranslations.contains(id)) {
          s.quickTranslations = [id, ...s.quickTranslations].take(4).toList();
        }
      });

  SharedPreferences get prefs => _p;
}
