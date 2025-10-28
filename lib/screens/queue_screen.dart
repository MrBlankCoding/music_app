import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import '../providers/music_player_provider.dart';
import '../widgets/song_card.dart';

class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final musicPlayerProvider = context.watch<MusicPlayerProvider>();
    final queue = musicPlayerProvider.audioPlayer.sequence ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Up Next'),
      ),
      body: queue.isEmpty
          ? const Center(
              child: Text('The queue is empty.'),
            )
          : ReorderableListView.builder(
              itemCount: queue.length,
              itemBuilder: (context, index) {
                final mediaItem = queue[index].tag;
                final song = mediaItem.extras as Map<String, dynamic>;

                return SongCard(
                  key: ValueKey(song['path']),
                  song: song,
                  heroTagPrefix: 'queue',
                  isPlaying: musicPlayerProvider.currentSong?['path'] == song['path'] &&
                      musicPlayerProvider.isPlaying,
                  onTap: () {
                    musicPlayerProvider.audioPlayer.seek(Duration.zero, index: index);
                  },
                  onPlay: () {
                    musicPlayerProvider.audioPlayer.seek(Duration.zero, index: index);
                  },
                );
              },
              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                final playlist = musicPlayerProvider.audioPlayer.audioSource as ConcatenatingAudioSource;
                playlist.move(oldIndex, newIndex);
              },
            ),
    );
  }
}
