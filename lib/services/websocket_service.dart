import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:oktoast/oktoast.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/youtube_video.dart';
import 'download_service.dart';
import '../providers/playlist_provider.dart';

class WebSocketService with ChangeNotifier {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  bool _isConnected = false;
  final String _serverUrl = 'wss://lasandra-sultriest-bumblingly.ngrok-free.dev/ws';
  
  // Playlist download progress tracking
  Map<String, PlaylistDownloadProgress> _playlistProgress = {};
  
  // Callback for library refresh
  VoidCallback? _onPlaylistCompleted;
  
  // Download service for automatic song downloads
  DownloadService? _downloadService;
  
  // Playlist provider for automatic playlist creation
  PlaylistProvider? _playlistProvider;
  
  // Track songs for each playlist to create playlists later
  Map<String, List<String>> _playlistSongs = {};
  
  bool get isConnected => _isConnected;
  Map<String, PlaylistDownloadProgress> get playlistProgress => _playlistProgress;

  void setOnPlaylistCompleted(VoidCallback callback) {
    _onPlaylistCompleted = callback;
  }

  void setDownloadService(DownloadService downloadService) {
    _downloadService = downloadService;
  }

  void setPlaylistProvider(PlaylistProvider playlistProvider) {
    _playlistProvider = playlistProvider;
  }

