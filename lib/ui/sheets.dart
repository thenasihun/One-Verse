import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../data/catalog.dart';
import '../data/downloads.dart';
import '../data/models.dart';
import '../data/network.dart';
import '../data/repository.dart';
import '../state/playback.dart';
import '../state/settings.dart';
import 'share_studio.dart';
import 'shell.dart';
import 'widgets/common.dart';
import 'widgets/quran_text.dart';

// ------------------------------------------------------------------ reciters

/// Picks the reciter (or translation voice). With [onPick], the choice goes
/// there instead of to the player, and [selected] is the one ticked.
void showReciterSheet(BuildContext context, {bool voices = false, ValueChanged<Reciter>? onPick, String? selected}) {
  showOvSheet(context,
      title: voices ? 'Translation voice' : 'Choose a reciter',
      scroll: false,
      builder: (_) => _ReciterPicker(voices: voices, onPick: onPick, selected: selected));
}

class _ReciterPicker extends StatefulWidget {
  final bool voices;
  final ValueChanged<Reciter>? onPick;
  final String? selected;
  const _ReciterPicker({required this.voices, this.onPick, this.selected});
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
    final current = widget.selected ?? (widget.voices ? settings.translationVoiceId : settings.reciterId);
    final list = (widget.voices ? translationVoices : reciters).where((r) {
      final p = repo.profileOf(r);
      final hay = '${r.name} ${r.language ?? ''} ${p?.country ?? ''}'.toLowerCase();
      if (q.isNotEmpty && !hay.contains(q.toLowerCase())) return false;
      if (filter == 'Word sync') return r.hasWordSync;
      if (filter == 'Favourites') return settings.isFavReciter(r.id);
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
            for (final f in ['All', 'Favourites', 'Word sync', 'Murattal', 'Mujawwad', 'Teaching'])
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
                if (widget.onPick != null) {
                  widget.onPick!(r);
                  Navigator.pop(context);
                  return;
                }
                if (widget.voices) {
                  // The text follows the voice: it reads this translation.
                  settings.setTranslation(r.textEdition!);
                } else {
                  settings.update((s) => s.reciterId = r.id);
                }
                context.read<Playback>().reload();
                Navigator.pop(context);
                toast(context, '${widget.voices ? 'Translation voice' : 'Now reciting'}: ${r.name}${widget.voices ? '' : ' · ${r.syncLabel.toLowerCase()}'}');
              },
              child: Column(children: [
                Stack(clipBehavior: Clip.none, children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: on ? c.gold : Colors.transparent, width: 2)),
                    child: ReciterAvatar(r, size: 80),
                  ),
                  if (!widget.voices)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: -6,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                              color: r.hasWordSync ? c.emerald : r.hasAyahSync ? c.emerald.withValues(alpha: 0.55) : c.raised2,
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(color: c.surface, width: 2)),
                          child: Text(r.syncLabel.toUpperCase(), style: T.ui(8.5, w: FontWeight.w800, color: r.hasAyahSync ? Colors.white : c.fg2)),
                        ),
                      ),
                    ),
                  if (on)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: CircleAvatar(radius: 12, backgroundColor: c.gold, child: Icon(Icons.check_rounded, size: 15, color: c.goldInk)),
                    ),
                  if (!widget.voices) Positioned(left: -4, top: -4, child: FavButton.reciter(r.id, size: 28)),
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

