import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/catalog.dart';
import '../../data/repository.dart';
import '../../state/listening_log.dart';
import '../../state/playback.dart';
import '../../state/reminders.dart';
import '../../state/settings.dart';
import '../widgets/common.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});
  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  String range = 'week';

  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    final log = context.watch<ListeningLog>();
    final s = context.watch<Settings>();
    final repo = context.read<QuranRepository>();
    final now = DateTime.now();
    final today = log.minutesOn(now);
    final streak = log.currentStreak();
    final best = math.max(streak, log.bestStreak());
    final data = log.series(range);
    final total = data.fold<double>(0, (t, b) => t + b.minutes);
    final counted = data.where((b) => !b.future).length;
    final week = log.series('week').fold<double>(0, (t, b) => t + b.minutes);
    final topR = log.top('reciter').take(3).toList();
    final topS = log.top('surah').take(3).toList();

    return ListView(padding: EdgeInsets.fromLTRB(0, MediaQuery.paddingOf(context).top + 10, 0, 28), children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Expanded(child: Text('Progress', style: T.display(26, color: c.fg))),
          Container(
            height: 34,
            padding: const EdgeInsets.fromLTRB(8, 0, 12, 0),
            decoration: BoxDecoration(color: c.goldWash, borderRadius: BorderRadius.circular(99)),
            child: Row(children: [
              Icon(Icons.local_fire_department_rounded, size: 18, color: c.gold),
              const SizedBox(width: 3),
              Text(streak == 1 ? '1 day' : '$streak days', style: T.ui(13, w: FontWeight.w800, color: c.gold)),
            ]),
          ),
        ]),
      ),
      _Card(
        child: Row(children: [
          GestureDetector(
            onTap: () => _pickGoal(context, s),
            child: SizedBox(
              width: 116,
              height: 116,
              child: CustomPaint(
                painter: _Ring((today / s.goalMinutes).clamp(0, 1).toDouble(), c.gold, c.raised2),
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('${today.floor()}', style: T.display(30, color: c.fg)),
                    Text('of ${s.goalMinutes} min', style: T.ui(11, color: c.fg3)),
                  ]),
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Wrap(runSpacing: 12, children: [
              _Stat('Streak', '$streak', icon: Icons.local_fire_department_rounded),
              _Stat('Ayahs today', '${log.days[dayKey(now)]?.ayahs ?? 0}'),
              _Stat('This week', fmtMinutes(week)),
              _Stat('Best streak', '$best'),
            ]),
          ),
        ]),
      ),
      if (streak == 0 && today == 0)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Text('Listen for a minute today to start a streak. Tap the ring to change your daily goal.',
              style: T.ui(12.5, color: c.fg3, height: 1.45)),
        ),
      _Card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('MINUTES LISTENED', style: T.label(c.fg3)),
          const SizedBox(height: 10),
          Segmented<String>(
            options: const [('day', 'Day'), ('week', 'Week'), ('month', 'Month'), ('year', 'Year')],
            value: range,
            onChanged: (v) => setState(() => range = v),
          ),
          const SizedBox(height: 16),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text({'day': 'Today', 'week': 'Last 7 days', 'month': 'Last 30 days', 'year': 'Last 12 months'}[range]!,
                    style: T.ui(11.5, color: c.fg3)),
                Text(fmtMinutes(total), style: T.display(26, color: c.fg)),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('Average per ${range == 'day' ? 'hour' : range == 'year' ? 'month' : 'day'}', style: T.ui(11.5, color: c.fg3)),
              Text(fmtMinutes(counted == 0 ? 0 : total / counted), style: T.ui(16, w: FontWeight.w700, color: c.fg)),
            ]),
          ]),
          const SizedBox(height: 12),
          _BarChart(data: data, hours: range == 'year'),
        ]),
      ),
      _Card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(_monthTitle(now).toUpperCase(), style: T.label(c.fg3)),
          const SizedBox(height: 12),
          _Calendar(log: log, now: now),
        ]),
      ),
      if (topR.isNotEmpty || topS.isNotEmpty)
        _Card(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('MOST LISTENED, LAST 30 DAYS', style: T.label(c.fg3)),
            const SizedBox(height: 6),
            for (final e in topR)
              _TopRow(leading: ReciterAvatar(reciterById(e.key), size: 30), title: reciterById(e.key).name, seconds: e.value, max: topR.first.value),
            for (final e in topS)
              _TopRow(
                  leading: StarNumber(int.parse(e.key), size: 30),
                  title: repo.surah(int.parse(e.key)).nameEn,
                  seconds: e.value,
                  max: topS.first.value),
          ]),
        ),
      _Card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('REMINDERS', style: T.label(c.fg3)),
          for (final (k, icon, title, sub) in [
            ('daily', Icons.notifications_rounded, 'Daily reminder', 'Every day at ${s.dailyTime.format(context)}, opens where you left off'),
            ('streak', Icons.local_fire_department_rounded, 'Gentle evening nudge', '8:00 PM, only on days you have not listened yet'),
            ('kahf', Icons.star_rounded, 'Al-Kahf on Friday', 'Friday 7:15 AM'),
            ('mulk', Icons.nightlight_round, 'Al-Mulk before sleep', '10:30 PM every night'),
            ('special', Icons.auto_awesome_rounded, 'Special days', 'Ramadan, the last ten nights, Arafah, both Eids and Ashura'),
          ])
            _ReminderRow(
              icon: icon,
              title: title,
              subtitle: sub,
              on: s.reminders[k] == true,
              onTap: k == 'daily' ? () => _pickTime(context, s) : null,
              onChanged: (v) async {
                if (v) await Reminders.instance.requestPermission();
                s.update((x) => x.reminders = {...x.reminders, k: v});
                final pb = context.mounted ? context.read<Playback>() : null;
                if (pb == null) return;
                await Reminders.instance.reschedule(s,
                    continueLabel: 'Continue ${repo.surah(pb.surah).nameEn}, ayah ${pb.ayah}.',
                    continuePayload: '${pb.surah}:${pb.ayah}',
                    goalMetToday: today >= s.goalMinutes);
              },
            ),
        ]),
      ),
      const SizedBox(height: 8),
    ]);
  }

  String _monthTitle(DateTime d) => '${const ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][d.month - 1]} ${d.year}';

  void _pickGoal(BuildContext context, Settings s) {
    showOvSheet(context, title: 'Daily goal', builder: (ctx) {
      final c = ctx.ov;
      return Wrap(spacing: 8, runSpacing: 8, children: [
        for (final m in [5, 10, 15, 20, 30, 45, 60, 90])
          OvChip('$m min', selected: s.goalMinutes == m, onTap: () {
            s.update((x) => x.goalMinutes = m);
            Navigator.pop(ctx);
          }),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text('Your streak counts any day with at least one minute of listening. The goal is just for you.',
              style: T.ui(12.5, color: c.fg3, height: 1.45)),
        ),
      ]);
    });
  }

  Future<void> _pickTime(BuildContext context, Settings s) async {
    final t = await showTimePicker(context: context, initialTime: s.dailyTime);
    if (t != null) s.update((x) => x.dailyTime = t);
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: c.line)),
      child: child,
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  final IconData? icon;
  const _Stat(this.label, this.value, {this.icon});
  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    return FractionallySizedBox(
      widthFactor: 0.5,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(), style: T.label(c.fg3).copyWith(fontSize: 10)),
        const SizedBox(height: 2),
        Row(children: [
          if (icon != null) Icon(icon, size: 18, color: c.gold),
          Text(value, style: T.display(20, w: FontWeight.w700, color: icon != null ? c.gold : c.fg)),
        ]),
      ]),
    );
  }
}

