import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/library_provider.dart';
import '../providers/music_player_provider.dart';
import '../widgets/song_card.dart';
import '../widgets/playlist_dialogs.dart';
import '../services/song_management_service.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final libraryProvider = context.watch<LibraryProvider>();
    final musicPlayerProvider = context.watch<MusicPlayerProvider>();
    final songManagementService = SongManagementService(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            onChanged: (value) => libraryProvider.setFilterQuery(value),
            decoration: const InputDecoration(
              hintText: 'Search library...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: libraryProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : libraryProvider.songs.isEmpty
                  ? const Center(child: Text('No songs'))
                  : RefreshIndicator(
                      onRefresh: () async {
                        await libraryProvider.loadSongs();
                      },
                      child: ListView.builder(
                        padding: EdgeInsets.only(
                          top: 8,
                          left: 12,
                          right: 12,
                          bottom: musicPlayerProvider.currentSong != null
                              ? 120
                              : 20,
                        ),
                        itemCount: libraryProvider.songs.length,
                        itemBuilder: (context, index) {
                          final song = libraryProvider.songs[index];
                          final isPlaying =
                              musicPlayerProvider.currentSong?['path'] ==
                                  song['path'];

                          return SongCard(
                            song: song,
                            isPlaying: isPlaying && musicPlayerProvider.isPlaying,
                            enableSwipeToDelete: true,
                            deleteConfirmMessage:
                                'Delete this song from your library? This action cannot be undone.',
                            onDelete: () async {
                              await songManagementService.deleteSong(song['path']);
                            },
                            onTap: () async {
                              if (musicPlayerProvider.currentSong?['path'] !=
                                  song['path']) {
                                await musicPlayerProvider.setQueue(
                                  libraryProvider.songs,
                                  initialIndex: index,
                                );
                              } else {
                                musicPlayerProvider.playPause();
                              }
                            },
                            onPlay: () async {
                              if (musicPlayerProvider.currentSong?['path'] !=
                                  song['path']) {
                                await musicPlayerProvider.setQueue(
                                  libraryProvider.songs,
                                  initialIndex: index,
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
                      ),
                    ),
        ),
      ],
    );
  }
}
