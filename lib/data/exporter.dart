import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'api.dart';
import 'downloads.dart';
import 'models.dart';
import 'repository.dart';

/// Runs one ffmpeg command; true when it succeeded. On the phone this is
/// ffmpeg-kit, in tests the system ffmpeg.
typedef FfmpegRunner = Future<bool> Function(List<String> args);

/// What to export: ayahs [from]..[to] of [surah] recited by [reciter], with the
/// translation read by [voice] after each ayah when it is set.
class ExportRequest {
  final int surah, from, to;
  final Reciter reciter;
  final Reciter? voice;
  const ExportRequest({required this.surah, required this.from, required this.to, required this.reciter, this.voice});

  int get count => to - from + 1;
}

/// A piece of audio: a whole file, or the part of it between [start] and [end]
/// seconds.
class AudioPiece {
  final String path;
  final double? start, end;
  final int ayah;
  const AudioPiece(this.path, this.ayah, {this.start, this.end});
}

class ExportException implements Exception {
  final String message;
  const ExportException(this.message);
  @override
  String toString() => message;
}

/// Builds shareable audio and video from recitations, on the phone.
///
/// Every input becomes 44.1 kHz stereo PCM first, so ayah files, cuts of a
/// full-surah file and translation audio (which come at different rates) join
/// cleanly; the result is AAC in an .m4a (audio) or H.264/MPEG-4 in an .mp4
/// (video).
class Exporter {
  Exporter(this.repo, this.downloads, {FfmpegRunner? run, Future<Directory> Function()? workDir, Dio? dio})
      : _run = run,
        _workDir = workDir ?? (() async => Directory('${(await getTemporaryDirectory()).path}/oneverse_share')),
        _dio = dio ?? Api.instance.dio;

  final QuranRepository repo;
  final Downloads downloads;
  final FfmpegRunner? _run;
  final Future<Directory> Function() _workDir;
  final Dio _dio;

  /// 0..1 while an export runs, null otherwise.
  final ValueNotifier<double?> progress = ValueNotifier(null);

  static const chunkSize = 40; // inputs per ffmpeg call
  static const maxVideoAyahs = 20;

  Future<bool> _ffmpeg(List<String> args) {
    final run = _run;
    if (run == null) throw const ExportException('Audio tools are not available here');
    return run(args);
  }

  Future<Directory> _dir(String sub) async {
    final d = Directory('${(await _workDir()).path}/$sub');
    await d.create(recursive: true);
    return d;
  }

  /// Downloads [url] once into the share cache.
  Future<String> _fetch(String url, String name) async {
    final f = File('${(await _dir('cache')).path}/$name');
    if (await f.exists() && await f.length() > 0) return f.path;
    final tmp = File('${f.path}.part');
    try {
      await _dio.download(url, tmp.path, options: Options(receiveTimeout: const Duration(minutes: 3)));
    } on DioException {
      throw const ExportException('Could not download the recitation. Check the connection and try again.');
    }
    await tmp.rename(f.path);
    return f.path;
  }

  /// The audio pieces for [r], in order: each ayah, and its translation after
  /// it when a voice is chosen.
  Future<List<List<AudioPiece>>> piecesByAyah(ExportRequest r) async {
    final out = <List<AudioPiece>>[for (var a = r.from; a <= r.to; a++) <AudioPiece>[]];
    final ed = r.reciter.ayahEdition;
    if (ed != null) {
      final urls = await repo.ayahAudio(ed, r.surah);
      for (var a = r.from; a <= r.to; a++) {
        final local = downloads.ayahFile(ed, r.surah, a);
        out[a - r.from].add(AudioPiece(local ?? await _fetch(urls[a - 1], '${ed}_${r.surah}_$a.mp3'), a));
        _tick(a - r.from + 1, r.count * (r.voice == null ? 1 : 2) + 2);
      }
    } else {
      final t = await repo.timing(r.reciter, r.surah);
      if (t == null) throw ExportException('${r.reciter.name} has no recording of this surah.');
      final whole = r.from == 1 && r.to == repo.surah(r.surah).ayahs;
      if (t.ayahs.isEmpty && !whole) {
        throw ExportException('${r.reciter.name} has no ayah timings, so only the whole surah can be shared. Choose the whole surah or another reciter.');
      }
      final file = downloads.chapterFile(r.reciter.id, r.surah) ?? await _fetch(t.audioUrl, '${r.reciter.id}_${r.surah}.mp3');
      for (var a = r.from; a <= r.to; a++) {
        if (t.ayahs.isEmpty) {
          out[0].add(AudioPiece(file, a));
          break;
        }
        final at = t.ayahs[a - 1];
        if (at.to <= at.from) continue;
        // The first ayah keeps the opening (isti'adha, basmala) when the
        // whole surah is taken.
        final start = a == 1 && whole ? 0.0 : at.from / 1000;
        out[a - r.from].add(AudioPiece(file, a, start: start, end: at.to / 1000));
      }
    }
    final v = r.voice;
    if (v != null) {
      final ved = v.ayahEdition!;
      final urls = await repo.ayahAudio(ved, r.surah);
      for (var a = r.from; a <= r.to; a++) {
        final local = downloads.ayahFile(ved, r.surah, a);
        out[a - r.from].add(AudioPiece(local ?? await _fetch(urls[a - 1], '${ved}_${r.surah}_$a.mp3'), a));
        _tick(r.count + a - r.from + 1, r.count * 2 + 2);
      }
    }
    return out;
  }

