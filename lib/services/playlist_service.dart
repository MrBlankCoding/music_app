import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../models/playlist.dart';
import '../utils/song_data_helper.dart';

class PlaylistService {
  static final PlaylistService _instance = PlaylistService._internal();
  factory PlaylistService() => _instance;
  PlaylistService._internal();

  String? _playlistsFile;
  List<Playlist> _playlists = [];

  Future<void> initialize() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    _playlistsFile = '${appDocDir.path}/playlists.json';
    await _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    if (_playlistsFile == null) return;

    final file = File(_playlistsFile!);
    if (!await file.exists()) {
      _playlists = [];
      return;
    }

    try {
      final content = await file.readAsString();
      final List<dynamic> jsonList = json.decode(content);
      _playlists = jsonList.map((json) => Playlist.fromJson(json)).toList();
    } catch (e) {
      _playlists = [];
    }
  }

  Future<void> _savePlaylists() async {
    if (_playlistsFile == null) return;

    final file = File(_playlistsFile!);
    final jsonList = _playlists.map((p) => p.toJson()).toList();
    await file.writeAsString(json.encode(jsonList));
  }

  Future<List<Playlist>> getPlaylists() async {
    if (_playlistsFile == null) await initialize();
    return List.from(_playlists);
  }

  Future<Playlist> createPlaylist(String name) async {
    if (_playlistsFile == null) await initialize();

    final playlist = Playlist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      createdAt: DateTime.now(),
      songs: [],
    );

    _playlists.add(playlist);
    await _savePlaylists();
    return playlist;
  }

  Future<Playlist> addPlaylist(Map<String, dynamic> playlistData) async {
    if (_playlistsFile == null) await initialize();

    final playlist = Playlist.fromJson(playlistData);

    _playlists.add(playlist);
    await _savePlaylists();
    return playlist;
  }

  Future<void> deletePlaylist(String playlistId) async {
    _playlists.removeWhere((p) => p.id == playlistId);
    await _savePlaylists();
  }

  Future<void> updatePlaylist(Playlist playlist) async {
    final index = _playlists.indexWhere((p) => p.id == playlist.id);
    if (index != -1) {
      _playlists[index] = playlist;
      await _savePlaylists();
    }
  }

  Future<void> addSongToPlaylist(
    String playlistId,
    Map<String, dynamic> song,
  ) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      final playlist = _playlists[index];
      final songPath = song['path'] as String;

      // Check if song already exists in playlist
      final exists = playlist.songs.any((s) => s['path'] == songPath);
      if (!exists) {
        // Ensure DateTime is properly formatted
        final songCopy = Map<String, dynamic>.from(song);
        if (songCopy['modified'] is DateTime) {
          songCopy['modified'] = (songCopy['modified'] as DateTime)
              .toIso8601String();
        }

        _playlists[index] = playlist.copyWith(
          songs: [...playlist.songs, songCopy],
        );
        await _savePlaylists();
      }
    }
  }

  Future<void> removeSongFromPlaylist(
    String playlistId,
    String songPath,
  ) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      final playlist = _playlists[index];
      final updatedSongs = playlist.songs
          .where((s) => s['path'] != songPath)
          .toList();
      _playlists[index] = playlist.copyWith(songs: updatedSongs);
      await _savePlaylists();
    }
  }

  Playlist? getPlaylistById(String playlistId) {
    try {
      return _playlists.firstWhere((p) => p.id == playlistId);
    } catch (e) {
      return null;
    }
  }

  Future<void> removeSongFromAllPlaylists(String songPath) async {
    bool modified = false;
    for (int i = 0; i < _playlists.length; i++) {
      final playlist = _playlists[i];
      final hasSong = playlist.songs.any((s) => s['path'] == songPath);
      if (hasSong) {
        _playlists[i] = playlist.copyWith(
          songs: playlist.songs.where((s) => s['path'] != songPath).toList(),
        );
        modified = true;
      }
    }
    if (modified) {
      await _savePlaylists();
    }
  }

  /// Resolves thumbnail URLs for a playlist by matching songs with library songs
  /// Returns up to 4 thumbnail URLs for display in playlist artwork
  List<String> getPlaylistThumbnails(
    Playlist playlist,
    List<Map<String, dynamic>> librarySongs,
  ) {
    final thumbnails = <String>[];

    for (var song in playlist.songs.take(4)) {
      final songData = SongData(song);
      final storedPath = songData.path;

      final filename = storedPath.split('/').last;
      final librarySong = librarySongs.firstWhere(
        (s) => (s['path'] as String).split('/').last == filename,
        orElse: () => <String, dynamic>{},
      );

      final thumbnailUrl = librarySong.isNotEmpty
          ? SongData(librarySong).thumbnailUrl
          : songData.thumbnailUrl;

      if (thumbnailUrl != null) {
        thumbnails.add(thumbnailUrl);
      }
    }

    return thumbnails;
  }
}