class _Ring extends CustomPainter {
  final double v;
  final Color color, track;
  _Ring(this.v, this.color, this.track);
  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(5, 5, size.width - 10, size.height - 10);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(r, 0, math.pi * 2, false, p..color = track);
    if (v > 0) canvas.drawArc(r, -math.pi / 2, math.pi * 2 * v, false, p..color = color);
  }

  @override
  bool shouldRepaint(_Ring o) => o.v != v || o.color != color;
}

class _BarChart extends StatefulWidget {
  final List<ChartBar> data;
  final bool hours;
  const _BarChart({required this.data, required this.hours});
  @override
  State<_BarChart> createState() => _BarChartState();
}

class _BarChartState extends State<_BarChart> {
  int? hover;

  @override
  void didUpdateWidget(_BarChart old) {
    super.didUpdateWidget(old);
    if (old.data.length != widget.data.length) hover = null;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    final max = _niceMax(widget.data.fold<double>(10, (m, b) => math.max(m, b.minutes)));
    return LayoutBuilder(builder: (context, box) {
      const padL = 30.0;
      final w = box.maxWidth;
      final bw = (w - padL) / widget.data.length;
      void pick(Offset p) {
        final i = ((p.dx - padL) / bw).floor();
        setState(() => hover = i >= 0 && i < widget.data.length ? i : null);
      }

      return GestureDetector(
        onTapDown: (d) => pick(d.localPosition),
        onHorizontalDragUpdate: (d) => pick(d.localPosition),
        onHorizontalDragEnd: (_) {},
        child: MouseRegion(
          onHover: (e) => pick(e.localPosition),
          onExit: (_) => setState(() => hover = null),
          child: SizedBox(
            height: 170,
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _BarsPainter(widget.data, max, hover, c, padL, widget.hours),
                ),
              ),
              if (hover != null)
                Positioned(
                  left: (padL + bw * hover! + bw / 2 - 60).clamp(0, w - 120),
                  top: -6,
                  width: 120,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: c.fg, borderRadius: BorderRadius.circular(10)),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(fmtMinutes(widget.data[hover!].minutes), style: T.ui(12.5, w: FontWeight.w700, color: c.bg)),
                      Text(widget.data[hover!].tip, style: T.ui(10.5, color: c.bg.withValues(alpha: 0.75))),
                    ]),
                  ),
                ),
            ]),
          ),
        ),
      );
    });
  }

  static double _niceMax(double v) =>
      [10, 15, 20, 30, 40, 60, 90, 120, 180, 240, 360, 480, 600, 900, 1200, 1800, 2400, 3600].firstWhere((s) => s >= v, orElse: () => (v / 600).ceil() * 600).toDouble();
}

