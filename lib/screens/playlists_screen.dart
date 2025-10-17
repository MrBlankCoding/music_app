import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../providers/playlist_provider.dart';
import '../providers/library_provider.dart';
import '../models/playlist.dart';
import 'playlist_detail_screen.dart';

class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  Future<void> _showCreatePlaylistDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

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

    if (result == true && nameController.text.isNotEmpty && context.mounted) {
      await context.read<PlaylistProvider>().createPlaylist(
            nameController.text,
            description: descriptionController.text.isEmpty
                ? null
                : descriptionController.text,
          );
    }

    nameController.dispose();
    descriptionController.dispose();
  }

  Future<void> _deletePlaylist(BuildContext context, Playlist playlist) async {
    final confirmed = await showDialog<bool>(
      context: context,
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

    if (context.mounted && confirmed == true) {
      await context.read<PlaylistProvider>().deletePlaylist(playlist.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final playlistProvider = context.watch<PlaylistProvider>();

    return Scaffold(
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
                        'Make a playlist!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount: playlistProvider.playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlistProvider.playlists[index];
                    return _PlaylistCard(
                      playlist: playlist,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlaylistDetailScreen(
                              playlistId: playlist.id,
                            ),
                          ),
                        ).then((_) {
                          if (context.mounted) {
                            context.read<PlaylistProvider>().loadPlaylists();
                          }
                        });
                      },
                      onDelete: () => _deletePlaylist(context, playlist),
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

class _PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PlaylistCard({
    required this.playlist,
    required this.onTap,
    required this.onDelete,
  });

  Future<String> _getPlaylistDuration() async {
    final player = AudioPlayer();
    int totalSeconds = 0;

    for (final songPath in playlist.songPaths) {
      try {
        await player.setSourceDeviceFile(songPath);
        final duration = await player.getDuration();
        if (duration != null) {
          totalSeconds += duration.inSeconds;
        }
      } catch (e) {
        // Skip songs that can't be loaded
        continue;
      }
    }

    await player.dispose();

    final duration = Duration(seconds: totalSeconds);
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);

    if (h > 0) {
      return '${h}h ${m}m';
    }
    return '${m}m';
  }

  Widget _buildPlaylistArtwork(BuildContext context) {
    final libraryProvider = context.watch<LibraryProvider>();

    // Get thumbnails from the first 4 songs in the playlist
    final thumbnails = <String>[];
    for (var songPath in playlist.songPaths.take(4)) {
      final song = libraryProvider.songs.firstWhere(
        (s) => s['path'] == songPath,
        orElse: () => <String, dynamic>{},
      );
      if (song.isNotEmpty && song['thumbnail_url'] != null) {
        thumbnails.add(song['thumbnail_url'] as String);
      }
    }

    final boxDecoration = BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );

    // No thumbnails available
    if (thumbnails.isEmpty) {
      return Container(
        width: 80,
        height: 80,
        decoration: boxDecoration.copyWith(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.secondaryContainer,
            ],
          ),
        ),
        child: Icon(
          Icons.queue_music,
          size: 40,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    // Single thumbnail
    if (thumbnails.length == 1) {
      return Container(
        width: 80,
        height: 80,
        decoration: boxDecoration,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            thumbnails[0],
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.queue_music,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
              );
            },
          ),
        ),
      );
    }

    // Multiple thumbnails - 2x2 grid
    return Container(
      width: 80,
      height: 80,
      decoration: boxDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
          ),
          itemCount: 4,
          itemBuilder: (context, i) {
            if (i < thumbnails.length) {
              return Image.network(
                thumbnails[i],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.music_note,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  );
                },
              );
            }
            return Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.music_note,
                size: 16,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withOpacity(0.5),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 6,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Playlist Artwork
              Hero(
                tag: 'playlist_${playlist.id}',
                child: _buildPlaylistArtwork(context),
              ),
              const SizedBox(width: 16),
              // Playlist Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (playlist.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        playlist.description!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    FutureBuilder<String>(
                      future: _getPlaylistDuration(),
                      builder: (context, snapshot) {
                        final duration = snapshot.data ?? 'Calculating...';
                        return Row(
                          children: [
                            Icon(
                              Icons.music_note,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${playlist.songPaths.length} songs',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            if (snapshot.hasData &&
                                playlist.songPaths.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                '•',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                duration,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              // More Options Button
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: Icon(
                              Icons.delete,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            title: Text(
                              'Delete Playlist',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              onDelete();
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}