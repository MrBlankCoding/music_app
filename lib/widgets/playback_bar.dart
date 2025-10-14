
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

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (currentSong!['thumbnailUrl'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    imageUrl: currentSong!['thumbnailUrl'],
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 48,
                      height: 48,
                      color: Colors.grey[300],
                      child: const Icon(Icons.music_note),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 48,
                      height: 48,
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              // Shuffle button
              if (onShuffle != null)
                IconButton(
                  icon: Icon(
                    Icons.shuffle,
                    color: isShuffleEnabled
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  onPressed: onShuffle,
                ),
              // Previous button
              if (onPrevious != null)
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  onPressed: onPrevious,
                ),
              // Play/Pause button
              IconButton(
                icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: onPlayPause,
              ),
              // Next button
              if (onNext != null)
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  onPressed: onNext,
                ),
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
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${_formatDuration(position)} / ${_formatDuration(duration)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ), 
              ),
              // Stop button
              IconButton(
                icon: const Icon(Icons.stop),
                onPressed: onStop,
              ),
            ],
          ),
          Slider(
            value: position.inSeconds.toDouble(),
            max: duration.inSeconds > 0 ? duration.inSeconds.toDouble() : 1.0,
            onChanged: (value) {
              audioPlayer.seek(Duration(seconds: value.toInt()));
            },
          ),
        ],
      ),
    );
  }
}