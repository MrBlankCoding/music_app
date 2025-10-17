import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FullPlayerScreen extends StatefulWidget {
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

  @override
  State<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends State<FullPlayerScreen> {
  double _dragOffset = 0.0;
  bool _isDragging = false;

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _isDragging = true;
      _dragOffset += details.primaryDelta ?? 0;
      // Clamp to only allow downward dragging
      if (_dragOffset < 0) _dragOffset = 0;
    });
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    if (_dragOffset > 100) {
      // Threshold to dismiss
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop();
    } else {
      setState(() {
        _dragOffset = 0.0;
        _isDragging = false;
      });
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thumbUrl = widget.currentSong['thumbnailUrl'] ?? widget.currentSong['thumbnail_url'];
    final artist = widget.currentSong['artist'] ?? '';

    final opacity = (_dragOffset / 300).clamp(0.0, 1.0);
    final scale = 1.0 - ((_dragOffset / 1000).clamp(0.0, 0.1));

    return Scaffold(
      backgroundColor: theme.colorScheme.surface.withOpacity(1.0 - opacity),
      body: GestureDetector(
        onVerticalDragUpdate: _handleVerticalDragUpdate,
        onVerticalDragEnd: _handleVerticalDragEnd,
        child: Transform.translate(
          offset: Offset(0, _dragOffset),
          child: Transform.scale(
            scale: scale,
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        // Drag indicator
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.keyboard_arrow_down, size: 32),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                Navigator.of(context).pop();
                              },
                              tooltip: 'Minimize',
                            ),
                          ],
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
                            widget.currentSong['name'] ?? '',
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
          ),
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
    return StreamBuilder<Duration?>(
      stream: widget.audioPlayer.durationStream,
      initialData: widget.duration,
      builder: (context, durationSnap) {
        final d = durationSnap.data ?? Duration.zero;
        final maxSeconds = d.inSeconds > 0 ? d.inSeconds.toDouble() : 1.0;
        return StreamBuilder<Duration>(
          stream: widget.audioPlayer.positionStream,
          initialData: widget.position,
          builder: (context, positionSnap) {
            final p = positionSnap.data ?? Duration.zero;
            final valueSeconds = p.inSeconds.clamp(0, d.inSeconds).toDouble();
            return Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  ),
                  child: Slider(
                    value: valueSeconds,
                    max: maxSeconds,
                    onChanged: (value) {
                      HapticFeedback.selectionClick();
                      widget.audioPlayer.seek(Duration(seconds: value.toInt()));
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(p),
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      Text(
                        _formatDuration(d),
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildControls(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (widget.onShuffle != null)
          IconButton(
            icon: const Icon(Icons.shuffle, size: 32),
            color: widget.isShuffleEnabled ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            onPressed: () {
              HapticFeedback.lightImpact();
              widget.onShuffle!();
            },
            tooltip: 'Shuffle',
          )
        else
          const SizedBox(width: 48),
        if (widget.onPrevious != null)
          IconButton(
            icon: const Icon(Icons.skip_previous, size: 40),
            onPressed: () {
              HapticFeedback.lightImpact();
              widget.onPrevious!();
            },
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
            icon: Icon(widget.isPlaying ? Icons.pause : Icons.play_arrow, size: 48),
            iconSize: 64,
            color: theme.colorScheme.onPrimaryContainer,
            onPressed: () {
              HapticFeedback.mediumImpact();
              widget.onPlayPause();
            },
            tooltip: widget.isPlaying ? 'Pause' : 'Play',
          ),
        ),
        if (widget.onNext != null)
          IconButton(
            icon: const Icon(Icons.skip_next, size: 40),
            onPressed: () {
              HapticFeedback.lightImpact();
              widget.onNext!();
            },
            tooltip: 'Next',
          )
        else
          const SizedBox(width: 48),
        IconButton(
          icon: const Icon(Icons.stop, size: 32),
          onPressed: () {
            HapticFeedback.lightImpact();
            widget.onStop();
          },
          tooltip: 'Stop',
        ),
      ],
    );
  }
}