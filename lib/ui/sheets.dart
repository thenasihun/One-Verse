import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/theme.dart';
import '../data/catalog.dart';
import '../data/downloads.dart';
import '../data/models.dart';
import '../data/repository.dart';
import '../state/playback.dart';
import '../state/settings.dart';
import 'shell.dart';
import 'widgets/common.dart';
import 'widgets/quran_text.dart';

// ------------------------------------------------------------------ reciters

void showReciterSheet(BuildContext context, {bool voices = false}) {
  showOvSheet(context, title: voices ? 'Translation voice' : 'Choose a reciter', scroll: false, builder: (_) => _ReciterPicker(voices: voices));
}

class _ReciterPicker extends StatefulWidget {
  final bool voices;
  const _ReciterPicker({required this.voices});
  @override
  State<_ReciterPicker> createState() => _ReciterPickerState();
}

class _ReciterPickerState extends State<_ReciterPicker> {
  String q = '';
  String filter = 'All';

  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    final settings = context.watch<Settings>();
    final repo = context.watch<QuranRepository>();
    final current = widget.voices ? settings.translationVoiceId : settings.reciterId;
    final list = (widget.voices ? translationVoices : reciters).where((r) {
      final p = repo.profileOf(r);
      final hay = '${r.name} ${r.language ?? ''} ${p?.country ?? ''}'.toLowerCase();
      if (q.isNotEmpty && !hay.contains(q.toLowerCase())) return false;
      if (filter == 'Word sync') return r.hasWordSync;
      if (filter != 'All') return r.style == filter;
      return true;
    }).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextField(
        onChanged: (v) => setState(() => q = v),
        decoration: InputDecoration(
          hintText: widget.voices ? 'Search languages' : 'Search reciters or countries',
          prefixIcon: const Icon(Icons.search_rounded),
          filled: true,
          fillColor: c.raised,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c.line)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c.line)),
        ),
      ),
      if (!widget.voices)
        SizedBox(
          height: 52,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.only(top: 12), children: [
            for (final f in ['All', 'Word sync', 'Murattal', 'Mujawwad', 'Teaching'])
              Padding(padding: const EdgeInsets.only(right: 8), child: OvChip(f, selected: filter == f, onTap: () => setState(() => filter = f))),
          ]),
        ),
      Flexible(
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 28),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 130, mainAxisExtent: 168, crossAxisSpacing: 10, mainAxisSpacing: 8),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final r = list[i];
            final on = r.id == current;
            final p = repo.profileOf(r);
            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                settings.update((s) => widget.voices ? s.translationVoiceId = r.id : s.reciterId = r.id);
                context.read<Playback>().reload();
                Navigator.pop(context);
                toast(context, '${widget.voices ? 'Translation voice' : 'Now reciting'}: ${r.name}${r.hasWordSync ? ' · word-exact' : ''}');
              },
              child: Column(children: [
                Stack(clipBehavior: Clip.none, children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: on ? c.gold : Colors.transparent, width: 2)),
                    child: ReciterAvatar(r, size: 80),
                  ),
                  if (r.hasWordSync)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: -6,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: c.emerald, borderRadius: BorderRadius.circular(99), border: Border.all(color: c.surface, width: 2)),
                          child: Text('WORD SYNC', style: T.ui(8.5, w: FontWeight.w800, color: Colors.white)),
                        ),
                      ),
                    ),
                  if (on)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: CircleAvatar(radius: 12, backgroundColor: c.gold, child: Icon(Icons.check_rounded, size: 15, color: c.goldInk)),
                    ),
                ]),
                const SizedBox(height: 10),
                Text(r.name, textAlign: TextAlign.center, maxLines: 2, style: T.ui(12.5, w: FontWeight.w600, color: on ? c.gold : c.fg, height: 1.2)),
                Text(widget.voices ? r.language! : [r.style, if (p?.country != null) p!.country!].join(' · '),
                    textAlign: TextAlign.center, maxLines: 2, style: T.ui(11, color: c.fg3, height: 1.2)),
              ]),
            );
          },
        ),
      ),
    ]);
  }
}

// ------------------------------------------------------------------ translations

