import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/music_player_provider.dart';
import '../providers/library_provider.dart';
import '../models/playlist.dart';
import '../widgets/song_card.dart';
import '../widgets/playback_bar.dart';
import 'home_screen.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final String playlistId;

  const PlaylistDetailScreen({super.key, required this.playlistId});

  Future<void> _removeSongFromPlaylist(
    BuildContext context,
    String songPath,
  ) async {
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
      final musicPlayerProvider = context.read<MusicPlayerProvider>();
      final playlistProvider = context.read<PlaylistProvider>();

      if (musicPlayerProvider.currentlyPlayingPath == songPath) {
        await musicPlayerProvider.stop();
      }
      await playlistProvider.removeSongFromPlaylist(playlistId, songPath);
    }
  }

  Future<void> _editPlaylist(BuildContext context, Playlist playlist) async {
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

    nameController.dispose();
    descriptionController.dispose();
  }

  List<Map<String, dynamic>> _getSongsWithMetadata(
    Playlist playlist,
    LibraryProvider libraryProvider,
  ) {
    return playlist.songPaths.map((path) {
      // Try to find the song in the library with metadata
      final librarySong = libraryProvider.songs.firstWhere(
        (s) => s['path'] == path,
        orElse: () => <String, dynamic>{},
      );

      if (librarySong.isNotEmpty) {
        return librarySong;
      }
      return null;
    }).whereType<Map<String, dynamic>>().toList();
  }

  Future<void> _handleSongTap(
    MusicPlayerProvider musicPlayerProvider,
    Map<String, dynamic> song,
    List<Map<String, dynamic>> songs,
    int index,
  ) async {
    if (musicPlayerProvider.currentlyPlayingPath != song['path']) {
      await musicPlayerProvider.setQueue(songs, initialIndex: index);
    } else {
      await musicPlayerProvider.playSong(song['path'] as String);
    }
  }

  Widget _buildPlaylistArtwork(BuildContext context, Playlist playlist, LibraryProvider libraryProvider) {
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

    final double size = 200;

    if (thumbnails.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.secondaryContainer,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          Icons.queue_music,
          size: 72,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    if (thumbnails.length == 1) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            thumbnails[0],
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.queue_music,
                  size: 72,
                  color: Theme.of(context).colorScheme.primary,
                ),
              );
            },
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 3,
            crossAxisSpacing: 3,
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
                      size: 24,
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
                size: 24,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playlistProvider = context.watch<PlaylistProvider>();
    final musicPlayerProvider = context.watch<MusicPlayerProvider>();
    final libraryProvider = context.watch<LibraryProvider>();
    final playlist = playlistProvider.getPlaylistById(playlistId);

    if (playlist == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('Playlist not found.'),
        ),
      );
    }

    final songs = _getSongsWithMetadata(playlist, libraryProvider);

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
          const SizedBox(height: 16),
          Center(
            child: Hero(
              tag: 'playlist_${playlist.id}',
              child: _buildPlaylistArtwork(context, playlist, libraryProvider),
            ),
          ),
          if (playlist.description != null) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                playlist.description!,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Expanded(
            child: songs.isEmpty
                ? const Center(
                    child: Text('No songs in this playlist'),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.only(bottom: 0),
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      final songPath = song['path'] as String;
                      final isPlaying =
                          musicPlayerProvider.currentlyPlayingPath == songPath;

                      return SongCard(
                        key: ValueKey(songPath),
                        cardKey: ValueKey(songPath),
                        song: song,
                        isPlaying: isPlaying && musicPlayerProvider.isPlaying,
                        showDragHandle: true,
                        reorderIndex: index,
                        onTap: () => _handleSongTap(
                          musicPlayerProvider,
                          song,
                          songs,
                          index,
                        ),
                        onPlay: () => _handleSongTap(
                          musicPlayerProvider,
                          song,
                          songs,
                          index,
                        ),
                        menuItems: [
                          PopupMenuItem<String>(
                            value: 'remove',
                            child: ListTile(
                              leading: Icon(
                                Icons.remove_circle_outline,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              title: Text(
                                'Remove from Playlist',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                            onTap: () {
                              Future.delayed(
                                const Duration(milliseconds: 100),
                                () => _removeSongFromPlaylist(context, songPath),
                              );
                            },
                          ),
                        ],
                      );
                    },
                    onReorder: (oldIndex, newIndex) {
                      if (newIndex > oldIndex) {
                        newIndex -= 1;
                      }
                      playlistProvider.reorderPlaylist(
                        playlistId,
                        oldIndex,
                        newIndex,
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PlaybackBar(
            audioPlayer: musicPlayerProvider.audioPlayer,
            currentSong: musicPlayerProvider.currentSong,
            isPlaying: musicPlayerProvider.isPlaying,
            position: musicPlayerProvider.position,
            duration: musicPlayerProvider.duration,
            onPlayPause: () => musicPlayerProvider
                .playSong(musicPlayerProvider.currentlyPlayingPath!),
            onStop: musicPlayerProvider.stop,
            onNext: musicPlayerProvider.playQueue.length > 1
                ? musicPlayerProvider.playNext
                : null,
            onPrevious: musicPlayerProvider.playQueue.length > 1
                ? musicPlayerProvider.playPrevious
                : null,
            onShuffle: musicPlayerProvider.playQueue.length > 1
                ? musicPlayerProvider.toggleShuffle
                : null,
            isShuffleEnabled: musicPlayerProvider.isShuffleEnabled,
          ),
          NavigationBar(
            selectedIndex: 2,
            onDestinationSelected: (index) {
              if (index != 2) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => HomeScreen(initialIndex: index),
                  ),
                  (route) => false,
                );
              }
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
        ],
      ),
    );
  }
}