/// Language first, then its translations. Languages with translation audio,
/// and the translation each voice reads, are marked.
class _TranslationPickerState extends State<_TranslationPicker> {
  String q = '';
  String? lang;
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _pick(TranslationEdition t) {
    final settings = context.read<Settings>();
    settings.setTranslation(t.id);
    context.read<Playback>().reload();
    Navigator.pop(context);
    final v = voiceFor(t.id);
    toast(context, v == null ? '${t.englishName} · text only' : '${t.englishName} · audio: ${v.name}');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    final repo = context.watch<QuranRepository>();
    final settings = context.watch<Settings>();
    final all = repo.translationList;
    final byLang = <String, List<TranslationEdition>>{};
    for (final t in all) {
      byLang.putIfAbsent(t.language, () => []).add(t);
    }
    final query = q.trim().toLowerCase();
    final current = repo.translationById(settings.translationId);

    Widget body;
    if (lang != null) {
      final list = [...?byLang[lang]]..sort((a, b) {
          final ea = exactVoiceFor(a.id) != null, eb = exactVoiceFor(b.id) != null;
          return ea != eb ? (ea ? -1 : 1) : a.englishName.compareTo(b.englishName);
        });
      body = ListView(padding: const EdgeInsets.only(top: 4, bottom: 28), children: [
        Row(children: [
          RoundIcon(Icons.arrow_back_rounded, tooltip: 'All languages', onTap: () => setState(() => lang = null)),
          const SizedBox(width: 4),
          Expanded(child: Text(_langName(lang!), style: T.display(18, w: FontWeight.w700, color: c.fg))),
          Text(_nativeName(lang!), style: T.ui(14, color: c.fg3)),
        ]),
        if (voiceForLanguage(lang!) == null)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
            child: Text('No translation audio in ${_langName(lang!)} yet. You can read it while listening to the Arabic.',
                style: T.ui(12.5, color: c.fg3, height: 1.4)),
          ),
        for (final t in list) _TranslationRow(t, selected: settings.show != ShowMode.arabic && settings.translationId == t.id, onTap: () => _pick(t)),
      ]);
    } else if (query.isNotEmpty) {
      final langs = byLang.keys.where((l) => '${_langName(l)} ${_nativeName(l)} $l'.toLowerCase().contains(query)).toList()
        ..sort((a, b) => _langName(a).compareTo(_langName(b)));
      final hits = all.where((t) => '${t.name} ${t.englishName}'.toLowerCase().contains(query)).toList();
      body = ListView(padding: const EdgeInsets.only(top: 8, bottom: 28), children: [
        if (langs.isNotEmpty) const Label('Languages'),
        for (final l in langs) _LanguageRow(l, byLang[l]!.length, onTap: () => setState(() => lang = l)),
        if (hits.isNotEmpty) const Label('Translations'),
        for (final t in hits) _TranslationRow(t, showLanguage: true, selected: settings.translationId == t.id, onTap: () => _pick(t)),
        if (langs.isEmpty && hits.isEmpty)
          Padding(padding: const EdgeInsets.all(24), child: Text('Nothing matches “$q”.', textAlign: TextAlign.center, style: T.ui(13.5, color: c.fg3))),
      ]);
    } else {
      bool audio(String l) => voiceForLanguage(l) != null;
      final withAudio = byLang.keys.where(audio).toList()..sort((a, b) => _langName(a).compareTo(_langName(b)));
      final textOnly = byLang.keys.where((l) => !audio(l)).toList()..sort((a, b) => _langName(a).compareTo(_langName(b)));
      body = ListView(padding: const EdgeInsets.only(top: 8, bottom: 28), children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: c.raised, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.line)),
          child: Row(children: [
            Icon(Icons.headphones_rounded, color: c.gold, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Now: ${current.englishName}${voiceFor(current.id) != null ? ' · audio by ${voiceFor(current.id)!.name}' : ''}',
                  style: T.ui(12.5, w: FontWeight.w600, color: c.fg2)),
            ),
          ]),
        ),
        Label('With translation audio · ${withAudio.length} languages'),
        for (final l in withAudio) _LanguageRow(l, byLang[l]!.length, onTap: () => setState(() => lang = l)),
        Label('Text only · ${textOnly.length} languages'),
        for (final l in textOnly) _LanguageRow(l, byLang[l]!.length, onTap: () => setState(() => lang = l)),
      ]);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextField(
        controller: _search,
        onChanged: (v) => setState(() {
          q = v;
          if (v.isNotEmpty) lang = null;
        }),
        decoration: InputDecoration(
          hintText: 'Search a language or translator',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: q.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => setState(() {
                    q = '';
                    _search.clear();
                  }),
                ),
          filled: true,
          fillColor: c.raised,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c.line)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c.line)),
        ),
      ),
      Flexible(child: body),
    ]);
  }
}

