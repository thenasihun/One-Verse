import 'models.dart';

/// Reciters shown in the app. Reciters with a [TimingSource] play a full-surah
/// file (with word or ayah timings); the rest play alquran.cloud ayah files.
const reciters = <Reciter>[
  Reciter(id: 'ar.alafasy', name: 'Mishary Alafasy', initials: 'MA', ayahEdition: 'ar.alafasy', timing: TimingSource.qdc(7), quranHubId: 'ar.alafasy.hafs'),
  Reciter(id: 'ar.mahermuaiqly', name: 'Maher Al-Muaiqly', initials: 'MM', ayahEdition: 'ar.mahermuaiqly', timing: TimingSource.github('maher-muaiqly'), quranHubId: 'ar.mahermuaiqly.hafs'),
  Reciter(id: 'ar.abdurrahmaansudais', name: 'Abdur-Rahman As-Sudais', initials: 'AS', ayahEdition: 'ar.abdurrahmaansudais', timing: TimingSource.qdc(3), quranHubId: 'ar.abdurrahmaansudais.hafs'),
  Reciter(id: 'ar.saoodshuraym', name: 'Saud Ash-Shuraym', initials: 'SS', ayahEdition: 'ar.saoodshuraym', timing: TimingSource.qdc(10), quranHubId: 'ar.saoodshuraym.hafs'),
  Reciter(id: 'ov.yasserdossari', name: 'Yasser Al-Dosari', initials: 'YD', timing: TimingSource.qdc(97), quranHubId: 'ar.yasseraldossari.hafs'),
  Reciter(id: 'ov.luhaidan', name: 'Muhammad Al-Luhaidan', initials: 'ML', timing: TimingSource.github('luhaidan'), quranHubId: 'ar.muhammadalluhaidan.hafs'),
  Reciter(id: 'ov.qatami', name: 'Nasser Al-Qatami', initials: 'NQ', timing: TimingSource.github('nasser-qatami'), quranHubId: 'ar.nasseralqatami.hafs'),
  Reciter(id: 'ov.islamsobhi', name: 'Islam Sobhi', initials: 'IS', timing: TimingSource.github('islam-sobhi')),
  // Full surahs from mp3quran.net, with ayah timings where published.
  Reciter(id: 'ov.saadghamdi', name: 'Saad Al-Ghamdi', initials: 'SG', timing: TimingSource.mp3quran('https://cdn.mp3quran.net/audio/saad-ghamdi/r1/', read: 30), quranHubId: 'ar.ghamdi.hafs'),
  Reciter(id: 'ov.khalidjaleel', name: 'Khalid Al-Jaleel', initials: 'KJ', timing: TimingSource.mp3quran('https://cdn.mp3quran.net/audio/khalid-jalil/r1/', read: 20), quranHubId: 'ar.khalidaljalil.hafs'),
  Reciter(id: 'ov.idreesabkar', name: 'Idrees Abkar', initials: 'IA', timing: TimingSource.mp3quran('https://cdn.mp3quran.net/audio/idrees-abkar/r1/', read: 12)),
  Reciter(id: 'ov.faresabbad', name: 'Fares Abbad', initials: 'FA', timing: TimingSource.mp3quran('https://cdn.mp3quran.net/audio/fares-abbad/r1/', read: 81), quranHubId: 'ar.faresabbad.hafs'),
  Reciter(id: 'ov.mansoursalimi', name: 'Mansour Al-Salimi', initials: 'MS', timing: TimingSource.mp3quran('https://cdn.mp3quran.net/audio/mansour-salimi/r1/', read: 245), quranHubId: 'ar.mansouralsalmi.hafs'),
  Reciter(id: 'ov.wadeeyamani', name: 'Wadee Al-Yamani', initials: 'WY', timing: TimingSource.mp3quran('https://cdn.mp3quran.net/audio/wadee-yamani/r1/', read: 219), quranHubId: 'ar.wadeealyamani.hafs'),
  Reciter(id: 'ov.ahmadnufais', name: 'Ahmed Al-Nufais', initials: 'AN', timing: TimingSource.mp3quran('https://cdn.mp3quran.net/audio/ahmad-nufais/r1/', read: 259), quranHubId: 'ar.ahmadalnufais.hafs'),
  Reciter(id: 'ov.badrturki', name: 'Bader Al-Turki', initials: 'BT', timing: TimingSource.mp3quran('https://cdn.mp3quran.net/audio/badr-turki/r1/'), quranHubId: 'ar.badralturki.hafs'),
  Reciter(id: 'ov.juhany', name: 'Abdullah Al-Juhany', initials: 'AJ', timing: TimingSource.mp3quran('https://cdn.mp3quran.net/audio/abdullah-juhani/r1/', read: 62), quranHubId: 'ar.abdullahawadaljuhani.hafs'),
  Reciter(id: 'ov.bandarbaleela', name: 'Bandar Baleela', initials: 'BB', timing: TimingSource.mp3quran('https://cdn.mp3quran.net/audio/bandar-baleela/r1/', read: 217), quranHubId: 'ar.bandarbaleela.hafs'),
  Reciter(id: 'ov.bukhatir', name: 'Salah Bukhatir', initials: 'SB', timing: TimingSource.mp3quran('https://cdn.mp3quran.net/audio/salah-bukhatir/r1/', read: 46), quranHubId: 'ar.salahbukhatir.hafs'),
  Reciter(id: 'ov.alijaber', name: 'Ali Jaber', initials: 'AJ', timing: TimingSource.mp3quran('https://cdn.mp3quran.net/audio/ali-jaber/r1/', read: 76), quranHubId: 'ar.alijaber.hafs'),
  Reciter(id: 'ov.raadkurdi', name: 'Raad Al-Kurdi', initials: 'RK', timing: TimingSource.mp3quran('https://cdn.mp3quran.net/audio/raad-kurdi/r1/', read: 221)),
  Reciter(id: 'ov.muhaisany', name: 'Muhammad Al-Mohaisany', initials: 'MM', timing: TimingSource.mp3quran('https://cdn.mp3quran.net/audio/muhammad-muhaisni/r1/')),
  Reciter(id: 'ov.yasserqurashi', name: 'Yasser Al-Qurashi', initials: 'YQ', timing: TimingSource.mp3quran('https://cdn.mp3quran.net/audio/yasser-qurashi/r1/'), quranHubId: 'ar.yasseralqurashi.hafs'),
  Reciter(id: 'ar.abdulbasitmurattal', name: 'Abdul Basit', initials: 'AB', ayahEdition: 'ar.abdulbasitmurattal', timing: TimingSource.qdc(2), quranHubId: 'ar.abdulbasitmurattal.hafs'),
  Reciter(id: 'ar.abdulsamad', name: 'Abdul Basit', initials: 'AD', style: 'Mujawwad', ayahEdition: 'ar.abdulsamad', timing: TimingSource.qdc(1), quranHubId: 'ar.abdulsamad.hafs'),
  Reciter(id: 'ar.husary', name: 'Mahmoud Al-Husary', initials: 'MH', ayahEdition: 'ar.husary', timing: TimingSource.qdc(6), quranHubId: 'ar.husary.hafs'),
  Reciter(id: 'ov.husarymuallim', name: 'Al-Husary', initials: 'HT', style: 'Teaching', timing: TimingSource.qdc(12), quranHubId: 'ar.husary.hafs'),
  Reciter(id: 'ar.minshawi', name: 'Siddiq Al-Minshawi', initials: 'SM', ayahEdition: 'ar.minshawi', timing: TimingSource.qdc(9), quranHubId: 'ar.minshawi.hafs'),
  Reciter(id: 'ar.shaatree', name: 'Abu Bakr Ash-Shaatree', initials: 'BS', ayahEdition: 'ar.shaatree', timing: TimingSource.qdc(4), quranHubId: 'ar.shaatree.hafs'),
  Reciter(id: 'ar.hanirifai', name: 'Hani Ar-Rifai', initials: 'HR', ayahEdition: 'ar.hanirifai', timing: TimingSource.qdc(5), quranHubId: 'ar.hanirifai.hafs'),
  Reciter(id: 'ov.tunaiji', name: 'Khalifa Al-Tunaiji', initials: 'KT', timing: TimingSource.qdc(161), quranHubId: 'ar.khalifaaltunaiji.hafs'),
  Reciter(id: 'ar.husarymujawwad', name: 'Al-Husary', initials: 'HM', style: 'Mujawwad', ayahEdition: 'ar.husarymujawwad', quranHubId: 'ar.husarymujawwad.hafs'),
  Reciter(id: 'ar.minshawimujawwad', name: 'Al-Minshawi', initials: 'MJ', style: 'Mujawwad', ayahEdition: 'ar.minshawimujawwad', quranHubId: 'ar.minshawimujawwad.hafs'),
  Reciter(id: 'ar.ahmedajamy', name: 'Ahmed Al-Ajamy', initials: 'AA', ayahEdition: 'ar.ahmedajamy', quranHubId: 'ar.ahmedajamy.hafs'),
  Reciter(id: 'ar.hudhaify', name: 'Ali Al-Hudhaify', initials: 'AH', ayahEdition: 'ar.hudhaify', quranHubId: 'ar.hudhaify.hafs'),
  Reciter(id: 'ar.muhammadayyoub', name: 'Muhammad Ayyoub', initials: 'MY', ayahEdition: 'ar.muhammadayyoub', quranHubId: 'ar.muhammadayyoub.hafs'),
  Reciter(id: 'ar.muhammadjibreel', name: 'Muhammad Jibreel', initials: 'JB', ayahEdition: 'ar.muhammadjibreel', quranHubId: 'ar.muhammadjibreel.hafs'),
  Reciter(id: 'ar.abdullahbasfar', name: 'Abdullah Basfar', initials: 'BF', ayahEdition: 'ar.abdullahbasfar', quranHubId: 'ar.abdullahbasfar.hafs'),
  Reciter(id: 'ar.ibrahimakhbar', name: 'Ibrahim Al-Akhdar', initials: 'IA', ayahEdition: 'ar.ibrahimakhbar', quranHubId: 'ar.ibrahimakhdar.hafs'),
  Reciter(id: 'ar.aymanswoaid', name: 'Ayman Suwaid', initials: 'SW', style: 'Teaching', ayahEdition: 'ar.aymanswoaid', quranHubId: 'ar.aymanswoaid.hafs'),
  Reciter(id: 'ov.ossi', name: 'Abdulrahman Al-Ossi', initials: 'AO', timing: TimingSource.mp3quran('https://cdn.mp3quran.net/audio/abdulrahman-oosi/r1/', read: 225), quranHubId: 'ar.abdulrahmanaloosi.hafs'),
  Reciter(id: 'ov.budair', name: 'Salah Al-Budair', initials: 'SB', timing: TimingSource.mp3quran('https://cdn.mp3quran.net/audio/salah-budair/r1/', read: 43), quranHubId: 'ar.salahalbudair.hafs'),
  Reciter(id: 'ov.qasim', name: 'Abdulmohsen Al-Qasim', initials: 'AQ', timing: TimingSource.mp3quran('https://cdn.mp3quran.net/audio/abdulmohsen-qasim/r1/', read: 67), quranHubId: 'ar.abdulmohsenalqasim.hafs'),
  Reciter(id: 'ov.hatemfarid', name: 'Hatem Farid Al-Waer', initials: 'HF', timing: TimingSource.mp3quran('https://cdn.mp3quran.net/audio/hatem-waer/r1/'), quranHubId: 'ar.hatemfarid.hafs'),
  Reciter(id: 'ov.mustafaismail', name: 'Mustafa Ismail', initials: 'MI', style: 'Mujawwad', timing: TimingSource.mp3quran('https://cdn.mp3quran.net/audio/mustafa-ismail/r2/', read: 288), quranHubId: 'ar.mustafaismailmujawwad.hafs'),
  Reciter(id: 'ov.banna', name: 'Mahmoud Ali Al-Banna', initials: 'MB', style: 'Mujawwad', timing: TimingSource.mp3quran('https://cdn.mp3quran.net/audio/mahmoud-banna/r2/', read: 122), quranHubId: 'ar.mahmoudalialbannamujawwad.hafs'),
  Reciter(id: 'ov.tablawi', name: 'Muhammad Al-Tablawi', initials: 'MT', timing: TimingSource.mp3quran('https://cdn.mp3quran.net/audio/muhammad-tablawi/r1/', read: 106), quranHubId: 'ar.mohamedtablawi.hafs'),
  Reciter(id: 'ov.khayyat', name: 'Abdullah Khayyat', initials: 'AK', timing: TimingSource.mp3quran('https://cdn.mp3quran.net/audio/abdullah-khayyat/r1/', read: 61), quranHubId: 'ar.abdullahkhayat.hafs'),
  Reciter(id: 'ov.sahlyassin', name: 'Sahl Yassin', initials: 'SY', timing: TimingSource.mp3quran('https://cdn.mp3quran.net/audio/sahl-yassin/r1/', read: 32), quranHubId: 'ar.sahlyasin.hafs'),
  Reciter(id: 'ov.nabilrifai', name: 'Nabil Ar-Rifai', initials: 'NR', timing: TimingSource.mp3quran('https://cdn.mp3quran.net/audio/nabil-rifai/r1/', read: 87), quranHubId: 'ar.nabilarrifai.hafs'),
  Reciter(id: 'ov.haneef', name: 'Abdulwadud Haneef', initials: 'AH', timing: TimingSource.mp3quran('https://cdn.mp3quran.net/audio/abdulwadood-haneef/r1/', read: 71), quranHubId: 'ar.abdulwadoodhaneef.hafs'),
];