class _BarsPainter extends CustomPainter {
  final List<ChartBar> data;
  final double max;
  final int? hover;
  final OvColors c;
  final double padL;
  final bool hours;
  _BarsPainter(this.data, this.max, this.hover, this.c, this.padL, this.hours);

  @override
  void paint(Canvas canvas, Size size) {
    const padB = 20.0, padT = 22.0;
    final ih = size.height - padB - padT;
    final bw = (size.width - padL) / data.length;
    final gap = (bw * 0.28).clamp(2.0, 6.0);
    double y(double v) => padT + ih - v / max * ih;
    final grid = Paint()
      ..color = c.line
      ..strokeWidth = 1;
    for (final t in [0.0, max / 2, max]) {
      canvas.drawLine(Offset(padL, y(t)), Offset(size.width, y(t)), grid);
      _text(canvas, hours ? '${(t / 60).round()}h' : '${t.round()}', Offset(padL - 6, y(t) - 7), right: true);
    }
    final every = data.length > 24 ? 5 : data.length > 12 ? 6 : 1;
    for (var i = 0; i < data.length; i++) {
      final b = data[i];
      final h = (b.minutes / max * ih).clamp(0.0, ih);
      final x = padL + i * bw + gap / 2;
      if (h > 0.5) {
        final r = math.min(4.0, (bw - gap) / 2);
        canvas.drawRRect(
          RRect.fromRectAndCorners(Rect.fromLTWH(x, padT + ih - h, bw - gap, h), topLeft: Radius.circular(r), topRight: Radius.circular(r)),
          Paint()..color = hover == null || hover == i ? c.gold : c.gold.withValues(alpha: 0.38),
        );
      }
      if (i % every == 0 || (every == 1 && i == data.length - 1)) {
        _text(canvas, b.label, Offset(padL + i * bw + bw / 2, size.height - 14), center: true);
      }
    }
  }