class _LanguageRow extends StatelessWidget {
  final String lang;
  final int count;
  final VoidCallback onTap;
  const _LanguageRow(this.lang, this.count, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    final selected = languageOf(context.watch<Settings>().translationId) == lang;
    final voice = voiceForLanguage(lang);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text.rich(TextSpan(children: [
                TextSpan(text: _langName(lang), style: T.ui(15, w: FontWeight.w700, color: selected ? c.gold : c.fg)),
                TextSpan(text: '   ${_nativeName(lang)}', style: T.ui(13, color: c.fg3)),
              ])),
              Text('$count translation${count == 1 ? '' : 's'}${voice != null ? ' · audio by ${voice.name}' : ''}', style: T.ui(12, color: c.fg3)),
            ]),
          ),
          if (voice != null) const _AudioBadge(),
          Icon(Icons.chevron_right_rounded, color: c.fg3),
        ]),
      ),
    );
  }
}

class _TranslationRow extends StatelessWidget {
  final TranslationEdition t;
  final bool selected, showLanguage;
  final VoidCallback onTap;
  const _TranslationRow(this.t, {required this.selected, required this.onTap, this.showLanguage = false});

  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    final exact = exactVoiceFor(t.id);
    final other = exact == null ? voiceFor(t.id) : null;
    final note = exact != null
        ? 'Audio matches this text · ${exact.name}'
        : other != null
            ? 'Audio is another translation · ${other.name}'
            : 'Text only';
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.englishName, style: T.ui(14.5, w: FontWeight.w600, color: c.fg)),
              Text(showLanguage ? '${_langName(t.language)} · ${t.name}' : t.name,
                  style: TextStyle(fontFamily: t.urdu ? AppFonts.urdu : AppFonts.ui, fontSize: 12.5, color: c.fg3, height: t.urdu ? 1.9 : 1.3)),
              const SizedBox(height: 2),
              Text(note, style: T.ui(11.5, w: FontWeight.w600, color: exact != null ? c.gold : c.fg3)),
            ]),
          ),
          if (exact != null) const _AudioBadge(),
          Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: selected ? c.gold : c.line2),
        ]),
      ),
    );
  }
}

class _AudioBadge extends StatelessWidget {
  const _AudioBadge();
  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: c.goldWash, borderRadius: BorderRadius.circular(99)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.headphones_rounded, size: 13, color: c.gold),
        const SizedBox(width: 4),
        Text('AUDIO', style: T.ui(10, w: FontWeight.w800, color: c.gold)),
      ]),
    );
  }
}

String _nativeName(String code) => const {
      'en': 'English', 'ur': 'اردو', 'hi': 'हिन्दी', 'bn': 'বাংলা', 'ar': 'العربية', 'id': 'Bahasa Indonesia', 'tr': 'Türkçe',
      'fr': 'Français', 'es': 'Español', 'de': 'Deutsch', 'ru': 'Русский', 'fa': 'فارسی', 'ms': 'Bahasa Melayu', 'zh': '中文',
      'ja': '日本語', 'ko': '한국어', 'it': 'Italiano', 'nl': 'Nederlands', 'pt': 'Português', 'sw': 'Kiswahili', 'ta': 'தமிழ்',
      'ml': 'മലയാളം', 'bs': 'Bosanski', 'sq': 'Shqip', 'az': 'Azərbaycan', 'ha': 'Hausa', 'so': 'Soomaali', 'uz': 'Oʻzbek',
      'tt': 'Татарча', 'sv': 'Svenska', 'no': 'Norsk', 'pl': 'Polski', 'ro': 'Română', 'cs': 'Čeština', 'th': 'ไทย',
      'tg': 'Тоҷикӣ', 'ku': 'Kurdî', 'ps': 'پښتو', 'sd': 'سنڌي', 'ug': 'ئۇيغۇرچە', 'dv': 'ދިވެހި', 'si': 'සිංහල',
      'am': 'አማርኛ', 'bg': 'Български', 'ber': 'Tamaziɣt', 'ce': 'Нохчийн', 'ky': 'Кыргызча', 'kk': 'Қазақша', 'mk': 'Македонски',
      'ba': 'Башҡорт', 'my': 'မြန်မာ', 'he': 'עברית',
    }[code] ??
    '';

