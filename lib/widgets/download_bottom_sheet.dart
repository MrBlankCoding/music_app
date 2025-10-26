import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/youtube_video.dart';
import '../services/download_service.dart';

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
                final isQueued = downloadService.downloadQueue.any(
                  (v) => v.videoId == video.videoId,
                );

                if (isQueued) {
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