import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../services/audio_player_service.dart';

class MusicPlayerProvider with ChangeNotifier {
  final AudioPlayerService _audioPlayerService;
  late StreamSubscription<Map<String, dynamic>?> _currentSongSubscription;
  late StreamSubscription<bool> _playingStateSubscription;

  Map<String, dynamic>? _currentSong;
  bool _isPlaying = false;

  MusicPlayerProvider({AudioPlayerService? audioPlayerService})
      : _audioPlayerService = audioPlayerService ?? AudioPlayerService() {
    _currentSongSubscription = _audioPlayerService.currentSongStream.listen((
      song,
    ) {
      _currentSong = song;
      notifyListeners();
    });
    _playingStateSubscription = _audioPlayerService.playingStream.listen((
      isPlaying,
    ) {
      _isPlaying = isPlaying;
      notifyListeners();
    });
  }

  // Getters
  AudioPlayer get audioPlayer => _audioPlayerService.audioPlayer;
  Map<String, dynamic>? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  bool get isShuffleEnabled =>
      _audioPlayerService.audioPlayer.shuffleModeEnabled;
  Stream<bool> get isShuffleEnabledStream =>
      _audioPlayerService.isShuffleEnabledStream;
  Stream<Duration> get positionStream => _audioPlayerService.positionStream;
  Stream<Duration?> get durationStream => _audioPlayerService.durationStream;
  Stream<bool> get playingStream => _audioPlayerService.playingStream;
  Stream<SequenceState?> get sequenceStateStream =>
      _audioPlayerService.sequenceStateStream;

  // Methods
  Future<void> setQueue(
    List<Map<String, dynamic>> songs, {
    int initialIndex = 0,
  }) async {
    await _audioPlayerService.playPlaylist(songs, initialIndex);
  }

  void playPause() {
    _audioPlayerService.playPause();
  }

  Future<void> playNext() async {
    await _audioPlayerService.next();
  }

  Future<void> playPrevious() async {
    await _audioPlayerService.previous();
  }

  Future<void> stop() async {
    await _audioPlayerService.stop();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayerService.seek(position);
  }

  Future<void> toggleShuffle() async {
    await _audioPlayerService.toggleShuffle();
    notifyListeners();
  }

  @override
  void dispose() {
    _currentSongSubscription.cancel();
    _playingStateSubscription.cancel();
    // The AudioPlayerService is a singleton, so we don't dispose it here.
    // It will live for the entire lifecycle of the app.
    super.dispose();
  }
}