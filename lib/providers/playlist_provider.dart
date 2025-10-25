import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../services/playlist_service.dart';

class PlaylistProvider with ChangeNotifier {
  final PlaylistService _playlistService = PlaylistService();

  List<Playlist> _playlists = [];
  bool _isLoading = true;

  // Getters
  List<Playlist> get playlists => _playlists;
  bool get isLoading => _isLoading;

  PlaylistProvider() {
    loadPlaylists();
  }

  Future<void> loadPlaylists() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _playlistService.initialize();
      _playlists = await _playlistService.getPlaylists();
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Playlist?> createPlaylist(String name, {String? description}) async {
    try {
      final playlist = await _playlistService.createPlaylist(
        name,
        description: description,
      );
      // Mutate local state instead of reloading from disk
      _playlists.add(playlist);
      notifyListeners();
      return playlist;
    } catch (e) {
      // Handle error
      return null;
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    try {
      await _playlistService.deletePlaylist(playlistId);
      // Mutate local state instead of reloading from disk
      _playlists.removeWhere((p) => p.id == playlistId);
      notifyListeners();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> updatePlaylist(Playlist playlist) async {
    try {
      await _playlistService.updatePlaylist(playlist);
      // Mutate local state instead of reloading from disk
      final index = _playlists.indexWhere((p) => p.id == playlist.id);
      if (index != -1) {
        _playlists[index] = playlist;
        notifyListeners();
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> addSongToPlaylist(
    String playlistId,
    Map<String, dynamic> song,
  ) async {
    try {
      await _playlistService.addSongToPlaylist(playlistId, song);
      // Mutate local state instead of reloading from disk
      final index = _playlists.indexWhere((p) => p.id == playlistId);
      if (index != -1) {
        final playlist = _playlists[index];
        final updatedSongs = List<Map<String, dynamic>>.from(playlist.songs)..add(song);
        _playlists[index] = playlist.copyWith(songs: updatedSongs);
        notifyListeners();
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> removeSongFromPlaylist(
    String playlistId,
    String songPath,
  ) async {
    try {
      await _playlistService.removeSongFromPlaylist(playlistId, songPath);
      // Mutate local state instead of reloading from disk
      final index = _playlists.indexWhere((p) => p.id == playlistId);
      if (index != -1) {
        final playlist = _playlists[index];
        final updatedSongs = playlist.songs.where((s) => s['path'] != songPath).toList();
        _playlists[index] = playlist.copyWith(songs: updatedSongs);
        notifyListeners();
      }
    } catch (e) {
      // Handle error
    }
  }

  Playlist? getPlaylistById(String id) {
    try {
      return _playlists.firstWhere((playlist) => playlist.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> reorderPlaylist(
    String playlistId,
    int oldIndex,
    int newIndex,
  ) async {
    try {
      final index = _playlists.indexWhere((p) => p.id == playlistId);
      if (index != -1) {
        final playlist = _playlists[index];
        final updatedSongs = List<Map<String, dynamic>>.from(playlist.songs);
        final item = updatedSongs.removeAt(oldIndex);
        updatedSongs.insert(newIndex, item);
        final updatedPlaylist = playlist.copyWith(songs: updatedSongs);
        // Mutate local state immediately for responsive UI
        _playlists[index] = updatedPlaylist;
        notifyListeners();
        // Persist to disk in background
        await _playlistService.updatePlaylist(updatedPlaylist);
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> removeSongFromAllPlaylists(String songPath) async {
    try {
      await _playlistService.removeSongFromAllPlaylists(songPath);
      // Mutate local state instead of reloading from disk
      for (int i = 0; i < _playlists.length; i++) {
        final playlist = _playlists[i];
        final updatedSongs = playlist.songs.where((s) => s['path'] != songPath).toList();
        if (updatedSongs.length != playlist.songs.length) {
          _playlists[i] = playlist.copyWith(songs: updatedSongs);
        }
      }
      notifyListeners();
    } catch (e) {
      // Handle error
    }
  }
}
