import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../data/models.dart';
import '../data/repository.dart';
import 'widgets/common.dart';

/// Picks one ayah of [s]: type its number, or scroll the list, where each ayah
/// shows its first words. [current] is highlighted and scrolled to; [min] and
/// [max] limit the choice (for a range's other end).
Future<int?> pickAyah(BuildContext context, SurahInfo s, {required int current, String? title, int min = 1, int? max, int? playing}) {
  return showOvSheet<int>(context,
      title: title ?? 'Choose an ayah · ${s.nameEn}',
      scroll: false,
      builder: (_) => _AyahPicker(s: s, current: current, min: min, max: max ?? s.ayahs, playing: playing));
}

class _AyahPicker extends StatefulWidget {
  final SurahInfo s;
  final int current, min, max;
  final int? playing;
  const _AyahPicker({required this.s, required this.current, required this.min, required this.max, this.playing});
  @override
  State<_AyahPicker> createState() => _AyahPickerState();
}

class _AyahPickerState extends State<_AyahPicker> {
  static const _rowHeight = 64.0;
  final _input = TextEditingController();
  late final ScrollController _scroll =
      ScrollController(initialScrollOffset: ((widget.current - widget.min - 2) * _rowHeight).clamp(0, double.infinity));
  List<VerseText>? _verses;
  String? _error;

  @override
  void initState() {
    super.initState();
    context.read<QuranRepository>().words(widget.s.number).then((v) {
      if (mounted) setState(() => _verses = v);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _submit(String v) {
    final n = int.tryParse(v.trim());
    if (n == null || n < widget.min || n > widget.max) {
      setState(() => _error = 'Enter a number from ${widget.min} to ${widget.max}');
      return;
    }
    Navigator.pop(context, n);
  }

  void _jumpTo(String v) {
    final n = int.tryParse(v.trim());
    setState(() => _error = null);
    if (n == null || n < widget.min || n > widget.max || !_scroll.hasClients) return;
    _scroll.animateTo(((n - widget.min - 1) * _rowHeight).clamp(0, _scroll.position.maxScrollExtent),
        duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    final count = widget.max - widget.min + 1;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.72,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(
          controller: _input,
          autofocus: true,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.go,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
          style: T.display(22, w: FontWeight.w700, color: c.fg),
          onChanged: _jumpTo,
          onSubmitted: _submit,
          decoration: InputDecoration(
            hintText: 'Ayah number (${widget.min}–${widget.max})',
            hintStyle: T.ui(15, color: c.fg3),
            errorText: _error,
            prefixIcon: const Icon(Icons.tag_rounded),
            suffixIcon: Padding(
              padding: const EdgeInsets.all(6),
              child: GoldButton('Go', onTap: () => _submit(_input.text)),
            ),
            filled: true,
            fillColor: c.raised,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            itemExtent: _rowHeight,
            itemCount: count,
            itemBuilder: (_, i) {
              final a = widget.min + i;
              final on = a == widget.current;
              final now = a == widget.playing;
              final v = _verses != null && a <= _verses!.length ? _verses![a - 1] : null;
              final words = v?.of(QuranScript.uthmani) ?? const <String>[];
              final preview = words.take(6).join(' ').replaceAll(RegExp(r'<[^>]+>'), '');
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Material(
                  color: on ? c.goldWash : c.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: on ? c.gold : c.line)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.pop(context, a),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(children: [
                        StarNumber(a, size: 36),
                        const SizedBox(width: 10),
                        if (now) ...[Icon(Icons.graphic_eq_rounded, size: 18, color: c.emerald), const SizedBox(width: 6)],
                        Expanded(
                          child: Text(
                            preview.isEmpty ? 'Ayah $a' : '$preview${words.length > 6 ? ' …' : ''}',
                            textDirection: preview.isEmpty ? TextDirection.ltr : TextDirection.rtl,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: preview.isEmpty
                                ? T.ui(14, color: c.fg2)
                                : TextStyle(fontFamily: 'AmiriQuran', fontSize: 17, height: 1.6, color: c.fg),
                          ),
                        ),
                        if (on) Icon(Icons.check_circle_rounded, color: c.gold),
                      ]),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

/// "From ayah" / "To ayah": shows the number large; tap to type or pick it,
/// with small − and + for one step.
class AyahField extends StatelessWidget {
  final String label;
  final int value, min, max;
  final SurahInfo surah;
  final ValueChanged<int> onChanged;
  const AyahField({super.key, required this.label, required this.value, required this.surah, required this.onChanged, this.min = 1, required this.max});

  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    return Expanded(
      child: Material(
        color: c.raised,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final a = await pickAyah(context, surah, current: value, title: '$label · ${surah.nameEn}');
            if (a != null) onChanged(a.clamp(min, max));
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(children: [
              Text(label.toUpperCase(), style: T.label(c.fg3).copyWith(fontSize: 10.5)),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                RoundIcon(Icons.remove_rounded, tooltip: '$label: one less', size: 36, onTap: value > min ? () => onChanged(value - 1) : null),
                Expanded(
                  child: Column(children: [
                    Text('$value', textAlign: TextAlign.center, style: T.display(22, w: FontWeight.w700, color: c.fg)),
                    Text('tap to type', textAlign: TextAlign.center, style: T.ui(9.5, color: c.gold)),
                  ]),
                ),
                RoundIcon(Icons.add_rounded, tooltip: '$label: one more', size: 36, onTap: value < max ? () => onChanged(value + 1) : null),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
