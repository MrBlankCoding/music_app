import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
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
  double _swipeOffset = 0.0;

  void _openFullPlayer() {
    HapticFeedback.mediumImpact();
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

    const double barHeight = 4.0;
    const double dotSize = 12.0;

    return GestureDetector(
      onTap: _openFullPlayer,
      onVerticalDragUpdate: (details) {
        if (details.primaryDelta! < 0) {
          setState(() {
            _swipeOffset += details.primaryDelta!;
          });
        }
      },
      onVerticalDragEnd: (details) {
        if (_swipeOffset < -50) {
          _openFullPlayer();
        }
        setState(() {
          _swipeOffset = 0.0;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress bar at the top
            SizedBox(
              height: barHeight + 4, // Extra space for the dot
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
                      alignment: Alignment.center,
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
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            height: barHeight,
                            width: filledWidth,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(barHeight / 2),
                            ),
                          ),
                        ),
                        // Position dot
                        Positioned(
                          left: dotLeft,
                          child: Container(
                            width: dotSize,
                            height: dotSize,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.colorScheme.surfaceContainerHighest,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withOpacity(0.4),
                                  blurRadius: 4,
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
            // Main content area
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  // Album artwork
                  if (thumbUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: thumbUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => _buildPlaceholder(theme, Icons.music_note),
                        errorWidget: (context, url, error) => _buildPlaceholder(theme, Icons.broken_image),
                      ),
                    )
                  else
                    _buildPlaceholder(theme, Icons.music_note),
                  const SizedBox(width: 12),
                  // Song info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.currentSong!['name'] ?? 'Unknown',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          artist.isEmpty ? 'Unknown Artist' : artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Control buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.onPrevious != null)
                        IconButton(
                          icon: const Icon(Icons.skip_previous),
                          iconSize: 28,
                          color: theme.colorScheme.onSurfaceVariant,
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            widget.onPrevious!();
                          },
                          tooltip: 'Previous',
                        ),
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            widget.isPlaying ? Icons.pause : Icons.play_arrow,
                            size: 28,
                          ),
                          color: theme.colorScheme.onPrimary,
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            widget.onPlayPause();
                          },
                          tooltip: widget.isPlaying ? 'Pause' : 'Play',
                        ),
                      ),
                      if (widget.onNext != null)
                        IconButton(
                          icon: const Icon(Icons.skip_next),
                          iconSize: 28,
                          color: theme.colorScheme.onSurfaceVariant,
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            widget.onNext!();
                          },
                          tooltip: 'Next',
                        ),
                    ],
                  ),
                ],
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
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        size: 24,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}