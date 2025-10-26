import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/library_provider.dart';
import '../providers/music_player_provider.dart';
import '../widgets/song_card.dart';
import '../widgets/song_grid_item.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/playlist_dialogs.dart';
import '../services/song_management_service.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredSongs = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      final libraryProvider = context.read<LibraryProvider>();
      _filteredSongs = libraryProvider.songs.where((song) {
        final title = song['title']?.toLowerCase() ?? '';
        final artist = song['artist']?.toLowerCase() ?? '';
        return title.contains(query.toLowerCase()) || artist.contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final libraryProvider = context.watch<LibraryProvider>();
    final musicPlayerProvider = context.watch<MusicPlayerProvider>();
    final theme = Theme.of(context);
    final songManagementService = SongManagementService(context);

    final songs = _searchController.text.isEmpty ? libraryProvider.songs : _filteredSongs;

    return Column(
      children: [
        SearchBarWidget(
          controller: _searchController,
          onChanged: _onSearchChanged,
          hintText: 'Search songs...',
        ),
        Expanded(
          child: libraryProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : songs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.music_off_rounded,
                            size: 64,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No songs found',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          if (_searchController.text.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Try a different search term',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 8),
                            Text(
                              'Add some music to get started',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        await libraryProvider.loadSongs();
                      },
                      child: libraryProvider.isGridView 
                          ? GridView.builder(
                              padding: const EdgeInsets.all(12),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.8,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: songs.length,
                              itemBuilder: (context, index) {
                                final song = songs[index];

                                return SongGridItem(
                                  song: song,
                                  onTap: () async {
                                    if (musicPlayerProvider.currentSong?['path'] != song['path']) {
                                      await musicPlayerProvider.setQueue(songs, index);
                                    } else {
                                      musicPlayerProvider.playPause();
                                    }
                                  },
                                );
                              },
                            )
                          : _buildListView(songs, musicPlayerProvider, songManagementService, context),
                    ),
        ),
      ],
    );
  }

  Widget _buildListView(List<Map<String, dynamic>> songs, 
                       MusicPlayerProvider musicPlayerProvider, 
                       SongManagementService songManagementService, 
                       BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80, left: 12, right: 12, top: 4),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        final isPlaying = musicPlayerProvider.currentSong?['path'] == song['path'];

        return SongCard(
          song: song,
          isPlaying: isPlaying && musicPlayerProvider.isPlaying,
          onTap: () async {
            if (musicPlayerProvider.currentSong?['path'] != song['path']) {
              await musicPlayerProvider.setQueue(
                songs,
                index,
              );
            } else {
              musicPlayerProvider.playPause();
            }
          },
          onPlay: () async {
            if (musicPlayerProvider.currentSong?['path'] != song['path']) {
              await musicPlayerProvider.setQueue(
                songs,
                index,
              );
            } else {
              musicPlayerProvider.playPause();
            }
          },
          menuItems: [
            PopupMenuItem<String>(
              value: 'add_to_playlist',
              child: ListTile(
                leading: const Icon(Icons.playlist_add),
                title: const Text('Add to Playlist'),
                contentPadding: EdgeInsets.zero,
              ),
              onTap: () => PlaylistDialogs.showAddToPlaylistDialog(context, song),
            ),
            PopupMenuItem<String>(
              value: 'delete',
              child: ListTile(
                leading: Icon(
                  Icons.delete,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Delete',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                contentPadding: EdgeInsets.zero,
              ),
              onTap: () => songManagementService.deleteSong(song['path']),
            ),
          ],
        );
      },
    );
  }


}
