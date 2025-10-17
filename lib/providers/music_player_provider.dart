import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_session/audio_session.dart';
import '../models/youtube_video.dart';

class MusicPlayerProvider with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  List<Map<String, dynamic>> _playQueue = [];
  int _currentIndex = -1;
  
  String? _currentlyPlayingPath;
  YouTubeVideo? _currentVideo;
  bool _isPlaying = false;
  bool _isShuffleEnabled = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<SequenceState?>? _sequenceSub;

  MusicPlayerProvider() {
    _initSession();
    _setupAudioPlayer();
  }

  Future<void> _initSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  // Getters
  AudioPlayer get audioPlayer => _audioPlayer;
  String? get currentlyPlayingPath => _currentlyPlayingPath;
  bool get isPlaying => _isPlaying;
  bool get isShuffleEnabled => _isShuffleEnabled;
  Duration get duration => _duration;
  Duration get position => _position;
  Map<String, dynamic>? get currentSong {
    if (_currentlyPlayingPath == null) return null;
    try {
      final song = _playQueue.firstWhere((s) => s['path'] == _currentlyPlayingPath);
      if (_currentVideo != null) {
        final vidCamel = song['videoId'];
        final vidSnake = song['video_id'];
        if (vidCamel == _currentVideo!.videoId || vidSnake == _currentVideo!.videoId) {
          song['thumbnailUrl'] = _currentVideo!.thumbnailUrl;
        }
      }
      return song;
    } catch (e) {
      return null;
    }
  }
  List<Map<String, dynamic>> get playQueue => _playQueue;

  void _setupAudioPlayer() {
    _positionSubscription = _audioPlayer.positionStream.listen((position) {
      _position = position;
      notifyListeners();
    });

    _durationSubscription = _audioPlayer.durationStream.listen((duration) {
      _duration = duration ?? Duration.zero;
      notifyListeners();
    });

    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });

    _sequenceSub = _audioPlayer.sequenceStateStream.listen((sequenceState) {
      _currentIndex = sequenceState?.currentIndex ?? _currentIndex;
      if (_currentIndex >= 0 && _currentIndex < _playQueue.length) {
        _currentlyPlayingPath = _playQueue[_currentIndex]['path'];
      }
      notifyListeners();
    });
  }

  Future<void> setQueue(List<Map<String, dynamic>> songs, {int initialIndex = 0}) async {
    try {
      final validSongs = <Map<String, dynamic>>[];
      for (final song in songs) {
        final path = song['path'];
        if (path == null) {
          print('Warning: Song has no path: $song');
          continue;
        }
        if (await _isValidSong(path)) {
          validSongs.add(song);
        } else {
          print('Warning: Invalid song path: $path');
        }
      }

      if (validSongs.isEmpty) {
        print('Error: No valid songs in queue');
        await stop();
        notifyListeners();
        return;
      }

      _playQueue = validSongs;
      if (_isShuffleEnabled) {
        _playQueue.shuffle(Random());
      }

      _currentIndex = initialIndex < _playQueue.length ? initialIndex : 0;

      final sources = _playQueue.map((song) {
        final path = song['path'] as String;
        final thumb = (song['thumbnailUrl'] ?? song['thumbnail_url']);
        final tag = MediaItem(
          id: path,
          title: (song['name'] ?? song['title'] ?? 'Unknown') as String,
          artist: (song['artist'] ?? 'Unknown Artist') as String,
          artUri: thumb != null ? Uri.parse(thumb) : null,
        );
        final uri = path.startsWith('http') ? Uri.parse(path) : Uri.file(path);
        return AudioSource.uri(uri, tag: tag);
      }).toList();

      final playlist = ConcatenatingAudioSource(children: sources);
      await _audioPlayer.setAudioSource(playlist, initialIndex: _currentIndex);
      await _audioPlayer.play();
      print('Successfully set queue with ${_playQueue.length} songs, playing index $_currentIndex');
      notifyListeners();
    } catch (e, stackTrace) {
      print('Error in setQueue: $e');
      print('Stack trace: $stackTrace');
      await stop();
      notifyListeners();
    }
  }

  void playYouTubeVideo(YouTubeVideo video, List<YouTubeVideo> queue) {
    _playQueue = queue.map((v) => {
      'path': 'https://www.youtube.com/watch?v=${v.videoId}',
      'name': v.title,
      'videoId': v.videoId,
      'artist': v.channelTitle,
      'thumbnailUrl': v.thumbnailUrl,
    }).toList();
    _currentVideo = video;
    final idx = _playQueue.indexWhere((s) => s['videoId'] == video.videoId);
    setQueue(_playQueue, initialIndex: idx >= 0 ? idx : 0);
  }

  void toggleShuffle() {
    _isShuffleEnabled = !_isShuffleEnabled;
    if (_isShuffleEnabled) {
      _playQueue.shuffle(Random());
      if (_currentlyPlayingPath != null) {
        _currentIndex = _playQueue.indexWhere((s) => s['path'] == _currentlyPlayingPath);
      }
    } else {
      _playQueue = _playQueue;
    }
    notifyListeners();
  }

  Future<void> playSong(String path) async {
    try {
      print('playSong called with path: $path');
      
      if (_currentlyPlayingPath == path && _isPlaying) {
        print('Pausing current song');
        await _audioPlayer.pause();
        notifyListeners();
        return;
      } else if (_currentlyPlayingPath == path && !_isPlaying) {
        print('Resuming current song');
        await _audioPlayer.play();
        notifyListeners();
        return;
      }

      final idx = _playQueue.indexWhere((s) => s['path'] == path);
      print('Song index in queue: $idx, queue length: ${_playQueue.length}');
      
      if (idx == -1) {
        print('Song not in queue, adding it');
        _playQueue.add({'path': path, 'name': path.split('/').last});
        final song = _playQueue.lastWhere((s) => s['path'] == path, orElse: () => {'name': path.split('/').last});
        final thumb = (song['thumbnailUrl'] ?? song['thumbnail_url']);
        final artist = (song['artist'] ?? 'Unknown Artist') as String;
        final source = AudioSource.uri(
          path.startsWith('http') ? Uri.parse(path) : Uri.file(path),
          tag: MediaItem(
            id: path,
            title: (song['name'] ?? path.split('/').last) as String,
            artist: artist,
            artUri: thumb != null ? Uri.parse(thumb) : null,
          ),
        );
        // Append to current playlist if exists
        final seq = _audioPlayer.sequence;
        if (seq != null) {
          await (_audioPlayer.audioSource as ConcatenatingAudioSource).add(source);
          _currentIndex = (_audioPlayer.sequence?.length ?? 1) - 1;
        } else {
          await _audioPlayer.setAudioSource(ConcatenatingAudioSource(children: [source]));
          _currentIndex = 0;
        }
      } else {
        print('Song found in queue at index $idx');
        _currentIndex = idx;
      }

      _currentlyPlayingPath = path;
      _currentVideo = _playQueue[_currentIndex].containsKey('videoId') || _playQueue[_currentIndex].containsKey('video_id')
          ? _currentVideo
          : null;

      print('Seeking to index $_currentIndex and playing');
      await _audioPlayer.seek(Duration.zero, index: _currentIndex);
      await _audioPlayer.play();
      print('Playback started successfully');
    } catch (e, stackTrace) {
      print('Error in playSong: $e');
      print('Stack trace: $stackTrace');
      _isPlaying = false;
      _currentlyPlayingPath = null;
      _currentIndex = -1;
      _currentVideo = null;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> _isValidSong(String path) async {
    if (path.startsWith('http')) return true;
    try {
      final file = File(path);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  Future<void> playNext() async {
    if (_audioPlayer.hasNext) {
      await _audioPlayer.seekToNext();
      await _audioPlayer.play();
    }
  }

  Future<void> playPrevious() async {
    if (_audioPlayer.hasPrevious) {
      await _audioPlayer.seekToPrevious();
      await _audioPlayer.play();
    }
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    _currentlyPlayingPath = null;
    _currentVideo = null;
    _isPlaying = false;
    _currentIndex = -1;
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _sequenceSub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