/// Translation voices (alquran.cloud ayah-by-ayah).
const translationVoices = <Reciter>[
  Reciter(id: 'en.walk', name: 'Ibrahim Walk', initials: 'EN', style: 'Translation', ayahEdition: 'en.walk', language: 'English · Saheeh Intl.', textEdition: 'en.sahih'),
  Reciter(id: 'ur.khan', name: 'Shamshad Ali Khan', initials: 'UR', style: 'Translation', ayahEdition: 'ur.khan', language: 'Urdu', textEdition: 'ur.jalandhry'),
  Reciter(id: 'fr.leclerc', name: 'Youssouf Leclerc', initials: 'FR', style: 'Translation', ayahEdition: 'fr.leclerc', language: 'French', textEdition: 'fr.hamidullah'),
  Reciter(id: 'ru.kuliev-audio', name: 'Elmir Kuliev', initials: 'RU', style: 'Translation', ayahEdition: 'ru.kuliev-audio', language: 'Russian', textEdition: 'ru.kuliev'),
  Reciter(id: 'fa.hedayatfarfooladvand', name: 'Fooladvand', initials: 'FA', style: 'Translation', ayahEdition: 'fa.hedayatfarfooladvand', language: 'Persian', textEdition: 'fa.fooladvand'),
  Reciter(id: 'zh.chinese', name: 'Chinese', initials: 'ZH', style: 'Translation', ayahEdition: 'zh.chinese', language: 'Chinese', textEdition: 'zh.jian'),
  Reciter(id: 'uz.sodik-audio', name: 'Muhammad Sodik', initials: 'UZ', style: 'Translation', ayahEdition: 'uz.sodik-audio', language: 'Uzbek', textEdition: 'uz.sodik'),
  Reciter(id: 'tr.vakfi-audio', name: 'Diyanet Vakfı', initials: 'TR', style: 'Translation', ayahEdition: 'tr.vakfi-audio', language: 'Turkish', textEdition: 'tr.vakfi'),
];