String _langName(String code) => const {
      'en': 'English', 'ur': 'Urdu', 'hi': 'Hindi', 'bn': 'Bengali', 'ar': 'Arabic', 'id': 'Indonesian', 'tr': 'Turkish',
      'fr': 'French', 'es': 'Spanish', 'de': 'German', 'ru': 'Russian', 'fa': 'Persian', 'ms': 'Malay', 'zh': 'Chinese',
      'ja': 'Japanese', 'ko': 'Korean', 'it': 'Italian', 'nl': 'Dutch', 'pt': 'Portuguese', 'sw': 'Swahili', 'ta': 'Tamil',
      'ml': 'Malayalam', 'bs': 'Bosnian', 'sq': 'Albanian', 'az': 'Azerbaijani', 'ha': 'Hausa', 'so': 'Somali', 'uz': 'Uzbek',
      'tt': 'Tatar', 'sv': 'Swedish', 'no': 'Norwegian', 'pl': 'Polish', 'ro': 'Romanian', 'cs': 'Czech', 'th': 'Thai',
      'tg': 'Tajik', 'ku': 'Kurdish', 'ps': 'Pashto', 'sd': 'Sindhi', 'ug': 'Uyghur', 'dv': 'Divehi', 'si': 'Sinhala',
      'am': 'Amharic', 'bg': 'Bulgarian', 'ber': 'Amazigh', 'ce': 'Chechen', 'ky': 'Kyrgyz', 'kk': 'Kazakh', 'mk': 'Macedonian',
      'ba': 'Bashkir', 'my': 'Burmese', 'he': 'Hebrew',
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
                    child: QuranText(words: splitWords(bismillahByScript[sc]!), script: sc, fontSize: 19, maxLines: 1),
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

    Widget row(String title, String sub, {bool on = true, String? lock, VoidCallback? onTap}) =>
        _OptionRow(title, sub, on: on, lock: lock, onTap: onTap);

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
      row(r.name, '${r.timing != null ? 'Full-surah recitation · ${r.syncLabel.toLowerCase()}' : 'Recitation, ${info.ayahs} ayahs'} · ~${(info.ayahs * 0.3).toStringAsFixed(1)} MB',
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
      if (job == null)
        TextButton.icon(
          onPressed: () {
            final nav = Navigator.of(context);
            nav.pop();
            showQuranDownloadSheet(nav.context);
          },
          icon: Icon(Icons.library_books_rounded, size: 18, color: c.gold),
          label: Text('Download the complete Quran instead', style: T.ui(13.5, w: FontWeight.w700, color: c.gold)),
        ),
    ]);
  }
}

