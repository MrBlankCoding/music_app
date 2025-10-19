import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/library_provider.dart';
import '../models/playlist.dart';
import '../widgets/playlist_dialogs.dart';
import 'playlist_detail_screen.dart';

class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  Future<void> _showCreatePlaylistDialog(BuildContext context) async {
    await PlaylistDialogs.showCreatePlaylistDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    final playlistProvider = context.watch<PlaylistProvider>();

    return Scaffold(
      body: playlistProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : playlistProvider.playlists.isEmpty
              ? _buildEmptyState(context)
              : _buildPlaylistGrid(context, playlistProvider),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePlaylistDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Create Playlist'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.playlist_play,
            size: 80,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistGrid(
    BuildContext context,
    PlaylistProvider playlistProvider,
  ) {
    return RefreshIndicator(
      onRefresh: playlistProvider.loadPlaylists,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: playlistProvider.playlists.length,
        itemBuilder: (context, index) {
          final playlist = playlistProvider.playlists[index];
          return Dismissible(
            key: Key('playlist_${playlist.id}'),
            direction: DismissDirection.endToStart,
            background: _buildDismissBackground(context),
            confirmDismiss: (_) =>
                PlaylistDialogs.showDeletePlaylistConfirmationDialog(context, playlist.name),
            onDismissed: (_) =>
                _handlePlaylistDismissed(context, playlistProvider, playlist),
            child: _PlaylistCard(
              playlist: playlist,
              onTap: () => _navigateToPlaylistDetail(context, playlist.id),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDismissBackground(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.delete, color: Colors.white, size: 32),
    );
  }

  Future<void> _handlePlaylistDismissed(
    BuildContext context,
    PlaylistProvider playlistProvider,
    Playlist playlist,
  ) async {
    await playlistProvider.deletePlaylist(playlist.id);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('"${playlist.name}" deleted')));
    }
  }

  void _navigateToPlaylistDetail(BuildContext context, String playlistId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaylistDetailScreen(playlistId: playlistId),
      ),
    ).then((_) {
      if (context.mounted) {
        context.read<PlaylistProvider>().loadPlaylists();
      }
    });
  }
}

class _PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onTap;

  const _PlaylistCard({required this.playlist, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Hero(
                tag: 'playlist_${playlist.id}',
                child: _PlaylistArtwork(playlist: playlist),
              ),
              const SizedBox(width: 16),
              Expanded(child: _PlaylistInfo(playlist: playlist)),
              _PlaylistOptionsButton(playlist: playlist),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaylistArtwork extends StatelessWidget {
  final Playlist playlist;

  const _PlaylistArtwork({required this.playlist});

  @override
  Widget build(BuildContext context) {
    final thumbnails = _getThumbnails(context);
    final boxDecoration = BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).shadowColor.withAlpha(25),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );

    if (thumbnails.isEmpty) {
      return _buildEmptyArtwork(context, boxDecoration);
    }

    if (thumbnails.length == 1) {
      return _buildSingleArtwork(context, thumbnails[0], boxDecoration);
    }

    return _buildGridArtwork(context, thumbnails, boxDecoration);
  }

  List<String> _getThumbnails(BuildContext context) {
    final libraryProvider = context.watch<LibraryProvider>();
    final thumbnails = <String>[];

    for (var song in playlist.songs.take(4)) {
      final storedPath = song['path'] as String?;
      if (storedPath == null) continue;

      final filename = storedPath.split('/').last;
      final librarySong = libraryProvider.songs.firstWhere(
        (s) => (s['path'] as String).split('/').last == filename,
        orElse: () => <String, dynamic>{},
      );

      final thumbnailUrl = librarySong.isNotEmpty
          ? librarySong['thumbnail_url']
          : song['thumbnail_url'];

      if (thumbnailUrl != null) {
        thumbnails.add(thumbnailUrl as String);
      }
    }

    return thumbnails;
  }

  Widget _buildEmptyArtwork(BuildContext context, BoxDecoration decoration) {
    return Container(
      width: 80,
      height: 80,
      decoration: decoration.copyWith(
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

  Widget _buildSingleArtwork(
    BuildContext context,
    String url,
    BoxDecoration decoration,
  ) {
    return Container(
      width: 80,
      height: 80,
      decoration: decoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          url,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackIcon(context),
        ),
      ),
    );
  }

  Widget _buildGridArtwork(
    BuildContext context,
    List<String> thumbnails,
    BoxDecoration decoration,
  ) {
    return Container(
      width: 80,
      height: 80,
      decoration: decoration,
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
                errorBuilder: (_, __, ___) => _buildGridPlaceholder(context),
              );
            }
            return _buildGridPlaceholder(context);
          },
        ),
      ),
    );
  }

  Widget _buildFallbackIcon(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Icon(
        Icons.queue_music,
        size: 40,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildGridPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.music_note,
        size: 16,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _PlaylistInfo extends StatelessWidget {
  final Playlist playlist;

  const _PlaylistInfo({required this.playlist});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          playlist.name,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (playlist.description != null) ...[
          const SizedBox(height: 4),
          Text(
            playlist.description!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.music_note,
            ),
            const SizedBox(width: 4),
            Text(
              '${playlist.songCount} songs',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PlaylistOptionsButton extends StatelessWidget {
  final Playlist playlist;

  const _PlaylistOptionsButton({required this.playlist});

  @override
  Widget build(BuildContext context) {
    return IconButton(
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
                  onTap: () async {
                    Navigator.pop(context);
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
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.error,
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (context.mounted && confirmed == true) {
                      await context.read<PlaylistProvider>().deletePlaylist(
                        playlist.id,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('"${playlist.name}" deleted')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
