import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FullPlayerScreen extends StatelessWidget {
  final AudioPlayer audioPlayer;
  final Map<String, dynamic> currentSong;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final VoidCallback onPlayPause;
  final VoidCallback onStop;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onShuffle;
  final bool isShuffleEnabled;

  const FullPlayerScreen({
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
    final theme = Theme.of(context);
    final thumbUrl = currentSong['thumbnailUrl'] ?? currentSong['thumbnail_url'];
    final artist = currentSong['artist'] ?? '';

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down, size: 32),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Minimize',
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: thumbUrl != null
                            ? CachedNetworkImage(
                                imageUrl: thumbUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => _buildPlaceholder(theme, Icons.music_note, size: 120),
                                errorWidget: (context, url, error) => _buildPlaceholder(theme, Icons.broken_image, size: 120),
                              )
                            : _buildPlaceholder(theme, Icons.music_note, size: 120),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      currentSong['name'] ?? '',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      artist,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildProgressBar(context, theme),
                    const SizedBox(height: 24),
                    _buildControls(theme),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme, IconData icon, {double size = 56}) {
    return Container(
      width: size,
      height: size,
      color: theme.colorScheme.surfaceContainerHigh,
      child: Icon(icon, size: size == 56 ? 24 : size, color: theme.colorScheme.onSurfaceVariant),
    );
  }

  Widget _buildProgressBar(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            value: position.inSeconds.toDouble(),
            max: duration.inSeconds > 0 ? duration.inSeconds.toDouble() : 1.0,
            onChanged: (value) => audioPlayer.seek(Duration(seconds: value.toInt())),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(position),
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              Text(
                _formatDuration(duration),
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControls(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (onShuffle != null)
          IconButton(
            icon: const Icon(Icons.shuffle, size: 32),
            color: isShuffleEnabled ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            onPressed: onShuffle,
            tooltip: 'Shuffle',
          )
        else
          const SizedBox(width: 48),
        if (onPrevious != null)
          IconButton(
            icon: const Icon(Icons.skip_previous, size: 40),
            onPressed: onPrevious,
            tooltip: 'Previous',
          )
        else
          const SizedBox(width: 48),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, size: 48),
            iconSize: 64,
            color: theme.colorScheme.onPrimaryContainer,
            onPressed: onPlayPause,
            tooltip: isPlaying ? 'Pause' : 'Play',
          ),
        ),
        if (onNext != null)
          IconButton(
            icon: const Icon(Icons.skip_next, size: 40),
            onPressed: onNext,
            tooltip: 'Next',
          )
        else
          const SizedBox(width: 48),
        IconButton(
          icon: const Icon(Icons.stop, size: 32),
          onPressed: onStop,
          tooltip: 'Stop',
        ),
      ],
    );
  }
}