import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme.dart';
import '../widgets/common.dart';

class Links {
  static const website = 'https://nasihun.com';
  static const moreApps = 'https://play.google.com/store/apps/dev?id=8907093897824220429';
  static const email = 'thenasihun@gmail.com';
  static const whatsapp =
      'https://api.whatsapp.com/send?phone=+923106162624&text=Hello%20Nasihun%20Team,%20I%20am%20contacting%20you%20from%20the%20OneVerse%20App.';
  static const youtube = 'https://youtube.com/@thenasihun';
  static const instagram = 'https://www.instagram.com/thenasihun';
  static const facebook = 'https://www.facebook.com/thenasihun';
  static const privacy = 'https://nasihun.com/privacy-policy';
  static const source = 'https://github.com/thenasihun/one-verse';
}

/// Who made the app and everyone whose work it is built on.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const credits = <(String, String, String)>[
    ('Quran.com · Quran Foundation', 'Quran text word by word in all five scripts, word timings for 12 reciters, the KFGQPC Hafs and IndoPak Nastaleeq fonts. Quran data provided by Quran Foundation.', 'https://quran.foundation'),
    ('King Fahd Glorious Quran Printing Complex', 'The Madani Hafs text and Uthmanic Hafs font.', 'https://qurancomplex.gov.sa'),
    ('AlQuran Cloud', 'Translations in 40+ languages, ayah-by-ayah recitations and translation audio.', 'https://alquran.cloud'),
    ('QuranHub (Misraj AI)', 'Reciter photos, countries and biographies.', 'https://qurani.ai'),
    ('Quranic Audio', 'Full-surah recitations used with word timings.', 'https://quranicaudio.com'),
    ('mp3quran.net', 'Recordings of Maher Al-Muaiqly, Nasser Al-Qatami, Islam Sobhi and Muhammad Al-Luhaidan.', 'https://mp3quran.net'),
    ('its3li/quran-word-timings', 'Word timings for Muhammad Al-Luhaidan (CC0).', 'https://github.com/its3li/quran-word-timings'),
    ('baklarrrr/quran-timings', 'Word timings for Maher Al-Muaiqly, Nasser Al-Qatami, Yasser Al-Dosari and Islam Sobhi.', 'https://github.com/baklarrrr/quran-timings'),
    ('Tajweed colours', 'Tajweed rule markup from Quran.com.', 'https://quran.com'),
    ('Fonts', 'Amiri Quran, Scheherazade New and Noto Nastaliq Urdu (SIL Open Font License); Figtree, Bricolage Grotesque and Reem Kufi (SIL Open Font License).', 'https://fonts.google.com'),
    ('Reciters', 'Every recitation belongs to its reciter and publisher. May Allah reward them.', ''),
  ];

  Future<void> _open(BuildContext context, String url) async {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication).catchError((_) => false);
    if (!ok && context.mounted) toast(context, 'Could not open the link');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ov;
    return Scaffold(
      appBar: AppBar(backgroundColor: c.bg, surfaceTintColor: Colors.transparent, title: Text('About', style: T.ui(16, w: FontWeight.w700, color: c.fg))),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 32), children: [
        Art(
          seed: 0,
          radius: BorderRadius.circular(24),
          padding: const EdgeInsets.all(20),
          child: Row(children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: c.gold, borderRadius: BorderRadius.circular(16)),
              child: Icon(Icons.menu_book_rounded, color: c.goldInk, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('One Verse', style: T.display(26, color: Colors.white)),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (_, s) => Text('Version ${s.data?.version ?? '2.0.0'} · by Nasihun', style: T.ui(13, color: Colors.white70)),
                ),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        Text(
          'Listen to and read the Quran one ayah at a time. Free, with no ads, no subscriptions and no account. '
          'Made as sadaqah jariyah; please remember us and everyone below in your duas.',
          style: T.ui(14, color: c.fg2, height: 1.55),
        ),
        const Label('Credits'),
        for (final (title, text, url) in credits)
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: url.isEmpty ? null : () => _open(context, url),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: T.ui(14.5, w: FontWeight.w700, color: c.fg)),
                    const SizedBox(height: 2),
                    Text(text, style: T.ui(12.5, color: c.fg2, height: 1.45)),
                  ]),
                ),
                if (url.isNotEmpty) Padding(padding: const EdgeInsets.only(left: 8, top: 2), child: Icon(Icons.open_in_new_rounded, size: 16, color: c.fg3)),
              ]),
            ),
          ),
        const Label('Get in touch'),
        Wrap(spacing: 8, runSpacing: 8, children: [
          OvChip('Website', leading: Icon(Icons.public_rounded, size: 16, color: c.fg2), onTap: () => _open(context, Links.website)),
          OvChip('WhatsApp', leading: Icon(Icons.chat_rounded, size: 16, color: c.fg2), onTap: () => _open(context, Links.whatsapp)),
          OvChip('YouTube', leading: Icon(Icons.play_circle_rounded, size: 16, color: c.fg2), onTap: () => _open(context, Links.youtube)),
          OvChip('Instagram', leading: Icon(Icons.camera_alt_rounded, size: 16, color: c.fg2), onTap: () => _open(context, Links.instagram)),
          OvChip('Facebook', leading: Icon(Icons.people_rounded, size: 16, color: c.fg2), onTap: () => _open(context, Links.facebook)),
          OvChip('More apps', leading: Icon(Icons.apps_rounded, size: 16, color: c.fg2), onTap: () => _open(context, Links.moreApps)),
          OvChip('Privacy policy', leading: Icon(Icons.shield_rounded, size: 16, color: c.fg2), onTap: () => _open(context, Links.privacy)),
          OvChip('Source code', leading: Icon(Icons.code_rounded, size: 16, color: c.fg2), onTap: () => _open(context, Links.source)),
        ]),
        const SizedBox(height: 16),
        SelectableText('Email: ${Links.email}', style: T.ui(13, color: c.fg3)),
      ]),
    );
  }
}
