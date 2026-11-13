import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../data/catalog.dart';
import '../data/models.dart';
import '../data/repository.dart';
import '../state/playback.dart';
import '../state/settings.dart';
import 'sheets.dart';
import 'study.dart';
import 'widgets/common.dart';

// Big, thumb-friendly player settings. Every choice is one tap on a large
// target that shows its current value, and opens a sheet of large options
// instead of cycling through values blindly.

String repeatLabel(int repeat) => repeat == 0 ? 'Off' : repeat < 0 ? 'Each ayah, until stopped' : 'Each ayah $repeat×';

String listenLabel(ListenMode m) => switch (m) {
      ListenMode.arabic => 'Arabic',
      ListenMode.arabicTranslation => 'Arabic + translation',
      ListenMode.translation => 'Translation only',
    };

/// Reciter, translation, what you hear, repeat and speed.
class PlayerDeck extends StatelessWidget {
  const PlayerDeck({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<Settings>();
    final pb = context.watch<Playback>();
    final repo = context.read<QuranRepository>();
    final tr = repo.translationById(s.translationId);
    final trOn = s.show != ShowMode.arabic;
    final repeat = pb.looping
        ? 'Ayahs ${pb.loopFrom}–${pb.loopTo}'
        : repeatLabel(s.repeat);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      DeckTile(
        leading: ReciterAvatar(s.reciter, size: 48),
        kicker: 'Reciter',
        title: s.reciter.name,
        subtitle: '${s.reciter.style} · ${s.reciter.syncLabel}',
        trailing: FavButton.reciter(s.reciterId, size: 40),
        onTap: () => showReciterSheet(context),
      ),
      const SizedBox(height: 10),
      IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
          child: DeckTile(
            icon: Icons.translate_rounded,
            kicker: 'Translation',
            title: trOn ? tr.englishName : 'Off',
            subtitle: trOn ? languageName(tr.language) : 'Arabic only',
            lit: trOn,
            vertical: true,
            onTap: () => showTranslationQuickSheet(context),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DeckTile(
            icon: Icons.headphones_rounded,
            kicker: 'You hear',
            title: listenLabel(s.listenMode),
            subtitle: s.listenMode == ListenMode.arabic ? 'Recitation only' : s.translationVoice.name,
            lit: s.listenMode != ListenMode.arabic,
            vertical: true,
            onTap: () => showListenSheet(context),
          ),
        ),
      ])),
      const SizedBox(height: 10),
      IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
          child: DeckTile(
            icon: pb.looping ? Icons.all_inclusive_rounded : s.repeat == 0 ? Icons.repeat_rounded : Icons.repeat_one_rounded,
            kicker: pb.looping ? 'Memorising' : 'Repeat',
            title: repeat,
            lit: s.repeat != 0 || pb.looping,
            vertical: true,
            onTap: () => showRepeatSheet(context),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DeckTile(
            icon: Icons.speed_rounded,
            kicker: 'Speed',
            title: s.speed == 1 ? 'Normal' : '${s.speed}×',
            lit: s.speed != 1,
            vertical: true,
            onTap: () => showSpeedSheet(context),
          ),
        ),
      ])),
    ]);
  }
}

/// A large tappable card: what it is, its current value, and a chevron.
class DeckTile extends StatelessWidget {
  final IconData? icon;
  final Widget? leading, trailing;
  final String kicker, title;
  final String? subtitle;
  final bool lit;
  final bool vertical; // icon on top, for half-width tiles
  final VoidCallback onTap;
  const DeckTile({super.key, this.icon, this.leading, this.trailing, required this.kicker, required this.title, this.subtitle, this.lit = false, this.vertical = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    final badge = leading ??
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: lit ? c.gold : c.raised, shape: BoxShape.circle),
          child: Icon(icon, size: 22, color: lit ? c.goldInk : c.fg),
        );
    final text = Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text(kicker.toUpperCase(), maxLines: 1, style: T.label(lit ? c.gold : c.fg3).copyWith(fontSize: 10.5)),
      const SizedBox(height: 2),
      Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: T.ui(15, w: FontWeight.w700, color: c.fg, height: 1.2)),
      if (subtitle != null) Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.ui(12, color: c.fg2)),
    ]);
    final body = vertical
        ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [badge, const Spacer(), Icon(Icons.chevron_right_rounded, color: c.fg3)]),
            const SizedBox(height: 10),
            text,
          ])
        : Row(children: [
            badge,
            const SizedBox(width: 12),
            Expanded(child: text),
            ?trailing,
            Icon(Icons.chevron_right_rounded, color: c.fg3),
          ]);
    return Semantics(
      button: true,
      label: '$kicker: $title',
      excludeSemantics: trailing == null,
      child: Material(
        color: lit ? c.goldWash : c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: lit ? c.gold.withValues(alpha: 0.45) : c.line)),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 76),
            child: Padding(
              padding: vertical ? const EdgeInsets.fromLTRB(14, 12, 10, 14) : const EdgeInsets.fromLTRB(14, 10, 10, 10),
              child: body,
            ),
          ),
        ),
      ),
    );
  }
}