void showTranslationSheet(BuildContext context) {
  showOvSheet(context, title: 'Translations', scroll: false, builder: (_) => const _TranslationPicker());
}

class _TranslationPicker extends StatefulWidget {
  const _TranslationPicker();
  @override
  State<_TranslationPicker> createState() => _TranslationPickerState();
}

class _TranslationPickerState extends State<_TranslationPicker> {
  String q = '';
  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    final repo = context.watch<QuranRepository>();
    final settings = context.watch<Settings>();
    final list = repo.translationList
        .where((t) => q.isEmpty || '${t.name} ${t.englishName} ${t.language}'.toLowerCase().contains(q.toLowerCase()))
        .toList()
      ..sort((a, b) => a.language == b.language ? a.englishName.compareTo(b.englishName) : _lang(a.language).compareTo(_lang(b.language)));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextField(
        onChanged: (v) => setState(() => q = v),
        decoration: InputDecoration(
          hintText: 'Search ${repo.translationList.length} translations',
          prefixIcon: const Icon(Icons.search_rounded),
          filled: true,
          fillColor: c.raised,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c.line)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c.line)),
        ),
      ),
      Flexible(
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 28),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final t = list[i];
            final on = settings.translationId == t.id && settings.show != ShowMode.arabic;
            final header = i == 0 || list[i - 1].language != t.language;
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (header) Label(_langName(t.language)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(t.englishName, style: T.ui(14.5, w: FontWeight.w600, color: c.fg)),
                subtitle: Text(t.name, style: T.ui(12.5, color: c.fg3)),
                trailing: Icon(on ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: on ? c.gold : c.line2),
                onTap: () {
                  settings.setTranslation(t.id);
                  context.read<Playback>().reload();
                  Navigator.pop(context);
                },
              ),
            ]);
          },
        ),
      ),
    ]);
  }

  static int _lang(String l) => const ['en', 'ur', 'hi', 'bn', 'ar', 'id', 'tr', 'fr', 'es'].contains(l)
      ? const ['en', 'ur', 'hi', 'bn', 'ar', 'id', 'tr', 'fr', 'es'].indexOf(l)
      : 20 + l.codeUnitAt(0);
}

String _langName(String code) => const {
      'en': 'English', 'ur': 'Urdu', 'hi': 'Hindi', 'bn': 'Bengali', 'ar': 'Arabic', 'id': 'Indonesian', 'tr': 'Turkish',
      'fr': 'French', 'es': 'Spanish', 'de': 'German', 'ru': 'Russian', 'fa': 'Persian', 'ms': 'Malay', 'zh': 'Chinese',
      'ja': 'Japanese', 'ko': 'Korean', 'it': 'Italian', 'nl': 'Dutch', 'pt': 'Portuguese', 'sw': 'Swahili', 'ta': 'Tamil',
      'ml': 'Malayalam', 'bs': 'Bosnian', 'sq': 'Albanian', 'az': 'Azerbaijani', 'ha': 'Hausa', 'so': 'Somali', 'uz': 'Uzbek',
      'tt': 'Tatar', 'sv': 'Swedish', 'no': 'Norwegian', 'pl': 'Polish', 'ro': 'Romanian', 'cs': 'Czech', 'th': 'Thai',
      'tg': 'Tajik', 'ku': 'Kurdish', 'ps': 'Pashto', 'sd': 'Sindhi', 'ug': 'Uyghur', 'dv': 'Divehi', 'si': 'Sinhala',
      'am': 'Amharic', 'bg': 'Bulgarian', 'ber': 'Amazigh', 'ce': 'Chechen', 'ky': 'Kyrgyz', 'kk': 'Kazakh', 'mk': 'Macedonian',
    }[code] ??
    code.toUpperCase();

// ------------------------------------------------------------------ script and display

void showDisplaySheet(BuildContext context) {
  showOvSheet(context, title: 'Script and reading', builder: (_) => const _DisplaySheet());
}

