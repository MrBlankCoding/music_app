import 'dart:typed_data';
import 'package:flutter/material.dart';

class AlbumArt extends StatelessWidget {
  final Uint8List? albumArt;
  final String heroId;
  final bool isPlaying;
  final AnimationController pulseController;
  final Animation<double> depthAnimation;

  const AlbumArt({
    super.key,
    required this.albumArt,
    required this.heroId,
    required this.isPlaying,
    required this.pulseController,
    required this.depthAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width * 0.68;

    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, _) {
        final scale = isPlaying ? 1 + (pulseController.value * 0.02) : 1.0;

        return Transform.scale(
          scale: scale,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                // Soft ambient shadow
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // Album image
                  albumArt != null
                      ? Image.memory(
                          albumArt!,
                          fit: BoxFit.cover,
                          width: size,
                          height: size,
                          errorBuilder: (_, __, ___) =>
                              const AlbumPlaceholder(icon: Icons.broken_image),
                        )
                      : const AlbumPlaceholder(icon: Icons.music_note),
                  
                  // Liquid glass overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.08),
                          Colors.transparent,
                          Colors.black.withOpacity(0.05),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.12),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  
                  // Subtle highlight
                  Positioned(
                    top: 12,
                    left: 12,
                    right: size * 0.5,
                    bottom: size * 0.7,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withOpacity(0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class AlbumPlaceholder extends StatelessWidget {
  final IconData icon;

  const AlbumPlaceholder({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2A2A3A),
            Color(0xFF1A1A2E),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 64,
          color: Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }
}