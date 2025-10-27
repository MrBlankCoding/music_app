import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;

import '../providers/music_player_provider.dart';
import '../utils/song_data_helper.dart';
import '../widgets/player/player_content.dart';
import '../widgets/player/side_glow_indicator.dart';

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
  late Animation<double> _depthAnimation;

  static const double _dismissThreshold = 80.0;
  static const double _songSwitchThreshold = 100.0;

  String? _currentSongId;
  Color _backgroundColor = const Color(0xFF0a0e27);
  Color _accentColor = Colors.purple;

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

    _depthAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOutSine,
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
      setState(() => _dragOffset = 0);
    }
  }

  void _handleHorizontalDragEnd(
    DragEndDetails details,
    MusicPlayerProvider provider,
  ) {
    final velocity = details.primaryVelocity ?? 0;
    final shouldSwitch = _horizontalDragOffset.abs() > _songSwitchThreshold ||
        velocity.abs() > 800;

    if (shouldSwitch && !_isTransitioning) {
      setState(() => _isTransitioning = true);
      HapticFeedback.mediumImpact();

      if (_horizontalDragOffset > 0 || velocity > 0) {
        provider.playPrevious();
      } else {
        provider.playNext();
      }

      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() => _isTransitioning = false);
        }
      });
    }

    _glowController.reverse();
    setState(() => _horizontalDragOffset = 0);
  }

  Future<void> _updateBackgroundColor(Uint8List? albumArt) async {
    if (!mounted) return;
    if (albumArt != null) {
      try {
        final colors = await _extractColorsFromImage(albumArt);
        
        if (mounted && colors.isNotEmpty) {
          setState(() {
            _backgroundColor = colors[0];
            _accentColor = colors.length > 1 ? colors[1] : colors[0];
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _backgroundColor = const Color(0xFF0a0e27));
        }
      }
    } else {
      if (mounted) {
        setState(() => _backgroundColor = const Color(0xFF0a0e27));
      }
    }
  }

  Future<List<Color>> _extractColorsFromImage(Uint8List imageBytes) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return [const Color(0xFF0a0e27)];

      // Resize image for faster processing
      final resized = img.copyResize(image, width: 50, height: 50);
      
      final Map<int, int> colorCounts = {};
      
      // Sample pixels and count colors
      for (int y = 0; y < resized.height; y += 2) {
        for (int x = 0; x < resized.width; x += 2) {
          final pixel = resized.getPixel(x, y);
          final r = pixel.r.toInt();
          final g = pixel.g.toInt();
          final b = pixel.b.toInt();
          
          // Skip very dark or very light colors
          final brightness = (r + g + b) / 3;
          if (brightness < 30 || brightness > 225) continue;
          
          // Quantize colors to reduce noise
          final quantizedR = (r ~/ 32) * 32;
          final quantizedG = (g ~/ 32) * 32;
          final quantizedB = (b ~/ 32) * 32;
          
          final colorKey = (quantizedR << 16) | (quantizedG << 8) | quantizedB;
          colorCounts[colorKey] = (colorCounts[colorKey] ?? 0) + 1;
        }
      }
      
      if (colorCounts.isEmpty) return [const Color(0xFF0a0e27)];
      
      // Sort by frequency and get most dominant colors
      final sortedColors = colorCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      final dominantColors = <Color>[];
      
      for (final entry in sortedColors.take(10)) {
        final colorValue = entry.key;
        final r = (colorValue >> 16) & 0xFF;
        final g = (colorValue >> 8) & 0xFF;
        final b = colorValue & 0xFF;
        
        final color = Color.fromARGB(255, r, g, b);
        
        // Check if this color is sufficiently different from existing colors
        bool isDifferent = true;
        for (final existingColor in dominantColors) {
          if (_colorDistance(color, existingColor) < 50) {
            isDifferent = false;
            break;
          }
        }
        
        if (isDifferent) {
          dominantColors.add(color);
          if (dominantColors.length >= 2) break;
        }
      }
      
      if (dominantColors.isEmpty) {
        dominantColors.add(const Color(0xFF0a0e27));
      }
      
      // If we only have one color, create a complementary one
      if (dominantColors.length == 1) {
        final baseColor = dominantColors[0];
        final complementary = Color.fromARGB(
          255,
          255 - baseColor.red,
          255 - baseColor.green,
          255 - baseColor.blue,
        );
        dominantColors.add(complementary);
      }
      
      return dominantColors;
    } catch (e) {
      return [const Color(0xFF0a0e27)];
    }
  }
  
  double _colorDistance(Color c1, Color c2) {
    final dr = c1.red - c2.red;
    final dg = c1.green - c2.green;
    final db = c1.blue - c2.blue;
    return (dr * dr + dg * dg + db * db).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicPlayerProvider>();
    final currentSong = provider.currentSong;

    if (currentSong == null) {
      return const Scaffold(
        body: Center(
          child: Text('No song selected'),
        ),
      );
    }

    final songData = SongData(currentSong);
    if (_currentSongId != currentSong['id']) {
      _currentSongId = currentSong['id'];
      _updateBackgroundColor(songData.albumArt);
    }

    return Scaffold(
      body: StreamBuilder<SequenceState?>(
        stream: provider.sequenceStateStream,
        builder: (context, snapshot) {
          final mediaItem = snapshot.data?.currentSource?.tag as MediaItem?;

          return GestureDetector(
            onVerticalDragUpdate: (details) {
              setState(() {
                _dragOffset = (_dragOffset + details.primaryDelta!).clamp(
                  0.0,
                  double.infinity,
                );
              });
            },
            onVerticalDragEnd: (_) => _handleDragEnd(),
            onHorizontalDragUpdate: (details) {
              if (!_isTransitioning) {
                setState(() {
                  _horizontalDragOffset += details.primaryDelta!;
                  _horizontalDragOffset = _horizontalDragOffset.clamp(
                    -200.0,
                    200.0,
                  );
                });

                if (_horizontalDragOffset.abs() > 20 &&
                    _glowController.status != AnimationStatus.forward) {
                  _glowController.forward();
                }
              }
            },
            onHorizontalDragEnd: (details) =>
                _handleHorizontalDragEnd(details, provider),
            child: Stack(
              children: [
                // Vibrant gradient background with blur
                AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topCenter,
                      radius: 1.5,
                      colors: [
                        _backgroundColor,
                        _accentColor.withValues(alpha: 0.8),
                        Colors.black.withValues(alpha: 0.9),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),

                // Main content with drag transforms
                Transform.translate(
                  offset: Offset(0, _dragOffset),
                  child: Transform.scale(
                    scale: _dragOffset > 0
                        ? (1.0 - (_dragOffset / 1000).clamp(0.0, 0.05))
                        : 1.0,
                    child: Opacity(
                      opacity: _dragOffset > 0
                          ? (1.0 - (_dragOffset / 200).clamp(0.0, 0.3))
                          : 1.0,
                      child: PlayerContent(
                        provider: provider,
                        songData: songData,
                        mediaItem: mediaItem,
                        pulseController: _pulseController,
                        depthAnimation: _depthAnimation,
                      ),
                    ),
                  ),
                ),

                // Side glow indicators for swipe feedback
                if (_horizontalDragOffset.abs() > 20)
                  SideGlowIndicator(
                    isLeft: _horizontalDragOffset > 0,
                    intensity: (_horizontalDragOffset.abs() / 200).clamp(0.0, 1.0),
                    glowAnimation: _glowAnimation,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}