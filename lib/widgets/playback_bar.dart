import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../providers/music_player_provider.dart';
import '../screens/full_player_screen.dart';
import '../utils/song_data_helper.dart';

class PlaybackBar extends StatefulWidget {
  final double bottomPadding;

  const PlaybackBar({super.key, this.bottomPadding = 0});

  @override
  State<PlaybackBar> createState() => _PlaybackBarState();
}

class _PlaybackBarState extends State<PlaybackBar>
    with TickerProviderStateMixin {
  static const double _barHeight = 4.0;
  static const double _dotSize = 12.0;
  static const double _swipeThreshold = 50.0;

  double _horizontalDragDx = 0.0;
  double _swipeOffset = 0.0;
  bool _isDraggingProgress = false;
  double? _seekFraction;
  late AnimationController _swipeAnimationController;
  late AnimationController _marqueeController;

  @override
  void initState() {
    super.initState();
    _swipeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _marqueeController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _swipeAnimationController.dispose();
    _marqueeController.dispose();
    super.dispose();
  }

  void _openFullPlayer() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const FullPlayerScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.0, 1.0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _handleHorizontalDragEnd(MusicPlayerProvider provider) {
    if (_horizontalDragDx <= -_swipeThreshold) {
      HapticFeedback.lightImpact();
      provider.playNext();
    } else if (_horizontalDragDx >= _swipeThreshold) {
      HapticFeedback.lightImpact();
      provider.playPrevious();
    }

    _swipeAnimationController.reverse().then((_) {
      if (mounted) setState(() => _horizontalDragDx = 0.0);
    });
  }

  void _updateSeekPosition(double fraction) {
    setState(() => _seekFraction = fraction.clamp(0.0, 1.0));
  }

  void _commitSeek(MusicPlayerProvider provider, Duration? duration) {
    if (_seekFraction != null && duration != null) {
      final totalMs = duration.inMilliseconds;
      final clampedFraction = _seekFraction!.clamp(0.0, 0.999);
      final targetMs = (totalMs * clampedFraction).round();
      provider.seek(Duration(milliseconds: targetMs));
    }
    setState(() {
      _isDraggingProgress = false;
      _seekFraction = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final musicPlayerProvider = context.watch<MusicPlayerProvider>();
    if (musicPlayerProvider.currentSong == null) return const SizedBox.shrink();

    final songData = SongData(musicPlayerProvider.currentSong!);
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: _openFullPlayer,
      onHorizontalDragStart: (_) {
        setState(() => _horizontalDragDx = 0.0);
        _swipeAnimationController.forward();
      },
      onHorizontalDragUpdate: (details) {
        setState(() => _horizontalDragDx += details.primaryDelta ?? 0.0);
      },
      onHorizontalDragEnd: (_) => _handleHorizontalDragEnd(musicPlayerProvider),
      onVerticalDragUpdate: (details) {
        if (details.primaryDelta! < 0) {
          setState(() => _swipeOffset += details.primaryDelta!);
        }
      },
      onVerticalDragEnd: (details) {
        if (_swipeOffset < -_swipeThreshold) _openFullPlayer();
        setState(() => _swipeOffset = 0.0);
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (_horizontalDragDx.abs() > 20) _buildSwipeIndicator(theme),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildProgressBar(theme, musicPlayerProvider),
                _buildContentArea(theme, songData, musicPlayerProvider),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(ThemeData theme, MusicPlayerProvider provider) {
    return StreamBuilder<Duration?>(
      stream: provider.durationStream,
      builder: (context, durationSnapshot) {
        final duration = durationSnapshot.data ?? Duration.zero;
        return StreamBuilder<Duration>(
          stream: provider.positionStream,
          builder: (context, positionSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;

            double progress = 0.0;
            if (_isDraggingProgress && _seekFraction != null) {
              progress = _seekFraction!;
            } else if (duration.inMilliseconds > 0) {
              progress = (position.inMilliseconds / duration.inMilliseconds)
                  .clamp(0.0, 1.0);
            }

            return SizedBox(
              height: _barHeight + 8,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final filledWidth = width * progress;
                  final dotLeft = (filledWidth - (_dotSize / 2)).clamp(
                    0.0,
                    width - _dotSize,
                  );

                  return GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTapDown: (details) {
                      setState(() => _isDraggingProgress = true);
                      _updateSeekPosition(details.localPosition.dx / width);
                    },
                    onTapUp: (_) => _commitSeek(provider, duration),
                    onHorizontalDragStart: (_) =>
                        setState(() => _isDraggingProgress = true),
                    onHorizontalDragUpdate: (details) {
                      _updateSeekPosition(details.localPosition.dx / width);
                    },
                    onHorizontalDragEnd: (_) => _commitSeek(provider, duration),
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        _buildProgressTrack(theme, width, filledWidth),
                        _buildProgressDot(theme, dotLeft),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProgressTrack(
    ThemeData theme,
    double width,
    double filledWidth,
  ) {
    return SizedBox(
      height: _barHeight,
      width: width,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(_barHeight / 2),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: filledWidth,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(_barHeight / 2),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressDot(ThemeData theme, double dotLeft) {
    return Positioned(
      left: dotLeft,
      child: AnimatedScale(
        scale: _isDraggingProgress ? 1.3 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: _dotSize,
          height: _dotSize,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.colorScheme.surfaceContainerHighest,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.4),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentArea(
    ThemeData theme,
    SongData songData,
    MusicPlayerProvider provider,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          _buildAlbumArt(theme, songData, provider),
          const SizedBox(width: 12),
          Expanded(child: _buildSongInfo(theme, songData)),
          const SizedBox(width: 12),
          _buildPlayPauseButton(theme, provider),
        ],
      ),
    );
  }

  Widget _buildAlbumArt(
    ThemeData theme,
    SongData songData,
    MusicPlayerProvider provider,
  ) {
    return StreamBuilder<SequenceState?>(
      stream: provider.sequenceStateStream,
      builder: (context, snapshot) {
        final mediaItem = snapshot.data?.currentSource?.tag as MediaItem?;
        final art = mediaItem?.extras?['albumArt'];
        Uint8List? artBytes;
        if (art is Uint8List) {
          artBytes = art;
        } else if (art is List<int>) {
          artBytes = Uint8List.fromList(art);
        } else if (art is String) {
          try {
            if (art.startsWith('data:')) {
              final comma = art.indexOf(',');
              if (comma != -1 && comma + 1 < art.length) {
                artBytes = base64Decode(art.substring(comma + 1));
              }
            } else {
              artBytes = base64Decode(art);
            }
          } catch (_) {
            artBytes = null;
          }
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: artBytes != null
              ? Image.memory(
                  artBytes,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _buildPlaceholder(theme, Icons.broken_image),
                )
              : _buildPlaceholder(theme, Icons.music_note),
        );
      },
    );
  }

  Widget _buildSongInfo(ThemeData theme, SongData songData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _MarqueeText(
          text: songData.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          controller: _marqueeController,
        ),
        const SizedBox(height: 4),
        Text(
          songData.artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayPauseButton(ThemeData theme, MusicPlayerProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(
          provider.isPlaying ? Icons.pause : Icons.play_arrow,
          size: 28,
        ),
        color: theme.colorScheme.onPrimary,
        onPressed: () {
          HapticFeedback.lightImpact();
          provider.playPause();
        },
        tooltip: provider.isPlaying ? 'Pause' : 'Play',
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme, IconData icon) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 24, color: theme.colorScheme.onSurfaceVariant),
    );
  }

  Widget _buildSwipeIndicator(ThemeData theme) {
    final isSwipingLeft = _horizontalDragDx < 0;
    final swipeProgress = (_horizontalDragDx.abs() / _swipeThreshold).clamp(
      0.0,
      1.0,
    );
    final opacity = (swipeProgress * 0.6).clamp(0.0, 0.6);

    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          alignment: isSwipingLeft
              ? Alignment.centerRight
              : Alignment.centerLeft,
          padding: EdgeInsets.only(
            left: isSwipingLeft ? 0 : 24,
            right: isSwipingLeft ? 24 : 0,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: isSwipingLeft
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              end: isSwipingLeft ? Alignment.centerRight : Alignment.centerLeft,
              colors: [
                Colors.transparent,
                theme.colorScheme.primary.withValues(alpha: opacity),
              ],
            ),
          ),
          child: AnimatedOpacity(
            opacity: swipeProgress,
            duration: const Duration(milliseconds: 100),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isSwipingLeft) ...[
                  Icon(
                    Icons.skip_previous_rounded,
                    color: theme.colorScheme.onPrimary,
                    size: 32,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  isSwipingLeft ? 'Next' : 'Previous',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isSwipingLeft) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.skip_next_rounded,
                    color: theme.colorScheme.onPrimary,
                    size: 32,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MarqueeText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final AnimationController controller;

  const _MarqueeText({
    required this.text,
    required this.style,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout();

        final shouldScroll = textPainter.width > constraints.maxWidth;

        if (!shouldScroll) {
          return Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          );
        }

        return ClipRect(
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final textWidth = textPainter.width;
              final scrollDistance = textWidth + 40;
              final offset = controller.value * scrollDistance;

              return Transform.translate(
                offset: Offset(-offset, 0),
                child: Row(
                  children: [
                    Text(text, style: style, maxLines: 1, softWrap: false),
                    const SizedBox(width: 40),
                    Text(text, style: style, maxLines: 1, softWrap: false),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
