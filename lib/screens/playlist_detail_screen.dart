import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/music_player_provider.dart';
import '../providers/library_provider.dart';
import '../models/playlist.dart';
import '../widgets/song_card.dart';
import '../widgets/playback_bar.dart';
import '../widgets/playlist_dialogs.dart';
import '../widgets/song_grid_item.dart';
import '../services/song_management_service.dart';

import 'home_screen.dart';
import '../utils/playlist_artwork_helper.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final String playlistId;

  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  bool _isGridView = false;

  // Cache for reconciled songs to avoid recomputation on every build
  List<Map<String, dynamic>>? _cachedSongs;
  String? _cachedPlaylistId;
  int? _cachedPlaylistSongsHash;
  int? _cachedLibrarySongsHash;

  List<Map<String, dynamic>> _getReconciledSongs(
    Playlist playlist,
    List<Map<String, dynamic>> librarySongs,
  ) {
    // Compute hash codes for change detection
    final playlistHash = Object.hashAll(playlist.songs.map((s) => s['path']));
    final libraryHash = Object.hashAll(librarySongs.map((s) => s['path']));

    // Return cached result if nothing changed
    if (_cachedSongs != null &&
        _cachedPlaylistId == playlist.id &&
        _cachedPlaylistSongsHash == playlistHash &&
        _cachedLibrarySongsHash == libraryHash) {
      return _cachedSongs!;
    }

    // Recompute and cache
    final songManagementService = SongManagementService(context);
    final reconciled = songManagementService.getReconciledPlaylistSongs(
      playlist,
    );

    _cachedSongs = reconciled;
    _cachedPlaylistId = playlist.id;
    _cachedPlaylistSongsHash = playlistHash;
    _cachedLibrarySongsHash = libraryHash;

    return reconciled;
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

  Future<void> _removeSongFromPlaylist(
    BuildContext context,
    String songPath,
  ) async {
    if (!context.mounted) return;

    final musicPlayerProvider = context.read<MusicPlayerProvider>();
    final playlistProvider = context.read<PlaylistProvider>();

    if (musicPlayerProvider.currentSong?['path'] == songPath) {
      await musicPlayerProvider.stop();
    }
    await playlistProvider.removeSongFromPlaylist(widget.playlistId, songPath);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Song removed from playlist'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleSongTap(
    MusicPlayerProvider musicPlayerProvider,
    Map<String, dynamic> song,
    List<Map<String, dynamic>> songs,
    int index,
  ) async {
    if (musicPlayerProvider.currentSong?['path'] != song['path']) {
      await musicPlayerProvider.setQueue(songs, index);
    } else {
      musicPlayerProvider.playPause();
    }
  }

  Widget _buildPlaylistArtwork(
    BuildContext context,
    Playlist playlist,
    LibraryProvider libraryProvider,
  ) {
    // Use reconciled songs for accurate meta data
    final songs = _getReconciledSongs(playlist, libraryProvider.songs);
    final albumArts = PlaylistArtworkHelper.getAlbumArts(playlist, songs);

    const double size = 200;

    if (albumArts.isEmpty) {
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
              color: Theme.of(context).shadowColor.withAlpha(25),
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

    if (albumArts.length == 1) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withAlpha(25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.memory(
            albumArts[0],
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
            color: Colors.black.withAlpha(25),
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
            if (i < albumArts.length) {
              return Image.memory(
                albumArts[i],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
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
    final playlist = playlistProvider.getPlaylistById(widget.playlistId);

    if (playlist == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Playlist not found.')),
      );
    }

    // Use cached reconciled songs to avoid recomputation on every build
    final songs = _getReconciledSongs(playlist, libraryProvider.songs);

    return Scaffold(
      appBar: AppBar(
        title: Text(playlist.name),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () =>
                PlaylistDialogs.showEditPlaylistDialog(context, playlist),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 16),
                Center(
                  child: Hero(
                    tag: 'playlist_${playlist.id}',
                    child: _buildPlaylistArtwork(
                      context,
                      playlist,
                      libraryProvider,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Playlist metadata
                Text(
                  playlist.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${songs.length} songs, ${_formatDuration(songs)} total',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                // Action buttons
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: StreamBuilder<bool>(
                          stream: musicPlayerProvider.isShuffleEnabledStream,
                          builder: (context, snapshot) {
                            final isShuffleEnabled = snapshot.data ?? false;
                            return ElevatedButton.icon(
                              icon: const Icon(Icons.shuffle),
                              label: const Text('Shuffle'),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: isShuffleEnabled
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                              onPressed: songs.isEmpty
                                  ? null
                                  : () {
                                      musicPlayerProvider.toggleShuffle();
                                    },
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Play'),
                          onPressed: songs.isEmpty
                              ? null
                              : () {
                                  musicPlayerProvider.setQueue(songs);
                                },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (songs.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('No songs in this playlist')),
            )
          else if (_isGridView)
            _buildSliverGrid(songs, musicPlayerProvider)
          else
            SliverReorderableList(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                final songPath = song['path'] as String;
                final isPlaying =
                    musicPlayerProvider.currentSong?['path'] == songPath;

                return SongCard(
                  key: ValueKey(songPath),
                  cardKey: ValueKey(songPath),
                  song: song,
                  heroTagPrefix: 'playlist_${playlist.id}',
                  isPlaying: isPlaying && musicPlayerProvider.isPlaying,
                  showDragHandle: true,
                  reorderIndex: index,
                  enableSwipeToDelete: true,
                  deleteConfirmMessage: 'Remove this song from the playlist?',
                  onDelete: () async {
                    await _removeSongFromPlaylist(context, songPath);
                  },
                  onAddToQueue: () async {
                    await musicPlayerProvider.addToQueue(song);
                  },
                  onTap: () =>
                      _handleSongTap(musicPlayerProvider, song, songs, index),
                  onPlay: () =>
                      _handleSongTap(musicPlayerProvider, song, songs, index),
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
                        _removeSongFromPlaylist(context, songPath);
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
                  widget.playlistId,
                  oldIndex,
                  newIndex,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Playlist reordered'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PlaybackBar(),
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

  Widget _buildSliverGrid(
    List<Map<String, dynamic>> songs,
    MusicPlayerProvider musicPlayerProvider,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.all(12),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final song = songs[index];
          final songPath = song['path'] as String;

          return SongGridItem(
            song: song,
            onTap: () =>
                _handleSongTap(musicPlayerProvider, song, songs, index),
            onAddToQueue: () async {
              await musicPlayerProvider.addToQueue(song);
            },
            onDelete: () async {
              await _removeSongFromPlaylist(context, songPath);
            },
          );
        }, childCount: songs.length),
      ),
    );
  }
}
