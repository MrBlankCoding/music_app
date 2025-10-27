import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'dart:ui';
import '../providers/music_player_provider.dart';
import '../utils/song_data_helper.dart';
import 'queue_screen.dart';

class FullPlayerScreen extends StatefulWidget {
  const FullPlayerScreen({super.key});

  @override
  State<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends State<FullPlayerScreen>
    with TickerProviderStateMixin {
  double _dragOffset = 0.0;
  double _horizontalDragOffset = 0.0;
  bool _isTransitioning = false;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  static const double _dismissThreshold = 80.0;
  static const double _songSwitchThreshold = 100.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _handleDragEnd() {
    if (_dragOffset > _dismissThreshold) {
      HapticFeedback.mediumImpact();
      Navigator.pop(context);
    } else {
      // Animate back to original position
      setState(() => _dragOffset = 0);
    }
  }
  
  void _handleHorizontalDragEnd(DragEndDetails details, MusicPlayerProvider provider) {
    final velocity = details.primaryVelocity ?? 0;
    final shouldSwitch = _horizontalDragOffset.abs() > _songSwitchThreshold || velocity.abs() > 800;
    
    if (shouldSwitch && !_isTransitioning) {
      setState(() => _isTransitioning = true);
      HapticFeedback.mediumImpact();
      
      // Robust navigation with fallbacks
      if (_horizontalDragOffset > 0 || velocity > 0) {
        _navigateToPrevious(provider);
      } else {
        _navigateToNext(provider);
      }
      
      // Reset after a short delay
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() => _isTransitioning = false);
        }
      });
    }
    
    _glowController.reverse();
    setState(() {
      _horizontalDragOffset = 0;
    });
  }
  
  void _navigateToNext(MusicPlayerProvider provider) {
    // Use just_audio's built-in navigation which handles queue boundaries
    provider.playNext();
  }
  
  void _navigateToPrevious(MusicPlayerProvider provider) {
    // Use just_audio's built-in navigation which handles queue boundaries
    provider.playPrevious();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicPlayerProvider>();
    final currentSong = provider.currentSong;

    if (currentSong == null) {
      return const Scaffold(
        body: Center(child: Text('No song selected')),
      );
    }

    return Scaffold(
      body: StreamBuilder<SequenceState?>(
        stream: provider.sequenceStateStream,
        builder: (context, snapshot) {
          final mediaItem = snapshot.data?.currentSource?.tag as MediaItem?;
          final songData = SongData(currentSong);
          
          return GestureDetector(
            onVerticalDragUpdate: (details) {
              setState(() {
                _dragOffset = (_dragOffset + details.primaryDelta!).clamp(0.0, double.infinity);
              });
            },
            onVerticalDragEnd: (_) => _handleDragEnd(),
            onHorizontalDragUpdate: (details) {
              if (!_isTransitioning) {
                setState(() {
                  _horizontalDragOffset += details.primaryDelta!;
                  _horizontalDragOffset = _horizontalDragOffset.clamp(-200.0, 200.0);
                });
                
                // Trigger glow animation when dragging
                if (_horizontalDragOffset.abs() > 20 && _glowController.status != AnimationStatus.forward) {
                  _glowController.forward();
                }
              }
            },
            onHorizontalDragEnd: (details) => _handleHorizontalDragEnd(details, provider),
            child: Stack(
              children: [
                _BlurredBackground(
                  albumArt: songData.albumArt,
                  pulseController: _pulseController,
                ),
                Stack(
                  children: [
                    // Main player content
                    Transform(
                      transform: Matrix4.identity()
                        ..translate(0.0, _dragOffset)
                        ..scale(_dragOffset > 0 ? (1.0 - (_dragOffset / 1000).clamp(0.0, 0.05)) : 1.0),
                      child: Opacity(
                        opacity: _dragOffset > 0 ? (1.0 - (_dragOffset / 200).clamp(0.0, 0.3)) : 1.0,
                        child: _PlayerContent(
                          provider: provider,
                          songData: songData,
                          mediaItem: mediaItem,
                          pulseController: _pulseController,
                        ),
                      ),
                    ),
                    // Side glow indicators
                    if (_horizontalDragOffset.abs() > 20)
                      _SideGlowIndicator(
                        isLeft: _horizontalDragOffset > 0,
                        intensity: (_horizontalDragOffset.abs() / 200).clamp(0.0, 1.0),
                        glowAnimation: _glowAnimation,
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BlurredBackground extends StatelessWidget {
  final Uint8List? albumArt;
  final AnimationController pulseController;

  const _BlurredBackground({
    required this.albumArt,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, _) {
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: const [
                    Color(0xFF0a0e27),
                    Color(0xFF1a1f3a),
                    Color(0xFF2d1b4e),
                  ],
                  stops: [0.0, 0.5 + pulseController.value * 0.1, 1.0],
                ),
              ),
            ),
            if (albumArt != null) ...[
              Positioned.fill(
                child: Image.memory(
                  albumArt!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.2,
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          Colors.black.withValues(alpha: 0.8),
                          Colors.black.withValues(alpha: 0.95),
                        ],
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
}

class _PlayerContent extends StatelessWidget {
  final MusicPlayerProvider provider;
  final SongData songData;
  final MediaItem? mediaItem;
  final AnimationController pulseController;

  const _PlayerContent({
    required this.provider,
    required this.songData,
    required this.mediaItem,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.1),
            Colors.black.withValues(alpha: 0.5),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _PlayerHeader(onOptionsPressed: () => _showOptions(context, provider)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),
                    _AlbumArt(
                      albumArt: songData.albumArt,
                      heroId: mediaItem?.id ?? songData.id,
                      isPlaying: provider.isPlaying,
                      pulseController: pulseController,
                    ),
                    const SizedBox(height: 36),
                    _SongInfo(
                      title: mediaItem?.title ?? songData.title,
                      artist: mediaItem?.artist ?? songData.artist,
                    ),
                    const SizedBox(height: 48),
                    _ProgressSection(provider: provider),
                    const SizedBox(height: 28),
                    _PlaybackControls(provider: provider),
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

  void _showOptions(BuildContext context, MusicPlayerProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F1F1F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.queue_music, color: Colors.white),
              title: const Text('Queue', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QueueScreen()),
                );
              },
            ),
            _ToggleOption(
              icon: Icons.repeat_one,
              title: 'Repeat',
              stream: provider.isLoopEnabledStream,
              onToggle: provider.toggleLoop,
            ),
            _ToggleOption(
              icon: Icons.shuffle,
              title: 'Shuffle',
              stream: provider.isShuffleEnabledStream,
              onToggle: provider.toggleShuffle,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _PlayerHeader extends StatelessWidget {
  final VoidCallback onOptionsPressed;

  const _PlayerHeader({required this.onOptionsPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 5,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _IconButton(
                icon: Icons.keyboard_arrow_down,
                onPressed: () => Navigator.pop(context),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: const Text(
                  'Now Playing',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              _IconButton(
                icon: Icons.more_horiz,
                onPressed: onOptionsPressed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AlbumArt extends StatelessWidget {
  final Uint8List? albumArt;
  final String heroId;
  final bool isPlaying;
  final AnimationController pulseController;

  const _AlbumArt({
    required this.albumArt,
    required this.heroId,
    required this.isPlaying,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width * 0.68;
    
    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, _) {
        final scale = isPlaying ? 1 + (pulseController.value * 0.02) : 1.0;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  if (isPlaying)
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.1),
                      blurRadius: 40,
                      spreadRadius: 5,
                    ),
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                    blurRadius: 50,
                    spreadRadius: 8,
                    offset: const Offset(0, 20),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 40,
                    offset: const Offset(0, 25),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: albumArt != null
                    ? Image.memory(
                        albumArt!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => 
                            _AlbumPlaceholder(icon: Icons.broken_image),
                      )
                    : _AlbumPlaceholder(icon: Icons.music_note),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AlbumPlaceholder extends StatelessWidget {
  final IconData icon;

  const _AlbumPlaceholder({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.secondaryContainer,
          ],
        ),
      ),
      child: Icon(
        icon,
        size: 80,
        color: Colors.white.withValues(alpha: 0.5),
      ),
    );
  }
}

class _SongInfo extends StatelessWidget {
  final String title;
  final String artist;

  const _SongInfo({required this.title, required this.artist});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.2,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          artist,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.75),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ProgressSection extends StatelessWidget {
  final MusicPlayerProvider provider;

  const _ProgressSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration?>(
      stream: provider.durationStream,
      builder: (context, durationSnapshot) {
        final duration = durationSnapshot.data ?? Duration.zero;

        return StreamBuilder<Duration>(
          stream: provider.positionStream,
          builder: (context, positionSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ProgressBar(
                progress: position,
                total: duration,
                buffered: duration,
                onSeek: (newPosition) {
                  provider.seek(newPosition);
                  HapticFeedback.lightImpact();
                },
                barHeight: 4.0,
                baseBarColor: Colors.white.withValues(alpha: 0.25),
                progressBarColor: Colors.white,
                bufferedBarColor: Colors.white.withValues(alpha: 0.35),
                thumbColor: Colors.white,
                thumbGlowColor: Colors.white.withValues(alpha: 0.2),
                thumbRadius: 8.0,
                thumbGlowRadius: 18.0,
                timeLabelTextStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                timeLabelPadding: 8.0,
              ),
            );
          },
        );
      },
    );
  }
}

class _PlaybackControls extends StatelessWidget {
  final MusicPlayerProvider provider;

  const _PlaybackControls({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ControlButton(
          icon: Icons.skip_previous,
          onPressed: provider.playPrevious,
        ),
        const SizedBox(width: 28),
        StreamBuilder<bool>(
          stream: provider.playingStream,
          initialData: provider.isPlaying,
          builder: (context, snapshot) {
            final isPlaying = snapshot.data ?? false;
            return _PlayPauseButton(
              isPlaying: isPlaying,
              onPressed: provider.playPause,
            );
          },
        ),
        const SizedBox(width: 28),
        _ControlButton(
          icon: Icons.skip_next,
          onPressed: provider.playNext,
        ),
      ],
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPressed;

  const _PlayPauseButton({
    required this.isPlaying,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFF5F5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.4),
            blurRadius: 30,
            spreadRadius: 8,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            onPressed();
          },
          borderRadius: BorderRadius.circular(36),
          child: Icon(
            isPlaying ? Icons.pause : Icons.play_arrow,
            size: 40,
            color: const Color(0xFF0a0e27),
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _ControlButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.15),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onPressed();
          },
          borderRadius: BorderRadius.circular(27),
          child: Icon(icon, size: 32, color: Colors.white),
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _IconButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 28, color: Colors.white),
        ),
      ),
    );
  }
}

class _SideGlowIndicator extends StatelessWidget {
  final bool isLeft;
  final double intensity;
  final Animation<double> glowAnimation;

  const _SideGlowIndicator({
    required this.isLeft,
    required this.intensity,
    required this.glowAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: isLeft ? 0 : null,
      right: isLeft ? null : 0,
      top: 0,
      bottom: 0,
      width: 120,
      child: AnimatedBuilder(
        animation: glowAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: isLeft ? Alignment.centerLeft : Alignment.centerRight,
                end: isLeft ? Alignment.centerRight : Alignment.centerLeft,
                colors: [
                  Colors.white.withValues(alpha: intensity * glowAnimation.value * 0.3),
                  Colors.transparent,
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isLeft ? Icons.skip_previous : Icons.skip_next,
                    color: Colors.white.withValues(alpha: intensity * glowAnimation.value),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isLeft ? 'Previous' : 'Next',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: intensity * glowAnimation.value),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final Stream<bool> stream;
  final VoidCallback onToggle;

  const _ToggleOption({
    required this.icon,
    required this.title,
    required this.stream,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: stream,
      initialData: false,
      builder: (context, snapshot) {
        final isEnabled = snapshot.data ?? false;
        final color = isEnabled ? Colors.deepOrange : Colors.white;

        return ListTile(
          leading: Icon(icon, color: color),
          title: Text(title, style: TextStyle(color: color)),
          trailing: Switch(
            value: isEnabled,
            onChanged: (_) => onToggle(),
            activeThumbColor: Colors.deepOrange,
          ),
          onTap: onToggle,
        );
      },
    );
  }
}