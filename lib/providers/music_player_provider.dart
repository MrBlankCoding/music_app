
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
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
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<void>? _completeSubscription;

  MusicPlayerProvider() {
    _setupAudioPlayer();
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
    _positionSubscription = _audioPlayer.onPositionChanged.listen((position) {
      _position = position;
      notifyListeners();
    });

    _durationSubscription = _audioPlayer.onDurationChanged.listen((duration) {
      _duration = duration;
      notifyListeners();
    });

    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      notifyListeners();
    });

    _completeSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      playNext();
    });
  }

  Future<void> setQueue(List<Map<String, dynamic>> songs, {int initialIndex = 0}) async {
    // Filter out invalid songs before setting the queue
    final validSongs = <Map<String, dynamic>>[];
    for (final song in songs) {
      if (await _isValidSong(song['path'])) {
        validSongs.add(song);
      }
    }
    
    _playQueue = validSongs;
    if (_isShuffleEnabled) {
      _playQueue.shuffle(Random());
    }
    
    // Adjust initial index if needed
    _currentIndex = initialIndex < _playQueue.length ? initialIndex : 0;
    
    if (_playQueue.isNotEmpty) {
      await playSong(_playQueue[_currentIndex]['path']);
    }
    notifyListeners();
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
    _currentIndex = _playQueue.indexWhere((s) => s['videoId'] == video.videoId);
    playSong(_playQueue[_currentIndex]['path']);
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
      if (_currentlyPlayingPath == path && _isPlaying) {
        await _audioPlayer.pause();
        notifyListeners();
        return;
      } else if (_currentlyPlayingPath == path && !_isPlaying) {
        await _audioPlayer.resume();
        notifyListeners();
        return;
      }

      _currentlyPlayingPath = path;
      _currentIndex = _playQueue.indexWhere((s) => s['path'] == path);
      if (_currentIndex < 0) {
        _playQueue.add({'path': path, 'name': path.split('/').last});
        _currentIndex = _playQueue.length - 1;
      }
      _currentVideo = _playQueue[_currentIndex].containsKey('videoId') || _playQueue[_currentIndex].containsKey('video_id')
          ? _currentVideo
          : null;
      notifyListeners();

      if (path.startsWith('http')) {
        await _audioPlayer.play(UrlSource(path));
      } else {
        await _audioPlayer.play(DeviceFileSource(path));
      }
    } catch (e) {
      // On failure, revert UI state
      _isPlaying = false;
      // keep _currentlyPlayingPath so user still sees the bar briefly if desired,
      // or clear it to hide the bar if playback failed. Choose to clear to avoid stale UI.
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
    if (_playQueue.isEmpty) return;
    
    int attempts = 0;
    int nextIndex = (_currentIndex + 1) % _playQueue.length;
    
    // Try to find a valid song, up to the queue length
    while (attempts < _playQueue.length) {
      final nextSong = _playQueue[nextIndex];
      final isValid = await _isValidSong(nextSong['path']);
      
      if (isValid) {
        await playSong(nextSong['path']);
        return;
      }
      
      // Remove invalid song from queue
      _playQueue.removeAt(nextIndex);
      if (_playQueue.isEmpty) {
        await stop();
        return;
      }
      
      // Adjust index after removal
      nextIndex = nextIndex % _playQueue.length;
      attempts++;
    }
    
    // No valid songs found
    await stop();
  }

  Future<void> playPrevious() async {
    if (_playQueue.isEmpty) return;
    
    int attempts = 0;
    int prevIndex = _currentIndex <= 0 ? _playQueue.length - 1 : _currentIndex - 1;
    
    // Try to find a valid song, up to the queue length
    while (attempts < _playQueue.length) {
      final prevSong = _playQueue[prevIndex];
      final isValid = await _isValidSong(prevSong['path']);
      
      if (isValid) {
        await playSong(prevSong['path']);
        return;
      }
      
      // Remove invalid song from queue
      _playQueue.removeAt(prevIndex);
      if (_playQueue.isEmpty) {
        await stop();
        return;
      }
      
      // Adjust index after removal
      if (prevIndex >= _playQueue.length) {
        prevIndex = _playQueue.length - 1;
      }
      prevIndex = prevIndex <= 0 ? _playQueue.length - 1 : prevIndex - 1;
      attempts++;
    }
    
    // No valid songs found
    await stop();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    _currentlyPlayingPath = null;
    _currentVideo = null;
    _isPlaying = false;
    _currentIndex = -1;
    notifyListeners();
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
}
