import 'package:flutter/material.dart';
import '../models/youtube_video.dart';
import '../services/download_service.dart';

class VideoDetailsSheet extends StatefulWidget {
  final YouTubeVideo video;

  const VideoDetailsSheet({super.key, required this.video});

  @override
  State<VideoDetailsSheet> createState() => _VideoDetailsSheetState();
}

class _VideoDetailsSheetState extends State<VideoDetailsSheet> {
  Future<void> _downloadSong() async {
    try {
      final downloadService = DownloadService();
      downloadService.addToQueue(widget.video);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Added to download queue')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            widget.video.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            widget.video.channelTitle,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _downloadSong,
              icon: const Icon(Icons.download),
              label: const Text('Download'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}