import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/theme.dart';
import '../data/catalog.dart';
import '../data/downloads.dart';
import '../data/exporter.dart';
import '../data/ffmpeg_runner.dart';
import '../data/models.dart';
import '../data/repository.dart';
import '../state/settings.dart';
import 'sheets.dart';
import 'widgets/common.dart';
import 'widgets/quran_text.dart';

const _storeLink = 'https://play.google.com/store/apps/details?id=com.nasihun.oneverse';

enum ShareFormat { image, video, audio, text }

enum CardStyle {
  surah('Surah colours', null, false),
  emerald('Emerald', [Color(0xFF0B5D47), Color(0xFF032A21)], false),
  night('Night', [Color(0xFF1B2A4A), Color(0xFF070B1A)], false),
  sand('Sand', [Color(0xFFF7EEDC), Color(0xFFE6D2AA)], true);

  final String label;
  final List<Color>? colors;
  final bool light;
  const CardStyle(this.label, this.colors, this.light);
}

/// The card drawn for images and videos: the ayahs, their meaning, the
/// reference, and the app's name in a corner. Laid out at 360 logical pixels
/// wide and captured at 3× (1080 px).
class ShareCard extends StatelessWidget {
  final SurahInfo info;
  final List<VerseText> verses;
  final List<String>? translations; // one per verse, or null
  final TranslationEdition edition;
  final QuranScript script;
  final CardStyle style;
  final bool story;
  const ShareCard({super.key, required this.info, required this.verses, this.translations, required this.edition, required this.script, required this.style, required this.story});

  static const width = 360.0;
  double get height => story ? 640 : 360;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.build(style.light ? Brightness.light : Brightness.dark);
    final s = script == QuranScript.tajweed ? QuranScript.uthmani : script;
    final arLen = verses.fold<int>(0, (n, v) => n + v.plain(s).length);
    final trLen = translations?.fold<int>(0, (n, t) => n + t.length) ?? 0;
    // Shrink long passages so they fit the card.
    final room = story ? 1.0 : 0.62;
    final arSize = (30 * math.sqrt(120 / math.max(arLen, 40)) * room).clamp(13.0, story ? 40.0 : 26.0);
    final trSize = (15 * math.sqrt(220 / math.max(trLen, 60)) * (story ? 1.0 : 0.8)).clamp(8.5, 15.5);
    final first = verses.first.ayah, last = verses.last.ayah;
    final ref = first == last ? '${info.number}:$first' : '${info.number}:$first–$last';
    final ink = style.light ? const Color(0xFF2A2116) : Colors.white;
    final accent = style.light ? const Color(0xFF8A5A12) : const Color(0xFFE9C46A);
    return Theme(
      data: theme,
      child: Material(
        type: MaterialType.transparency,
        child: SizedBox(
        width: width,
        height: height,
        child: Art(
          seed: info.number,
          colors: style.colors,
          radius: BorderRadius.zero,
          padding: EdgeInsets.fromLTRB(26, story ? 46 : 20, 26, story ? 22 : 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(info.nameAr, textAlign: TextAlign.center, style: T.kufi(story ? 30 : 22, color: accent)),
            Text('${info.nameEn.toUpperCase()}  ·  $ref', textAlign: TextAlign.center,
                style: T.ui(story ? 10.5 : 9, w: FontWeight.w700, color: ink.withValues(alpha: 0.75)).copyWith(letterSpacing: 1.6)),
            // The passage is scaled down as a whole when it is too tall.
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: width - 52,
                    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final v in verses)
              QuranText(words: v.of(s), script: s, fontSize: arSize, ayahNumber: v.ayah, align: TextAlign.center),
            if (translations != null) ...[
              SizedBox(height: story ? 16 : 8),
              Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 90), color: accent.withValues(alpha: 0.5)),
              SizedBox(height: story ? 14 : 8),
              for (final (i, t) in translations!.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    verses.length > 1 ? '(${verses[i].ayah}) $t' : t,
                    textAlign: TextAlign.center,
                    textDirection: edition.rtl ? TextDirection.rtl : TextDirection.ltr,
                    style: TextStyle(
                      fontFamily: edition.urdu ? AppFonts.urdu : edition.rtl ? 'NotoNaskhArabic' : AppFonts.ui,
                      fontSize: edition.urdu ? trSize + 1 : trSize,
                      height: edition.urdu ? 2.0 : 1.5,
                      color: ink.withValues(alpha: 0.88),
                    ),
                  ),
                ),
            ],
                    ]),
                  ),
                ),
              ),
            ),
            Row(children: [
              Text(edition.englishName.isEmpty || translations == null ? '' : edition.englishName,
                  style: T.ui(story ? 8.5 : 7.5, color: ink.withValues(alpha: 0.55))),
              const Spacer(),
              ClipOval(child: Image.asset('assets/images/logo.png', width: story ? 22 : 18, height: story ? 22 : 18, fit: BoxFit.cover)),
              const SizedBox(width: 6),
              Text('One Verse', style: T.display(story ? 13 : 11, w: FontWeight.w700, color: ink)),
            ]),
          ]),
        ),
        ),
      ),
    );
  }
}

