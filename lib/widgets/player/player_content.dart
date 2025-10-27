import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../../providers/music_player_provider.dart';
import '../../utils/song_data_helper.dart';
import '../../screens/queue_screen.dart';
import './album_art.dart';
import './player_header.dart';
import './progress_section.dart';
import './playback_controls.dart';
import './song_info.dart';
import './toggle_option.dart';

class PlayerContent extends StatelessWidget {
  final MusicPlayerProvider provider;
  final SongData songData;
  final MediaItem? mediaItem;
  final AnimationController pulseController;
  final Animation<double> depthAnimation;

  const PlayerContent({
    super.key,
    required this.provider,
    required this.songData,
    required this.mediaItem,
    required this.pulseController,
    required this.depthAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.05),
            Colors.black.withOpacity(0.15),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            PlayerHeader(onOptionsPressed: () => _showOptions(context, provider)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),
                    AlbumArt(
                      albumArt: songData.albumArt,
                      heroId: mediaItem?.id ?? songData.id,
                      isPlaying: provider.isPlaying,
                      pulseController: pulseController,
                      depthAnimation: depthAnimation,
                    ),
                    const SizedBox(height: 36),
                    SongInfo(
                      title: mediaItem?.title ?? songData.title,
                      artist: mediaItem?.artist ?? songData.artist,
                    ),
                    const SizedBox(height: 48),
                    ProgressSection(
                      provider: provider,
                      depthAnimation: depthAnimation,
                    ),
                    const SizedBox(height: 28),
                    PlaybackControls(
                      provider: provider,
                      depthAnimation: depthAnimation,
                    ),
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
                color: Colors.white.withOpacity(0.3),
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
            ToggleOption(
              icon: Icons.repeat_one,
              title: 'Repeat',
              stream: provider.isLoopEnabledStream,
              onToggle: provider.toggleLoop,
            ),
            ToggleOption(
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
