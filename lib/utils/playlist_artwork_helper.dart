import '../models/playlist.dart';
import 'song_data_helper.dart';

class PlaylistArtworkHelper {
  const PlaylistArtworkHelper._();

  static List<String> getThumbnails(
    Playlist playlist,
    List<Map<String, dynamic>> librarySongs,
  ) {
    final thumbnails = <String>[];

    for (final song in playlist.songs) {
      if (thumbnails.length >= 4) break;

      final storedPath = song['path'] as String?;
      Map<String, dynamic>? librarySong;

      if (storedPath != null) {
        final filename = storedPath.split('/').last;
        librarySong = librarySongs.firstWhere(
          (s) {
            final libraryPath = s['path'] as String?;
            if (libraryPath == null) return false;
            return libraryPath.split('/').last == filename;
          },
          orElse: () => <String, dynamic>{},
        );
        if (librarySong.isEmpty) {
          librarySong = null;
        }
      }

      final librarySongData = librarySong != null ? SongData(librarySong) : null;
      final playlistSongData = SongData(song);

      final thumbnailUrl =
          librarySongData?.thumbnailUrl ?? playlistSongData.thumbnailUrl;

      if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
        print('Found thumbnail: $thumbnailUrl');
        thumbnails.add(thumbnailUrl);
      }
    }

    return thumbnails;
  }
}
