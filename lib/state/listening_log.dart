import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/cache_store.dart';

String dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class DayStats {
  int seconds;
  final List<int> hours;
  final Map<String, int> reciters;
  final Map<String, int> surahs;
  int ayahs;
  DayStats([this.seconds = 0, List<int>? hours, Map<String, int>? reciters, Map<String, int>? surahs, this.ayahs = 0])
      : hours = hours ?? List.filled(24, 0),
        reciters = reciters ?? {},
        surahs = surahs ?? {};

  Map<String, dynamic> toJson() => {'s': seconds, 'h': hours, 'r': reciters, 'q': surahs, 'a': ayahs};
  factory DayStats.fromJson(Map j) => DayStats(
        j['s'] as int? ?? 0,
        List<int>.from(j['h'] as List? ?? List.filled(24, 0)),
        Map<String, int>.from(j['r'] as Map? ?? {}),
        Map<String, int>.from(j['q'] as Map? ?? {}),
        j['a'] as int? ?? 0,
      );
}

class ChartBar {
  final String label, tip;
  final double minutes;
  final bool future;
  const ChartBar(this.label, this.tip, this.minutes, {this.future = false});
}

/// Our own listening history and streak algorithm, stored on the device.
///
/// A day counts toward the streak when at least [minSecondsForStreak] of
/// recitation were played. The current streak stays alive through today even
/// before today's first listen, so it never shows a broken streak in the
/// morning.
class ListeningLog extends ChangeNotifier {
  ListeningLog({CacheStore? store}) : store = store ?? CacheStore.instance;
  final CacheStore store;
  static const minSecondsForStreak = 60;

  final Map<String, DayStats> days = {};
  int _unsaved = 0;
  Timer? _saveTimer;

  Future<void> init() async {
    final e = await store.read('listen_log');
    if (e?.data is Map) {
      for (final en in (e!.data as Map).entries) {
        days[en.key as String] = DayStats.fromJson(en.value as Map);
      }
    }
    notifyListeners();
  }

  void add(int seconds, {required String reciterId, required int surah, DateTime? at}) {
    final now = at ?? DateTime.now();
    final d = days.putIfAbsent(dayKey(now), DayStats.new);
    d.seconds += seconds;
    d.hours[now.hour] += seconds;
    d.reciters[reciterId] = (d.reciters[reciterId] ?? 0) + seconds;
    d.surahs['$surah'] = (d.surahs['$surah'] ?? 0) + seconds;
    _unsaved += seconds;
    if (_unsaved >= 10) {
      _unsaved = 0;
      _scheduleSave();
    }
    notifyListeners();
  }

  void addAyah({DateTime? at}) {
    days.putIfAbsent(dayKey(at ?? DateTime.now()), DayStats.new).ayahs++;
    _scheduleSave();
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), flush);
  }

  Future<void> flush() => store.write('listen_log', {for (final e in days.entries) e.key: e.value.toJson()});

  int secondsOn(DateTime d) => days[dayKey(d)]?.seconds ?? 0;
  double minutesOn(DateTime d) => secondsOn(d) / 60;
  bool counts(DateTime d) => secondsOn(d) >= minSecondsForStreak;

  int currentStreak([DateTime? today]) {
    final t = _date(today ?? DateTime.now());
    var day = counts(t) ? t : t.subtract(const Duration(days: 1));
    var n = 0;
    while (counts(day)) {
      n++;
      day = DateTime(day.year, day.month, day.day - 1);
    }
    return n;
  }

  int bestStreak() {
    final keys = days.keys.where((k) => days[k]!.seconds >= minSecondsForStreak).toList()..sort();
    var best = 0, run = 0;
    DateTime? prev;
    for (final k in keys) {
      final d = DateTime.parse(k);
      run = prev != null && d.difference(prev).inDays == 1 ? run + 1 : 1;
      if (run > best) best = run;
      prev = d;
    }
    return best;
  }

  static DateTime _date(DateTime d) => DateTime(d.year, d.month, d.day);

  List<ChartBar> series(String range, [DateTime? now]) {
    final t = now ?? DateTime.now();
    final today = _date(t);
    switch (range) {
      case 'day':
        final h = days[dayKey(t)]?.hours ?? List.filled(24, 0);
        return [
          for (var i = 0; i < 24; i++)
            ChartBar('$i', '${i.toString().padLeft(2, '0')}:00', h[i] / 60, future: i > t.hour),
        ];
      case 'week':
      case 'month':
        final n = range == 'week' ? 7 : 30;
        return [
          for (var i = n - 1; i >= 0; i--)
            () {
              final d = DateTime(today.year, today.month, today.day - i);
              return ChartBar(range == 'week' ? _wd[d.weekday - 1] : '${d.day}', '${_wd[d.weekday - 1]} ${d.day} ${_mo[d.month - 1]}',
                  minutesOn(d));
            }(),
        ];
      default:
        return [
          for (var i = 11; i >= 0; i--)
            () {
              final m = DateTime(today.year, today.month - i, 1);
              var s = 0;
              for (final e in days.entries) {
                final d = DateTime.parse(e.key);
                if (d.year == m.year && d.month == m.month) s += e.value.seconds;
              }
              return ChartBar(_mo[m.month - 1].substring(0, 1), '${_mo[m.month - 1]} ${m.year}', s / 60);
            }(),
        ];
    }
  }

  /// Seconds per key over the last [daysBack] days, sorted high to low.
  List<MapEntry<String, int>> top(String kind, {int daysBack = 30, DateTime? now}) {
    final t = _date(now ?? DateTime.now());
    final acc = <String, int>{};
    for (var i = 0; i < daysBack; i++) {
      final d = days[dayKey(DateTime(t.year, t.month, t.day - i))];
      if (d == null) continue;
      for (final e in (kind == 'reciter' ? d.reciters : d.surahs).entries) {
        acc[e.key] = (acc[e.key] ?? 0) + e.value;
      }
    }
    return acc.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }

  static const _wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _mo = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
}