class _DisplaySheet extends StatelessWidget {
  const _DisplaySheet();
  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    final s = context.watch<Settings>();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Label('Quran script', padding: EdgeInsets.only(bottom: 10)),
      for (final sc in QuranScript.values)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: s.script == sc ? c.goldWash : c.raised,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: s.script == sc ? c.gold : c.line)),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => s.update((x) => x.script = sc),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(sc.title, style: T.ui(14, w: FontWeight.w700, color: c.fg)),
                      const SizedBox(height: 2),
                      Text(sc.note, style: T.ui(11.5, color: c.fg3, height: 1.35)),
                    ]),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 140,
                    child: QuranText(words: bismillahByScript[sc]!.split(' '), script: sc, fontSize: 19, maxLines: 1),
                  ),
                ]),
              ),
            ),
          ),
        ),
      if (s.script == QuranScript.tajweed)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(spacing: 12, runSpacing: 6, children: [
            for (final (rule, name) in TajweedColors.legend)
              Row(mainAxisSize: MainAxisSize.min, children: [
                CircleAvatar(radius: 4.5, backgroundColor: TajweedColors.of(rule, context.isDark)),
                const SizedBox(width: 6),
                Text(name, style: T.ui(12, color: c.fg2)),
              ]),
          ]),
        ),
      const Label('Show'),
      Segmented<ShowMode>(
        options: const [(ShowMode.both, 'Arabic +\nTranslation'), (ShowMode.arabic, 'Arabic'), (ShowMode.translation, 'Translation')],
        value: s.show,
        onChanged: (v) => s.update((x) => x.show = v),
      ),
      const Label('Arabic size'),
      _SizeSlider(value: s.arabicSize, min: 20, max: 44, onChanged: (v) => s.update((x) => x.arabicSize = v), sample: 'ع'),
      const Label('Arabic size in focus view'),
      _SizeSlider(value: s.focusSize, min: 26, max: 64, onChanged: (v) => s.update((x) => x.focusSize = v), sample: 'ع'),
      const Label('Translation size'),
      _SizeSlider(value: s.translationSize, min: 12, max: 24, onChanged: (v) => s.update((x) => x.translationSize = v), sample: 'Aa'),
      const Label('Theme'),
      Segmented<ThemeMode>(
        options: const [(ThemeMode.dark, 'Dark'), (ThemeMode.light, 'Light'), (ThemeMode.system, 'System')],
        value: s.themeMode,
        onChanged: (v) => s.update((x) => x.themeMode = v),
      ),
    ]);
  }
}

class _SizeSlider extends StatelessWidget {
  final double value, min, max;
  final ValueChanged<double> onChanged;
  final String sample;
  const _SizeSlider({required this.value, required this.min, required this.max, required this.onChanged, required this.sample});
  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    return Row(children: [
      Text(sample, style: TextStyle(fontFamily: sample == 'Aa' ? AppFonts.ui : 'UthmanicHafs', fontSize: 16, color: c.fg2)),
      Expanded(child: Slider(value: value.clamp(min, max), min: min, max: max, divisions: (max - min).round(), onChanged: onChanged)),
      SizedBox(width: 30, child: Text('${value.round()}', textAlign: TextAlign.right, style: T.ui(13, color: c.fg2))),
    ]);
  }
}

// ------------------------------------------------------------------ sleep, jump, resume

void showSleepSheet(BuildContext context) {
  final pb = context.read<Playback>();
  showOvSheet(context, title: 'Sleep timer', builder: (ctx) {
    final c = ctx.ov;
    final opts = <(String, Duration?, bool)>[
      ('Off', null, false),
      ('5 minutes', const Duration(minutes: 5), false),
      ('15 minutes', const Duration(minutes: 15), false),
      ('30 minutes', const Duration(minutes: 30), false),
      ('1 hour', const Duration(hours: 1), false),
      ('End of surah', null, true),
    ];
    return Column(children: [
      for (final o in opts)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(o.$1, style: T.ui(15, w: FontWeight.w600, color: c.fg)),
          trailing: Icon(Icons.chevron_right_rounded, color: c.fg3),
          onTap: () {
            pb.setSleep(after: o.$2, endOfSurah: o.$3);
            Navigator.pop(ctx);
            toast(context, o.$1 == 'Off' ? 'Sleep timer off' : 'Sleep timer: ${o.$1.toLowerCase()}');
          },
        ),
    ]);
  });
}

