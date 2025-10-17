import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/youtube_video.dart';
import '../services/download_service.dart';

class VideoDetailsSheet extends StatefulWidget {
  final YouTubeVideo video;

  const VideoDetailsSheet({super.key, required this.video});

  @override
  State<VideoDetailsSheet> createState() => _VideoDetailsSheetState();
}

class _VideoDetailsSheetState extends State<VideoDetailsSheet> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  Future<void> _downloadSong() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final downloadService = DownloadService();
      await downloadService.initialize();

      await downloadService.downloadAudio(
        widget.video,
        onProgress: (progress) {
          setState(() => _downloadProgress = progress);
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Downloaded')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDownloading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
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
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: widget.video.thumbnailUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 180,
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                child: Icon(
                  Icons.music_note,
                  size: 60,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.video.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
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
          if (_isDownloading) ...[
            LinearProgressIndicator(value: _downloadProgress > 0 ? _downloadProgress : null),
            const SizedBox(height: 8),
            Text('${(_downloadProgress * 100).toInt()}%'),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isDownloading ? null : _downloadSong,
              icon: Icon(_isDownloading ? Icons.downloading : Icons.download),
              label: Text(_isDownloading ? 'Downloading...' : 'Download'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}