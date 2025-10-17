
import 'dart:async';
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

  void setQueue(List<Map<String, dynamic>> songs, {int initialIndex = 0}) {
    _playQueue = List.from(songs);
    if (_isShuffleEnabled) {
      _playQueue.shuffle(Random());
    }
    _currentIndex = initialIndex;
    if (_playQueue.isNotEmpty) {
      playSong(_playQueue[_currentIndex]['path']);
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

  Future<void> playNext() async {
    if (_playQueue.isEmpty) return;
    
    final nextIndex = (_currentIndex + 1) % _playQueue.length;
    final nextSong = _playQueue[nextIndex];
    await playSong(nextSong['path']);
  }

  Future<void> playPrevious() async {
    if (_playQueue.isEmpty) return;
    
    final prevIndex = _currentIndex <= 0 ? _playQueue.length - 1 : _currentIndex - 1;
    final prevSong = _playQueue[prevIndex];
    await playSong(prevSong['path']);
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