void showJumpSheet(BuildContext context, int surah, void Function(int ayah) onPick) {
  final repo = context.read<QuranRepository>();
  final pb = context.read<Playback>();
  final s = repo.surah(surah);
  showOvSheet(context, title: 'Go to ayah · ${s.nameEn}', builder: (ctx) {
    final c = ctx.ov;
    return GridView.count(
      crossAxisCount: 6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.3,
      children: [
        for (var a = 1; a <= s.ayahs; a++)
          Material(
            color: pb.surah == surah && pb.ayah == a ? c.gold : c.raised,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.pop(ctx);
                onPick(a);
              },
              child: Center(
                child: Text('$a', style: T.ui(13.5, w: FontWeight.w700, color: pb.surah == surah && pb.ayah == a ? c.goldInk : c.fg)),
              ),
            ),
          ),
      ],
    );
  });
}

void showResumeSheet(BuildContext context) {
  final pb = context.read<Playback>();
  final repo = context.read<QuranRepository>();
  final s = context.read<Settings>();
  final info = repo.surah(pb.surah);
  showOvSheet(context, title: 'Welcome back', builder: (ctx) {
    final c = ctx.ov;
    String rep() => s.repeat == 0 ? 'Repeat off' : s.repeat < 0 ? 'Repeat ∞' : 'Repeat ${s.repeat}×';
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Art(
        seed: pb.surah,
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Text(info.nameAr, style: T.kufi(28, color: Colors.white)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${info.nameEn} · Ayah ${pb.ayah}', style: T.ui(16, w: FontWeight.w700, color: Colors.white)),
              Text('${fmtDur(Duration(milliseconds: s.prefs.getInt('session_pos') ?? 0))} into the ayah · saved when you left',
                  style: T.ui(12.5, color: Colors.white70)),
            ]),
          ),
        ]),
      ),
      const Label('Your settings are kept'),
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final t in [
          s.reciter.name,
          ['Arabic', 'Arabic + Translation', 'Translation'][s.listenMode.index],
          repo.translationById(s.translationId).englishName,
          '${s.script.short} script',
          '${s.speed}× speed',
          rep(),
        ])
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: c.raised, borderRadius: BorderRadius.circular(99), border: Border.all(color: c.line)),
            child: Text(t, style: T.ui(12, w: FontWeight.w600, color: c.fg2)),
          ),
      ]),
      const SizedBox(height: 18),
      GoldButton('Resume listening', icon: Icons.play_arrow_rounded, expand: true, onTap: () {
        Navigator.pop(ctx);
        pb.toggle();
        Nav.nowPlaying(context);
      }),
      const SizedBox(height: 8),
      GhostButton('Just open the app', expand: true, onTap: () => Navigator.pop(ctx)),
    ]);
  });
}

// ------------------------------------------------------------------ download

void showDownloadSheet(BuildContext context, int surah) {
  final dl = context.read<Downloads>();
  if (!dl.supported) {
    toast(context, 'Downloads are available in the Android and iOS app');
    return;
  }
  showOvSheet(context, title: 'Download ${context.read<QuranRepository>().surah(surah).nameEn}', builder: (_) => _DownloadSheet(surah));
}

class _DownloadSheet extends StatefulWidget {
  final int surah;
  const _DownloadSheet(this.surah);
  @override
  State<_DownloadSheet> createState() => _DownloadSheetState();
}

class _DownloadSheetState extends State<_DownloadSheet> {
  late Set<String> texts;
  bool voice = false;

