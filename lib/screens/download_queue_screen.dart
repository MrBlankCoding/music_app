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

  @override
  Widget build(BuildContext context) {
    final downloadService = context.watch<DownloadService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Download Queue')),
      body: ListView.builder(
        itemCount: downloadService.downloadQueue.length,
        itemBuilder: (context, index) {
          final video = downloadService.downloadQueue.elementAt(index);

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
                  Text(
                    'Queued',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