/// A row with a checkbox, or a badge such as "Included", in download sheets.
class _OptionRow extends StatelessWidget {
  final String title, sub;
  final bool on;
  final String? lock;
  final VoidCallback? onTap;
  const _OptionRow(this.title, this.sub, {this.on = true, this.lock, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    return InkWell(
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
              child: Text(lock!.toUpperCase(), style: T.ui(10, w: FontWeight.w800, color: c.emerald)),
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
  }
}

// ------------------------------------------------------------------ complete Quran

void showQuranDownloadSheet(BuildContext context) {
  if (!context.read<Downloads>().supported) {
    toast(context, 'Downloads are available in the Android and iOS app');
    return;
  }
  showOvSheet(context, title: 'Download the complete Quran', builder: (_) => const _QuranDownloadSheet());
}

class _QuranDownloadSheet extends StatefulWidget {
  const _QuranDownloadSheet();
  @override
  State<_QuranDownloadSheet> createState() => _QuranDownloadSheetState();
}

class _QuranDownloadSheetState extends State<_QuranDownloadSheet> {
  late bool voice;
  bool wifiOnly = true;
  String? _sizeKey;
  Future<int?>? _size;

  @override
  void initState() {
    super.initState();
    voice = context.read<Settings>().listenMode != ListenMode.arabic;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    final s = context.watch<Settings>();
    final dl = context.watch<Downloads>();
    final net = context.watch<NetworkStatus>();
    final repo = context.read<QuranRepository>();
    final r = s.reciter;
    final v = s.translationVoice;
    final key = '${r.id}|${voice ? v.id : ''}';
    if (key != _sizeKey) {
      _sizeKey = key;
      _size = dl.estimateQuranBytes(r, voice: voice ? v : null);
    }
    final saved = dl.records.where((x) => x.reciterId == r.id).length;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Art(
        seed: 'quran',
        radius: BorderRadius.circular(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 112),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text('114 surahs · 6,236 ayahs', style: T.display(20, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Listen anywhere, with no internet', style: T.ui(13, color: Colors.white.withValues(alpha: 0.85))),
                ]),
              ),
              const SizedBox(width: 10),
              Text('القرآن', style: TextStyle(fontFamily: 'UthmanicHafs', fontSize: 40, color: Colors.white.withValues(alpha: 0.92))),
            ]),
          ),
        ),
      ),
      const SizedBox(height: 14),
      InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => showReciterSheet(context),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: c.raised, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.line)),
          child: Row(children: [
            ReciterAvatar(r, size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.name, style: T.ui(15, w: FontWeight.w700, color: c.fg)),
                Text(
                    '${r.timing != null ? 'Full surahs · ${r.syncLabel.toLowerCase()}' : 'Ayah by ayah'}${saved > 0 ? ' · $saved already saved' : ''}',
                    style: T.ui(12.5, color: c.fg3)),
              ]),
            ),
            Text('Change', style: T.ui(13.5, w: FontWeight.w700, color: c.gold)),
          ]),
        ),
      ),
      const SizedBox(height: 4),
      _OptionRow('Quran text', 'All five scripts, so any script works offline', lock: 'Included'),
      _OptionRow(repo.translationById(s.translationId).englishName, 'Translation text, all 114 surahs', lock: 'Included'),
      _OptionRow('${v.name} · ${v.language}', 'Translation audio after each ayah', on: voice, onTap: () => setState(() => voice = !voice)),
      _OptionRow('Wi-Fi only', 'Pauses on mobile data and carries on when Wi-Fi is back',
          on: wifiOnly, onTap: () => setState(() => wifiOnly = !wifiOnly)),
      const SizedBox(height: 6),
      FutureBuilder<int?>(
        future: _size,
        builder: (_, snap) {
          final b = snap.data;
          final text = snap.connectionState != ConnectionState.done
              ? 'Working out the size…'
              : b == null
                  ? 'Size unknown offline'
                  : 'About ${fmtBytes(b)} · make sure your phone has room for it';
          return Row(children: [
            Icon(Icons.sd_storage_rounded, size: 18, color: c.fg3),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: T.ui(12.5, color: c.fg2))),
          ]);
        },
      ),
      const SizedBox(height: 6),
      Text('Saved surahs are skipped. Pause any time; it carries on from where it stopped, even after the app is closed.',
          style: T.ui(12, color: c.fg3, height: 1.4)),
      const SizedBox(height: 14),
      FutureBuilder<int?>(
        future: _size,
        builder: (_, snap) => GoldButton(
          snap.data == null ? 'Download complete Quran' : 'Download · ${fmtBytes(snap.data!)}',
          icon: Icons.download_for_offline_rounded,
          expand: true,
          onTap: () async {
            await dl.startQuran(QuranPlan(r.id, [s.translationId], voice ? v.id : null, wifiOnly: wifiOnly));
            if (!context.mounted) return;
            Navigator.pop(context);
            toast(context, wifiOnly && !net.unmetered ? 'Will download when you are on Wi-Fi' : 'Downloading the complete Quran');
          },
        ),
      ),
    ]);
  }
}

// ------------------------------------------------------------------ share

/// Opens the share studio: image, video, audio or text, for one ayah or
/// a passage.
Future<void> shareAyah(BuildContext context, int surah, int ayah) async => ShareStudio.open(context, surah, ayah);

/// English name of a language code, e.g. 'ur' → 'Urdu'.
String languageName(String code) => _langName(code);
