import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:rxdart/rxdart.dart';
import '../utils/song_data_helper.dart';

/// A service to manage audio playback.
///
/// This is a singleton that encapsulates the [AudioPlayer] instance
/// and provides streams for the UI to listen to.
class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;

  AudioPlayerService._internal() {
    _init();
  }

  final AudioPlayer _audioPlayer = AudioPlayer();
  final BehaviorSubject<Map<String, dynamic>?> _currentSongSubject =
      BehaviorSubject<Map<String, dynamic>?>();
  final BehaviorSubject<bool> _isShuffleEnabledSubject =
      BehaviorSubject<bool>.seeded(false);
  final BehaviorSubject<List<Map<String, dynamic>>> _playlistSubject =
      BehaviorSubject<List<Map<String, dynamic>>>.seeded([]);

  /// Stream of the currently playing song's data.
  ValueStream<Map<String, dynamic>?> get currentSongStream =>
      _currentSongSubject.stream;

  /// Stream of the player's position.
  Stream<Duration> get positionStream => _audioPlayer.positionStream;

  /// Stream of the song's duration.
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;

  /// Stream of the player's playing state.
  Stream<bool> get playingStream => _audioPlayer.playingStream;

  /// Stream of the player's sequence state.
  Stream<SequenceState?> get sequenceStateStream =>
      _audioPlayer.sequenceStateStream;

  /// Stream of the shuffle mode state.
  Stream<bool> get isShuffleEnabledStream => _isShuffleEnabledSubject.stream;

  /// Stream of the current playlist.
  ValueStream<List<Map<String, dynamic>>> get playlistStream =>
      _playlistSubject.stream;

  /// The underlying [AudioPlayer] instance.
  AudioPlayer get audioPlayer => _audioPlayer;

  void _init() {
    _audioPlayer.currentIndexStream.listen((index) {
      if (index != null &&
          _audioPlayer.sequenceState?.sequence.isNotEmpty == true) {
        final mediaItem =
            _audioPlayer.sequenceState!.sequence[index].tag as MediaItem?;
        if (mediaItem?.extras != null) {
          _currentSongSubject.add(mediaItem!.extras!);
        }
      }
    });

    _audioPlayer.shuffleModeEnabledStream.listen((isEnabled) {
      _isShuffleEnabledSubject.add(isEnabled);
    });
  }

  /// Converts album art bytes to a URI for MediaItem
  Uri? _albumArtToUri(Uint8List? albumArt) {
    if (albumArt == null) return null;
    
    // Convert bytes to base64 data URI
    final base64String = base64Encode(albumArt);
    return Uri.parse('data:image/jpeg;base64,$base64String');
  }

  /// Plays a single song.
  Future<void> play(Map<String, dynamic> song) async {
    await playPlaylist([song], 0);
  }

  /// Plays a list of songs.
  Future<void> playPlaylist(
    List<Map<String, dynamic>> songs,
    int initialIndex, {
    bool shuffle = false,
  }) async {
    if (songs.isEmpty) return;

    _playlistSubject.add(songs);

    final playlist = ConcatenatingAudioSource(
      children: songs.map((song) {
        final songData = SongData(song);
        final mediaItem = MediaItem(
          id: songData.id,
          title: songData.title,
          artist: songData.artist,
          artUri: _albumArtToUri(songData.albumArt),
          extras: song,
        );
        final uri = songData.path.startsWith('http')
            ? Uri.parse(songData.path)
            : Uri.file(songData.path);
        return AudioSource.uri(uri, tag: mediaItem);
      }).toList(),
    );

    await _audioPlayer.setShuffleModeEnabled(shuffle);
    await _audioPlayer.setAudioSource(playlist, initialIndex: initialIndex);
    _currentSongSubject.add(songs[initialIndex]);
    await _audioPlayer.play();
  }

  Future<void> addToQueue(Map<String, dynamic> song) async {
    final songData = SongData(song);
    final mediaItem = MediaItem(
      id: songData.id,
      title: songData.title,
      artist: songData.artist,
      artUri: _albumArtToUri(songData.albumArt),
      extras: song,
    );
    final uri = songData.path.startsWith('http')
        ? Uri.parse(songData.path)
        : Uri.file(songData.path);
    final audioSource = AudioSource.uri(uri, tag: mediaItem);

    final playlist = _audioPlayer.audioSource as ConcatenatingAudioSource;
    await playlist.add(audioSource);

    final currentPlaylist = _playlistSubject.value;
    currentPlaylist.add(song);
    _playlistSubject.add(currentPlaylist);
  }

  /// Toggles between play and pause.
  void playPause() {
    if (_audioPlayer.playing) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play();
    }
  }

  /// Seeks to a position in the current song.
  Future<void> seek(Duration position) async =>
      await _audioPlayer.seek(position);

  /// Stops playback.
  Future<void> stop() async => await _audioPlayer.stop();

  /// Skips to the next song.
  Future<void> next() async => await _audioPlayer.seekToNext();

  /// Skips to the previous song.
  Future<void> previous() async => await _audioPlayer.seekToPrevious();

  /// Toggles shuffle mode.
  Future<void> toggleShuffle() async {
    final isEnabled = !_isShuffleEnabledSubject.value;
    await _audioPlayer.setShuffleModeEnabled(isEnabled);
  }

  /// Disposes the audio player.
  void dispose() {
    _audioPlayer.dispose();
    _currentSongSubject.close();
    _isShuffleEnabledSubject.close();
    _playlistSubject.close();
  }
}