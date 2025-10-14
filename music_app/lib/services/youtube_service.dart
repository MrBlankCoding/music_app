import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/youtube_video.dart';

class YouTubeService {
  final String apiKey;

  YouTubeService({required this.apiKey});

  Future<List<YouTubeVideo>> searchVideos(String query) async {
    if (query.trim().isEmpty) return [];

    final url = Uri.parse(
      'https://www.googleapis.com/youtube/v3/search'
      '?part=snippet&q=$query&type=video&videoCategoryId=10&maxResults=25&key=$apiKey',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to search: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    final items = data['items'] as List;
    return items.map((item) => YouTubeVideo.fromJson(item)).toList();
  }
}