import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/youtube_playlist.dart';
import 'package:oktoast/oktoast.dart';
import 'package:html_unescape/html_unescape.dart';

class PlaylistCard extends StatefulWidget {
  final YouTubePlaylist playlist;

  const PlaylistCard({super.key, required this.playlist});

  @override
  State<PlaylistCard> createState() => _PlaylistCardState();
}

class _PlaylistCardState extends State<PlaylistCard> {
  bool _isDownloading = false;

  void _downloadPlaylist() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://2c1783657af6.ngrok-free.app/download_playlist'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'playlist_id': widget.playlist.playlistId,
          'title': widget.playlist.title,
          'thumbnail': widget.playlist.thumbnailUrl,
          'channel_title': widget.playlist.channelTitle,
        }),
      );

      if (response.statusCode == 200) {
        showToast(
          "✓ Playlist download started!",
          duration: const Duration(seconds: 3),
        );
      } else {
        showToast(
          "✗ Failed to start download",
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      showToast(
        "✗ Error: ${e.toString()}",
        duration: const Duration(seconds: 3),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final unescape = HtmlUnescape();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: widget.playlist.thumbnailUrl.isNotEmpty
              ? Image.network(
                  widget.playlist.thumbnailUrl,
                  width: 80,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 80,
                    height: 60,
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    child: Icon(
                      Icons.library_music,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : Container(
                  width: 80,
                  height: 60,
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  child: Icon(
                    Icons.library_music,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
        ),
        title: Text(
          unescape.convert(widget.playlist.title),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              widget.playlist.channelTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.playlist_play,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.playlist.videoCount} songs',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: _isDownloading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : IconButton(
                icon: const Icon(Icons.download),
                onPressed: _downloadPlaylist,
                tooltip: 'Download playlist',
              ),
        onTap: _downloadPlaylist,
      ),
    );
  }
}
