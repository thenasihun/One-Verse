import 'package:flutter/material.dart';
import 'package:oneverse/providers/audio_provider.dart';
import 'package:oneverse/providers/quran_provider.dart';
import 'package:oneverse/providers/settings_provider.dart';
import 'package:oneverse/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final settingsProvider = SettingsProvider();
  await settingsProvider.loadPreferences();

  // Pre-fetch settings
  settingsProvider.fetchAvailableEditions();

  runApp(
    OneVerseApp(settingsProvider: settingsProvider),
  );
}

class OneVerseApp extends StatelessWidget {
  final SettingsProvider settingsProvider;

  const OneVerseApp({Key? key, required this.settingsProvider}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        // --- UPDATED: Create and immediately fetch Surah list ---
        ChangeNotifierProvider(create: (_) => QuranProvider()..fetchSurahList()), 
        ChangeNotifierProxyProvider<SettingsProvider, AudioProvider>(
          create: (_) => AudioProvider(),
          update: (_, settings, audio) => audio!..update(settings),
        ),
      ],
      child: const MyApp(),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return MaterialApp(
          title: 'OneVerse',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settings.themeMode,
          home: const HomeScreen(),
        );
      },
    );
  }
}