
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/youtube_video.dart';
import '../services/youtube_service.dart';

class SearchProvider with ChangeNotifier {
  final YouTubeService _youtubeService = YouTubeService(
    apiKey: dotenv.env['YOUTUBE_API_KEY'] ?? '',
  );

  List<YouTubeVideo> _videos = [];
  bool _isLoading = false;
  String _query = '';
  final List<String> _recentSearches = [];

  // Getters
  List<YouTubeVideo> get videos => _videos;
  bool get isLoading => _isLoading;
  String get query => _query;
  List<String> get recentSearches => List.unmodifiable(_recentSearches);

  Future<void> search(String query) async {
    if (query.trim().isEmpty) return;

    // Record in recent history (dedupe, most-recent-first, max 5)
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
      _videos = await _youtubeService.searchVideos(q);
    } catch (e) {
      // Handle error
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
}
