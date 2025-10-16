import 'package:flutter/material.dart';

class SongCard extends StatelessWidget {
  final Map<String, dynamic> song;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onPlay;
  final List<PopupMenuEntry<String>>? menuItems;
  final bool showDragHandle;
  final Key? cardKey;
  final int? reorderIndex;

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
  });

  @override
  Widget build(BuildContext context) {
    final songPath = song['path'] as String;
    final thumbnailUrl = song['thumbnail_url'] as String?;
    final artist = song['artist'] as String? ?? 'Unknown Artist';
    final title = song['title'] as String? ?? song['name'] as String;

    return Card(
      key: cardKey,
      margin: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 6,
      ),
      elevation: isPlaying ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isPlaying
            ? BorderSide(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                width: 2,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
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
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withOpacity(0.5),
                    ),
                  )
                else
                  Icon(
                    Icons.drag_handle,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withOpacity(0.5),
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
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: thumbnailUrl != null
                        ? Image.network(
                            thumbnailUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.music_note,
                                size: showDragHandle ? 28 : 32,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              );
                            },
                          )
                        : Icon(
                            Icons.music_note,
                            size: showDragHandle ? 28 : 32,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
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
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight:
                                      isPlaying ? FontWeight.w600 : FontWeight.w500,
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
                      style:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
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
                    onPressed: onPlay,
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
  }
}