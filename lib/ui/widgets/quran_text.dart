import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import 'common.dart';

/// A run of text with an optional tajweed rule.
class TajweedRun {
  final String text;
  final String? rule;
  const TajweedRun(this.text, this.rule);
}

/// Parses Quran.com tajweed markup (`<rule class=madda_normal>…</rule>`).
List<TajweedRun> parseTajweed(String s) {
  final out = <TajweedRun>[];
  final re = RegExp(r'<rule class=([a-z_]+)>(.*?)</rule>');
  var i = 0;
  for (final m in re.allMatches(s)) {
    if (m.start > i) out.add(TajweedRun(_strip(s.substring(i, m.start)), null));
    out.add(TajweedRun(_strip(m.group(2)!), m.group(1)));
    i = m.end;
  }
  if (i < s.length) out.add(TajweedRun(_strip(s.substring(i)), null));
  return out.where((r) => r.text.isNotEmpty).toList();
}

String _strip(String s) => s.replaceAll(RegExp(r'<[^>]+>'), '');

const bismillahByScript = {
  QuranScript.hafs: 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ',
  QuranScript.indopak: 'بِسۡمِ اللهِ الرَّحۡمٰنِ الرَّحِيۡمِ',
  QuranScript.uthmani: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
  QuranScript.simple: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
  QuranScript.tajweed:
      'بِسۡمِ <rule class=ham_wasl>ٱ</rule>للَّهِ <rule class=ham_wasl>ٱ</rule><rule class=laam_shamsiyah>ل</rule>رَّحۡمَ<rule class=madda_normal>ـٰ</rule>نِ <rule class=ham_wasl>ٱ</rule><rule class=laam_shamsiyah>ل</rule>رَّح<rule class=madda_permissible>ِي</rule>مِ',
};

/// One ayah in the chosen script. [highlight] follows the recitation:
/// -2 everything lit (idle), -1 nothing yet, i = word i being recited,
/// >= word count all lit.
class QuranText extends StatelessWidget {
  final List<String> words;
  final QuranScript script;
  final double fontSize;
  final int? ayahNumber;
  final int highlight;
  final bool active;
  final TextAlign align;
  final int? maxLines;
  const QuranText({
    super.key,
    required this.words,
    required this.script,
    required this.fontSize,
    this.ayahNumber,
    this.highlight = -2,
    this.active = false,
    this.align = TextAlign.right,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    final dark = context.isDark;
    final base = TextStyle(
      fontFamily: script.fontFamily,
      fontSize: fontSize * script.scale,
      height: script.lineHeight,
      color: c.fg,
    );
    final dim = c.fg.withValues(alpha: 0.38);
    final spans = <InlineSpan>[];
    for (var i = 0; i < words.length; i++) {
      final state = !active || highlight == -2 || highlight >= words.length
          ? 1
          : i < highlight
              ? 1
              : i == highlight
                  ? 2
                  : 0;
      final color = state == 2 ? c.gold : state == 1 ? null : dim;
      if (script == QuranScript.tajweed) {
        spans.add(TextSpan(children: [
          for (final r in parseTajweed(words[i]))
            TextSpan(
              text: r.text,
              style: TextStyle(
                color: state == 2
                    ? c.gold
                    : r.rule == null
                        ? color
                        : TajweedColors.of(r.rule!, dark).withValues(alpha: state == 0 ? 0.45 : 1),
              ),
            ),
        ]));
      } else {
        spans.add(TextSpan(text: words[i], style: TextStyle(color: color)));
      }
      if (i < words.length - 1) spans.add(const TextSpan(text: ' '));
    }
    if (ayahNumber != null) {
      spans.add(TextSpan(
        text: ' ${arNum(ayahNumber!)}',
        style: TextStyle(fontFamily: 'UthmanicHafs', color: c.gold, fontSize: fontSize * 0.95, height: script.lineHeight),
      ));
    }
    return Text.rich(
      TextSpan(style: base, children: spans),
      textDirection: TextDirection.rtl,
      textAlign: align,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
    );
  }
}

/// Translation paragraph with the right font and direction for its language.
class TranslationText extends StatelessWidget {
  final String text;
  final TranslationEdition edition;
  final double size;
  final Color? color;
  final TextAlign? align;
  final int? maxLines;
  const TranslationText(this.text, this.edition, {super.key, this.size = 15, this.color, this.align, this.maxLines});

  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    final urdu = edition.urdu;
    final rtl = edition.rtl;
    return Text(
      text,
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      textAlign: align ?? (rtl ? TextAlign.right : TextAlign.left),
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: urdu ? AppFonts.urdu : rtl ? 'NotoNaskhArabic' : AppFonts.ui,
        fontSize: urdu ? size + 1 : size,
        height: urdu ? 2.2 : 1.6,
        color: color ?? c.fg2,
      ),
    );
  }
}
