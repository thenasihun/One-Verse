import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// Design tokens for One Verse. Dark is the primary look (deep green-black with
/// gold); light mirrors it.
@immutable
class OvColors extends ThemeExtension<OvColors> {
  final Color bg, surface, raised, raised2, line, line2;
  final Color fg, fg2, fg3;
  final Color gold, goldInk, goldWash, emerald, emeraldWash, scrim;

  const OvColors({
    required this.bg,
    required this.surface,
    required this.raised,
    required this.raised2,
    required this.line,
    required this.line2,
    required this.fg,
    required this.fg2,
    required this.fg3,
    required this.gold,
    required this.goldInk,
    required this.goldWash,
    required this.emerald,
    required this.emeraldWash,
    required this.scrim,
  });

  static const dark = OvColors(
    bg: Color(0xFF060D0B),
    surface: Color(0xFF0D1915),
    raised: Color(0xFF14231E),
    raised2: Color(0xFF1B2E27),
    line: Color(0x17D6ECE2),
    line2: Color(0x29D6ECE2),
    fg: Color(0xFFEAF2EE),
    fg2: Color(0xFF9BB1A8),
    fg3: Color(0xFF6B8279),
    gold: Color(0xFFE2BE4F),
    goldInk: Color(0xFF1A1404),
    goldWash: Color(0x24E2BE4F),
    emerald: Color(0xFF22A87D),
    emeraldWash: Color(0x2422A87D),
    scrim: Color(0x9E030806),
  );

  static const light = OvColors(
    bg: Color(0xFFEEF3F0),
    surface: Color(0xFFFFFFFF),
    raised: Color(0xFFF2F6F4),
    raised2: Color(0xFFE5EDE9),
    line: Color(0x1706281E),
    line2: Color(0x2906281E),
    fg: Color(0xFF0A1F18),
    fg2: Color(0xFF4B6158),
    fg3: Color(0xFF7A8E86),
    gold: Color(0xFF9E7A12),
    goldInk: Color(0xFFFFFFFF),
    goldWash: Color(0x1F9E7A12),
    emerald: Color(0xFF08684D),
    emeraldWash: Color(0x1A08684D),
    scrim: Color(0x6B0A1F18),
  );

  @override
  OvColors copyWith() => this;

  @override
  OvColors lerp(ThemeExtension<OvColors>? other, double t) {
    if (other is! OvColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return OvColors(
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      raised: l(raised, other.raised),
      raised2: l(raised2, other.raised2),
      line: l(line, other.line),
      line2: l(line2, other.line2),
      fg: l(fg, other.fg),
      fg2: l(fg2, other.fg2),
      fg3: l(fg3, other.fg3),
      gold: l(gold, other.gold),
      goldInk: l(goldInk, other.goldInk),
      goldWash: l(goldWash, other.goldWash),
      emerald: l(emerald, other.emerald),
      emeraldWash: l(emeraldWash, other.emeraldWash),
      scrim: l(scrim, other.scrim),
    );
  }
}

/// Tajweed rule colours, tuned for each theme.
class TajweedColors {
  static Color of(String rule, bool dark) {
    final m = dark ? _dark : _light;
    return m[rule] ?? m['default']!;
  }

  static const _light = {
    'ham_wasl': Color(0xFF9A9A9A),
    'slnt': Color(0xFF9A9A9A),
    'laam_shamsiyah': Color(0xFF9A9A9A),
    'madda_normal': Color(0xFF3E6BEF),
    'madda_permissible': Color(0xFF3442E6),
    'madda_obligatory': Color(0xFF2144C1),
    'madda_necessary': Color(0xFF000EBC),
    'qalaqah': Color(0xFFD4000A),
    'ghunnah': Color(0xFFE8700F),
    'ikhafa': Color(0xFF9400A8),
    'ikhafa_shafawi': Color(0xFFC800AA),
    'idgham_ghunnah': Color(0xFF14896A),
    'idgham_wo_ghunnah': Color(0xFF168C00),
    'idgham_shafawi': Color(0xFF4FA600),
    'iqlab': Color(0xFF0A9FDB),
    'idgham_mutajanisayn': Color(0xFF8E8E8E),
    'idgham_mutaqaribayn': Color(0xFF8E8E8E),
    'default': Color(0xFF8E8E8E),
  };

