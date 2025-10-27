import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/youtube_video.dart';
import '../services/download_service.dart';
import 'video_details_sheet.dart';
import 'download_bottom_sheet.dart';

class MusicCard extends StatefulWidget {
  final YouTubeVideo video;

  const MusicCard({super.key, required this.video});

  @override
  State<MusicCard> createState() => _MusicCardState();
}

class _MusicCardState extends State<MusicCard> {
  void _showDownloadSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => DownloadBottomSheet(video: widget.video),
    );
  }

  @override
  Widget build(BuildContext context) {
    final downloadService = context.watch<DownloadService>();
    final isDownloading =
        downloadService.currentlyDownloadingVideoId == widget.video.videoId;
    final isQueued = downloadService.downloadQueue
        .any((v) => v.videoId == widget.video.videoId);
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 80,
          height: 60,
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          child: widget.video.thumbnailUrl.isNotEmpty
              ? Image.network(
                  widget.video.thumbnailUrl,
                  width: 80,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.music_note,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        strokeWidth: 2,
                      ),
                    );
                  },
                )
              : Icon(
                  Icons.music_note,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
        ),
      ),
      title: Text(
        widget.video.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        widget.video.channelTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: isDownloading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : isQueued
              ? const Chip(label: Text('Queued'))
              : const Icon(Icons.download),
      enabled: !isQueued,
      onTap: () => _showDownloadSheet(context),
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => VideoDetailsSheet(video: widget.video),
        );
      },
    );
  }
}