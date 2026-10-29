import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/offline_sync.dart';
import '../../data/repository.dart';

const arabicDigits = '٠١٢٣٤٥٦٧٨٩';
String arNum(int n) => n.toString().split('').map((d) => arabicDigits[int.parse(d)]).join();

String fmtDur(Duration d) {
  final s = d.inSeconds.clamp(0, 1 << 31);
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

String fmtMinutes(double m) {
  if (m >= 120) return '${(m / 60).toStringAsFixed(m >= 600 ? 0 : 1)} h';
  return '${m.round()} min';
}

String fmtBytes(int b) {
  if (b > 1 << 30) return '${(b / (1 << 30)).toStringAsFixed(1)} GB';
  if (b > 1 << 20) return '${(b / (1 << 20)).toStringAsFixed(1)} MB';
  return '${(b / 1024).round()} KB';
}

/// Gradient card art with an eight-pointed star lattice.
class Art extends StatelessWidget {
  final Object seed;
  final Widget? child;
  final BorderRadius radius;
  final EdgeInsetsGeometry padding;
  const Art({super.key, required this.seed, this.child, this.radius = const BorderRadius.all(Radius.circular(22)), this.padding = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    final c = artFor(seed);
    return ClipRRect(
      borderRadius: radius,
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: c)),
        child: CustomPaint(
          painter: _StarLattice(),
          child: Padding(padding: padding, child: DefaultTextStyle.merge(style: const TextStyle(color: Colors.white), child: child ?? const SizedBox())),
        ),
      ),
    );
  }
}

class _StarLattice extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.09);
    const step = 56.0;
    for (var y = 0.0; y < size.height + step; y += step) {
      for (var x = 0.0; x < size.width + step; x += step) {
        _star(canvas, Offset(x + 28, y + 28), 12, p);
      }
    }
  }

  void _star(Canvas c, Offset o, double r, Paint p) {
    final sq = Rect.fromCenter(center: o, width: r * 2, height: r * 2);
    c.drawRect(sq, p);
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate(math.pi / 4);
    c.drawRect(Rect.fromCenter(center: Offset.zero, width: r * 2, height: r * 2), p);
    c.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Ayah or surah number inside an eight-pointed star.
class StarNumber extends StatelessWidget {
  final int n;
  final double size;
  const StarNumber(this.n, {super.key, this.size = 38});

  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _StarOutline(c.gold.withValues(alpha: 0.75)),
        child: Center(
          child: Text('$n', style: T.ui(size * 0.32, w: FontWeight.w700, color: c.fg).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
        ),
      ),
    );
  }
}

class _StarOutline extends CustomPainter {
  final Color color;
  _StarOutline(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = color;
    final r = size.width * 0.3;
    final o = size.center(Offset.zero);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: o, width: r * 2, height: r * 2), const Radius.circular(2)), p);
    canvas.save();
    canvas.translate(o.dx, o.dy);
    canvas.rotate(math.pi / 4);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: r * 2, height: r * 2), const Radius.circular(2)), p);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StarOutline old) => old.color != color;
}

/// Reciter photo (cached on the device), falling back to a monogram.
class ReciterAvatar extends StatelessWidget {
  final Reciter reciter;
  final double size;
  final double? radius;
  const ReciterAvatar(this.reciter, {super.key, this.size = 44, this.radius});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<QuranRepository>();
    final sync = context.read<OfflineSync>();
    final local = sync.photoPath(reciter.id);
    final url = repo.profileOf(reciter)?.imageUrl;
    final r = BorderRadius.circular(radius ?? size / 2);
    Widget fallback() => _Monogram(reciter, size);
    Widget img;
    if (local != null && !kIsWeb) {
      img = Image.file(File(local), width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, _, _) => fallback());
    } else if (url != null) {
      img = Image.network(url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          cacheWidth: (size * 3).round(),
          errorBuilder: (_, _, _) => fallback(),
          frameBuilder: (_, child, frame, sync) => frame == null && !sync ? fallback() : child);
      if (!kIsWeb) sync.cachePhoto(reciter.id).catchError((_) {});
    } else {
      img = fallback();
    }
    return ClipRRect(borderRadius: r, child: SizedBox(width: size, height: size, child: img));
  }
}

class _Monogram extends StatelessWidget {
  final Reciter r;
  final double size;
  const _Monogram(this.r, this.size);
  @override
  Widget build(BuildContext context) {
    final c = artFor(r.id);
    return DecoratedBox(
      decoration: BoxDecoration(gradient: LinearGradient(colors: c, begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: Center(child: Text(r.initials, style: T.display(size * 0.3, w: FontWeight.w700, color: Colors.white))),
    );
  }
}

class OvChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool urdu;
  final Widget? leading, trailing;
  final Color? tint;
  const OvChip(this.label, {super.key, this.selected = false, this.onTap, this.urdu = false, this.leading, this.trailing, this.tint});

  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    final bg = tint != null ? c.goldWash : selected ? c.fg : c.raised;
    final fg = tint ?? (selected ? c.bg : c.fg2);
    return Material(
      color: bg,
      shape: StadiumBorder(side: BorderSide(color: tint != null ? Colors.transparent : selected ? c.fg : c.line)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (leading != null) ...[leading!, const SizedBox(width: 6)],
            Text(label,
                style: urdu
                    ? TextStyle(fontFamily: AppFonts.urdu, fontSize: 13, color: fg, height: 1.2)
                    : T.ui(13, w: FontWeight.w600, color: fg)),
            if (trailing != null) ...[const SizedBox(width: 4), trailing!],
          ]),
        ),
      ),
    );
  }
}

class GoldButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool expand;
  const GoldButton(this.label, {super.key, this.icon, this.onTap, this.expand = false});
  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    return Material(
      color: c.gold,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
            if (icon != null) ...[Icon(icon, color: c.goldInk, size: 22), const SizedBox(width: 8)],
            Text(label, style: T.ui(15, w: FontWeight.w700, color: c.goldInk)),
          ]),
        ),
      ),
    );
  }
}

class GhostButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool expand;
  final Color? color;
  const GhostButton(this.label, {super.key, this.icon, this.onTap, this.expand = false, this.color});
  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    return Material(
      color: c.raised,
      shape: StadiumBorder(side: BorderSide(color: c.line)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
            if (icon != null) ...[Icon(icon, size: 20, color: color ?? c.fg), const SizedBox(width: 8)],
            Text(label, style: T.ui(14, w: FontWeight.w600, color: color ?? c.fg)),
          ]),
        ),
      ),
    );
  }
}

class RoundIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;
  final double size;
  final Color? color;
  const RoundIcon(this.icon, {super.key, required this.tooltip, this.onTap, this.size = 40, this.color});
  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: onTap,
        tooltip: tooltip,
        iconSize: size * 0.55,
        style: IconButton.styleFrom(minimumSize: Size(size, size), foregroundColor: color ?? context.ov.fg),
        icon: Icon(icon),
      );
}

class SyncBadge extends StatelessWidget {
  final bool exact;
  final String? suffix;
  const SyncBadge(this.exact, {super.key, this.suffix});
  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: exact ? c.emeraldWash : c.raised, borderRadius: BorderRadius.circular(99)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(exact ? Icons.check_rounded : Icons.graphic_eq_rounded, size: 13, color: exact ? c.emerald : c.fg3),
        const SizedBox(width: 5),
        Flexible(
          child: Text('${exact ? 'Word-exact timing' : 'Estimated timing'}${suffix ?? ''}',
              overflow: TextOverflow.ellipsis, style: T.ui(11.5, w: FontWeight.w700, color: exact ? c.emerald : c.fg3)),
        ),
      ]),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionTitle(this.title, {super.key, this.action, this.onAction});
  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 26, 8, 10),
      child: Row(children: [
        Expanded(child: Text(title, style: T.display(20, w: FontWeight.w700, color: c.fg))),
        if (action != null) TextButton(onPressed: onAction, child: Text(action!, style: T.ui(13, w: FontWeight.w600, color: c.fg2))),
      ]),
    );
  }
}

class Label extends StatelessWidget {
  final String text;
  final EdgeInsetsGeometry padding;
  const Label(this.text, {super.key, this.padding = const EdgeInsets.fromLTRB(0, 18, 0, 10)});
  @override
  Widget build(BuildContext context) => Padding(padding: padding, child: Text(text.toUpperCase(), style: T.label(context.ov.fg3)));
}

/// Segmented control.
class Segmented<V> extends StatelessWidget {
  final List<(V, String)> options;
  final V value;
  final ValueChanged<V> onChanged;
  const Segmented({super.key, required this.options, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: c.raised, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.line)),
      child: Row(children: [
        for (final o in options)
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(o.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: o.$1 == value ? c.fg : Colors.transparent, borderRadius: BorderRadius.circular(10)),
                child: Text(o.$2,
                    textAlign: TextAlign.center,
                    style: T.ui(12.5, w: FontWeight.w700, color: o.$1 == value ? c.bg : c.fg2, height: 1.1)),
              ),
            ),
          ),
      ]),
    );
  }
}

void toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(milliseconds: 2200)));
}

Future<R?> showOvSheet<R>(BuildContext context, {required String title, required WidgetBuilder builder, bool scroll = true}) {
  return showModalBottomSheet<R>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.88, maxWidth: 640),
    builder: (ctx) {
      final c = ctx.ov;
      return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 8, 6),
          child: Row(children: [
            Expanded(child: Text(title, style: T.display(20, w: FontWeight.w700, color: c.fg))),
            RoundIcon(Icons.close_rounded, tooltip: 'Close', onTap: () => Navigator.pop(ctx)),
          ]),
        ),
        Flexible(
          child: scroll
              ? SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 28), child: builder(ctx))
              : Padding(padding: const EdgeInsets.fromLTRB(20, 4, 20, 0), child: builder(ctx)),
        ),
      ]);
    },
  );
}
