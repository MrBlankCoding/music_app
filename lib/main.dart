import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:oktoast/oktoast.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'providers/music_player_provider.dart';
import 'providers/library_provider.dart';
import 'providers/playlist_provider.dart';
import 'providers/search_provider.dart';
import 'services/download_service.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

import 'services/youtube_service.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Initialize background audio (required for lock screen metadata & controls)
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.musicapp.channel.audio',
    androidNotificationChannelName: 'Music Playback',
    androidNotificationOngoing: true,
  );

  final musicPlayerProvider = MusicPlayerProvider();
  final youTubeService = YouTubeService(apiKey: dotenv.env['YOUTUBE_API_KEY']!);

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: youTubeService),
        ChangeNotifierProvider.value(value: musicPlayerProvider),
        ChangeNotifierProvider(create: (_) => LibraryProvider()),
        ChangeNotifierProvider(create: (_) => PlaylistProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProxyProvider<LibraryProvider, DownloadService>(
          create: (_) => DownloadService(),
          update: (_, libraryProvider, downloadService) =>
              downloadService!..setLibraryProvider(libraryProvider),
        ),
      ],
      child: const MusicSearchApp(),
    ),
  );
}

class MusicSearchApp extends StatelessWidget {
  const MusicSearchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return OKToast(
      child: MaterialApp(
        navigatorObservers: [routeObserver],
        title: 'Music Library',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: const HomeScreen(),
      ),
    );
  }
}
