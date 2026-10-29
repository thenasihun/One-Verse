import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../data/catalog.dart';
import '../data/downloads.dart';
import '../data/models.dart';
import '../data/offline_sync.dart';
import '../data/repository.dart';
import 'audio_handler.dart';
import 'listening_log.dart';
import 'settings.dart';

enum Phase { arabic, translation }

/// One playlist entry: an ayah's Arabic recitation or its translation.
class PlanItem {
  final int ayah;
  final Phase phase;
  const PlanItem(this.ayah, this.phase);
}

/// Saved so a closed app reopens on the same ayah, position and settings.
class Session {
  final int surah, ayah, positionMs;
  const Session(this.surah, this.ayah, this.positionMs);
}

/// The playback engine.
///
/// * Reciters with word timings and Arabic-only listening play one full-surah
///   file (gapless); the ayah and word come from the timings.
/// * Arabic + translation with timings plays clips of that file between
///   translation ayahs.
/// * Reciters without timings play alquran.cloud ayah files.
class Playback extends ChangeNotifier implements PlayerCommands {
  Playback({
    required this.repo,
    required this.settings,
    required this.downloads,
    required this.log,
    required this.sync,
    required this.handler,
  }) : player = handler.player {
    handler.commands = this;
    _subs.add(player.currentIndexStream.listen(_onIndex));
    _subs.add(player.createPositionStream(steps: 2000, minPeriod: const Duration(milliseconds: 40), maxPeriod: const Duration(milliseconds: 120)).listen(_onPosition));
    _subs.add(player.playerStateStream.listen(_onState));
    _subs.add(player.playbackEventStream.listen((_) {}, onError: (Object e, StackTrace _) {
      error = 'Playback stopped. Check the connection or download this surah.';
      notifyListeners();
    }));
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  final QuranRepository repo;
  final Settings settings;
  final Downloads downloads;
  final ListeningLog log;
  final OfflineSync sync;
  final OvAudioHandler handler;
  final AudioPlayer player;
  final List<StreamSubscription> _subs = [];
  late final Timer _ticker;

  // What is loaded
  int surah = 67;
  int ayah = 1;
  bool hasSession = false;
  bool loading = false;
  String? error;
  Phase phase = Phase.arabic;
  List<VerseText> verses = const [];
  SurahTiming? timing;
  bool singleFile = false;
  List<PlanItem> items = const [];
  String? _loadedKey;

  // Fine-grained state for the UI (no full rebuilds)
  final ValueNotifier<int> word = ValueNotifier(-2); // -2 idle (all lit), -1 none yet, >= count all lit
  final ValueNotifier<double> ayahProgress = ValueNotifier(0);
  final ValueNotifier<Duration> ayahPosition = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> ayahLength = ValueNotifier(Duration.zero);

  int _reps = 0;
  bool _repeatSeek = false;
  int _pendingPosMs = 0;
  bool _userNav = false;
  int? _lastIndex;
  DateTime? sleepAt;
  bool sleepEndOfSurah = false;
  Timer? _sleepTimer;
  int _sinceSave = 0;

  bool get playing => player.playing && player.processingState != ProcessingState.completed;
  bool get wordExact => timing != null && settings.listenMode != ListenMode.translation;
  SurahInfo get info => repo.surah(surah);
  VerseText? get verse => ayah - 1 < verses.length ? verses[ayah - 1] : null;
  Reciter get reciter => settings.reciter;
  Reciter get leadVoice => settings.listenMode == ListenMode.translation ? settings.translationVoice : settings.reciter;

  // ---------------------------------------------------------------- session

  Future<Session?> restore() async {
    final p = settings.prefs;
    final s = p.getInt('session_surah');
    if (s == null) return null;
    surah = s;
    ayah = p.getInt('session_ayah') ?? 1;
    _pendingPosMs = p.getInt('session_pos') ?? 0;
    hasSession = true;
    try {
      verses = await repo.words(surah);
    } catch (_) {}
    notifyListeners();
    return Session(surah, ayah, _pendingPosMs);
  }

  void saveSession() {
    final p = settings.prefs;
    p.setInt('session_surah', surah);
    p.setInt('session_ayah', ayah);
    p.setInt('session_pos', ayahPosition.value.inMilliseconds);
  }

  // ---------------------------------------------------------------- loading

  String _key() => '$surah|${settings.reciterId}|${settings.translationVoiceId}|${settings.listenMode.name}';

  /// Loads [n] and starts at [startAyah]. Keeps the current position when
  /// only a setting changed.
  Future<void> play(int n, {int startAyah = 1, bool autoplay = true, int offsetMs = 0}) async {
    surah = n;
    ayah = startAyah;
    hasSession = true;
    error = null;
    loading = true;
    _reps = 0;
    word.value = -1;
    notifyListeners();
    try {
      verses = await repo.words(n);
      await _build(startAyah, offsetMs);
      _loadedKey = _key();
      loading = false;
      notifyListeners();
      if (autoplay) await player.play();
    } catch (e) {
      loading = false;
      error = e.toString().contains('internet') || e.toString().contains('reach')
          ? 'You are offline and this surah is not downloaded yet.'
          : 'Could not load this recitation. ${reciter.name} may not have this surah; try another reciter.';
      notifyListeners();
    }
    saveSession();
  }

  Future<void> _build(int startAyah, int offsetMs) async {
    final mode = settings.listenMode;
    final r = settings.reciter;
    final voice = settings.translationVoice;
    timing = mode == ListenMode.translation ? null : await repo.timing(r, surah);
    final count = info.ayahs;

    AudioSource chapterSource() {
      final local = downloads.chapterFile(r.id, surah);
      return local != null ? AudioSource.file(local) : AudioSource.uri(Uri.parse(timing!.audioUrl));
    }

    Future<List<UriAudioSource>> ayahSources(Reciter who) async {
      final ed = who.ayahEdition;
      if (ed == null) throw StateError('no ayah audio');
      final urls = await repo.ayahAudio(ed, surah);
      return [
        for (var i = 0; i < urls.length; i++)
          () {
            final local = downloads.ayahFile(ed, surah, i + 1);
            return local != null ? AudioSource.file(local) : AudioSource.uri(Uri.parse(urls[i]));
          }(),
      ];
    }

    if (mode == ListenMode.arabic && timing != null) {
      singleFile = true;
      items = const [];
      final start = timing!.ayahs[startAyah - 1].from + offsetMs;
      await player.setAudioSource(chapterSource(), initialPosition: Duration(milliseconds: start));
    } else {
      singleFile = false;
      final sources = <AudioSource>[];
      final plan = <PlanItem>[];
      final ar = mode == ListenMode.translation || timing != null ? null : await ayahSources(r);
      final tr = mode == ListenMode.arabic ? null : await ayahSources(voice);
      for (var a = 1; a <= count; a++) {
        if (mode != ListenMode.translation) {
          if (timing != null) {
            final t = timing!.ayahs[a - 1];
            if (t.to > t.from) {
              final local = downloads.chapterFile(r.id, surah);
              sources.add(ClippingAudioSource(
                child: local != null ? AudioSource.file(local) : AudioSource.uri(Uri.parse(timing!.audioUrl)),
                start: Duration(milliseconds: t.from),
                end: Duration(milliseconds: t.to),
              ));
              plan.add(PlanItem(a, Phase.arabic));
            }
          } else {
            sources.add(ar![a - 1]);
            plan.add(PlanItem(a, Phase.arabic));
          }
        }
        if (tr != null) {
          sources.add(tr[a - 1]);
          plan.add(PlanItem(a, Phase.translation));
        }
      }
      items = plan;
      final idx = plan.indexWhere((p) => p.ayah >= startAyah);
      await player.setAudioSources(sources,
          initialIndex: idx < 0 ? 0 : idx, initialPosition: Duration(milliseconds: offsetMs));
    }
    await player.setSpeed(settings.speed);
    _lastIndex = player.currentIndex;
    _publishMediaItem();
  }

  /// Rebuilds the plan after a reciter, voice or mode change, staying on the
  /// same ayah.
  Future<void> reload() async {
    if (!hasSession || _loadedKey == null || _loadedKey == _key()) return;
    final wasPlaying = playing;
    await play(surah, startAyah: ayah, autoplay: wasPlaying);
  }

  // ---------------------------------------------------------------- tracking

  void _onIndex(int? index) {
    if (index == null || singleFile || items.isEmpty || index >= items.length) return;
    final item = items[index];
    final prev = _lastIndex;
    _lastIndex = index;
    if (prev != null && !_userNav && prev < items.length && items[prev].ayah != item.ayah && index == prev + 1) {
      if (_shouldRepeat()) {
        final first = items.indexWhere((p) => p.ayah == items[prev].ayah);
        _lastIndex = first;
        Future.delayed(const Duration(milliseconds: 40), () => player.seek(Duration.zero, index: first));
        return;
      }
      log.addAyah();
    }
    _userNav = false;
    _setAyah(item.ayah, item.phase);
  }

  bool _shouldRepeat() {
    final rep = settings.repeat;
    if (rep == 0) return false;
    if (rep < 0 || _reps < rep) {
      _reps++;
      return true;
    }
    _reps = 0;
    return false;
  }

  void _setAyah(int a, Phase p) {
    final changed = a != ayah || p != phase;
    if (a != ayah) _reps = _userNav ? 0 : _reps;
    ayah = a;
    phase = p;
    if (changed) {
      _publishMediaItem();
      notifyListeners();
    }
  }

  void _onPosition(Duration pos) {
    final ms = pos.inMilliseconds;
    final count = verse?.wordCount ?? 0;
    if (singleFile && timing != null) {
      var ai = timing!.ayahAt(ms);
      if (ai < 0) ai = 0;
      final current = ayah - 1;
      if (_repeatSeek) {
        if (ai != current) return; // waiting for the repeat seek to land
        _repeatSeek = false;
      }
      // Natural move to the next ayah: repeat or count it.
      if (ai == current + 1 && !_userNav && player.playing) {
        if (_shouldRepeat()) {
          _repeatSeek = true;
          player.seek(Duration(milliseconds: timing!.ayahs[current].from));
          return;
        }
        log.addAyah();
      }
      if (ai != current) {
        _userNav = false;
        _setAyah(ai + 1, Phase.arabic);
      }
      final t = timing!.ayahs[ai];
      final len = (t.to - t.from).clamp(1, 1 << 31);
      ayahPosition.value = Duration(milliseconds: (ms - t.from).clamp(0, len));
      ayahLength.value = Duration(milliseconds: len);
      ayahProgress.value = ((ms - t.from) / len).clamp(0.0, 1.0);
      word.value = player.playing || ms > t.from ? wordAt(t, ms, count) : -2;
      return;
    }
    final idx = player.currentIndex;
    if (idx == null || idx >= items.length) return;
    final item = items[idx];
    final dur = player.duration ?? Duration.zero;
    final dms = dur.inMilliseconds.clamp(1, 1 << 31);
    final frac = (ms / dms).clamp(0.0, 1.0);
    ayahPosition.value = pos;
    ayahLength.value = dur;
    final paired = settings.listenMode == ListenMode.arabicTranslation;
    ayahProgress.value = !paired ? frac : item.phase == Phase.arabic ? frac * 0.6 : 0.6 + frac * 0.4;
    if (item.phase == Phase.translation) {
      word.value = count; // Arabic done, fully lit
    } else if (timing != null) {
      final t = timing!.ayahs[item.ayah - 1];
      word.value = wordAt(t, t.from + ms, count);
    } else {
      word.value = !player.playing && ms == 0 ? -2 : (frac * count).floor().clamp(0, count);
    }
  }

  void _onState(PlayerState s) {
    if (s.processingState == ProcessingState.completed) {
      if (settings.repeat != 0 && _shouldRepeat()) {
        if (singleFile) {
          player.seek(Duration(milliseconds: timing!.ayahs[ayah - 1].from));
        } else {
          final first = items.indexWhere((p) => p.ayah == ayah);
          player.seek(Duration.zero, index: first < 0 ? 0 : first);
        }
        player.play();
        return;
      }
      log.addAyah();
      if (sleepEndOfSurah) {
        sleepEndOfSurah = false;
      }
      player.pause();
      word.value = verse?.wordCount ?? 0;
    }
    handler.refresh();
    notifyListeners();
  }

  void _tick() {
    if (player.playing && player.processingState == ProcessingState.ready) {
      log.add(1, reciterId: leadVoice.id, surah: surah);
      if (++_sinceSave >= 5) {
        _sinceSave = 0;
        saveSession();
      }
    }
  }

  void _publishMediaItem() {
    final s = info;
    final photo = sync.photoPath(leadVoice.id);
    final url = repo.profileOf(leadVoice)?.imageUrl;
    handler.mediaItem.add(MediaItem(
      id: '$surah:$ayah',
      title: '${s.nameEn} · Ayah $ayah',
      artist: leadVoice.name,
      album: 'One Verse · ${s.meaning}',
      displaySubtitle: phase == Phase.translation ? 'Translation · ${settings.translationVoice.name}' : leadVoice.name,
      displayDescription: verse?.plain(),
      artUri: photo != null ? Uri.file(photo) : (url != null ? Uri.parse(url) : null),
      duration: singleFile ? player.duration : null,
      extras: {'surah': surah, 'ayah': ayah},
    ));
  }

  // ---------------------------------------------------------------- commands

  Future<void> toggle() async {
    if (player.playing) return player.pause();
    if (_loadedKey != _key() || player.processingState == ProcessingState.idle) {
      return play(surah, startAyah: ayah, offsetMs: _pendingPosMs);
    }
    if (player.processingState == ProcessingState.completed) await seekToAyah(1);
    await player.play();
  }

  Future<void> seekToAyah(int a, {bool autoplay = false}) async {
    if (a < 1 || a > info.ayahs) return;
    _userNav = true;
    _reps = 0;
    _pendingPosMs = 0;
    if (_loadedKey != _key()) {
      await play(surah, startAyah: a, autoplay: autoplay || player.playing);
      return;
    }
    if (singleFile) {
      await player.seek(Duration(milliseconds: timing!.ayahs[a - 1].from));
      _setAyah(a, Phase.arabic);
      _userNav = false;
    } else {
      final idx = items.indexWhere((p) => p.ayah == a);
      if (idx >= 0) await player.seek(Duration.zero, index: idx);
    }
    word.value = -1;
    if (autoplay && !player.playing) await player.play();
    saveSession();
  }

  Future<void> playAyah(int n, int a) async {
    if (n == surah && _loadedKey == _key()) {
      await seekToAyah(a, autoplay: true);
    } else {
      await play(n, startAyah: a);
    }
  }

  Future<void> next() => seekToAyah(ayah + 1, autoplay: player.playing);

  Future<void> previous() async {
    if (ayahPosition.value > const Duration(seconds: 3) && player.playing) {
      return seekToAyah(ayah, autoplay: true);
    }
    return seekToAyah(ayah - 1, autoplay: player.playing);
  }

  /// Seek inside the current ayah, 0..1.
  Future<void> seekWithinAyah(double f) async {
    if (singleFile) {
      final t = timing!.ayahs[ayah - 1];
      await player.seek(Duration(milliseconds: (t.from + (t.to - t.from) * f).round()));
    } else {
      final d = player.duration;
      if (d != null) await player.seek(d * f);
    }
  }

  void setSpeed(double s) {
    settings.update((x) => x.speed = s);
    player.setSpeed(s);
    handler.refresh();
    notifyListeners();
  }

  void cycleRepeat() {
    const steps = [0, 1, 3, -1];
    final i = steps.indexOf(settings.repeat);
    settings.update((x) => x.repeat = steps[(i + 1) % steps.length]);
    _reps = 0;
    handler.refresh();
    notifyListeners();
  }

  void setSleep({Duration? after, bool endOfSurah = false}) {
    _sleepTimer?.cancel();
    sleepEndOfSurah = endOfSurah;
    sleepAt = after == null ? null : DateTime.now().add(after);
    if (after != null) {
      _sleepTimer = Timer(after, () {
        player.pause();
        sleepAt = null;
        notifyListeners();
      });
    }
    notifyListeners();
  }

  void dismissError() {
    error = null;
    notifyListeners();
  }

  // PlayerCommands (notification, lock screen, headset)
  @override
  Future<void> cmdPlay() => toggle().then((_) {});
  @override
  Future<void> cmdPause() => player.pause();
  @override
  Future<void> cmdNext() => next();
  @override
  Future<void> cmdPrevious() => previous();
  @override
  Future<void> cmdStop() async {
    await player.pause();
    saveSession();
    handler.dismiss();
  }

  @override
  Future<void> cmdSeek(Duration p) => player.seek(p);
  @override
  Future<void> cmdToggleRepeat() async => cycleRepeat();
  @override
  int get repeatSetting => settings.repeat;

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _ticker.cancel();
    _sleepTimer?.cancel();
    player.dispose();
    super.dispose();
  }
}

/// Picks the reciter used for "Arabic" when the chosen one has neither timings
/// nor ayah files for a surah (never for the catalog today, kept for safety).
Reciter fallbackReciter() => reciters.first;
