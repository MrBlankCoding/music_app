import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  final List<String> _titles = ['Search', 'Library', 'Playlists'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),

        actions: [
          // Show sort menu when on Library tab
          if (_selectedIndex == 1)
            Selector<LibraryProvider, SortOrder>(
              selector: (_, provider) => provider.sortOrder,
              builder: (context, sortOrder, child) {
                return PopupMenuButton<SortOrder>(
                  onSelected: (sortOrder) =>
                      context.read<LibraryProvider>().setSortOrder(sortOrder),

                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: SortOrder.dateNewest,
                      child: Text('Date Added (Newest)'),
                    ),

                    PopupMenuItem(
                      value: SortOrder.dateOldest,
                      child: Text('Date Added (Oldest)'),
                    ),

                    PopupMenuItem(
                      value: SortOrder.nameAz,
                      child: Text('Name (A-Z)'),
                    ),

                    PopupMenuItem(
                      value: SortOrder.nameZa,
                      child: Text('Name (Z-A)'),
                    ),

                    PopupMenuItem(
                      value: SortOrder.sizeLargest,
                      child: Text('Size (Largest)'),
                    ),

                    PopupMenuItem(
                      value: SortOrder.sizeSmallest,
                      child: Text('Size (Smallest)'),
                    ),
                  ],
                );
              },
            ),

          // Show refresh button when on Playlists tab
          if (_selectedIndex == 2)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => context.read<PlaylistProvider>().loadPlaylists(),
            ),

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
