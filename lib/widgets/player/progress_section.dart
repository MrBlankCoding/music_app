import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import '../../providers/music_player_provider.dart';

class ProgressSection extends StatelessWidget {
  final MusicPlayerProvider provider;
  final Animation<double> depthAnimation;

  const ProgressSection({
    super.key,
    required this.provider,
    required this.depthAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: depthAnimation,
      builder: (context, child) {
        final depth = depthAnimation.value;
        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..translate(0.0, 0.0, 3 + (depth * 10)),
          child: StreamBuilder<Duration?>(
            stream: provider.durationStream,
            builder: (context, durationSnapshot) {
              final duration = durationSnapshot.data ?? Duration.zero;

              return StreamBuilder<Duration>(
                stream: provider.positionStream,
                builder: (context, positionSnapshot) {
                  final position = positionSnapshot.data ?? Duration.zero;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2 + (depth * 0.1)),
                          blurRadius: 15 + (depth * 10),
                          offset: Offset(0, 4 + (depth * 3)),
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.05 + (depth * 0.03)),
                          blurRadius: 10 + (depth * 5),
                          offset: Offset(0, -2 - (depth * 1)),
                        ),
                      ],
                    ),
                    child: ProgressBar(
                      progress: position,
                      total: duration,
                      buffered: duration,
                      onSeek: (newPosition) {
                        provider.seek(newPosition);
                        HapticFeedback.lightImpact();
                      },
                      barHeight: 5.0 + (depth * 2),
                      baseBarColor: Colors.white.withOpacity(0.2 + (depth * 0.05)),
                      progressBarColor: Colors.white.withOpacity(0.9 + (depth * 0.1)),
                      bufferedBarColor: Colors.white.withOpacity(0.3 + (depth * 0.1)),
                      thumbColor: Colors.white,
                      thumbGlowColor: Colors.white.withOpacity(0.3 + (depth * 0.2)),
                      thumbRadius: 9.0 + (depth * 2),
                      thumbGlowRadius: 20.0 + (depth * 8),
                      timeLabelTextStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.7 + (depth * 0.2)),
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3 + (depth * 0.2)),
                            blurRadius: 4 + (depth * 2),
                            offset: Offset(0, 1 + (depth * 0.5)),
                          ),
                        ],
                      ),
                      timeLabelPadding: 8.0,
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
