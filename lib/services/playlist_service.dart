import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../models/playlist.dart';

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

  Future<Playlist> createPlaylist(String name, {String? description}) async {
    if (_playlistsFile == null) await initialize();
    
    final playlist = Playlist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      createdAt: DateTime.now(),
      songPaths: [],
    );
    
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

  Future<void> addSongToPlaylist(String playlistId, String songPath) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      final playlist = _playlists[index];
      if (!playlist.songPaths.contains(songPath)) {
        _playlists[index] = playlist.copyWith(
          songPaths: [...playlist.songPaths, songPath],
        );
        await _savePlaylists();
      }
    }
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songPath) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      final playlist = _playlists[index];
      final updatedSongs = playlist.songPaths.where((p) => p != songPath).toList();
      _playlists[index] = playlist.copyWith(songPaths: updatedSongs);
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
      if (playlist.songPaths.contains(songPath)) {
        _playlists[i] = playlist.copyWith(
          songPaths: playlist.songPaths.where((p) => p != songPath).toList(),
        );
        modified = true;
      }
    }
    if (modified) {
      await _savePlaylists();
    }
  }
}