  /// Neighbouring cuts of one file become a single cut, so a passage from a
  /// full-surah recording plays without seams.
  static List<AudioPiece> mergeContiguous(List<AudioPiece> pieces) {
    final out = <AudioPiece>[];
    for (final p in pieces) {
      final last = out.isEmpty ? null : out.last;
      if (last != null && last.path == p.path && last.end != null && p.start != null && (p.start! - last.end!).abs() < 0.05) {
        out[out.length - 1] = AudioPiece(p.path, last.ayah, start: last.start, end: p.end);
      } else {
        out.add(p);
      }
    }
    return out;
  }

  void _tick(int done, int total) => progress.value = (done / total).clamp(0.0, 0.95);

  /// The ffmpeg arguments that join [pieces] into one PCM WAV at [out].
  static List<String> joinArgs(List<AudioPiece> pieces, String out) {
    final args = <String>['-y', '-hide_banner', '-loglevel', 'error'];
    for (final p in pieces) {
      if (p.start != null) args.addAll(['-ss', p.start!.toStringAsFixed(3)]);
      if (p.end != null) args.addAll(['-to', p.end!.toStringAsFixed(3)]);
      args.addAll(['-i', p.path]);
    }
    final f = StringBuffer();
    for (var i = 0; i < pieces.length; i++) {
      f.write('[$i:a]aresample=44100,aformat=sample_fmts=s16:channel_layouts=stereo[s$i];');
    }
    for (var i = 0; i < pieces.length; i++) {
      f.write('[s$i]');
    }
    f.write('concat=n=${pieces.length}:v=0:a=1[out]');
    args.addAll(['-filter_complex', f.toString(), '-map', '[out]', '-c:a', 'pcm_s16le', out]);
    return args;
  }

  static List<String> _meta(String title, String artist) =>
      ['-metadata', 'title=$title', '-metadata', 'artist=$artist', '-metadata', 'album=One Verse', '-metadata', 'comment=Shared from One Verse'];

  /// Joins [pieces] (any number) into [wav], in chunks so that a whole surah
  /// does not open hundreds of inputs at once.
  Future<void> _join(List<AudioPiece> pieces, String wav, Directory tmp) async {
    if (pieces.length <= chunkSize) {
      if (!await _ffmpeg(joinArgs(pieces, wav))) throw const ExportException('Could not join the audio.');
      return;
    }
    final parts = <AudioPiece>[];
    for (var i = 0; i < pieces.length; i += chunkSize) {
      final part = '${tmp.path}/part_${i ~/ chunkSize}.wav';
      final slice = pieces.sublist(i, (i + chunkSize).clamp(0, pieces.length));
      if (!await _ffmpeg(joinArgs(slice, part))) throw const ExportException('Could not join the audio.');
      parts.add(AudioPiece(part, slice.first.ayah));
    }
    await _join(parts, wav, tmp);
  }

  static String fileTitle(SurahInfo s, ExportRequest r) =>
      r.from == 1 && r.to == s.ayahs ? 'Surah ${s.nameEn}' : r.from == r.to ? '${s.nameEn} ${r.surah}:${r.from}' : '${s.nameEn} ${r.surah}:${r.from}-${r.to}';

  static String safeName(String s) => s.replaceAll(RegExp(r'[^\w\-:. ]'), '').replaceAll(':', '.').trim();

  /// One audio file with the request's ayahs (and translation), ready to share.
  Future<File> audio(ExportRequest r) async {
    progress.value = 0;
    try {
      final info = repo.surah(r.surah);
      final title = fileTitle(info, r);
      final artist = r.voice == null ? r.reciter.name : '${r.reciter.name} · ${r.voice!.name}';
      final tmp = await _dir('work_${DateTime.now().microsecondsSinceEpoch}');
      final pieces = mergeContiguous([for (final a in await piecesByAyah(r)) ...a]);
      if (pieces.isEmpty) throw const ExportException('Nothing to share for these ayahs.');
      final wav = '${tmp.path}/all.wav';
      await _join(pieces, wav, tmp);
      progress.value = 0.97;
      final out = '${(await _dir('out')).path}/${safeName('$title - ${r.reciter.name}')}${r.voice != null ? ' (with translation)' : ''}.m4a';
      final ok = await _ffmpeg(['-y', '-hide_banner', '-loglevel', 'error', '-i', wav, '-c:a', 'aac', '-b:a', '160k', ..._meta(title, artist), out]);
      if (!ok) throw const ExportException('Could not make the audio file.');
      unawaited(tmp.delete(recursive: true).catchError((_) => tmp));
      return File(out);
    } finally {
      progress.value = null;
    }
  }