/// A full-width option row, at least 60 high, with a tick when chosen.
class OptionRow extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;
  const OptionRow({super.key, this.icon, required this.title, this.subtitle, this.selected = false, required this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? c.goldWash : c.raised,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: selected ? c.gold : Colors.transparent, width: 1.5)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 60),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(children: [
                if (icon != null) ...[Icon(icon, color: selected ? c.gold : c.fg2), const SizedBox(width: 14)],
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text(title, style: T.ui(15, w: FontWeight.w700, color: c.fg)),
                    if (subtitle != null) Text(subtitle!, style: T.ui(12.5, color: c.fg2, height: 1.35)),
                  ]),
                ),
                trailing ??
                    (selected
                        ? Icon(Icons.check_circle_rounded, color: c.gold)
                        : Icon(Icons.radio_button_unchecked_rounded, color: c.fg3)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// A grid of large equal buttons for numbers (repeat count, speed).
class _BigChoices<V> extends StatelessWidget {
  final List<(V, String, String?)> options; // value, label, small note
  final V value;
  final ValueChanged<V> onPick;
  final int columns;
  const _BigChoices({required this.options, required this.value, required this.onPick, this.columns = 4});

  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    return GridView.count(
      crossAxisCount: columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: columns == 3 ? 1.9 : 1.35,
      children: [
        for (final (v, label, note) in options)
          Semantics(
            selected: v == value,
            button: true,
            label: note == null ? label : '$label, $note',
            excludeSemantics: true,
            child: Material(
              color: v == value ? c.gold : c.raised,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => onPick(v),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(label, style: T.display(20, w: FontWeight.w700, color: v == value ? c.goldInk : c.fg)),
                  if (note != null) Text(note, style: T.ui(10.5, w: FontWeight.w600, color: v == value ? c.goldInk : c.fg3)),
                ]),
              ),
            ),
          ),
      ],
    );
  }
}

// ------------------------------------------------------------------ sheets

void showRepeatSheet(BuildContext context) {
  final pb = context.read<Playback>();
  final s = context.read<Settings>();
  showOvSheet(context, title: 'Repeat', builder: (ctx) {
    final c = ctx.ov;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Play each ayah again before moving on.', style: T.ui(13.5, color: c.fg2)),
      const SizedBox(height: 12),
      _BigChoices<int>(
        options: const [(0, 'Off', null), (1, '1×', null), (2, '2×', null), (3, '3×', null), (5, '5×', null), (10, '10×', null), (-1, '∞', 'until stopped')],
        value: s.repeat,
        onPick: (v) {
          pb.setRepeat(v);
          Navigator.pop(ctx);
          toast(context, v == 0 ? 'Repeat off' : 'Repeat: ${repeatLabel(v).toLowerCase()}');
        },
      ),
      const Label('Memorise a passage'),
      OptionRow(
        icon: Icons.all_inclusive_rounded,
        title: pb.looping ? 'Memorising ayahs ${pb.loopFrom}–${pb.loopTo}' : 'Loop a range of ayahs',
        subtitle: pb.looping ? 'Tap to change or stop' : 'For example ayahs 1–5, ten times, with a pause between rounds',
        selected: pb.looping,
        trailing: Icon(Icons.chevron_right_rounded, color: c.fg3),
        onTap: () {
          Navigator.pop(ctx);
          showLoopSheet(context);
        },
      ),
    ]);
  });
}

