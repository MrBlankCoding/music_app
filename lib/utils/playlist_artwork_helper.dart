import 'dart:typed_data';
import '../models/playlist.dart';
import 'song_data_helper.dart';

class PlaylistArtworkHelper {
  /// Get album arts from songs in the playlist
  /// Returns up to 4 unique album arts for grid display
  static List<Uint8List> getAlbumArts(
    Playlist playlist,
    List<Map<String, dynamic>> allSongs,
  ) {
    final List<Uint8List> albumArts = [];
    final Set<String> seenPaths = {};

    // Get songs in the playlist
    for (final songData in playlist.songs) {
      if (albumArts.length >= 4) break;

      final songPath = songData['path'] as String?;
      if (songPath == null) continue;

      // Find the matching song in allSongs
      final matchingSong = allSongs.firstWhere(
        (song) => song['path'] == songPath,
        orElse: () => <String, dynamic>{},
      );

      // Skip if song is empty (path is missing)
      if (matchingSong.isEmpty || matchingSong['path'] == null) continue;

      // Use SongData helper to get album art as Uint8List
      final albumArt = SongData(matchingSong).albumArt;

      // Only add if it exists and we haven't seen it before
      if (albumArt != null && !seenPaths.contains(songPath)) {
        albumArts.add(albumArt);
        seenPaths.add(songPath);
      }
    }

    return albumArts;
  }
}
