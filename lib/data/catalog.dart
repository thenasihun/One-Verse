import 'models.dart';

/// Reciters shown in the app. Reciters with a [TimingSource] play a full-surah
/// file with word timings; the rest play alquran.cloud ayah files.
const reciters = <Reciter>[
  Reciter(id: 'ar.alafasy', name: 'Mishary Alafasy', initials: 'MA', ayahEdition: 'ar.alafasy', timing: TimingSource.qdc(7), quranHubId: 'ar.alafasy.hafs'),
  Reciter(id: 'ar.mahermuaiqly', name: 'Maher Al-Muaiqly', initials: 'MM', ayahEdition: 'ar.mahermuaiqly', timing: TimingSource.github('maher-muaiqly'), quranHubId: 'ar.mahermuaiqly.hafs'),
  Reciter(id: 'ar.abdurrahmaansudais', name: 'Abdur-Rahman As-Sudais', initials: 'AS', ayahEdition: 'ar.abdurrahmaansudais', timing: TimingSource.qdc(3), quranHubId: 'ar.abdurrahmaansudais.hafs'),
  Reciter(id: 'ar.saoodshuraym', name: 'Saud Ash-Shuraym', initials: 'SS', ayahEdition: 'ar.saoodshuraym', timing: TimingSource.qdc(10), quranHubId: 'ar.saoodshuraym.hafs'),
  Reciter(id: 'ov.yasserdossari', name: 'Yasser Al-Dosari', initials: 'YD', timing: TimingSource.qdc(97), quranHubId: 'ar.yasseraldossari.hafs'),
  Reciter(id: 'ov.luhaidan', name: 'Muhammad Al-Luhaidan', initials: 'ML', timing: TimingSource.github('luhaidan'), quranHubId: 'ar.muhammadalluhaidan.hafs'),
  Reciter(id: 'ov.qatami', name: 'Nasser Al-Qatami', initials: 'NQ', timing: TimingSource.github('nasser-qatami'), quranHubId: 'ar.nasseralqatami.hafs'),
  Reciter(id: 'ov.islamsobhi', name: 'Islam Sobhi', initials: 'IS', timing: TimingSource.github('islam-sobhi')),
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
];

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
