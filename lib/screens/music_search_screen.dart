import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/youtube_video.dart';
import '../services/youtube_service.dart';
import '../widgets/music_card.dart';

class MusicSearchScreen extends StatefulWidget {
  const MusicSearchScreen({super.key});

  @override
  State<MusicSearchScreen> createState() => _MusicSearchScreenState();
}

class _MusicSearchScreenState extends State<MusicSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final YouTubeService _youtubeService = YouTubeService(
    apiKey: dotenv.env['YOUTUBE_API_KEY'] ?? '',
  );
  
  List<YouTubeVideo> _videos = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchMusic() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final videos = await _youtubeService.searchVideos(query);
      setState(() {
        _videos = videos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search music...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _videos = [];
                          });
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _searchMusic(),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _videos.isEmpty
                    ? const Center(child: Text('No results'))
                    : ListView.builder(
                        itemCount: _videos.length,
                        itemBuilder: (context, index) {
                          return MusicCard(video: _videos[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}