  @override
  void initState() {
    super.initState();
    final s = context.read<Settings>();
    texts = {s.translationId};
    voice = s.listenMode != ListenMode.arabic;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    final s = context.watch<Settings>();
    final dl = context.watch<Downloads>();
    final repo = context.read<QuranRepository>();
    final info = repo.surah(widget.surah);
    final job = dl.jobs[widget.surah];
    final done = dl.recordFor(widget.surah, s.reciterId);
    final r = s.reciter;
    final estimate = info.ayahs * 0.3 + (voice ? info.ayahs * 0.2 : 0) + 0.05 * (texts.length + 1);

    Widget row(String title, String sub, {bool on = true, String? lock, VoidCallback? onTap}) => InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: T.ui(14.5, w: FontWeight.w600, color: c.fg)),
                  Text(sub, style: T.ui(12.5, color: c.fg3)),
                ]),
              ),
              if (lock != null)
                Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: c.emeraldWash, borderRadius: BorderRadius.circular(99)),
                  child: Text(lock.toUpperCase(), style: T.ui(10, w: FontWeight.w800, color: c.emerald)),
                ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: on ? c.gold : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: on ? c.gold : c.line2, width: 2),
                ),
                child: on ? Icon(Icons.check_rounded, size: 15, color: c.goldInk) : null,
              ),
            ]),
          ),
        );

    if (done != null && job == null) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: c.emeraldWash, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Saved for offline', style: T.display(18, w: FontWeight.w700, color: c.emerald)),
                Text('${fmtBytes(done.bytes)} · ${r.name} · all five scripts', style: T.ui(12.5, color: c.fg2)),
              ]),
            ),
            CircleAvatar(backgroundColor: c.emerald, child: const Icon(Icons.check_rounded, color: Colors.white)),
          ]),
        ),
        const SizedBox(height: 10),
        for (final t in done.translations) row(repo.translationById(t).englishName, 'Translation text · complete surah', lock: 'Offline'),
        if (done.voiceId != null) row(reciterById(done.voiceId).name, 'Translation audio', lock: 'Offline'),
        const SizedBox(height: 12),
        GhostButton('Remove download', icon: Icons.delete_outline_rounded, expand: true, onTap: () async {
          await dl.remove(done);
          if (context.mounted) toast(context, 'Removed');
        }),
      ]);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      row(r.name, '${r.hasWordSync ? 'Full-surah recitation with word timings' : 'Recitation, ${info.ayahs} ayahs'} · ~${(info.ayahs * 0.3).toStringAsFixed(1)} MB',
          lock: 'Required'),
      row('Quran text', 'All five scripts, so any script works offline', lock: 'Included'),
      for (final t in {s.translationId, ...s.quickTranslations})
        row(repo.translationById(t).englishName, 'Translation text · complete surah',
            on: texts.contains(t),
            lock: t == s.translationId ? 'Your translation' : null,
            onTap: t == s.translationId ? null : () => setState(() => texts.contains(t) ? texts.remove(t) : texts.add(t))),
      row('${s.translationVoice.name} · ${s.translationVoice.language}', 'Translation audio · ~${(info.ayahs * 0.2).toStringAsFixed(1)} MB',
          on: voice, onTap: () => setState(() => voice = !voice)),
      const SizedBox(height: 10),
      if (job != null) ...[
        ValueListenableBuilder<double>(
          valueListenable: job.progress,
          builder: (_, v, _) => ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: v, minHeight: 6, color: c.emerald, backgroundColor: c.line2),
          ),
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<String>(valueListenable: job.step, builder: (_, v, _) => Text(v, style: T.ui(12.5, color: c.fg3))),
        const SizedBox(height: 12),
        GhostButton('Cancel', expand: true, onTap: () => dl.cancel(widget.surah)),
      ] else
        GoldButton('Download ~${estimate.toStringAsFixed(1)} MB', icon: Icons.download_rounded, expand: true, onTap: () async {
          try {
            await dl.download(surah: widget.surah, reciter: r, translations: texts.toList(), voice: voice ? s.translationVoice : null);
            if (context.mounted) toast(context, '${info.nameEn} is ready offline');
          } catch (e) {
            if (context.mounted) toast(context, 'Download stopped. ${e is Exception ? 'Check your connection.' : ''}');
          }
        }),
    ]);
  }
}

// ------------------------------------------------------------------ share

Future<void> shareAyah(BuildContext context, int surah, int ayah) async {
  final repo = context.read<QuranRepository>();
  final s = context.read<Settings>();
  try {
    final v = (await repo.words(surah))[ayah - 1];
    final tr = (await repo.translation(s.translationId, surah))[ayah - 1];
    final info = repo.surah(surah);
    await SharePlus.instance.share(ShareParams(
      text: '${v.plain(QuranScript.uthmani)}\n\n$tr\n\n— ${info.nameEn} $surah:$ayah · One Verse',
    ));
  } catch (_) {
    if (context.mounted) toast(context, 'Could not share this ayah offline yet');
  }
}
