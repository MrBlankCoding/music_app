
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_player_provider.dart';
import '../providers/library_provider.dart';
import '../providers/playlist_provider.dart';
import '../services/download_service.dart';
import '../widgets/playback_bar.dart';
import 'music_search_screen.dart';
import 'library_screen.dart';
import 'playlists_screen.dart';
import 'download_queue_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  final List<Widget> _screens = [
    const MusicSearchScreen(),
    const LibraryScreen(),
    const PlaylistsScreen(),
  ];

  final List<String> _titles = [
    'Search',
    'Library',
    'Playlists',
  ];

  @override
  Widget build(BuildContext context) {
    final musicPlayerProvider = context.watch<MusicPlayerProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          // Show sort menu when on Library tab
          if (_selectedIndex == 1)
            Consumer<LibraryProvider>(
              builder: (context, libraryProvider, child) {
                return PopupMenuButton<SortOrder>(
                  onSelected: (sortOrder) => libraryProvider.setSortOrder(sortOrder),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: SortOrder.dateNewest, child: Text('Date Added (Newest)')),
                    PopupMenuItem(value: SortOrder.dateOldest, child: Text('Date Added (Oldest)')),
                    PopupMenuItem(value: SortOrder.nameAz, child: Text('Name (A-Z)')),
                    PopupMenuItem(value: SortOrder.nameZa, child: Text('Name (Z-A)')),
                    PopupMenuItem(value: SortOrder.sizeLargest, child: Text('Size (Largest)')),
                    PopupMenuItem(value: SortOrder.sizeSmallest, child: Text('Size (Smallest)')),
                  ],
                );
              },
            ),
          // Show refresh button when on Playlists tab
          if (_selectedIndex == 2)
            Consumer<PlaylistProvider>(
              builder: (context, playlistProvider, child) {
                return IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => playlistProvider.loadPlaylists(),
                );
              },
            ),
          Consumer<DownloadService>(
            builder: (context, downloadService, child) {
              if (downloadService.downloadQueue.isEmpty) {
                return const SizedBox.shrink();
              }
              return IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DownloadQueueScreen(),
                    ),
                  );
                },
                icon: Badge(
                  label: Text(downloadService.downloadQueue.length.toString()),
                  child: const Icon(Icons.download),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          _screens[_selectedIndex],
          // Overlay the playback bar on top of the body content, pinned to bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: PlaybackBar(
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
              bottomPadding: 80, // keep minimized bar above NavigationBar
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
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
    );
  }
}