  void _text(Canvas canvas, String s, Offset o, {bool right = false, bool center = false}) {
    final tp = TextPainter(text: TextSpan(text: s, style: T.ui(10, color: c.fg3)), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(right ? o.dx - tp.width : center ? o.dx - tp.width / 2 : o.dx, o.dy));
  }

  @override
  bool shouldRepaint(_BarsPainter o) => o.data != data || o.hover != hover || o.max != max || o.c != c;
}

class _Calendar extends StatelessWidget {
  final ListeningLog log;
  final DateTime now;
  const _Calendar({required this.log, required this.now});
  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    final first = DateTime(now.year, now.month, 1);
    final days = DateTime(now.year, now.month + 1, 0).day;
    final lead = first.weekday - 1;
    Color fill(double m) => m <= 0
        ? c.raised2
        : m < 10
            ? Color.lerp(c.raised2, c.emerald, 0.3)!
            : m < 25
                ? Color.lerp(c.raised2, c.emerald, 0.6)!
                : c.emerald;
    return Column(children: [
      Row(children: [
        for (final d in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
          Expanded(child: Center(child: Text(d, style: T.ui(10.5, w: FontWeight.w700, color: c.fg3)))),
      ]),
      const SizedBox(height: 8),
      GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 5,
        crossAxisSpacing: 5,
        children: [
          for (var i = 0; i < lead; i++) const SizedBox(),
          for (var d = 1; d <= days; d++)
            () {
              final date = DateTime(now.year, now.month, d);
              final future = date.isAfter(now);
              final m = future ? 0.0 : log.minutesOn(date);
              return Tooltip(
                message: future ? '' : '${fmtMinutes(m)} on $d',
                child: Container(
                  decoration: BoxDecoration(
                    color: future ? Colors.transparent : fill(m),
                    borderRadius: BorderRadius.circular(7),
                    border: d == now.day ? Border.all(color: c.gold, width: 2) : null,
                  ),
                  alignment: Alignment.center,
                  child: Text('$d', style: T.ui(10.5, color: m >= 25 ? Colors.white : future ? c.fg3.withValues(alpha: 0.5) : c.fg2)),
                ),
              );
            }(),
        ],
      ),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        Text('Less ', style: T.ui(11, color: c.fg3)),
        for (final m in [0.0, 5.0, 15.0, 30.0])
          Container(margin: const EdgeInsets.symmetric(horizontal: 2), width: 12, height: 12, decoration: BoxDecoration(color: fill(m), borderRadius: BorderRadius.circular(3))),
        Text(' More', style: T.ui(11, color: c.fg3)),
      ]),
    ]);
  }
}

class _TopRow extends StatelessWidget {
  final Widget leading;
  final String title;
  final int seconds, max;
  const _TopRow({required this.leading, required this.title, required this.seconds, required this.max});
  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        leading,
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: T.ui(13.5, w: FontWeight.w600, color: c.fg)),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: max == 0 ? 0 : seconds / max, minHeight: 4, color: c.gold, backgroundColor: c.raised2),
            ),
          ]),
        ),
        const SizedBox(width: 12),
        Text(fmtMinutes(seconds / 60), style: T.ui(12.5, color: c.fg2)),
      ]),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool on;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onTap;
  const _ReminderRow({required this.icon, required this.title, required this.subtitle, required this.on, required this.onChanged, this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: c.raised2, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 20, color: c.gold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: T.ui(14, w: FontWeight.w600, color: c.fg)),
              Text(subtitle, style: T.ui(12, color: c.fg3, height: 1.35)),
            ]),
          ),
          Switch(value: on, onChanged: onChanged, activeTrackColor: c.emerald),
        ]),
      ),
    );
  }
}
