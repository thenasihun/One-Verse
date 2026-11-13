@Tags(['live'])
@Timeout(Duration(minutes: 5))
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oneverse/core/theme.dart';
import 'package:oneverse/data/cache_store_memory.dart';
import 'package:oneverse/data/models.dart';
import 'package:oneverse/data/repository.dart';
import 'package:oneverse/ui/share_studio.dart';

/// Draws share cards with the real fonts and text into PNG files, to look at.
/// `OUT=dir flutter test --tags live test/share_card_render_test.dart`
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;
  final out = Platform.environment['OUT'] ?? Directory.systemTemp.path;

  Future<void> font(String family, List<String> files) async {
    final l = FontLoader(family);
    for (final f in files) {
      l.addFont(rootBundle.load('assets/fonts/$f'));
    }
    await l.load();
  }

  testWidgets('cards in every style', (t) async {
    late QuranRepository repo;
    late List<VerseText> v;
    late List<String> ur, en;
    await t.runAsync(() async {
      await font('Figtree', ['Figtree-400.ttf', 'Figtree-500.ttf', 'Figtree-600.ttf', 'Figtree-700.ttf']);
      await font('Bricolage', ['BricolageGrotesque-700.ttf', 'BricolageGrotesque-800.ttf']);
      await font('ReemKufi', ['ReemKufi-500.ttf', 'ReemKufi-700.ttf']);
      await font('UthmanicHafs', ['UthmanicHafs1Ver18.ttf']);
      await font('IndoPakNastaleeq', ['IndoPakNastaleeq-v4.2.1.ttf']);
      await font('NotoNastaliqUrdu', ['NotoNastaliqUrdu-Regular.ttf']);
      repo = QuranRepository(store: MemoryCacheStore());
      await repo.init();
      v = await repo.words(94);
      ur = await repo.translation('ur.jalandhry', 94);
      en = await repo.translation('en.sahih', 94);
    });
    final cases = [
      ('story-surah-ur', CardStyle.surah, true, [5, 6], ur, 'ur.jalandhry', QuranScript.hafs),
      ('story-sand-en', CardStyle.sand, true, [5], en, 'en.sahih', QuranScript.hafs),
      ('story-night-indopak', CardStyle.night, true, [5, 6, 7, 8], ur, 'ur.jalandhry', QuranScript.indopak),
      ('square-emerald-en', CardStyle.emerald, false, [5, 6], en, 'en.sahih', QuranScript.hafs),
    ];
    for (final (name, style, story, ayahs, tr, trId, script) in cases) {
      final key = GlobalKey();
      await t.pumpWidget(MaterialApp(
        theme: AppTheme.build(Brightness.dark),
        home: Center(
          child: RepaintBoundary(
            key: key,
            child: ShareCard(
              info: repo.surah(94),
              verses: [for (final a in ayahs) v[a - 1]],
              translations: [for (final a in ayahs) tr[a - 1]],
              edition: repo.translationById(trId),
              script: script,
              style: style,
              story: story,
            ),
          ),
        ),
      ));
      await t.runAsync(() async {
        await precacheImage(const AssetImage('assets/images/logo.png'), key.currentContext!);
      });
      await t.pump();
      await t.runAsync(() async {
        final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await b.toImage(pixelRatio: 3);
        final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
        await File('$out/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
        expect(img.width, 1080);
      });
    }
  });
}
