import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/library_provider.dart';
import '../models/playlist.dart';
import '../utils/playlist_artwork_helper.dart';
import '../widgets/playlist_dialogs.dart';
import '../widgets/search_bar_widget.dart';
import 'playlist_detail_screen.dart';

class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showCreatePlaylistDialog(BuildContext context) async {
    await PlaylistDialogs.showCreatePlaylistDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    final playlistProvider = context.watch<PlaylistProvider>();
    final query = _searchController.text.toLowerCase();
    final playlists = playlistProvider.playlists
        .where((p) => p.name.toLowerCase().contains(query))
        .toList();

    return Scaffold(
      body: Column(
        children: [
          SearchBarWidget(
            controller: _searchController,
            hintText: 'Search playlists...',
            onChanged: (value) => setState(() {}),
          ),
          Expanded(
            child: playlistProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : playlists.isEmpty
                    ? _buildEmptyState(context)
                    : playlistProvider.isGridView
                        ? _buildPlaylistGrid(context, playlists)
                        : _buildPlaylistList(context, playlists),
          ),
        ],
      ),
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
    List<Playlist> playlists,
  ) {
    final playlistProvider = context.read<PlaylistProvider>();
    return RefreshIndicator(
      onRefresh: playlistProvider.loadPlaylists,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: playlists.length,
        itemBuilder: (context, index) {
          final playlist = playlists[index];
          return _PlaylistGridItem(
            playlist: playlist,
            onTap: () => _navigateToPlaylistDetail(context, playlist.id),
          );
        },
      ),
    );
  }

  Widget _buildPlaylistList(
    BuildContext context,
    List<Playlist> playlists,
  ) {
    final playlistProvider = context.read<PlaylistProvider>();
    return RefreshIndicator(
      onRefresh: playlistProvider.loadPlaylists,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: playlists.length,
        itemBuilder: (context, index) {
          final playlist = playlists[index];
          return _PlaylistListItem(
            playlist: playlist,
            onTap: () => _navigateToPlaylistDetail(context, playlist.id),
            onDelete: () async {
              await playlistProvider.deletePlaylist(playlist.id);
            },
          );
        },
      ),
    );
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

class _PlaylistGridItem extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onTap;

  const _PlaylistGridItem({required this.playlist, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Hero(
              tag: 'playlist_${playlist.id}',
              child: _PlaylistArtwork(playlist: playlist),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            playlist.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${playlist.songCount} songs, ${_formatDuration(playlist.songs)} total',
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

String _formatDuration(List<Map<String, dynamic>> songs) {
  // Duration is stored in milliseconds, convert to seconds
  final totalMs = songs.fold<int>(
    0,
    (prev, song) => prev + (song['duration'] as int? ?? 0),
  );
  
  final totalSeconds = (totalMs / 1000).round();
  final duration = Duration(seconds: totalSeconds);
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);

  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

class _PlaylistListItem extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onTap;
  final Future<void> Function()? onDelete;

  const _PlaylistListItem({
    required this.playlist,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cardWidget = Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 60,
            height: 60,
            child: _PlaylistArtwork(playlist: playlist),
          ),
        ),
        title: Text(
          playlist.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        subtitle: Text(
          '${playlist.songCount} songs, ${_formatDuration(playlist.songs)} total',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        onTap: onTap,
      ),
    );

    if (onDelete == null) {
      return cardWidget;
    }

    return Dismissible(
      key: Key('playlist_${playlist.id}'),
      direction: DismissDirection.endToStart,
      movementDuration: const Duration(milliseconds: 200),
      dismissThresholds: const {
        DismissDirection.endToStart: 0.3,
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        color: Theme.of(context).colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(
          Icons.delete_rounded,
          color: Colors.white,
          size: 32,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Delete Playlist'),
            content: Text('Are you sure you want to delete "${playlist.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        await onDelete!();
      },
      child: cardWidget,
    );
  }

  String _formatDuration(List<Map<String, dynamic>> songs) {
    // Duration is stored in milliseconds, convert to seconds
    final totalMs = songs.fold<int>(
      0,
      (prev, song) => prev + (song['duration'] as int? ?? 0),
    );
    
    final totalSeconds = (totalMs / 1000).round();
    final duration = Duration(seconds: totalSeconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class _PlaylistArtwork extends StatelessWidget {
  final Playlist playlist;

  const _PlaylistArtwork({required this.playlist});

  @override
  Widget build(BuildContext context) {
    final albumArts = context.select<LibraryProvider, List<Uint8List>>(
      (libraryProvider) => PlaylistArtworkHelper.getAlbumArts(
        playlist,
        libraryProvider.songs,
      ),
    );

    if (albumArts.isEmpty) {
      return _buildEmptyArtwork(context);
    }

    if (albumArts.length == 1) {
      return _buildSingleArtwork(context, albumArts[0]);
    }

    return _buildGridArtwork(context, albumArts);
  }

  Widget _buildEmptyArtwork(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
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

  Widget _buildSingleArtwork(BuildContext context, Uint8List albumArt) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.memory(
        albumArt,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallbackIcon(context),
      ),
    );
  }

  Widget _buildGridArtwork(BuildContext context, List<Uint8List> albumArts) {
    return ClipRRect(
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
          if (i < albumArts.length) {
            return Image.memory(
              albumArts[i],
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildGridPlaceholder(context),
            );
          }
          return _buildGridPlaceholder(context);
        },
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