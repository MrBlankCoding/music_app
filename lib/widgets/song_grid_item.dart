import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/song_data_helper.dart';

class SongGridItem extends StatelessWidget {
  final Map<String, dynamic> song;
  final VoidCallback onTap;
  final Future<void> Function()? onAddToQueue;
  final Future<void> Function()? onDelete;

  const SongGridItem({
    super.key,
    required this.song,
    required this.onTap,
    this.onAddToQueue,
    this.onDelete,
  });

  Uint8List? _getAlbumArt() {
    final songData = SongData(song);
    return songData.albumArt;
  }

  @override
  Widget build(BuildContext context) {
    final albumArt = _getAlbumArt();
    
    Widget cardContent = Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: albumArt != null
                    ? Image.memory(
                        albumArt,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.music_note, size: 40),
                        ),
                      )
                    : Container(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.music_note, size: 40),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song['title'] ?? 'Unknown Title',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    song['artist'] ?? 'Unknown Artist',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // Grid view doesn't support swipe gestures - use long press instead
    if (onAddToQueue != null || onDelete != null) {
      return GestureDetector(
        onLongPress: () async {
          HapticFeedback.mediumImpact();
          if (onDelete != null) {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: const Text('Delete Song'),
                content: const Text('Are you sure you want to delete this song?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              await onDelete!();
            }
          }
        },
        child: cardContent,
      );
    }

    return cardContent;
  }
}
