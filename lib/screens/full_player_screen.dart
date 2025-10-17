import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';

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

class _FullPlayerScreenState extends State<FullPlayerScreen> with TickerProviderStateMixin {
  double _dragOffset = 0.0;
  late AnimationController _pulseController;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _rotationController = AnimationController(vsync: this, duration: const Duration(seconds: 20));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(FullPlayerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.isPlaying ? _rotationController.repeat() : _rotationController.stop();
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_dragOffset > 100) {
      HapticFeedback.mediumImpact();
      Navigator.pop(context);
    } else {
      setState(() => _dragOffset = 0);
    }
  }

  String _formatDuration(Duration d) => '${d.inMinutes.remainder(60)}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final scale = 1.0 - (_dragOffset / 1000).clamp(0.0, 0.1);

    return Scaffold(
      body: StreamBuilder<SequenceState?>(
        stream: widget.audioPlayer.sequenceStateStream,
        builder: (context, seqSnap) {
          final seq = seqSnap.data;
          final mediaItem = seq?.currentSource?.tag as MediaItem?;

          final thumbUrl = mediaItem?.artUri?.toString() ??
              (widget.currentSong['thumbnailUrl'] ?? widget.currentSong['thumbnail_url']);
          final title = mediaItem?.title ?? (widget.currentSong['name'] ?? '');
          final artist = mediaItem?.artist ?? (widget.currentSong['artist'] ?? '');
          final heroId = mediaItem?.id ?? (widget.currentSong['id']?.toString() ?? 'current');

          return Stack(
            children: [
              _buildBackground(thumbUrl),
              GestureDetector(
                onVerticalDragUpdate: (d) => setState(() => _dragOffset = (_dragOffset + (d.primaryDelta ?? 0)).clamp(0.0, double.infinity)),
                onVerticalDragEnd: _handleDragEnd,
                child: Transform.translate(
                  offset: Offset(0, _dragOffset),
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black.withOpacity(0.2), Colors.black.withOpacity(0.6)],
                        ),
                      ),
                      child: SafeArea(
                        child: Column(
                          children: [
                            _buildHeader(),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 28),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildAlbumArt(thumbUrl, heroId),
                                    const SizedBox(height: 40),
                                    _buildSongInfo(title, artist),
                                    const SizedBox(height: 36),
                                    _buildProgressBar(),
                                    const SizedBox(height: 28),
                                    _buildControls(),
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
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBackground(String? thumbUrl) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: const [Color(0xFF0a0e27), Color(0xFF1a1f3a), Color(0xFF2d1b4e)],
                  stops: [0.0, 0.5 + _pulseController.value * 0.1, 1.0],
                ),
              ),
            ),
            if (thumbUrl != null) ...[
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: thumbUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topCenter,
                        radius: 1.5,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.75),
                          Colors.black.withOpacity(0.95),
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 5,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.4), borderRadius: BorderRadius.circular(3)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _iconButton(Icons.keyboard_arrow_down, () => Navigator.pop(context), size: 32),
              if (widget.onShuffle != null)
                _iconButton(Icons.shuffle, widget.onShuffle!, 
                  isActive: widget.isShuffleEnabled, size: 26)
              else
                const SizedBox(width: 40),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumArt(String? thumbUrl, String heroId) {
    final size = MediaQuery.of(context).size.width * 0.72;
    return Hero(
      tag: 'album_art_${heroId}',
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final pulse = 1 + (_pulseController.value * 0.03);
          return Transform.scale(
            scale: widget.isPlaying ? pulse : 1.0,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.15),
                    blurRadius: 50,
                    spreadRadius: widget.isPlaying ? 8 : 0,
                  ),
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 40,
                    spreadRadius: 5,
                    offset: const Offset(0, 15),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 30,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: thumbUrl != null
                    ? CachedNetworkImage(
                        imageUrl: thumbUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _placeholder(Icons.music_note),
                        errorWidget: (_, __, ___) => _placeholder(Icons.broken_image),
                      )
                    : _placeholder(Icons.music_note),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _placeholder(IconData icon) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).colorScheme.primaryContainer, Theme.of(context).colorScheme.secondaryContainer],
        ),
      ),
      child: Icon(icon, size: 100, color: Colors.white.withOpacity(0.5)),
    );
  }

  Widget _buildSongInfo(String title, String artist) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Text(
            artist,
            style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.85)),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return StreamBuilder<Duration?>(
      stream: widget.audioPlayer.durationStream,
      initialData: widget.duration,
      builder: (_, dSnap) {
        final d = dSnap.data ?? Duration.zero;
        return StreamBuilder<Duration>(
          stream: widget.audioPlayer.positionStream,
          initialData: widget.position,
          builder: (_, pSnap) {
            final p = pSnap.data ?? Duration.zero;
            return Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white.withOpacity(0.2),
                    thumbColor: Colors.white,
                    overlayColor: Colors.white.withOpacity(0.2),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  ),
                  child: Slider(
                    value: p.inSeconds.clamp(0, d.inSeconds).toDouble(),
                    max: d.inSeconds > 0 ? d.inSeconds.toDouble() : 1,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      widget.audioPlayer.seek(Duration(seconds: v.toInt()));
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(p), style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7))),
                      Text(_formatDuration(d), style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7))),
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

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.onPrevious != null) _controlButton(Icons.skip_previous, widget.onPrevious!, 34),
        const SizedBox(width: 24),
        StreamBuilder<bool>(
          stream: widget.audioPlayer.playingStream,
          initialData: widget.isPlaying,
          builder: (_, snap) {
            final isPlaying = snap.data ?? widget.isPlaying;
            return Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [Colors.white, Color(0xFFF0F0F0)]),
                boxShadow: [
                  BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 25, spreadRadius: 5),
                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    widget.onPlayPause();
                  },
                  borderRadius: BorderRadius.circular(38),
                  child: Icon(isPlaying ? Icons.pause : Icons.play_arrow, size: 42, color: const Color(0xFF0a0e27)),
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 24),
        if (widget.onNext != null) _controlButton(Icons.skip_next, widget.onNext!, 34),
      ],
    );
  }

  Widget _controlButton(IconData icon, VoidCallback onTap, double size) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(27),
          child: Icon(icon, size: size, color: Colors.white),
        ),
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap, {bool isActive = false, double size = 28}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: isActive
              ? BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                )
              : null,
          child: Icon(icon, size: size, color: Colors.white),
        ),
      ),
    );
  }
}