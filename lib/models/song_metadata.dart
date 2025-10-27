import 'dart:convert';
import 'dart:typed_data';

/// A model class representing song metadata including title, artist, album, and other information.
class SongMetadata {
  /// The title of the song
  final String title;

  /// The artist or artists performing the song
  final String artist;

  /// The album this song belongs to
  final String album;

  /// The duration of the song in milliseconds
  final int? duration;

  /// Album art as raw bytes
  final Uint8List? albumArt;

  /// The local file path to the song
  final String localPath;

  /// The genre of the song
  final String? genre;

  /// The year the song was released
  final int? year;

  /// Video ID if downloaded from YouTube
  final String? videoId;

  /// Unique identifier for the song (typically the path or video ID)
  final String id;

  /// The name/title - same as title, for backward compatibility
  final String name;

  SongMetadata({
    required this.title,
    required this.artist,
    required this.album,
    this.duration,
    this.albumArt,
    required this.localPath,
    this.genre,
    this.year,
    this.videoId,
    String? id,
  })  : id = id ?? localPath,
        name = title;

  /// Creates a SongMetadata instance from a Map (for compatibility with existing code)
  factory SongMetadata.fromMap(Map<String, dynamic> map) {
    // Provide safe fallbacks for all required fields
    final path = map['path'];
    
    return SongMetadata(
      title: map['title'] as String? ??
          map['name'] as String? ??
          'Unknown Title',
      artist: map['artist'] as String? ?? 'Unknown Artist',
      album: map['album'] as String? ?? 'Unknown Album',
      duration: map['duration'] as int?,
      albumArt: _parseAlbumArt(map['albumArt'] ?? map['album_art']),
      localPath: path is String ? path : '',
      genre: map['genre'] as String?,
      year: map['year'] as int?,
      videoId: map['video_id']?.toString(),
      id: map['id']?.toString(),
    );
  }

  /// Converts SongMetadata to a Map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'name': name,
      'artist': artist,
      'album': album,
      'duration': duration,
      'albumArt': albumArt != null ? base64Encode(albumArt!) : null,
      'album_art': albumArt != null ? base64Encode(albumArt!) : null,
      'path': localPath,
      'genre': genre,
      'year': year,
      'video_id': videoId,
      'id': id,
    };
  }

  /// Parses album art from various formats
  static Uint8List? _parseAlbumArt(dynamic value) {
    if (value == null) return null;

    if (value is Uint8List) return value;
    if (value is List<int>) return Uint8List.fromList(value);

    if (value is String) {
      try {
        if (value.startsWith('data:')) {
          final comma = value.indexOf(',');
          if (comma != -1 && comma + 1 < value.length) {
            return base64Decode(value.substring(comma + 1));
          }
        }
        return base64Decode(value);
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  SongMetadata copyWith({
    String? title,
    String? artist,
    String? album,
    int? duration,
    Uint8List? albumArt,
    String? localPath,
    String? genre,
    int? year,
    String? videoId,
    String? id,
  }) {
    return SongMetadata(
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      albumArt: albumArt ?? this.albumArt,
      localPath: localPath ?? this.localPath,
      genre: genre ?? this.genre,
      year: year ?? this.year,
      videoId: videoId ?? this.videoId,
      id: id ?? this.id,
    );
  }
}

