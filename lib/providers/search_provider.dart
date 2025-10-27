import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/youtube_video.dart';
import '../models/youtube_playlist.dart';

class SearchProvider with ChangeNotifier {
  List<YouTubeVideo> _videos = [];
  List<YouTubePlaylist> _playlists = [];
  bool _isLoading = false;
  String _query = '';
  final List<String> _recentSearches = [];
  bool _isPlaylistSearch = false;

  // Getters
  List<YouTubeVideo> get videos => _videos;
  List<YouTubePlaylist> get playlists => _playlists;
  bool get isLoading => _isLoading;
  String get query => _query;
  List<String> get recentSearches => List.unmodifiable(_recentSearches);
  bool get isPlaylistSearch => _isPlaylistSearch;

  Future<void> search(String query) async {
    if (query.trim().isEmpty) return;

    final q = query.trim();
    _recentSearches.removeWhere((e) => e.toLowerCase() == q.toLowerCase());
    _recentSearches.insert(0, q);
    if (_recentSearches.length > 5) {
      _recentSearches.removeRange(5, _recentSearches.length);
    }

    _query = q;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('https://lasandra-sultriest-bumblingly.ngrok-free.dev/search?query=$q'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['videos'] as List;
        _videos = items.map((item) => YouTubeVideo.fromJson(item)).toList();
      } else {
        _videos = [];
      }
    } catch (e) {
      _videos = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _videos = [];
    _query = '';
    notifyListeners();
  }

  void clearRecentSearches() {
    _recentSearches.clear();
    notifyListeners();
  }

  void setPlaylistSearch(bool value) {
    _isPlaylistSearch = value;
    notifyListeners();
  }

  Future<void> searchPlaylists(String query) async {
    if (query.trim().isEmpty) return;

    final q = query.trim();
    _isPlaylistSearch = true;
    _playlists = [];
    _query = q;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('https://lasandra-sultriest-bumblingly.ngrok-free.dev/search_playlists?query=$q'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['playlists'] as List;
        _playlists = items
            .map((item) => YouTubePlaylist.fromJson(item))
            .toList();
      } else {
        _playlists = [];
      }
    } catch (e) {
      _playlists = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
