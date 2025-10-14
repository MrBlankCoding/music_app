
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

  // Getters
  List<YouTubeVideo> get videos => _videos;
  bool get isLoading => _isLoading;
  String get query => _query;

  Future<void> search(String query) async {
    if (query.trim().isEmpty) return;

    _query = query;
    _isLoading = true;
    notifyListeners();

    try {
      _videos = await _youtubeService.searchVideos(query);
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
}