void showSpeedSheet(BuildContext context) {
  final pb = context.read<Playback>();
  final s = context.read<Settings>();
  showOvSheet(context, title: 'Speed', builder: (ctx) {
    return _BigChoices<double>(
      columns: 3,
      options: const [(0.5, '0.5×', 'slow'), (0.75, '0.75×', null), (1.0, '1×', 'normal'), (1.25, '1.25×', null), (1.5, '1.5×', null), (2.0, '2×', 'fast')],
      value: s.speed,
      onPick: (v) {
        pb.setSpeed(v);
        Navigator.pop(ctx);
      },
    );
  });
}

void showListenSheet(BuildContext context) {
  final pb = context.read<Playback>();
  showOvSheet(context, title: 'What you hear', builder: (ctx) {
    final c = ctx.ov;
    final s = ctx.watch<Settings>();
    final voice = s.translationVoice;
    void pick(ListenMode m) {
      s.update((x) => x.listenMode = m);
      pb.reload();
      Navigator.pop(ctx);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      OptionRow(
        icon: Icons.record_voice_over_rounded,
        title: 'Arabic',
        subtitle: 'Only the recitation by ${s.reciter.name}',
        selected: s.listenMode == ListenMode.arabic,
        onTap: () => pick(ListenMode.arabic),
      ),
      OptionRow(
        icon: Icons.translate_rounded,
        title: 'Arabic + translation',
        subtitle: 'After each ayah, hear its meaning in ${voice.language ?? 'your language'} (${voice.name})',
        selected: s.listenMode == ListenMode.arabicTranslation,
        onTap: () => pick(ListenMode.arabicTranslation),
      ),
      OptionRow(
        icon: Icons.headphones_rounded,
        title: 'Translation only',
        subtitle: 'Listen to the meaning alone, read by ${voice.name}',
        selected: s.listenMode == ListenMode.translation,
        onTap: () => pick(ListenMode.translation),
      ),
      const Label('Translation voice'),
      OptionRow(
        icon: Icons.person_rounded,
        title: voice.name,
        subtitle: '${voice.language} · change the voice that reads the meaning',
        trailing: Icon(Icons.chevron_right_rounded, color: c.fg3),
        onTap: () {
          Navigator.pop(ctx);
          showReciterSheet(context, voices: true);
        },
      ),
    ]);
  });
}

void showTranslationQuickSheet(BuildContext context) {
  final pb = context.read<Playback>();
  showOvSheet(context, title: 'Translation', builder: (ctx) {
    final c = ctx.ov;
    final s = ctx.watch<Settings>();
    final repo = ctx.read<QuranRepository>();
    final on = s.show != ShowMode.arabic;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final id in s.quickTranslations)
        () {
          final t = repo.translationById(id);
          final v = voiceFor(id);
          return OptionRow(
            title: t.englishName,
            subtitle: '${languageName(t.language)} · ${v == null ? 'text only' : 'with audio: ${v.name}'}',
            selected: on && s.translationId == id,
            onTap: () {
              s.setTranslation(id);
              pb.reload();
              Navigator.pop(ctx);
            },
          );
        }(),
      OptionRow(
        title: 'No translation',
        subtitle: 'Show the Arabic only',
        selected: !on,
        onTap: () {
          s.update((x) => x.show = ShowMode.arabic);
          Navigator.pop(ctx);
        },
      ),
      const SizedBox(height: 6),
      GoldButton('All translations · 40+ languages', icon: Icons.language_rounded, expand: true, onTap: () {
        Navigator.pop(ctx);
        showTranslationSheet(context);
      }),
      const Label('Quran script'),
      OptionRow(
        icon: Icons.menu_book_rounded,
        title: s.script.title,
        subtitle: 'Madani, IndoPak, Tajweed colours, Uthmani or Simple · text size',
        trailing: Icon(Icons.chevron_right_rounded, color: c.fg3),
        onTap: () {
          Navigator.pop(ctx);
          showDisplaySheet(context);
        },
      ),
    ]);
  });
}
