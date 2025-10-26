import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/youtube_video.dart';

class YouTubeService {
  final String apiKey;
  final String _serverUrl = 'http://127.0.0.1:8000';

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

  Stream<Map<String, dynamic>> downloadPlaylistStream(String playlistUrl) async* {
    final encodedPlaylistUrl = Uri.encodeComponent(playlistUrl);
    final url = Uri.parse('$_serverUrl/download-playlist?playlist_url=$encodedPlaylistUrl');

    final client = http.Client();
    final request = http.Request('GET', url);

    try {
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('Failed to download playlist: ${response.statusCode}');
      }

      String buffer = '';
      await for (var chunk in response.stream.transform(utf8.decoder)) {
        buffer += chunk;

        while (buffer.contains('\n\n')) {
          final endIndex = buffer.indexOf('\n\n');
          final message = buffer.substring(0, endIndex);
          buffer = buffer.substring(endIndex + 2);

          if (message.startsWith('data: ')) {
            final jsonStr = message.substring(6);
            try {
              final data = json.decode(jsonStr);
              yield data;
            } catch (e) {
              print('Error parsing SSE data: $e');
            }
          }
        }
      }
    } finally {
      client.close();
    }
  }
}
