import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import '../models/song_metadata.dart';

/// Utility class for extracting and working with song metadata
class SongUtils {
  /// Default values for missing metadata
  static const String unknownArtist = 'Unknown Artist';
  static const String unknownAlbum = 'Unknown Album';
  static const String unknownTitle = 'Unknown Title';
  static const String unknownGenre = 'Unknown Genre';

  /// Extracts metadata from a local audio file
  ///
  /// Returns a [SongMetadata] object containing all available metadata.
  /// Handles missing metadata gracefully with fallback values.
  static Future<SongMetadata> extractMetadata(String filePath) async {
    final file = File(filePath);

    if (!await file.exists()) {
      // Return metadata with just the file path if file doesn't exist
      return _createMetadataFromFilename(
        filePath: filePath,
        title: null,
        artist: null,
        album: null,
      );
    }

    try {
      // Try to extract metadata using flutter_media_metadata
      final metadata = await MetadataRetriever.fromFile(file);

      final title = metadata.trackName ?? _extractTitleFromPath(filePath);
      final artist =
          metadata.trackArtistNames?.join(', ') ?? unknownArtist;
      final album = metadata.albumName ?? unknownAlbum;
      final duration = metadata.trackDuration;
      final genre = metadata.genre;
      final year = metadata.year;

      // Extract album art
      Uint8List? albumArt;
      if (metadata.albumArt != null) {
        albumArt = metadata.albumArt!;
      }

      return SongMetadata(
        title: title,
        artist: artist,
        album: album,
        duration: duration,
        albumArt: albumArt,
        localPath: filePath,
        genre: genre,
        year: year,
      );
    } catch (e) {
      // If metadata extraction fails, create metadata from filename
      // debugPrint('Failed to extract metadata from file: $e');
      return _createMetadataFromFilename(
        filePath: filePath,
        title: null,
        artist: null,
        album: null,
      );
    }
  }

  /// Creates metadata from a file path and optional data
  static SongMetadata _createMetadataFromFilename({
    required String filePath,
    String? title,
    String? artist,
    String? album,
  }) {
    final filename = _getFilename(filePath);
    final filenameWithoutExt = _removeExtension(filename);

    final finalTitle = title ?? filenameWithoutExt;
    final finalArtist = artist ?? unknownArtist;
    final finalAlbum = album ?? unknownAlbum;

    return SongMetadata(
      title: finalTitle.isEmpty ? unknownTitle : finalTitle,
      artist: finalArtist,
      album: finalAlbum,
      localPath: filePath,
    );
  }

  /// Extracts title from file path
  static String _extractTitleFromPath(String path) {
    final filename = _getFilename(path);
    final title = _removeExtension(filename);
    return title.isEmpty ? unknownTitle : title;
  }

  /// Gets filename from path
  static String _getFilename(String path) {
    return path.split('/').last;
  }

  /// Removes file extension from filename
  static String _removeExtension(String filename) {
    final dotIndex = filename.lastIndexOf('.');
    if (dotIndex == -1) return filename;
    return filename.substring(0, dotIndex);
  }

  /// Formats duration in milliseconds to mm:ss format
  ///
  /// Example: formatDuration(125000) returns "2:05"
  static String formatDuration(int? milliseconds) {
    if (milliseconds == null || milliseconds <= 0) {
      return '0:00';
    }

    final totalSeconds = milliseconds ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Formats duration in seconds to mm:ss format
  ///
  /// Example: formatDurationSeconds(125) returns "2:05"
  static String formatDurationSeconds(int? totalSeconds) {
    if (totalSeconds == null || totalSeconds < 0) {
      return '0:00';
    }

    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Converts a song metadata to a Map for storage
  static Map<String, dynamic> toStorageMap(SongMetadata metadata) {
    return {
      'title': metadata.title,
      'name': metadata.name,
      'artist': metadata.artist,
      'album': metadata.album,
      'duration': metadata.duration,
      'albumArt': metadata.albumArt != null
          ? base64Encode(metadata.albumArt!)
          : null,
      'album_art': metadata.albumArt != null
          ? base64Encode(metadata.albumArt!)
          : null,
      'path': metadata.localPath,
      'genre': metadata.genre,
      'year': metadata.year,
      'video_id': metadata.videoId,
      'id': metadata.id,
    };
  }

  /// Gets album art as bytes from various input formats
  static Uint8List? getAlbumArtBytes(dynamic albumArt) {
    if (albumArt == null) return null;

    if (albumArt is Uint8List) return albumArt;
    if (albumArt is List<int>) return Uint8List.fromList(albumArt);
    if (albumArt is String) {
      try {
        if (albumArt.startsWith('data:')) {
          final comma = albumArt.indexOf(',');
          if (comma != -1 && comma + 1 < albumArt.length) {
            return base64Decode(albumArt.substring(comma + 1));
          }
        }
        return base64Decode(albumArt);
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  /// Validates if song metadata is valid (not completely empty)
  static bool isValidMetadata(SongMetadata metadata) {
    return metadata.title.isNotEmpty &&
        metadata.title != unknownTitle &&
        metadata.artist.isNotEmpty &&
        metadata.artist != unknownArtist;
  }

  /// Gets a safe filename by sanitizing special characters
  static String sanitizeFilename(String filename) {
    return filename
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
  }
}

