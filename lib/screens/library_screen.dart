
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../providers/library_provider.dart';
import '../providers/music_player_provider.dart';
import '../providers/playlist_provider.dart';
import '../models/playlist.dart';
import '../widgets/song_card.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  Future<void> _showAddToPlaylistDialog(BuildContext context, Map<String, dynamic> song) async {
    final playlistProvider = context.read<PlaylistProvider>();
    await playlistProvider.loadPlaylists();

    if (!context.mounted) return;

    if (playlistProvider.playlists.isEmpty) {
      final createNew = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Playlists'),
          content: const Text('You don\'t have any playlists yet. Would you like to create one?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Create Playlist'),
            ),
          ],
        ),
      );

      if (createNew == true) {
        await _showCreatePlaylistDialog(context, song['path']);
      }
      return;
    }

    final selectedPlaylist = await showDialog<Playlist>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add to Playlist'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: playlistProvider.playlists.length + 1,
            itemBuilder: (context, index) {
              if (index == playlistProvider.playlists.length) {
                return ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('Create New Playlist'),
                  onTap: () => Navigator.pop(context),
                );
              }
              final playlist = playlistProvider.playlists[index];
              return ListTile(
                leading: const Icon(Icons.playlist_play),
                title: Text(playlist.name),
                subtitle: Text('${playlist.songPaths.length} songs'),
                onTap: () => Navigator.pop(context, playlist),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedPlaylist != null) {
      try {
        await playlistProvider.addSongToPlaylist(
          selectedPlaylist.id,
          song['path'],
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Added to "${selectedPlaylist.name}"')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    } else {
      await _showCreatePlaylistDialog(context, song['path']);
    }
  }

  Future<void> _showCreatePlaylistDialog(BuildContext context, String songPath) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final playlistProvider = context.read<PlaylistProvider>();

    if (!context.mounted) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Playlist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Playlist Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.isNotEmpty) {
      try {
        final playlist = await playlistProvider.createPlaylist(
          nameController.text,
          description: descriptionController.text.isEmpty
              ? null
              : descriptionController.text,
        );
        if (playlist != null) {
          await playlistProvider.addSongToPlaylist(playlist.id, songPath);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Created "${playlist.name}" and added song')),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteSong(BuildContext context, Map<String, dynamic> song) async {
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Song'),
        content: Text('Delete "${song['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!context.mounted) return;
      final musicPlayerProvider = context.read<MusicPlayerProvider>();
      final libraryProvider = context.read<LibraryProvider>();
      if (musicPlayerProvider.currentlyPlayingPath == song['path']) {
        await musicPlayerProvider.stop();
      }
      await libraryProvider.deleteSong(song['path']);
      await libraryProvider.loadSongs();
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    final i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
  }

  Future<String> _getSongDuration(String path) async {
    final player = AudioPlayer();
    await player.setSourceDeviceFile(path);
    final duration = await player.getDuration();
    await player.dispose();
    if (duration == null) return '--:--';
    final m = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final libraryProvider = context.watch<LibraryProvider>();
    final musicPlayerProvider = context.watch<MusicPlayerProvider>();

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
                    : ListView.builder(
                        padding: EdgeInsets.only(
                          top: 8,
                          left: 12,
                          right: 12,
                          bottom: musicPlayerProvider.currentlyPlayingPath != null ? 120 : 20,
                        ),
                        itemCount: libraryProvider.songs.length,
                        itemBuilder: (context, index) {
                          final song = libraryProvider.songs[index];
                          final isPlaying = musicPlayerProvider.currentlyPlayingPath == song['path'];
                          
                          return SongCard(
                            song: song,
                            isPlaying: isPlaying && musicPlayerProvider.isPlaying,
                            onTap: () {
                              if (musicPlayerProvider.currentlyPlayingPath != song['path']) {
                                musicPlayerProvider.setQueue(libraryProvider.songs, initialIndex: index);
                              } else {
                                musicPlayerProvider.playSong(song['path']);
                              }
                            },
                            onPlay: () {
                              if (musicPlayerProvider.currentlyPlayingPath != song['path']) {
                                musicPlayerProvider.setQueue(libraryProvider.songs, initialIndex: index);
                              } else {
                                musicPlayerProvider.playSong(song['path']);
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
                                onTap: () {
                                  Future.delayed(
                                    const Duration(milliseconds: 100),
                                    () => _showAddToPlaylistDialog(context, song),
                                  );
                                },
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
                                onTap: () {
                                  Future.delayed(
                                    const Duration(milliseconds: 100),
                                    () => _deleteSong(context, song),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
          ),
        ],
      );
  }
}