  /// Seconds of audio in a 44.1 kHz stereo 16-bit WAV written by [joinArgs].
  static Future<double> wavSeconds(String path) async => ((await File(path).length()) - 44) / (44100 * 2 * 2);

  /// The ffmpeg arguments for a video that shows [cards] (PNG, one per ayah)
  /// for [seconds] each over [audio].
  static List<String> videoArgs(List<String> cards, List<double> seconds, String audio, String out, {required String codec, int fps = 24}) {
    final args = <String>['-y', '-hide_banner', '-loglevel', 'error'];
    for (var i = 0; i < cards.length; i++) {
      args.addAll(['-loop', '1', '-framerate', '$fps', '-t', seconds[i].toStringAsFixed(3), '-i', cards[i]]);
    }
    args.addAll(['-i', audio]);
    final f = StringBuffer();
    for (var i = 0; i < cards.length; i++) {
      final fadeOut = (seconds[i] - 0.35).clamp(0.0, 1e9);
      f.write('[$i:v]scale=1080:-2,format=yuv420p,fade=t=in:st=0:d=0.35'
          '${cards.length > 1 ? ',fade=t=out:st=${fadeOut.toStringAsFixed(3)}:d=0.35' : ''}[v$i];');
    }
    for (var i = 0; i < cards.length; i++) {
      f.write('[v$i]');
    }
    f.write('concat=n=${cards.length}:v=1:a=0[v]');
    args.addAll(['-filter_complex', f.toString(), '-map', '[v]', '-map', '${cards.length}:a']);
    args.addAll(codec == 'h264_mediacodec'
        ? ['-c:v', 'h264_mediacodec', '-b:v', '5M', '-g', '${fps * 2}']
        : codec == 'libx264'
            ? ['-c:v', 'libx264', '-preset', 'veryfast', '-crf', '20']
            : ['-c:v', 'mpeg4', '-q:v', '2', '-g', '${fps * 2}']);
    args.addAll(['-c:a', 'aac', '-b:a', '160k', '-r', '$fps', '-shortest', '-movflags', '+faststart', out]);
    return args;
  }

  /// Video codecs to try in order: the phone's hardware encoder, then
  /// ffmpeg's own MPEG-4 encoder.
  List<String> videoCodecs = const ['h264_mediacodec', 'mpeg4'];

  /// A video of the request: [cardFor] draws the card for each ayah (or for
  /// all of them when [oneCard] is true) and returns its PNG path.
  Future<File> video(ExportRequest r, Future<String> Function(int ayah) cardFor, {bool oneCard = false}) async {
    if (r.count > maxVideoAyahs) throw const ExportException('A video can hold up to $maxVideoAyahs ayahs. Choose fewer, or share audio.');
    progress.value = 0;
    try {
      final info = repo.surah(r.surah);
      final tmp = await _dir('work_${DateTime.now().microsecondsSinceEpoch}');
      final byAyah = (await piecesByAyah(r)).where((l) => l.isNotEmpty).toList();
      final wavs = <String>[];
      final secs = <double>[];
      for (final (i, pieces) in byAyah.indexed) {
        final w = '${tmp.path}/ayah_$i.wav';
        if (!await _ffmpeg(joinArgs(pieces, w))) throw const ExportException('Could not join the audio.');
        wavs.add(w);
        secs.add(await wavSeconds(w));
      }
      final all = '${tmp.path}/all.wav';
      await _join([for (final w in wavs) AudioPiece(w, 0)], all, tmp);
      progress.value = 0.96;
      final cards = <String>[];
      final cardSecs = <double>[];
      if (oneCard) {
        cards.add(await cardFor(r.from));
        cardSecs.add(secs.fold(0.0, (a, b) => a + b));
      } else {
        for (final (i, l) in byAyah.indexed) {
          cards.add(await cardFor(l.first.ayah));
          cardSecs.add(secs[i]);
        }
      }
      final out = '${(await _dir('out')).path}/${safeName('${fileTitle(info, r)} - ${r.reciter.name}')}.mp4';
      for (final codec in videoCodecs) {
        if (await _ffmpeg(videoArgs(cards, cardSecs, all, out, codec: codec))) {
          unawaited(tmp.delete(recursive: true).catchError((_) => tmp));
          return File(out);
        }
      }
      throw const ExportException('Could not make the video on this phone.');
    } finally {
      progress.value = null;
    }
  }
}
