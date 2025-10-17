import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/download_service.dart';

class DownloadQueueScreen extends StatefulWidget {
  const DownloadQueueScreen({super.key});

  @override
  State<DownloadQueueScreen> createState() => _DownloadQueueScreenState();
}

class _DownloadQueueScreenState extends State<DownloadQueueScreen> {
  late DownloadService _downloadService;
  @override
  void initState() {
    super.initState();
    _downloadService = context.read<DownloadService>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _downloadService.isQueueScreenVisible = true;
    });
  }

  @override
  void dispose() {
    _downloadService.isQueueScreenVisible = false;
    super.dispose();
  }

  String _getProgressText(double progress, Map<String, dynamic>? details) {
    if (details != null && details['status'] == 'converting') {
      return 'Converting to MP3...';
    }
    return '${(progress * 100).toStringAsFixed(1)}%';
  }

  String _formatSpeed(dynamic speed) {
    if (speed == null || speed == 0) return '';
    final speedInBytes = speed is int ? speed.toDouble() : speed as double;

    if (speedInBytes < 1024) {
      return '${speedInBytes.toStringAsFixed(0)} B/s';
    } else if (speedInBytes < 1024 * 1024) {
      return '${(speedInBytes / 1024).toStringAsFixed(1)} KB/s';
    } else {
      return '${(speedInBytes / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
  }

  String _formatEta(int eta) {
    if (eta <= 0) return 'Unknown';

    if (eta < 60) {
      return '${eta}s';
    } else if (eta < 3600) {
      final minutes = eta ~/ 60;
      final seconds = eta % 60;
      return '${minutes}m ${seconds}s';
    } else {
      final hours = eta ~/ 3600;
      final minutes = (eta % 3600) ~/ 60;
      return '${hours}h ${minutes}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    final downloadService = context.watch<DownloadService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Download Queue'),
      ),
      body: ListView.builder(
        itemCount: downloadService.downloadQueue.length,
        itemBuilder: (context, index) {
          final video = downloadService.downloadQueue.elementAt(index);
          final progress = downloadService.downloadProgress[video.videoId];
          final details = downloadService.downloadDetails[video.videoId];

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          video.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel),
                        onPressed: () {
                          downloadService.cancelDownload(video);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (progress != null) ...[
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getProgressText(progress, details),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (details != null &&
                            details['speed'] != null &&
                            details['speed'] > 0)
                          Text(
                            _formatSpeed(details['speed']),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                    if (details != null &&
                        details['eta'] != null &&
                        details['eta'] > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'ETA: ${_formatEta(details['eta'])}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                  ] else
                    Text(
                      'Queued',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
