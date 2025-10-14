
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_player_provider.dart';
import '../widgets/playback_bar.dart';
import 'music_search_screen.dart';
import 'library_screen.dart';
import 'playlists_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const MusicSearchScreen(),
    const LibraryScreen(),
    const PlaylistsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final musicPlayerProvider = context.watch<MusicPlayerProvider>();

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PlaybackBar(
            audioPlayer: musicPlayerProvider.audioPlayer,
            currentSong: musicPlayerProvider.currentSong,
            isPlaying: musicPlayerProvider.isPlaying,
            position: musicPlayerProvider.position,
            duration: musicPlayerProvider.duration,
            onPlayPause: () => musicPlayerProvider.playSong(musicPlayerProvider.currentlyPlayingPath!),
            onStop: musicPlayerProvider.stop,
            onNext: musicPlayerProvider.playQueue.length > 1 ? musicPlayerProvider.playNext : null,
            onPrevious: musicPlayerProvider.playQueue.length > 1 ? musicPlayerProvider.playPrevious : null,
            onShuffle: musicPlayerProvider.playQueue.length > 1 ? musicPlayerProvider.toggleShuffle : null,
            isShuffleEnabled: musicPlayerProvider.isShuffleEnabled,
          ),
          NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.search),
                selectedIcon: Icon(Icons.search),
                label: 'Search',
              ),
              NavigationDestination(
                icon: Icon(Icons.library_music_outlined),
                selectedIcon: Icon(Icons.library_music),
                label: 'Library',
              ),
              NavigationDestination(
                icon: Icon(Icons.playlist_play),
                selectedIcon: Icon(Icons.playlist_play),
                label: 'Playlists',
              ),
            ],
          ),
        ],
      ),
    );
  }
}