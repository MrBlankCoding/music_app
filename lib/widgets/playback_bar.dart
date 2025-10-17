import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../screens/full_player_screen.dart';

class PlaybackBar extends StatefulWidget {
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
  final double bottomPadding;

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
    this.bottomPadding = 0,
  });

  @override
  State<PlaybackBar> createState() => _PlaybackBarState();
}

class _PlaybackBarState extends State<PlaybackBar> {
  void _openFullPlayer() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => FullPlayerScreen(
          audioPlayer: widget.audioPlayer,
          currentSong: widget.currentSong!,
          isPlaying: widget.isPlaying,
          position: widget.position,
          duration: widget.duration,
          onPlayPause: widget.onPlayPause,
          onStop: widget.onStop,
          onNext: widget.onNext,
          onPrevious: widget.onPrevious,
          onShuffle: widget.onShuffle,
          isShuffleEnabled: widget.isShuffleEnabled,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _seekToDx(double width, double dx) {
    final totalMs = widget.duration.inMilliseconds;
    if (totalMs <= 0) return;
    final fraction = (dx / width).clamp(0.0, 1.0);
    final targetMs = (totalMs * fraction).round();
    widget.audioPlayer.seek(Duration(milliseconds: targetMs));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentSong == null) return const SizedBox.shrink();

    return _buildMinimizedBar(context);
  }

  Widget _buildMinimizedBar(BuildContext context) {
    final theme = Theme.of(context);
    final thumbUrl = widget.currentSong!['thumbnailUrl'] ?? widget.currentSong!['thumbnail_url'];
    final artist = widget.currentSong!['artist'] ?? '';

    final totalMs = widget.duration.inMilliseconds;
    final posMs = widget.position.inMilliseconds;
    final progress = totalMs > 0 ? (posMs / totalMs).clamp(0.0, 1.0) : 0.0;

    const double barHeight = 4.0; // thicker bar
    const double dotSize = 10.0;   // dot diameter

    return GestureDetector(
      onTap: _openFullPlayer,
      child: Container(
        height: 80,
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
        child: Stack(
          children: [
            Row(
              children: [
                if (thumbUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CachedNetworkImage(
                      imageUrl: thumbUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => _buildPlaceholder(theme, Icons.music_note),
                      errorWidget: (context, url, error) => _buildPlaceholder(theme, Icons.broken_image),
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.currentSong!['name'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
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
                _buildPlayButton(theme),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final filledWidth = width * progress;
                  final dotLeft = (filledWidth - (dotSize / 2)).clamp(0.0, width - dotSize);

                  return GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTapDown: (details) {
                      _seekToDx(width, details.localPosition.dx);
                    },
                    onHorizontalDragUpdate: (details) {
                      _seekToDx(width, details.localPosition.dx);
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Background bar
                        Container(
                          height: barHeight,
                          width: width,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(barHeight / 2),
                          ),
                        ),
                        // Filled progress
                        Container(
                          height: barHeight,
                          width: filledWidth,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(barHeight / 2),
                          ),
                        ),
                        // Position dot
                        Positioned(
                          left: dotLeft,
                          top: -(dotSize - barHeight) / 2,
                          child: Container(
                            width: dotSize,
                            height: dotSize,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withOpacity(0.3),
                                  blurRadius: 6,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
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

  Widget _buildPlayButton(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(widget.isPlaying ? Icons.pause : Icons.play_arrow, size: 28),
        color: theme.colorScheme.onPrimaryContainer,
        onPressed: widget.onPlayPause,
        tooltip: widget.isPlaying ? 'Pause' : 'Play',
      ),
    );
  }
}