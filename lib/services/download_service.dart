import 'dart:collection';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/youtube_video.dart';
import 'dart:developer' as developer;
import 'package:oktoast/oktoast.dart';
import '../providers/library_provider.dart';
import '../utils/metadata_utils.dart';

class DownloadService with ChangeNotifier {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  LibraryProvider? _libraryProvider;
  bool isQueueScreenVisible = false;

  void setLibraryProvider(LibraryProvider libraryProvider) {
    _libraryProvider = libraryProvider;
  }

  String? _downloadDirectory;
  final String _serverUrl = 'http://127.0.0.1:8000';
  final Queue<YouTubeVideo> _downloadQueue = Queue<YouTubeVideo>();
  bool _isDownloading = false;

  Queue<YouTubeVideo> get downloadQueue => _downloadQueue;
  bool get isDownloading => _isDownloading;
  String? get currentlyDownloadingVideoId =>
      _isDownloading && _downloadQueue.isNotEmpty
          ? _downloadQueue.first.videoId
          : null;

  Future<void> initialize() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    _downloadDirectory = '${appDocDir.path}/MusicDownloads';
    await Directory(_downloadDirectory!).create(recursive: true);
  }

  void addToQueue(YouTubeVideo video) {
    if (_downloadQueue.any((v) => v.videoId == video.videoId)) {
      return;
    }
    _downloadQueue.add(video);
    notifyListeners();
    _processQueue();
  }

  Future<void> _processQueue() async {
    if (_isDownloading || _downloadQueue.isEmpty) return;

    _isDownloading = true;
    final video = _downloadQueue.first;

    try {
      // Changed to GET request with video_id in the path
      final response = await http.get(
        Uri.parse('$_serverUrl/download/${video.videoId}'),
      );

      if (response.statusCode == 200) {
        _downloadQueue.removeFirst();

        if (!isQueueScreenVisible) {
          showToast(
            "✓ Downloaded: ${video.title}",
            position: const ToastPosition(
              align: Alignment.bottomCenter,
              offset: -72.0,
            ),
            duration: const Duration(seconds: 3),
          );
        }

        _libraryProvider?.loadSongs();
      } else {
        throw Exception('Failed to download: ${response.body}');
      }
    } catch (e, s) {
      developer.log(
        'Download failed for ${video.title}',
        name: 'DownloadService',
        error: e,
        stackTrace: s,
      );
      _downloadQueue.removeFirst();

      if (!isQueueScreenVisible) {
        showToast(
          "✗ Download failed: ${video.title}",
          position: const ToastPosition(
            align: Alignment.bottomCenter,
            offset: -72.0,
          ),
          duration: const Duration(seconds: 3),
        );
      }
    } finally {
      _isDownloading = false;
      notifyListeners();
      _processQueue();
    }
  }

  Future<List<Map<String, dynamic>>> getDownloadedSongs() async {
    if (_downloadDirectory == null) await initialize();

    final dir = Directory(_downloadDirectory!);
    if (!await dir.exists()) return [];

    final files = await dir
        .list()
        .where((e) => e is File && e.path.endsWith('.mp3'))
        .cast<File>()
        .toList();

    final songs = await Future.wait(
      files.map((file) async {
        final stat = await file.stat();
        final baseName = file.path.replaceAll('.mp3', '');
        final metadataPath = '$baseName.json';

        // Load metadata if exists
        Map<String, dynamic>? metadata;
        try {
          final metadataFile = File(metadataPath);
          if (await metadataFile.exists()) {
            final metadataContent = await metadataFile.readAsString();
            metadata = json.decode(metadataContent);
          }
        } catch (e) {
          developer.log(
            'Error loading metadata for ${file.path}: $e',
            name: 'DownloadService',
          );
        }

        // Derive display name from filename
        String fileDisplayName = file.path
            .split('/')
            .last
            .replaceAll('.mp3', '')
            .replaceAll('_', ' ');
        fileDisplayName = MetadataUtils.decodeHtmlEntities(
          fileDisplayName,
        ).trim();

        // Prefer artist from metadata; fallback to channel
        String? artist = (metadata?['artist'] as String?)?.trim();
        artist ??= (metadata?['channel'] as String?)?.trim();

        // Prefer title from metadata
        String? title = (metadata?['title'] as String?)?.trim();

        // Decode HTML entities from metadata values
        if (artist != null) {
          artist = MetadataUtils.decodeHtmlEntities(artist).trim();
        }
        if (title != null) {
          title = MetadataUtils.decodeHtmlEntities(title).trim();
        }

        // If artist missing, try to parse from filename pattern: "Artist - Title"
        final parsed = MetadataUtils.extractArtistTitle(fileDisplayName);
        if ((artist == null || artist.isEmpty) && parsed.artist != null) {
          artist = parsed.artist;
        }

        // Decide on title -> clean/
        final baseTitle = (title != null && title.isNotEmpty)
            ? title
            : (parsed.title ?? fileDisplayName);
        final effectiveTitle = MetadataUtils.cleanTitle(
          MetadataUtils.normalizeWhitespace(baseTitle),
        );
        final effectiveName =
            effectiveTitle; // what Library UI uses for display/sort

        return {
          'path': file.path,
          'name': effectiveName,
          'size': stat.size,
          'modified': stat.modified,
          'thumbnailUrl': metadata?['thumbnail_url'],
          'artist': artist,
          'title': effectiveTitle,
          'video_id': metadata?['video_id'],
        };
      }),
    );

    songs.sort(
      (a, b) =>
          (b['modified'] as DateTime).compareTo(a['modified'] as DateTime),
    );
    return songs;
  }

  void cancelDownload(YouTubeVideo video) {
    if (_downloadQueue.contains(video)) {
      _downloadQueue.remove(video);
      notifyListeners();
    }
  }

  Future<void> deleteSong(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  String get downloadDirectory => _downloadDirectory ?? '';
}