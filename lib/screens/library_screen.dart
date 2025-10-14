import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/download_service.dart';
import '../services/playlist_service.dart';
import '../models/playlist.dart';
import '../widgets/playback_bar.dart';
import 'dart:async';
import 'dart:math';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final DownloadService _downloadService = DownloadService();
  final PlaylistService _playlistService = PlaylistService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  List<Map<String, dynamic>> _songs = [];
  List<Map<String, dynamic>> _playQueue = [];
  int _currentIndex = -1;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<void>? _completeSubscription;
  
  bool _isLoading = true;
  String? _currentlyPlayingPath;
  bool _isPlaying = false;
  bool _isShuffleEnabled = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadSongs();
    _setupAudioPlayer();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _completeSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _setupAudioPlayer() {
    _positionSubscription = _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) setState(() => _position = position);
    });

    _durationSubscription = _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) setState(() => _duration = duration);
    });

    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });

    _completeSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) _playNext();
    });
  }

  Future<void> _loadSongs() async {
    setState(() => _isLoading = true);
    try {
      await _downloadService.initialize();
      final songs = await _downloadService.getDownloadedSongs();
      setState(() {
        _songs = songs;
        _playQueue = List.from(songs);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _toggleShuffle() {
    setState(() {
      _isShuffleEnabled = !_isShuffleEnabled;
      if (_isShuffleEnabled) {
        _playQueue = List.from(_songs)..shuffle(Random());
        // Find current song in new queue
        if (_currentlyPlayingPath != null) {
          _currentIndex = _playQueue.indexWhere((s) => s['path'] == _currentlyPlayingPath);
        }
      } else {
        _playQueue = List.from(_songs);
        if (_currentlyPlayingPath != null) {
          _currentIndex = _playQueue.indexWhere((s) => s['path'] == _currentlyPlayingPath);
        }
      }
    });
  }

  Future<void> _playSong(String path) async {
    try {
      if (_currentlyPlayingPath == path && _isPlaying) {
        await _audioPlayer.pause();
      } else if (_currentlyPlayingPath == path && !_isPlaying) {
        await _audioPlayer.resume();
      } else {
        await _audioPlayer.play(DeviceFileSource(path));
        setState(() {
          _currentlyPlayingPath = path;
          _currentIndex = _playQueue.indexWhere((s) => s['path'] == path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _playNext() async {
    if (_playQueue.isEmpty) return;
    
    final nextIndex = (_currentIndex + 1) % _playQueue.length;
    final nextSong = _playQueue[nextIndex];
    await _playSong(nextSong['path']);
  }

  Future<void> _playPrevious() async {
    if (_playQueue.isEmpty) return;
    
    final prevIndex = _currentIndex <= 0 ? _playQueue.length - 1 : _currentIndex - 1;
    final prevSong = _playQueue[prevIndex];
    await _playSong(prevSong['path']);
  }

  Future<void> _stopSong() async {
    await _audioPlayer.stop();
    setState(() {
      _currentlyPlayingPath = null;
      _isPlaying = false;
      _currentIndex = -1;
    });
  }

  Future<void> _showAddToPlaylistDialog(Map<String, dynamic> song) async {
    await _playlistService.initialize();
    final playlists = await _playlistService.getPlaylists();

    if (!mounted) return;

    if (playlists.isEmpty) {
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
        await _showCreatePlaylistDialog(song['path']);
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
            itemCount: playlists.length + 1,
            itemBuilder: (context, index) {
              if (index == playlists.length) {
                return ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('Create New Playlist'),
                  onTap: () => Navigator.pop(context),
                );
              }
              final playlist = playlists[index];
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
        await _playlistService.addSongToPlaylist(
          selectedPlaylist.id,
          song['path'],
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Added to "${selectedPlaylist.name}"')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    } else {
      await _showCreatePlaylistDialog(song['path']);
    }
  }

  Future<void> _showCreatePlaylistDialog(String songPath) async {
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

    if (result == true && nameController.text.isNotEmpty) {
      try {
        final playlist = await _playlistService.createPlaylist(
          nameController.text,
          description: descriptionController.text.isEmpty
              ? null
              : descriptionController.text,
        );
        await _playlistService.addSongToPlaylist(playlist.id, songPath);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Created "${playlist.name}" and added song')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteSong(Map<String, dynamic> song) async {
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
      try {
        if (_currentlyPlayingPath == song['path']) {
          await _stopSong();
        }
        await _downloadService.deleteSong(song['path']);
        await _loadSongs();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSongs,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _songs.isEmpty
                    ? const Center(child: Text('No songs'))
                    : ListView.builder(
                        padding: EdgeInsets.only(
                          bottom: _currentlyPlayingPath != null ? 120 : 0,
                        ),
                        itemCount: _songs.length,
                        itemBuilder: (context, index) {
                          final song = _songs[index];
                          final isPlaying = _currentlyPlayingPath == song['path'];
                          return ListTile(
                            leading: Icon(
                              isPlaying && _isPlaying
                                  ? Icons.graphic_eq
                                  : Icons.music_note,
                            ),
                            title: Text(song['name']),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    isPlaying && _isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                  ),
                                  onPressed: () => _playSong(song['path']),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.playlist_add),
                                  onPressed: () => _showAddToPlaylistDialog(song),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _deleteSong(song),
                                ),
                              ],
                            ),
                            onTap: () => _playSong(song['path']),
                          );
                        },
                      ),
          ),
          PlaybackBar(
            audioPlayer: _audioPlayer,
            currentSongName: _currentlyPlayingPath != null
                ? _songs.firstWhere(
                    (s) => s['path'] == _currentlyPlayingPath,
                    orElse: () => <String, Object>{'name': 'Unknown'},
                  )['name'] as String?
                : null,
            isPlaying: _isPlaying,
            position: _position,
            duration: _duration,
            onPlayPause: () => _playSong(_currentlyPlayingPath!),
            onStop: _stopSong,
            onNext: _playQueue.length > 1 ? _playNext : null,
            onPrevious: _playQueue.length > 1 ? _playPrevious : null,
            onShuffle: _songs.length > 1 ? _toggleShuffle : null,
            isShuffleEnabled: _isShuffleEnabled,
          ),
        ],
      ),
    );
  }
}