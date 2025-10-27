import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
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
    final albumArtBytes = songData.albumArt;
    final artist = songData.artist;
    final title = songData.title;

    final cardWidget = Card(
      key: cardKey,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: isPlaying ? 2 : 0,
      shadowColor: isPlaying 
          ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isPlaying
            ? BorderSide(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                width: 1.5,
              )
            : BorderSide.none,
      ),
      color: isPlaying
          ? Theme.of(context).colorScheme.primary.withOpacity(0.08)
          : Theme.of(context).colorScheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
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
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Icon(
                        Icons.drag_indicator,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withOpacity(0.5),
                        size: 24,
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(
                      Icons.drag_indicator,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withOpacity(0.5),
                      size: 24,
                    ),
                  ),
              ],
              // Album Art with animated scale
              Hero(
                tag: 'song_$songPath',
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: showDragHandle ? 56 : 60,
                  height: showDragHandle ? 56 : 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    boxShadow: isPlaying
                        ? [
                            BoxShadow(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Theme.of(context).shadowColor.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildAlbumArtImage(
                      context,
                      albumArtBytes,
                      showDragHandle,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Song Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        if (isPlaying)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Icon(
                              Icons.graphic_eq_rounded,
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
                                  fontWeight: FontWeight.w600,
                                  color: isPlaying
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.onSurface,
                                  letterSpacing: 0.1,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      artist,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withOpacity(0.8),
                            fontSize: 13,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              // Action Buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      isPlaying
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_filled_rounded,
                      size: 40,
                    ),
                    color: Theme.of(context).colorScheme.primary,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      onPlay();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  ),
                  if (menuItems != null)
                    IconButton(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withOpacity(0.7),
                      ),
                      onPressed: () {
                        showMenu(
                          context: context,
                          position: RelativeRect.fromLTRB(
                            MediaQuery.of(context).size.width,
                            0,
                            0,
                            0,
                          ),
                          items: menuItems!,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        );
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
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
          padding: const EdgeInsets.only(right: 24),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.error.withOpacity(0.0),
                Theme.of(context).colorScheme.error,
              ],
              stops: const [0.0, 0.7],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.delete_rounded,
            color: Theme.of(context).colorScheme.onError,
            size: 32,
          ),
        ),
        confirmDismiss: (direction) async {
          HapticFeedback.mediumImpact();
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text('Delete Song'),
              content: Text(
                deleteConfirmMessage ??
                    'Are you sure you want to delete this song?',
              ),
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
    Uint8List? albumArtBytes,
    bool compact,
  ) {
    final musicPlayerProvider = context.watch<MusicPlayerProvider>();
    if (isPlaying) {
      return StreamBuilder<SequenceState?>(
        stream: musicPlayerProvider.sequenceStateStream,
        builder: (context, snapshot) {
          final mediaItem = snapshot.data?.currentSource?.tag as MediaItem?;
          Uint8List? effectiveBytes;
          // Try to get album art from mediaItem extras
          if (mediaItem?.extras?['albumArt'] is Uint8List) {
            effectiveBytes = mediaItem?.extras?['albumArt'] as Uint8List?;
          } else if (mediaItem?.extras?['artUri'] != null) {
            // Try to get from artUri if it's a base64 data URI
            final artUri = mediaItem?.extras?['artUri'] as String?;
            if (artUri != null && artUri.startsWith('data:image')) {
              try {
                final base64Data = artUri.split(',')[1];
                effectiveBytes = base64Decode(base64Data);
              } catch (e) {
                // Silently handle decoding errors
              }
            }
          }
          effectiveBytes ??= albumArtBytes;
          return _buildAlbumArt(context, effectiveBytes, compact);
        },
      );
    }

    return _buildAlbumArt(context, albumArtBytes, compact);
  }

  Widget _buildAlbumArt(BuildContext context, Uint8List? albumArtBytes, bool compact) {
    if (albumArtBytes != null) {
      return Image.memory(
        albumArtBytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) {
          return _buildPlaceholder(context, Icons.broken_image_rounded);
        },
      );
    }
    return _buildPlaceholder(context, Icons.music_note_rounded);
  }

  Widget _buildPlaceholder(BuildContext context, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surfaceContainerHighest,
            Theme.of(context).colorScheme.surfaceContainer,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 28,
          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
        ),
      ),
    );
  }
}