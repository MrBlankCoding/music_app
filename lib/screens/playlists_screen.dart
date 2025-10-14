
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../providers/playlist_provider.dart';
import '../models/playlist.dart';
import 'playlist_detail_screen.dart';

class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  Future<String> _getPlaylistDuration(Playlist playlist) async {
    final player = AudioPlayer();
    int totalSeconds = 0;
    for (final songPath in playlist.songPaths) {
      await player.setSourceDeviceFile(songPath);
      final duration = await player.getDuration();
      if (duration != null) {
        totalSeconds += duration.inSeconds;
      }
    }
    await player.dispose();
    final duration = Duration(seconds: totalSeconds);
    final m = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _showCreatePlaylistDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final playlistProvider = context.read<PlaylistProvider>();

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
      await playlistProvider.createPlaylist(
        nameController.text,
        description: descriptionController.text.isEmpty
            ? null
            : descriptionController.text,
      );
    }
  }

  Future<void> _deletePlaylist(BuildContext context, Playlist playlist) async {
    final contextBeforeAsync = context;
  
    final confirmed = await showDialog<bool>(
      context: contextBeforeAsync,
      builder: (context) => AlertDialog(
        title: const Text('Delete Playlist'),
        content: Text('Delete "${playlist.name}"?'),
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

    if (contextBeforeAsync.mounted && confirmed == true) {
      await contextBeforeAsync.read<PlaylistProvider>().deletePlaylist(playlist.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final playlistProvider = context.watch<PlaylistProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => playlistProvider.loadPlaylists(),
          ),
        ],
      ),
      body: playlistProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : playlistProvider.playlists.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.playlist_play,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No playlists yet',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create a playlist to get started',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: playlistProvider.playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlistProvider.playlists[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.playlist_play,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        title: Text(playlist.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (playlist.description != null)
                              Text(
                                playlist.description!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            FutureBuilder<String>(
                              future: _getPlaylistDuration(playlist),
                              builder: (context, snapshot) {
                                final duration = snapshot.data ?? '--:--';
                                return Text('${playlist.songPaths.length} songs • $duration');
                              },
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deletePlaylist(context, playlist),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlaylistDetailScreen(
                                playlistId: playlist.id,
                              ),
                            ),
                          ).then((_) => playlistProvider.loadPlaylists());
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePlaylistDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Create Playlist'),
      ),
    );
  }
}