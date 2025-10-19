import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../providers/music_player_provider.dart';
import '../utils/song_data_helper.dart';

class SongCard extends StatelessWidget {
  final Map<String, dynamic> song;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onPlay;
  final List<PopupMenuEntry<String>>? menuItems;
  final bool showDragHandle;
  final Key? cardKey;
  final int? reorderIndex;
  final bool enableSwipeToDelete;
  final Future<void> Function()? onDelete;
  final String? deleteConfirmMessage;

  const SongCard({
    super.key,
    required this.song,
    required this.isPlaying,
    required this.onTap,
    required this.onPlay,
    this.menuItems,
    this.showDragHandle = false,
    this.cardKey,
    this.reorderIndex,
    this.enableSwipeToDelete = false,
    this.onDelete,
    this.deleteConfirmMessage,
  });

  @override
  Widget build(BuildContext context) {
    final songData = SongData(song);
    final songPath = songData.path;
    final thumbnailUrl = songData.thumbnailUrl;
    final artist = songData.artist;
    final title = songData.title;

    final cardWidget = Card(
      key: cardKey,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      elevation: isPlaying ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isPlaying
            ? BorderSide(
                color: Theme.of(context).colorScheme.primary.withAlpha(128),
                width: 2,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        onLongPress: () {
          HapticFeedback.mediumImpact();
          // Long press could trigger additional actions in the future
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Optional Drag Handle
              if (showDragHandle) ...[
                if (reorderIndex != null)
                  ReorderableDragStartListener(
                    index: reorderIndex!,
                    child: Icon(
                      Icons.drag_handle,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withAlpha(128),
                    ),
                  )
                else
                  Icon(
                    Icons.drag_handle,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withAlpha(128),
                  ),
                const SizedBox(width: 8),
              ],
              // Album Art
              Hero(
                tag: 'song_$songPath',
                child: Container(
                  width: showDragHandle ? 56 : 64,
                  height: showDragHandle ? 56 : 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).shadowColor.withAlpha(25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildAlbumArtImage(
                      context,
                      thumbnailUrl,
                      showDragHandle,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Song Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isPlaying)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Icon(
                              Icons.graphic_eq,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: isPlaying
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: isPlaying
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      artist,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Action Buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                      size: 32,
                    ),
                    color: Theme.of(context).colorScheme.primary,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      onPlay();
                    },
                  ),
                  if (menuItems != null)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      itemBuilder: (context) => menuItems!,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    // Wrap with Dismissible if swipe-to-delete is enabled
    if (enableSwipeToDelete && onDelete != null) {
      return Dismissible(
        key: Key('song_dismiss_$songPath'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.error,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.delete, color: Colors.white, size: 32),
        ),
        confirmDismiss: (direction) async {
          HapticFeedback.mediumImpact();
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Song'),
              content: Text(
                deleteConfirmMessage ??
                    'Are you sure you want to delete this song?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
        },
        onDismissed: (direction) async {
          HapticFeedback.lightImpact();
          await onDelete!();
        },
        child: cardWidget,
      );
    }

    return cardWidget;
  }

  Widget _buildAlbumArtImage(
    BuildContext context,
    String? thumbnailUrl,
    bool compact,
  ) {
    final musicPlayerProvider = context.watch<MusicPlayerProvider>();
    if (isPlaying) {
      return StreamBuilder<SequenceState?>(
        stream: musicPlayerProvider.sequenceStateStream,
        builder: (context, snapshot) {
          final mediaItem = snapshot.data?.currentSource?.tag as MediaItem?;
          final effectiveUrl = mediaItem?.artUri?.toString() ?? thumbnailUrl;
          return _buildAlbumArtFromUrl(context, effectiveUrl, compact);
        },
      );
    }

    return _buildAlbumArtFromUrl(context, thumbnailUrl, compact);
  }

  Widget _buildAlbumArtFromUrl(
    BuildContext context,
    String? url,
    bool compact,
  ) {
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (context, _) => Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        errorWidget: (context, __, ___) => Icon(
          Icons.music_note,
          size: compact ? 28 : 32,
          color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(153),
        ),
      );
    }

    return Icon(
      Icons.music_note,
      size: compact ? 28 : 32,
      color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(153),
    );
  }
}
