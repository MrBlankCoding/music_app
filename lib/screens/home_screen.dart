import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/library_provider.dart';
import '../providers/playlist_provider.dart';
import '../services/download_service.dart';
import '../widgets/playback_bar.dart';

import 'music_search_screen.dart';
import 'playlists_screen.dart';
import 'library_screen.dart';
import 'download_queue_screen.dart';
import 'queue_screen.dart';


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

    // Kick off initial data loads after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<LibraryProvider>().loadSongs();
      context.read<PlaylistProvider>().loadPlaylists();
    });
  }

  final List<Widget> _screens = [
    const MusicSearchScreen(),

    const LibraryScreen(),

    const PlaylistsScreen(),
  ];

  final List<String> _titles = ['Search', 'Library', 'Playlists'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),

        actions: [
          if (_selectedIndex == 1) ...[
            IconButton(
              icon: const Icon(Icons.queue_music),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const QueueScreen()),
                );
              },
              tooltip: 'Queue',
            ),
            Consumer<LibraryProvider>(
              builder: (context, libraryProvider, child) => IconButton(
                icon: Icon(libraryProvider.isGridView ? Icons.list : Icons.grid_view),
                onPressed: () => libraryProvider.toggleView(),
                tooltip: libraryProvider.isGridView ? 'List View' : 'Grid View',
              ),
            ),
          ],

          // Show refresh button when on Playlists tab
          if (_selectedIndex == 2)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => context.read<PlaylistProvider>().loadPlaylists(),
            ),

/*
          if (_selectedIndex == 0) ...[
            IconButton(
              icon: const Icon(Icons.playlist_add),
              onPressed: () => _showDownloadPlaylistDialog(context),
            ),
          ],
*/

          Selector<DownloadService, int>(
            selector: (_, service) => service.downloadQueue.length,
            builder: (context, queueLength, child) {
              if (queueLength == 0) {
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
                  label: Text(queueLength.toString()),
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
          const Align(
            alignment: Alignment.bottomCenter,

            child: PlaybackBar(
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