  Future<void> connect() async {
    if (_isConnected) return;
    
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_serverUrl));
      _isConnected = true;
      
      // Listen to messages
      _channel!.stream.listen(
        _handleMessage,
        onError: (error) {
          _handleDisconnection();
        },
        onDone: () {
          _handleDisconnection();
        },
      );
      
      notifyListeners();
    } catch (e) {
      _isConnected = false;
      notifyListeners();
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final data = json.decode(message);
      final type = data['type'] as String?;
      
      switch (type) {
        case 'playlist_started':
          _handlePlaylistStarted(data);
          break;
        case 'playlist_progress':
          _handlePlaylistProgress(data);
          break;
        case 'song_completed':
          _handleSongCompleted(data);
          break;
        case 'song_failed':
          _handleSongFailed(data);
          break;
        case 'playlist_completed':
          _handlePlaylistCompleted(data);
          break;
        case 'playlist_failed':
          _handlePlaylistFailed(data);
          break;
        default:
          print('Unknown message type: $type');
      }
    } catch (e) {
      print('Error parsing WebSocket message: $e');
    }
  }

  void _handlePlaylistStarted(Map<String, dynamic> data) {
    final playlistId = data['playlist_id'] as String;
    final title = data['title'] as String;
    final message = data['message'] as String;
    
    _playlistProgress[playlistId] = PlaylistDownloadProgress(
      playlistId: playlistId,
      title: title,
      status: PlaylistDownloadStatus.downloading,
      current: 0,
      total: 0,
      completedSongs: [],
      failedSongs: [],
    );
    
    // Initialize song tracking for this playlist
    _playlistSongs[playlistId] = [];
    
    showToast(
      message,
      duration: const Duration(seconds: 3),
    );
    
    notifyListeners();
  }

  void _handlePlaylistProgress(Map<String, dynamic> data) {
    final playlistId = data['playlist_id'] as String;
    final current = data['current'] as int;
    final total = data['total'] as int;
    
    if (_playlistProgress.containsKey(playlistId)) {
      _playlistProgress[playlistId] = _playlistProgress[playlistId]!.copyWith(
        current: current,
        total: total,
        status: PlaylistDownloadStatus.downloading,
      );
      
      notifyListeners();
    }
  }

  void _handleSongCompleted(Map<String, dynamic> data) {
    final playlistId = data['playlist_id'] as String;
    final completed = data['completed'] as int;
    final total = data['total'] as int;
    final videoId = data['video_id'] as String;
    final songTitle = data['song_title'] as String;
    final message = data['message'] as String;
    
    if (_playlistProgress.containsKey(playlistId)) {
      final progress = _playlistProgress[playlistId]!;
      final updatedCompletedSongs = List<String>.from(progress.completedSongs)
        ..add(songTitle);
      
      _playlistProgress[playlistId] = progress.copyWith(
        current: completed,
        total: total,
        completedSongs: updatedCompletedSongs,
      );
      
      // Track this song for playlist creation
      if (_playlistSongs.containsKey(playlistId)) {
        _playlistSongs[playlistId]!.add(songTitle);
      }
      
      // Automatically download the song to the app's library
      if (_downloadService != null) {
        final video = YouTubeVideo(
          videoId: videoId,
          title: songTitle,
          channelTitle: 'Unknown Artist', // We'll get this from the API
          thumbnailUrl: '',
          duration: 'Unknown',
        );
        _downloadService!.addToQueue(video);
      }
      
      showToast(
        message,
        duration: const Duration(seconds: 2),
      );
      
      notifyListeners();
    }
  }

  void _handleSongFailed(Map<String, dynamic> data) {
    final playlistId = data['playlist_id'] as String;
    final videoId = data['video_id'] as String;
    final message = data['message'] as String;
    
    if (_playlistProgress.containsKey(playlistId)) {
      final progress = _playlistProgress[playlistId]!;
      final updatedFailedSongs = List<String>.from(progress.failedSongs)
        ..add(videoId);
      
      _playlistProgress[playlistId] = progress.copyWith(
        failedSongs: updatedFailedSongs,
      );
      
      showToast(
        message,
        duration: const Duration(seconds: 3),
      );
      
      notifyListeners();
    }
  }

  void _handlePlaylistCompleted(Map<String, dynamic> data) {
    final playlistId = data['playlist_id'] as String;
    final totalSongs = data['total_songs'] as int;
    final successfulDownloads = data['successful_downloads'] as int;
    final message = data['message'] as String;
    
    if (_playlistProgress.containsKey(playlistId)) {
      _playlistProgress[playlistId] = _playlistProgress[playlistId]!.copyWith(
        status: PlaylistDownloadStatus.completed,
        total: totalSongs,
        current: successfulDownloads,
      );
      
      showToast(
        message,
        duration: const Duration(seconds: 5),
      );
      
      notifyListeners();
      
      // Create playlist with downloaded songs
      if (_playlistProvider != null && _playlistSongs.containsKey(playlistId)) {
        final progress = _playlistProgress[playlistId]!;
        final songTitles = _playlistSongs[playlistId]!;
        
        // Create the playlist after a short delay to ensure songs are in library
        Future.delayed(const Duration(seconds: 3), () async {
          await _playlistProvider!.createPlaylist(progress.title);
          
          // Add songs to the playlist
          for (final songTitle in songTitles) {
            await _playlistProvider!.addSongToPlaylist(progress.title, songTitle);
          }
          
          showToast(
            "Created playlist: ${progress.title}",
            duration: const Duration(seconds: 3),
          );
        });
        
        // Clean up song tracking
        _playlistSongs.remove(playlistId);
      }
      
      // Trigger library refresh callback
      _onPlaylistCompleted?.call();
      
      // Remove from progress after a delay
      Future.delayed(const Duration(seconds: 10), () {
        _playlistProgress.remove(playlistId);
        notifyListeners();
      });
    }
  }

  void _handlePlaylistFailed(Map<String, dynamic> data) {
    final playlistId = data['playlist_id'] as String;
    final message = data['message'] as String;
    
    if (_playlistProgress.containsKey(playlistId)) {
      _playlistProgress[playlistId] = _playlistProgress[playlistId]!.copyWith(
        status: PlaylistDownloadStatus.failed,
      );
      
      showToast(
        message,
        duration: const Duration(seconds: 5),
      );
      
      notifyListeners();
      
      // Remove from progress after a delay
      Future.delayed(const Duration(seconds: 15), () {
        _playlistProgress.remove(playlistId);
        notifyListeners();
      });
    }
  }

  void _handleDisconnection() {
    _isConnected = false;
    _channel = null;
    notifyListeners();
    
    // Attempt to reconnect after a delay
    Future.delayed(const Duration(seconds: 5), () {
      if (!_isConnected) {
        connect();
      }
    });
  }

  void disconnect() {
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }
    _isConnected = false;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}

enum PlaylistDownloadStatus {
  downloading,
  completed,
  failed,
}

class PlaylistDownloadProgress {
  final String playlistId;
  final String title;
  final PlaylistDownloadStatus status;
  final int current;
  final int total;
  final List<String> completedSongs;
  final List<String> failedSongs;

  const PlaylistDownloadProgress({
    required this.playlistId,
    required this.title,
    required this.status,
    required this.current,
    required this.total,
    required this.completedSongs,
    required this.failedSongs,
  });

  PlaylistDownloadProgress copyWith({
    String? playlistId,
    String? title,
    PlaylistDownloadStatus? status,
    int? current,
    int? total,
    List<String>? completedSongs,
    List<String>? failedSongs,
  }) {
    return PlaylistDownloadProgress(
      playlistId: playlistId ?? this.playlistId,
      title: title ?? this.title,
      status: status ?? this.status,
      current: current ?? this.current,
      total: total ?? this.total,
      completedSongs: completedSongs ?? this.completedSongs,
      failedSongs: failedSongs ?? this.failedSongs,
    );
  }

  double get progress {
    if (total == 0) return 0.0;
    return current / total;
  }

  String get progressText {
    if (total == 0) return 'Preparing...';
    return '$current / $total songs';
  }
}
