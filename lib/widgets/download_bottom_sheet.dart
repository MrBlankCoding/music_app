import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/youtube_video.dart';
import '../services/download_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DownloadBottomSheet extends StatelessWidget {
  final YouTubeVideo video;

  const DownloadBottomSheet({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: video.thumbnailUrl,
                width: 120,
                height: 90,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              video.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              video.channelTitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Consumer<DownloadService>(
              builder: (context, downloadService, child) {
                final progress = downloadService.downloadProgress[video.videoId];
                final isQueued = downloadService.downloadQueue.any((v) => v.videoId == video.videoId);

                if (progress != null) {
                  return Column(
                    children: [
                      LinearProgressIndicator(value: progress),
                      const SizedBox(height: 8),
                      Text('${(progress * 100).toStringAsFixed(0)}%'),
                    ],
                  );
                } else if (isQueued) {
                  return const Chip(label: Text('Queued'));
                } else {
                  return ElevatedButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('Download'),
                    onPressed: () {
                      downloadService.addToQueue(video);
                      Navigator.pop(context);
                    },
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