  static const _dark = {
    'ham_wasl': Color(0xFF7D8A85),
    'slnt': Color(0xFF7D8A85),
    'laam_shamsiyah': Color(0xFF7D8A85),
    'madda_normal': Color(0xFF82A2FF),
    'madda_permissible': Color(0xFF9AA0FF),
    'madda_obligatory': Color(0xFF6F8EFF),
    'madda_necessary': Color(0xFFB3B8FF),
    'qalaqah': Color(0xFFFF6B70),
    'ghunnah': Color(0xFFFFA35C),
    'ikhafa': Color(0xFFD77BEB),
    'ikhafa_shafawi': Color(0xFFF27BDD),
    'idgham_ghunnah': Color(0xFF43CFA6),
    'idgham_wo_ghunnah': Color(0xFF78D865),
    'idgham_shafawi': Color(0xFF93DE55),
    'iqlab': Color(0xFF63D4FF),
    'idgham_mutajanisayn': Color(0xFF8F9A96),
    'idgham_mutaqaribayn': Color(0xFF8F9A96),
    'default': Color(0xFF8F9A96),
  };

  static const legend = [
    ('madda_normal', 'Madd 2'),
    ('madda_permissible', 'Madd 2·4·6'),
    ('madda_obligatory', 'Madd 4·5'),
    ('madda_necessary', 'Madd 6'),
    ('ghunnah', 'Ghunnah'),
    ('qalaqah', 'Qalqalah'),
    ('ikhafa', 'Ikhfa'),
    ('idgham_ghunnah', 'Idgham + ghunnah'),
    ('idgham_wo_ghunnah', 'Idgham'),
    ('iqlab', 'Iqlab'),
    ('slnt', 'Silent'),
  ];
}

/// Card art palettes (self-contained, readable in both themes).
const artPalettes = <List<Color>>[
  [Color(0xFF0E6B4F), Color(0xFF04261C)],
  [Color(0xFF8A6A16), Color(0xFF2A1E05)],
  [Color(0xFF1F5A6B), Color(0xFF081F26)],
  [Color(0xFF6B2E43), Color(0xFF230E17)],
  [Color(0xFF3C5A22), Color(0xFF111B08)],
  [Color(0xFF433C78), Color(0xFF15122C)],
  [Color(0xFF7A3F1C), Color(0xFF24110A)],
  [Color(0xFF245C52), Color(0xFF0A211D)],
];

List<Color> artFor(Object key) {
  final h = key is int ? key : _hash(key.toString());
  return artPalettes[h % artPalettes.length];
}

int _hash(String s) {
  var h = 7;
  for (final c in s.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return h;
}

class AppFonts {
  static const ui = 'Figtree';
  static const display = 'Bricolage';
  static const kufi = 'ReemKufi';
  static const urdu = 'NotoNastaliqUrdu';
}

class AppTheme {
  static ThemeData build(Brightness b) {
    final c = b == Brightness.dark ? OvColors.dark : OvColors.light;
    final base = ThemeData(
      useMaterial3: true,
      brightness: b,
      fontFamily: AppFonts.ui,
      scaffoldBackgroundColor: c.bg,
      canvasColor: c.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF064E3B),
        brightness: b,
        primary: c.gold,
        onPrimary: c.goldInk,
        secondary: c.emerald,
        surface: c.surface,
        onSurface: c.fg,
      ),
      extensions: [c],
    );
    return base.copyWith(
      splashFactory: InkSparkle.splashFactory,
      dividerColor: c.line,
      textTheme: base.textTheme.apply(bodyColor: c.fg, displayColor: c.fg),
      iconTheme: IconThemeData(color: c.fg),
      sliderTheme: SliderThemeData(
        activeTrackColor: c.gold,
        thumbColor: c.gold,
        inactiveTrackColor: c.line2,
        overlayColor: c.goldWash,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.fg,
        contentTextStyle: TextStyle(color: c.bg, fontFamily: AppFonts.ui, fontWeight: FontWeight.w600),
        behavior: SnackBarBehavior.floating,
        shape: const StadiumBorder(),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        modalBackgroundColor: c.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
        showDragHandle: true,
        dragHandleColor: c.line2,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
    );
  }
}

extension OvContext on BuildContext {
  OvColors get ov => Theme.of(this).extension<OvColors>()!;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

class T {
  static TextStyle display(double size, {FontWeight w = FontWeight.w800, Color? color}) =>
      TextStyle(fontFamily: AppFonts.display, fontSize: size, fontWeight: w, letterSpacing: -0.02 * size, height: 1.08, color: color);
  static TextStyle ui(double size, {FontWeight w = FontWeight.w500, Color? color, double? height}) =>
      TextStyle(fontFamily: AppFonts.ui, fontSize: size, fontWeight: w, color: color, height: height);
  static TextStyle label(Color color) =>
      TextStyle(fontFamily: AppFonts.ui, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: color);
  static TextStyle kufi(double size, {Color? color}) =>
      TextStyle(fontFamily: AppFonts.kufi, fontSize: size, fontWeight: FontWeight.w700, color: color, height: 1.35);
}
