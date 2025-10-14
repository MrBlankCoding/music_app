import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/playlist.dart';
import '../services/playlist_service.dart';
import '../widgets/playback_bar.dart';
import 'dart:async';
import 'dart:io';

class PlaylistDetailScreen extends StatefulWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  final PlaylistService _playlistService = PlaylistService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  late Playlist _playlist;
  List<Map<String, dynamic>> _songs = [];
  int _currentIndex = -1;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<void>? _completeSubscription;
  
  String? _currentlyPlayingPath;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _playlist = widget.playlist;
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
    final songs = <Map<String, dynamic>>[];
    for (final path in _playlist.songPaths) {
      final file = File(path);
      if (await file.exists()) {
        final stat = await file.stat();
        songs.add({
          'path': path,
          'name': path.split('/').last.replaceAll('.mp3', '').replaceAll('_', ' '),
          'size': stat.size,
          'modified': stat.modified,
        });
      }
    }
    setState(() => _songs = songs);
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
          _currentIndex = _songs.indexWhere((s) => s['path'] == path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing song: $e')),
        );
      }
    }
  }

  Future<void> _playNext() async {
    if (_songs.isEmpty) return;
    
    final nextIndex = (_currentIndex + 1) % _songs.length;
    final nextSong = _songs[nextIndex];
    await _playSong(nextSong['path']);
  }

  Future<void> _playPrevious() async {
    if (_songs.isEmpty) return;
    
    final prevIndex = _currentIndex <= 0 ? _songs.length - 1 : _currentIndex - 1;
    final prevSong = _songs[prevIndex];
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

  Future<void> _removeSongFromPlaylist(String songPath) async {
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

    if (confirmed == true) {
      try {
        if (_currentlyPlayingPath == songPath) {
          await _stopSong();
        }
        await _playlistService.removeSongFromPlaylist(_playlist.id, songPath);
        final updatedPlaylist = _playlistService.getPlaylistById(_playlist.id);
        if (updatedPlaylist != null) {
          setState(() => _playlist = updatedPlaylist);
          await _loadSongs();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error removing song: $e')),
          );
        }
      }
    }
  }

  Future<void> _editPlaylist() async {
    final nameController = TextEditingController(text: _playlist.name);
    final descriptionController = TextEditingController(
      text: _playlist.description ?? '',
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

    if (result == true && nameController.text.isNotEmpty) {
      try {
        final updatedPlaylist = _playlist.copyWith(
          name: nameController.text,
          description: descriptionController.text.isEmpty 
              ? null 
              : descriptionController.text,
        );
        await _playlistService.updatePlaylist(updatedPlaylist);
        setState(() => _playlist = updatedPlaylist);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating playlist: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_playlist.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editPlaylist,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_playlist.description != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _playlist.description!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          Expanded(
            child: _songs.isEmpty
                ? const Center(
                    child: Text('No songs in this playlist'),
                  )
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
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => _removeSongFromPlaylist(song['path']),
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
            onNext: _songs.length > 1 ? _playNext : null,
            onPrevious: _songs.length > 1 ? _playPrevious : null,
          ),
        ],
      ),
    );
  }
}