import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oktoast/oktoast.dart';

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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MusicPlayerProvider()),
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



    final textTheme = Theme.of(context).textTheme;







    return OKToast(



      child: MaterialApp(

        navigatorObservers: [routeObserver],
        title: 'Music Library',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF7E57C2),
            brightness: Brightness.light,
            primary: const Color(0xFF7E57C2),
            secondary: const Color(0xFF9575CD),
            surface: const Color(0xFFFFFFFF),
          ),
          textTheme: GoogleFonts.interTextTheme(textTheme).copyWith(
            bodyMedium: GoogleFonts.inter(textStyle: textTheme.bodyMedium),
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF7E57C2),
            brightness: Brightness.dark,
            primary: const Color(0xFF9575CD),
            secondary: const Color(0xFFB39DDB),
            surface: const Color(0xFF1E1E1E),
            surfaceContainerHighest: const Color(0xFF121212),
          ),
          textTheme: GoogleFonts.interTextTheme(textTheme).copyWith(
            bodyMedium: GoogleFonts.inter(
              textStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
          ),
        ),
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}
