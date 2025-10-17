import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oktoast/oktoast.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'providers/music_player_provider.dart';
import 'providers/library_provider.dart';
import 'providers/playlist_provider.dart';
import 'providers/search_provider.dart';
import 'services/download_service.dart';
import 'screens/home_screen.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

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

  runApp(
    MultiProvider(
      providers: [
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
    // Get base text theme before MaterialApp is built
    const baseTextTheme = TextTheme();

    return OKToast(
      child: MaterialApp(
        navigatorObservers: [routeObserver],
        title: 'Music Library',
        debugShowCheckedModeBanner: false,
        theme: _buildLightTheme(baseTextTheme),
        darkTheme: _buildDarkTheme(baseTextTheme),
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }

  ThemeData _buildLightTheme(TextTheme baseTextTheme) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF7E57C2),
        brightness: Brightness.light,
        primary: const Color(0xFF7E57C2),
        secondary: const Color(0xFF9575CD),
        surface: const Color(0xFFFFFFFF),
        surfaceContainerHighest: const Color(0xFFF5F5F5),
        surfaceContainerHigh: const Color(0xFFEEEEEE),
        onSurface: const Color(0xFF1C1B1F),
        onSurfaceVariant: const Color(0xFF49454F),
      ),
      textTheme: GoogleFonts.interTextTheme(baseTextTheme).copyWith(
        bodyMedium: GoogleFonts.inter(
          textStyle: baseTextTheme.bodyMedium?.copyWith(
            color: const Color(0xFF1C1B1F),
          ),
        ),
      ),
      scaffoldBackgroundColor: const Color(0xFFFFFFFF),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFFFFF),
        foregroundColor: Color(0xFF1C1B1F),
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFFFFFFF),
        elevation: 2,
        shadowColor: const Color.fromRGBO(0, 0, 0, 0.1),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFFFFFFFF),
        indicatorColor: const Color.fromRGBO(125, 87, 194, 0.12),
      ),
    );
  }

  ThemeData _buildDarkTheme(TextTheme baseTextTheme) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF7E57C2),
        brightness: Brightness.dark,
        primary: const Color(0xFF9575CD),
        secondary: const Color(0xFFB39DDB),
        surface: const Color(0xFF1C1B1F),
        surfaceContainerHighest: const Color(0xFF2B2930),
        surfaceContainerHigh: const Color(0xFF36343B),
        onSurface: const Color(0xFFE6E1E5),
        onSurfaceVariant: const Color(0xFFCAC4D0),
      ),
      textTheme: GoogleFonts.interTextTheme(baseTextTheme).copyWith(
        bodyMedium: GoogleFonts.inter(
          textStyle: baseTextTheme.bodyMedium?.copyWith(
            color: const Color(0xFFE6E1E5),
          ),
        ),
      ),
      scaffoldBackgroundColor: const Color(0xFF1C1B1F),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1C1B1F),
        foregroundColor: Color(0xFFE6E1E5),
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF2B2930),
        elevation: 2,
        shadowColor: const Color.fromRGBO(0, 0, 0, 0.3),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF2B2930),
        indicatorColor: const Color.fromRGBO(149, 117, 205, 0.24),
      ),
    );
  }
}
