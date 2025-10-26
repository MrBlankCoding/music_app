import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../providers/library_provider.dart';
import '../providers/music_player_provider.dart';
import '../providers/playlist_provider.dart';
import '../utils/song_data_helper.dart';

class SongManagementService {
  final BuildContext context;

  SongManagementService(this.context);

  MusicPlayerProvider get _musicPlayerProvider =>
      context.read<MusicPlayerProvider>();
  LibraryProvider get _libraryProvider => context.read<LibraryProvider>();
  PlaylistProvider get _playlistProvider => context.read<PlaylistProvider>();

  Future<void> deleteSong(String songPath) async {
    if (_musicPlayerProvider.currentSong?['path'] == songPath) {
      await _musicPlayerProvider.stop();
    }
    await _libraryProvider.deleteSong(songPath);
    await _playlistProvider.removeSongFromAllPlaylists(songPath);
    await _libraryProvider.loadSongs();
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Song deleted from library'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  List<Map<String, dynamic>> getReconciledPlaylistSongs(Playlist playlist) {
    final List<Map<String, dynamic>> reconciledSongs = [];

    for (final song in playlist.songs) {
      final storedPath = song['path'] as String?;
      if (storedPath == null) continue;

      final filename = storedPath.split('/').last;

      final librarySong = _libraryProvider.songs.firstWhere(
        (s) => (s['path'] as String).split('/').last == filename,
        orElse: () => <String, dynamic>{},
      );

      Map<String, dynamic> songCopy;

      if (librarySong.isNotEmpty) {
        songCopy = Map<String, dynamic>.from(librarySong);
      } else {
        final songData = SongData(song);
        songCopy = <String, dynamic>{
          'path': storedPath,
          'name': songData.title,
          'artist': songData.artist,
          'size': song['size'] ?? 0,
          'albumArt': songData.albumArt,
          'title': songData.title,
          'video_id': song['video_id'],
          'duration': song['duration'] ?? 0,
        };

        if (song['modified'] is String) {
          try {
            songCopy['modified'] = DateTime.parse(song['modified'] as String);
          } catch (e) {
            songCopy['modified'] = DateTime.now();
          }
        } else if (song['modified'] is DateTime) {
          songCopy['modified'] = song['modified'];
        } else {
          songCopy['modified'] = DateTime.now();
        }
      }

      reconciledSongs.add(songCopy);
    }

    return reconciledSongs;
  }
}