class ShareStudio extends StatefulWidget {
  final int surah, ayah;
  const ShareStudio({super.key, required this.surah, required this.ayah});

  static void open(BuildContext context, int surah, int ayah) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => ShareStudio(surah: surah, ayah: ayah)));

  @override
  State<ShareStudio> createState() => _ShareStudioState();
}

class _ShareStudioState extends State<ShareStudio> {
  final _card = GlobalKey();
  late int from = widget.ayah, to = widget.ayah;
  ShareFormat format = ShareFormat.image;
  CardStyle style = CardStyle.surah;
  bool story = true, showTr = true, hearTr = false;
  List<VerseText> verses = const [];
  List<String>? tr;
  int? _cardAyah; // while rendering video cards: the one ayah shown
  Exporter? _ex;
  String? _busy;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<QuranRepository>();
    final s = context.read<Settings>();
    try {
      final v = await repo.words(widget.surah);
      List<String>? t;
      try {
        t = await repo.translation(s.translationId, widget.surah);
      } catch (_) {}
      if (mounted) {
        setState(() {
          verses = v;
          tr = t;
        });
      }
    } catch (_) {
      if (mounted) toast(context, 'This surah is not on the phone yet. Connect to the internet once.');
    }
  }

  Exporter get ex => _ex ??= Exporter(context.read<QuranRepository>(), context.read<Downloads>(), run: kIsWeb ? null : runFfmpegKit);

  SurahInfo get info => context.read<QuranRepository>().surah(widget.surah);
  int get count => to - from + 1;
  int get maxImage => 5;

  List<VerseText> get shown {
    if (verses.isEmpty) return const [];
    final a = _cardAyah;
    return a != null ? [verses[a - 1]] : verses.sublist(from - 1, to);
  }

  String? get problem {
    final s = context.read<Settings>();
    if (kIsWeb && (format == ShareFormat.video || format == ShareFormat.audio)) return 'Audio and video sharing work in the Android and iOS app.';
    if (format == ShareFormat.image && count > maxImage) return 'An image holds up to $maxImage ayahs. Choose fewer, or share audio.';
    if (format == ShareFormat.video && count > Exporter.maxVideoAyahs) return 'A video holds up to ${Exporter.maxVideoAyahs} ayahs. Choose fewer, or share audio.';
    if (hearTr && (format == ShareFormat.audio || format == ShareFormat.video) && voiceFor(s.translationId)?.ayahEdition == null) {
      return 'Your translation has no audio. Pick an Urdu, English or other voiced translation to hear it.';
    }
    return null;
  }

  ExportRequest _request() {
    final s = context.read<Settings>();
    final voice = hearTr ? voiceFor(s.translationId) : null;
    return ExportRequest(surah: widget.surah, from: from, to: to, reciter: s.reciter, voice: voice);
  }

  Future<String> _capture(String name) async {
    await WidgetsBinding.instance.endOfFrame;
    final boundary = _card.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
    final dir = Directory('${(await getTemporaryDirectory()).path}/oneverse_share/out');
    await dir.create(recursive: true);
    final f = File('${dir.path}/$name.png');
    await f.writeAsBytes(bytes);
    return f.path;
  }

  String get _title => Exporter.fileTitle(info, ExportRequest(surah: widget.surah, from: from, to: to, reciter: context.read<Settings>().reciter));

  Future<String?> _make() async {
    final s = context.read<Settings>();
    switch (format) {
      case ShareFormat.image:
        setState(() => _busy = 'Drawing the image…');
        return _capture(Exporter.safeName('$_title - One Verse'));
      case ShareFormat.audio:
        setState(() => _busy = 'Preparing the audio…');
        return (await ex.audio(_request())).path;
      case ShareFormat.video:
        setState(() => _busy = 'Making the video…');
        final f = await ex.video(_request(), (a) async {
          setState(() => _cardAyah = a);
          return _capture('card_$a');
        });
        if (mounted) setState(() => _cardAyah = null);
        return f.path;
      case ShareFormat.text:
        final text = StringBuffer();
        for (var a = from; a <= to; a++) {
          text.writeln(verses[a - 1].plain(QuranScript.uthmani));
          if (showTr && tr != null) text.writeln(tr![a - 1]);
          text.writeln();
        }
        text.write('— ${info.nameEn} ${from == to ? '${widget.surah}:$from' : '${widget.surah}:$from-$to'} · ${s.reciter.name}\nOne Verse: $_storeLink');
        await SharePlus.instance.share(ShareParams(text: text.toString()));
        return null;
    }
  }

  Future<void> _go({required bool save}) async {
    final p = problem;
    if (p != null) return toast(context, p);
    try {
      final path = await _make();
      if (path == null || !mounted) return;
      if (save) {
        final saved = await FlutterFileDialog.saveFile(params: SaveFileDialogParams(sourceFilePath: path));
        if (saved != null && mounted) toast(context, 'Saved');
      } else {
        await SharePlus.instance.share(ShareParams(
          files: [XFile(path)],
          text: '${info.nameEn} ${from == to ? '${widget.surah}:$from' : '${widget.surah}:$from-$to'} · shared from One Verse\n$_storeLink',
        ));
      }
    } on ExportException catch (e) {
      if (mounted) toast(context, e.message);
    } catch (e) {
      if (mounted) toast(context, 'Could not prepare this. ${e.toString().split('\n').first}');
    } finally {
      if (mounted) {
        setState(() {
          _busy = null;
          _cardAyah = null;
        });
      }
    }
  }

  void _setRange(int a, int b) => setState(() {
        from = a.clamp(1, info.ayahs);
        to = b.clamp(from, info.ayahs);
      });

  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    final s = context.watch<Settings>();
    final repo = context.read<QuranRepository>();
    final edition = repo.translationById(s.translationId);
    final voice = voiceFor(s.translationId);
    final visual = format == ShareFormat.image || format == ShareFormat.video;
    final shownVerses = shown;
    final card = shownVerses.isEmpty
        ? const SizedBox()
        : RepaintBoundary(
            key: _card,
            child: ShareCard(
              info: info,
              verses: shownVerses,
              translations: showTr && tr != null ? [for (final v in shownVerses) tr![v.ayah - 1]] : null,
              edition: edition,
              script: s.script,
              style: style,
              story: story,
            ),
          );
    return Scaffold(
      appBar: AppBar(
        backgroundColor: c.bg,
        title: Text('Share · ${info.nameEn}', style: T.display(19, w: FontWeight.w700, color: c.fg)),
      ),
      body: Stack(children: [
        Column(children: [
          // Preview
          SizedBox(
            height: visual ? MediaQuery.sizeOf(context).height * 0.38 : 0,
            child: visual
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: ClipRRect(borderRadius: BorderRadius.circular(14), child: FittedBox(child: card)),
                    ),
                  )
                : null,
          ),
          if (!visual)
            // The card is still laid out off screen for the capture code.
            Offstage(child: card),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 120), children: [
              Segmented<ShareFormat>(
                options: const [(ShareFormat.image, 'Image'), (ShareFormat.video, 'Video'), (ShareFormat.audio, 'Audio'), (ShareFormat.text, 'Text')],
                value: format,
                onChanged: (v) => setState(() => format = v),
              ),
              const Label('Ayahs'),
              Row(children: [
                _Stepper(label: 'From', value: from, onChanged: (v) => _setRange(v, math.max(v, to)), max: info.ayahs),
                const SizedBox(width: 10),
                _Stepper(label: 'To', value: to, onChanged: (v) => _setRange(math.min(from, v), v), max: info.ayahs),
              ]),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                OvChip('This ayah', selected: count == 1 && from == widget.ayah, onTap: () => _setRange(widget.ayah, widget.ayah)),
                OvChip('${math.min(5, info.ayahs - widget.ayah + 1)} ayahs from here',
                    selected: from == widget.ayah && to == math.min(info.ayahs, widget.ayah + 4) && count > 1,
                    onTap: () => _setRange(widget.ayah, widget.ayah + 4)),
                OvChip('Whole surah', selected: from == 1 && to == info.ayahs, onTap: () => _setRange(1, info.ayahs)),
              ]),
              if (visual) ...[
                const Label('Size'),
                Segmented<bool>(options: const [(true, 'Story · status'), (false, 'Square · post')], value: story, onChanged: (v) => setState(() => story = v)),
                const Label('Style'),
                SizedBox(
                  height: 64,
                  child: ListView(scrollDirection: Axis.horizontal, children: [
                    for (final st in CardStyle.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Semantics(
                          button: true,
                          selected: st == style,
                          label: 'Style ${st.label}',
                          child: GestureDetector(
                            onTap: () => setState(() => style = st),
                            child: Container(
                              width: 92,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: st == style ? c.gold : c.line, width: st == style ? 2.5 : 1),
                                gradient: LinearGradient(colors: st.colors ?? artFor(widget.surah)),
                              ),
                              alignment: Alignment.center,
                              child: Text(st.label, style: T.ui(11.5, w: FontWeight.w700, color: st.light ? const Color(0xFF2A2116) : Colors.white)),
                            ),
                          ),
                        ),
                      ),
                  ]),
                ),
              ],
              const Label('Translation'),
              if (format != ShareFormat.audio)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeTrackColor: c.gold,
                  value: showTr && tr != null,
                  onChanged: tr == null ? null : (v) => setState(() => showTr = v),
                  title: Text(format == ShareFormat.text ? 'Add the translation' : 'Show the translation', style: T.ui(14.5, w: FontWeight.w600, color: c.fg)),
                  subtitle: Text(edition.englishName, style: T.ui(12, color: c.fg3)),
                ),
              if (format == ShareFormat.audio || format == ShareFormat.video)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeTrackColor: c.gold,
                  value: hearTr,
                  onChanged: (v) => setState(() => hearTr = v),
                  title: Text('Hear the translation after each ayah', style: T.ui(14.5, w: FontWeight.w600, color: c.fg)),
                  subtitle: Text(voice != null ? 'Read by ${voice.name} (${voice.language})' : 'This translation has no audio', style: T.ui(12, color: c.fg3)),
                ),
              PickerChip(label: 'Change translation', icon: Icons.translate_rounded, onTap: () => showTranslationSheet(context)),
              if (format == ShareFormat.audio || format == ShareFormat.video) ...[
                const Label('Reciter'),
                Material(
                  color: c.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: c.line)),
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    leading: ReciterAvatar(s.reciter, size: 40),
                    title: Text(s.reciter.name, style: T.ui(14.5, w: FontWeight.w700, color: c.fg)),
                    subtitle: Text(s.reciter.syncLabel, style: T.ui(12, color: c.fg3)),
                    trailing: Text('Change', style: T.ui(12.5, w: FontWeight.w700, color: c.gold)),
                    onTap: () => showReciterSheet(context),
                  ),
                ),
              ],
              if (problem != null)
                Padding(padding: const EdgeInsets.only(top: 14), child: Text(problem!, style: T.ui(13, color: c.gold))),
            ]),
          ),
        ]),
        // Actions, within thumb reach.
        Positioned(
          left: 16,
          right: 16,
          bottom: 16 + MediaQuery.paddingOf(context).bottom,
          child: Row(children: [
            if (format != ShareFormat.text && !kIsWeb) ...[
              Expanded(child: GhostButton('Save to phone', icon: Icons.download_rounded, expand: true, onTap: _busy == null ? () => _go(save: true) : null)),
              const SizedBox(width: 10),
            ],
            Expanded(
              flex: 2,
              child: GoldButton(
                switch (format) {
                  ShareFormat.image => 'Share image',
                  ShareFormat.video => 'Share video',
                  ShareFormat.audio => 'Share audio',
                  ShareFormat.text => 'Share text',
                },
                icon: Icons.ios_share_rounded,
                expand: true,
                onTap: _busy == null ? () => _go(save: false) : null,
              ),
            ),
          ]),
        ),
        if (_busy != null)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black54,
              child: Center(
                child: Container(
                  width: 280,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(20)),
                  child: ValueListenableBuilder<double?>(
                    valueListenable: ex.progress,
                    builder: (_, v, _) => Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(_busy!, style: T.ui(15, w: FontWeight.w700, color: c.fg)),
                      const SizedBox(height: 14),
                      LinearProgressIndicator(value: v, color: c.gold, backgroundColor: c.line),
                      const SizedBox(height: 8),
                      Text(v == null ? '' : '${(v * 100).round()}%', style: T.ui(12, color: c.fg3)),
                    ]),
                  ),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

class _Stepper extends StatelessWidget {
  final String label;
  final int value, max;
  final ValueChanged<int> onChanged;
  const _Stepper({required this.label, required this.value, required this.max, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(color: c.raised, borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          Text('${label.toUpperCase()} AYAH', style: T.label(c.fg3).copyWith(fontSize: 10.5)),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            RoundIcon(Icons.remove_rounded, tooltip: '$label: one less', size: 40, onTap: value > 1 ? () => onChanged(value - 1) : null),
            SizedBox(width: 48, child: Text('$value', textAlign: TextAlign.center, style: T.display(22, w: FontWeight.w700, color: c.fg))),
            RoundIcon(Icons.add_rounded, tooltip: '$label: one more', size: 40, onTap: value < max ? () => onChanged(value + 1) : null),
          ]),
        ]),
      ),
    );
  }
}