/// Language code of a translation id such as `ur.jalandhry`.
String languageOf(String translationId) => translationId.split('.').first;

/// The translation voice that reads [translationId] word for word, if any.
Reciter? exactVoiceFor(String translationId) {
  for (final v in translationVoices) {
    if (v.textEdition == translationId) return v;
  }
  return null;
}

/// The voice to hear with [translationId]: the one reading that very
/// translation, else another translation in the same language.
Reciter? voiceFor(String translationId) {
  return exactVoiceFor(translationId) ?? voiceForLanguage(languageOf(translationId));
}

/// A translation voice in language [lang] (`ur`, `en`…), if any.
Reciter? voiceForLanguage(String lang) {
  for (final v in translationVoices) {
    if (languageOf(v.textEdition!) == lang) return v;
  }
  return null;
}

Reciter reciterById(String? id) =>
    [...reciters, ...translationVoices].firstWhere((r) => r.id == id, orElse: () => reciters.first);

/// Translation chips offered before the user picks others.
const defaultQuickTranslations = ['en.sahih', 'en.asad', 'ur.jalandhry'];

/// Fallback names when the translation list has not been fetched yet.
const knownTranslations = <TranslationEdition>[
  TranslationEdition('en.sahih', 'Saheeh International', 'Saheeh International', 'en'),
  TranslationEdition('en.asad', 'Asad', 'Muhammad Asad', 'en'),
  TranslationEdition('ur.jalandhry', 'جالندہری', 'Fateh Muhammad Jalandhry', 'ur'),
];
