import 'dart:typed_data';
import '../models/song_metadata.dart';

/// Compatibility wrapper around Map to provide SongMetadata-like interface
/// 
/// This class is maintained for backward compatibility.
/// New code should use SongMetadata directly.
class SongData {
  final SongMetadata _metadata;

  SongData(Map<String, dynamic> songData) : _metadata = SongMetadata.fromMap(songData);

  /// Returns album art as Uint8List, or null if unavailable
  Uint8List? get albumArt => _metadata.albumArt;

  String get title => _metadata.title;
  String get artist => _metadata.artist;
  String get album => _metadata.album;
  String get genre => _metadata.genre ?? 'Unknown Genre';
  int? get duration => _metadata.duration;
  int? get year => _metadata.year;
  String get path => _metadata.localPath;
  String get videoId => _metadata.videoId ?? '';
  String get id => _metadata.id;
  String get name => _metadata.name;
}
