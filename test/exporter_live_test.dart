@Tags(['live'])
@Timeout(Duration(minutes: 10))
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oneverse/data/cache_store_memory.dart';
import 'package:oneverse/data/catalog.dart';
import 'package:oneverse/data/downloads.dart';
import 'package:oneverse/data/exporter.dart';
import 'package:oneverse/data/repository.dart';

/// Real recitations through the system ffmpeg, with the same arguments the
/// phone passes to ffmpeg-kit. Run with: flutter test --tags live
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null; // the test binding blocks real requests
  final repo = QuranRepository(store: MemoryCacheStore());
  late Directory dir;
  late Exporter ex;

  Future<bool> ffmpeg(List<String> args) async {
    final r = await Process.run('ffmpeg', args);
    if (r.exitCode != 0) printOnFailure(r.stderr.toString());
    return r.exitCode == 0;
  }

  Future<double> seconds(String path) async {
    final r = await Process.run('ffprobe', ['-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', path]);
    return double.parse(r.stdout.toString().trim());
  }

  Future<String> probe(String path, String entries) async =>
      (await Process.run('ffprobe', ['-v', 'error', '-show_entries', entries, '-of', 'csv=p=0', path])).stdout.toString().trim();

  setUpAll(() async {
    await repo.init();
    dir = await Directory.systemTemp.createTemp('ov_export');
    ex = Exporter(repo, Downloads(repo), run: ffmpeg, workDir: () async => dir)
      ..videoCodecs = const ['mpeg4'];
  });
  tearDownAll(() => dir.delete(recursive: true));

  test('ayah files with Urdu translation become one audio file', () async {
    final r = ExportRequest(surah: 112, from: 1, to: 4, reciter: reciterById('ar.alafasy'), voice: reciterById('ur.khan'));
    final f = await ex.audio(r);
    expect(f.path, endsWith('Surah Al-Ikhlaas - Mishary Alafasy (with translation).m4a'));
    final s = await seconds(f.path);
    expect(s, inInclusiveRange(25, 90), reason: 'four ayahs and their Urdu, got $s s');
    expect(await probe(f.path, 'stream=codec_name,sample_rate,channels'), 'aac,44100,2');
    expect(await probe(f.path, 'format_tags=title'), 'Surah Al-Ikhlaas');
  });

  test('a passage cut from a full-surah recording (mp3quran, ayah timings)', () async {
    final r = ExportRequest(surah: 67, from: 1, to: 3, reciter: reciterById('ov.saadghamdi'));
    final f = await ex.audio(r);
    final t = (await repo.timing(r.reciter, 67))!;
    final expected = (t.ayahs[2].to - t.ayahs[0].from) / 1000;
    expect((await seconds(f.path) - expected).abs(), lessThan(1.0));
  });

  test('a two-ayah video with one card per ayah', () async {
    final cards = <String>[];
    for (final c in ['green', 'navy']) {
      final p = '${dir.path}/card_$c.png';
      expect(await ffmpeg(['-y', '-loglevel', 'error', '-f', 'lavfi', '-i', 'color=c=$c:s=1080x1920', '-frames:v', '1', p]), isTrue);
      cards.add(p);
    }
    var i = 0;
    final r = ExportRequest(surah: 112, from: 1, to: 2, reciter: reciterById('ar.alafasy'));
    final f = await ex.video(r, (_) async => cards[i++]);
    expect(await probe(f.path, 'stream=codec_type,width,height'), contains('video,1080,1920'));
    expect(await probe(f.path, 'stream=codec_type'), contains('audio'));
    expect(await seconds(f.path), inInclusiveRange(4, 30));
  });
}
