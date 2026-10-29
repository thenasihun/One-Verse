import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'settings.dart';

/// A special day from the Hijri calendar, with the surah suggested for it.
class SpecialDay {
  final DateTime date;
  final String title, body;
  final int surah;
  const SpecialDay(this.date, this.title, this.body, this.surah);
}

/// Special days in the next [days] days (Umm al-Qura calendar).
List<SpecialDay> upcomingSpecialDays(DateTime from, {int days = 400}) {
  final out = <SpecialDay>[];
  for (var i = 0; i < days; i++) {
    final d = DateTime(from.year, from.month, from.day + i);
    final h = HijriCalendar.fromDate(d);
    final m = h.hMonth, day = h.hDay;
    if (m == 9 && day == 1) out.add(SpecialDay(d, 'Ramadan Mubarak', 'A new month with the Quran. Begin with Al-Baqarah.', 2));
    if (m == 9 && day >= 21 && day <= 29 && day.isOdd) {
      out.add(SpecialDay(d, 'One of the last ten nights', 'Laylat al-Qadr may be tonight. Listen to Surah Al-Qadr.', 97));
    }
    if (m == 10 && day == 1) out.add(SpecialDay(d, 'Eid Mubarak', 'Begin Eid with Surah Al-A\'la.', 87));
    if (m == 12 && day == 9) out.add(SpecialDay(d, 'The Day of Arafah', 'The best day for dua. Listen to Surah Al-Fatihah and Al-Hajj.', 22));
    if (m == 12 && day == 10) out.add(SpecialDay(d, 'Eid al-Adha Mubarak', 'Surah Al-Kawthar for the day of sacrifice.', 108));
    if (m == 1 && day == 10) out.add(SpecialDay(d, 'Day of Ashura', 'Remember the story of Musa. Listen to Surah Taha.', 20));
  }
  return out;
}

/// The special day for [d], if any.
SpecialDay? specialDayOn(DateTime d) {
  final l = upcomingSpecialDays(d, days: 1);
  return l.isEmpty ? null : l.first;
}

/// Opt-in reminders. Wording is gentle by design: no countdowns and no
/// pressure about losing a streak.
class Reminders {
  Reminders._();
  static final Reminders instance = Reminders._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  void Function(String payload)? onOpen;

  Future<void> init() async {
    if (kIsWeb) return;
    try {
      tzdata.initializeTimeZones();
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/launcher_icon'),
          iOS: DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false),
        ),
        onDidReceiveNotificationResponse: (r) {
          if (r.payload != null) onOpen?.call(r.payload!);
        },
      );
      _ready = true;
    } catch (e) {
      debugPrint('Reminders unavailable: $e');
    }
  }

  Future<String?> launchPayload() async {
    if (!_ready) return null;
    final d = await _plugin.getNotificationAppLaunchDetails();
    return d?.didNotificationLaunchApp == true ? d!.notificationResponse?.payload : null;
  }

  Future<bool> requestPermission() async {
    if (!_ready) return false;
    final a = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final i = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    return (await a?.requestNotificationsPermission()) ?? (await i?.requestPermissions(alert: true, sound: true)) ?? true;
  }

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails('ov_reminders', 'Reminders',
        channelDescription: 'Daily listening, Friday Al-Kahf, Al-Mulk at night and special days',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        color: Color(0xFFE2BE4F)),
    iOS: DarwinNotificationDetails(),
  );

  tz.TZDateTime _next(int hour, int minute, {int? weekday, DateTime? day}) {
    final now = tz.TZDateTime.now(tz.local);
    var t = day != null
        ? tz.TZDateTime(tz.local, day.year, day.month, day.day, hour, minute)
        : tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (day != null) return t;
    while (t.isBefore(now) || (weekday != null && t.weekday != weekday)) {
      t = t.add(const Duration(days: 1));
    }
    return t;
  }

  Future<void> _at(int id, tz.TZDateTime when, String title, String body, String payload, {DateTimeComponents? repeat}) =>
      _plugin.zonedSchedule(
        id: id,
        scheduledDate: when,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: title,
        body: body,
        payload: payload,
        matchDateTimeComponents: repeat,
      );

  /// Re-plans every reminder. Called on launch and after listening.
  Future<void> reschedule(Settings s,
      {required String continueLabel, required String continuePayload, required bool goalMetToday}) async {
    if (!_ready) return;
    await _plugin.cancelAll();
    final r = s.reminders;
    if (r['daily'] == true) {
      await _at(1, _next(s.dailyTime.hour, s.dailyTime.minute), 'Time for the Quran', continueLabel, continuePayload,
          repeat: DateTimeComponents.time);
    }
    if (r['streak'] == true) {
      final now = DateTime.now();
      final day = goalMetToday || now.hour >= 20 ? DateTime(now.year, now.month, now.day + 1) : now;
      await _at(2, _next(20, 0, day: day), 'A few minutes tonight?', 'Even one surah keeps your listening going. $continueLabel',
          continuePayload);
    }
    if (r['kahf'] == true) {
      await _at(3, _next(7, 15, weekday: DateTime.friday), 'Jumu\'ah Mubarak', 'It is Friday. Listen to Surah Al-Kahf.', '18:1',
          repeat: DateTimeComponents.dayOfWeekAndTime);
    }
    if (r['mulk'] == true) {
      await _at(4, _next(22, 30), 'Before you sleep', 'Surah Al-Mulk, recited every night.', '67:1', repeat: DateTimeComponents.time);
    }
    if (r['special'] == true) {
      var id = 100;
      for (final d in upcomingSpecialDays(DateTime.now()).take(20)) {
        final when = _next(d.surah == 97 ? 21 : 6, 30, day: d.date);
        if (when.isAfter(tz.TZDateTime.now(tz.local))) await _at(id++, when, d.title, d.body, '${d.surah}:1');
      }
    }
  }
}
