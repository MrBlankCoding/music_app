
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/music_player_provider.dart';
import '../models/playlist.dart';
import 'dart:io';

class PlaylistDetailScreen extends StatelessWidget {
  final String playlistId;

  const PlaylistDetailScreen({super.key, required this.playlistId});

  Future<void> _removeSongFromPlaylist(BuildContext context, String songPath) async {
    // Store providers before async gap
    final musicPlayerProvider = context.read<MusicPlayerProvider>();
    final playlistProvider = context.read<PlaylistProvider>();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Song'),
        content: const Text('Remove this song from the playlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      if (musicPlayerProvider.currentlyPlayingPath == songPath) {
        await musicPlayerProvider.stop();
      }
      await playlistProvider.removeSongFromPlaylist(playlistId, songPath);
    }
  }

  Future<void> _editPlaylist(BuildContext context, Playlist playlist) async {
    // Store provider before async gap
    final nameController = TextEditingController(text: playlist.name);
    final descriptionController = TextEditingController(
      text: playlist.description ?? '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Playlist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Playlist Name',
                border: OutlineInputBorder(),
              ),
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
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.isNotEmpty && context.mounted) {
      final updatedPlaylist = playlist.copyWith(
        name: nameController.text,
        description: descriptionController.text.isEmpty
            ? null
            : descriptionController.text,
      );
      await context.read<PlaylistProvider>().updatePlaylist(updatedPlaylist);
    }
  }

  @override
  Widget build(BuildContext context) {
    final playlistProvider = context.watch<PlaylistProvider>();
    final musicPlayerProvider = context.watch<MusicPlayerProvider>();
    final playlist = playlistProvider.getPlaylistById(playlistId);

    if (playlist == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('Playlist not found.'),
        ),
      );
    }

    final songs = playlist.songPaths.map((path) {
      final file = File(path);
      if (file.existsSync()) {
        final stat = file.statSync();
        return {
          'path': path,
          'name': path.split('/').last.replaceAll('.mp3', '').replaceAll('_', ' '),
          'size': stat.size,
          'modified': stat.modified,
        };
      }
      return null;
    }).where((song) => song != null).toList().cast<Map<String, dynamic>>();

    return Scaffold(
      appBar: AppBar(
        title: Text(playlist.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editPlaylist(context, playlist),
          ),
        ],
      ),
      body: Column(
        children: [
          if (playlist.description != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                playlist.description!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          Expanded(
            child: songs.isEmpty
                ? const Center(
                    child: Text('No songs in this playlist'),
                  )
                : ReorderableListView.builder(
                    padding: EdgeInsets.only(
                      bottom: musicPlayerProvider.currentlyPlayingPath != null ? 120 : 0,
                    ),
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      final isPlaying = musicPlayerProvider.currentlyPlayingPath == song['path'];
                      return ListTile(
                        key: ValueKey(song['path']),
                        leading: Icon(
                          isPlaying && musicPlayerProvider.isPlaying
                              ? Icons.graphic_eq
                              : Icons.music_note,
                        ),
                        title: Text(song['name']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                isPlaying && musicPlayerProvider.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                              ),
                              onPressed: () {
                                if (musicPlayerProvider.currentlyPlayingPath != song['path']) {
                                  musicPlayerProvider.setQueue(songs, initialIndex: index);
                                } else {
                                  musicPlayerProvider.playSong(song['path']);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => _removeSongFromPlaylist(context, song['path']!),
                            ),
                          ],
                        ),
                        onTap: () {
                          if (musicPlayerProvider.currentlyPlayingPath != song['path']) {
                            musicPlayerProvider.setQueue(songs, initialIndex: index);
                          } else {
                            musicPlayerProvider.playSong(song['path']);
                          }
                        },
                      );
                    },
                    onReorder: (oldIndex, newIndex) {
                      if (newIndex > oldIndex) {
                        newIndex -= 1;
                      }
                      playlistProvider.reorderPlaylist(playlistId, oldIndex, newIndex);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}