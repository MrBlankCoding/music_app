import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/websocket_service.dart';

class PlaylistDownloadProgress extends StatelessWidget {
  const PlaylistDownloadProgress({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WebSocketService>(
      builder: (context, webSocketService, child) {
        final progressMap = webSocketService.playlistProgress;
        
        if (progressMap.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: progressMap.values.map((progress) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getStatusIcon(progress.status),
                            color: _getStatusColor(progress.status),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              progress.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            progress.progressText,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      if (progress.status == PlaylistDownloadStatus.downloading) ...[
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progress.progress,
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                      if (progress.status == PlaylistDownloadStatus.completed) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Download completed successfully',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[600],
                          ),
                        ),
                      ],
                      if (progress.status == PlaylistDownloadStatus.failed) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Download failed',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  IconData _getStatusIcon(PlaylistDownloadStatus status) {
    switch (status) {
      case PlaylistDownloadStatus.downloading:
        return Icons.download;
      case PlaylistDownloadStatus.completed:
        return Icons.check_circle;
      case PlaylistDownloadStatus.failed:
        return Icons.error;
    }
  }

  Color _getStatusColor(PlaylistDownloadStatus status) {
    switch (status) {
      case PlaylistDownloadStatus.downloading:
        return Colors.blue;
      case PlaylistDownloadStatus.completed:
        return Colors.green;
      case PlaylistDownloadStatus.failed:
        return Colors.red;
    }
  }
}
