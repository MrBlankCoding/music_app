import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PlaybackBar extends StatelessWidget {
  final AudioPlayer audioPlayer;
  final Map<String, dynamic>? currentSong;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final VoidCallback onPlayPause;
  final VoidCallback onStop;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onShuffle;
  final bool isShuffleEnabled;

  const PlaybackBar({
    super.key,
    required this.audioPlayer,
    required this.currentSong,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.onPlayPause,
    required this.onStop,
    this.onNext,
    this.onPrevious,
    this.onShuffle,
    this.isShuffleEnabled = false,
  });

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (currentSong == null) return const SizedBox.shrink();

    final thumbUrl = currentSong!['thumbnailUrl'] ?? currentSong!['thumbnail_url'];
    final artist = currentSong!['artist'] ?? '';
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Album art
              if (thumbUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: CachedNetworkImage(
                    imageUrl: thumbUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 56,
                      height: 56,
                      color: theme.colorScheme.surfaceContainerHigh,
                      child: Icon(
                        Icons.music_note,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 56,
                      height: 56,
                      color: theme.colorScheme.surfaceContainerHigh,
                      child: Icon(
                        Icons.broken_image,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 16),
              // Song info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentSong!['name'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Control buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onShuffle != null)
                    IconButton(
                      icon: Icon(Icons.shuffle),
                      color: isShuffleEnabled
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      onPressed: onShuffle,
                      tooltip: 'Shuffle',
                    ),
                  if (onPrevious != null)
                    IconButton(
                      icon: const Icon(Icons.skip_previous),
                      onPressed: onPrevious,
                      tooltip: 'Previous',
                    ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 28,
                      ),
                      color: theme.colorScheme.onPrimaryContainer,
                      onPressed: onPlayPause,
                      tooltip: isPlaying ? 'Pause' : 'Play',
                    ),
                  ),
                  if (onNext != null)
                    IconButton(
                      icon: const Icon(Icons.skip_next),
                      onPressed: onNext,
                      tooltip: 'Next',
                    ),
                  IconButton(
                    icon: const Icon(Icons.stop),
                    onPressed: onStop,
                    tooltip: 'Stop',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar with time labels
          Row(
            children: [
              Text(
                _formatDuration(position),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontVariations: [const FontVariation('wght', 500)],
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 14,
                    ),
                  ),
                  child: Slider(
                    value: position.inSeconds.toDouble(),
                    max: duration.inSeconds > 0 ? duration.inSeconds.toDouble() : 1.0,
                    onChanged: (value) {
                      audioPlayer.seek(Duration(seconds: value.toInt()));
                    },
                  ),
                ),
              ),
              Text(
                _formatDuration(duration),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontVariations: [const FontVariation('wght', 500)],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}