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
  final String _serverUrl =
      'http://127.0.0.1:8000';
  // http://127.0.0.1:8000
  // https://hurt-denni-mrblankcoding-605d0a56.koyeb.app
  // https://downloadapi-production-6d65.up.railway.app
  final Queue<YouTubeVideo> _downloadQueue = Queue<YouTubeVideo>();
  final Map<String, double> _downloadProgress = {};
  final Map<String, Map<String, dynamic>> _downloadDetails = {};
  bool _isDownloading = false;

  Queue<YouTubeVideo> get downloadQueue => _downloadQueue;
  Map<String, double> get downloadProgress => _downloadProgress;
  Map<String, Map<String, dynamic>> get downloadDetails => _downloadDetails;
  bool get isDownloading => _isDownloading;

  Future<void> initialize() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    _downloadDirectory = '${appDocDir.path}/MusicDownloads';
    await Directory(_downloadDirectory!).create(recursive: true);
  }

  void addToQueue(YouTubeVideo video) {
    if (_downloadQueue.any((v) => v.videoId == video.videoId) ||
        _downloadProgress.containsKey(video.videoId)) {
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
    bool downloadSucceeded = false;

    try {
      await downloadAudioWithProgress(video);
      downloadSucceeded = true;
      _downloadQueue.removeFirst();
      _downloadProgress.remove(video.videoId);
      _downloadDetails.remove(video.videoId);

      // Show success toast only when queue screen is not visible
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
    } catch (e, s) {
      developer.log(
        'Download failed for ${video.title}',
        name: 'DownloadService',
        error: e,
        stackTrace: s,
      );
      _downloadQueue.removeFirst();
      _downloadProgress.remove(video.videoId);
      _downloadDetails.remove(video.videoId);

      // Show failure toast only when queue screen is not visible
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

  Future<String> downloadAudioWithProgress(YouTubeVideo video) async {
    if (_downloadDirectory == null) await initialize();
    developer.log(
      'Starting download for: ${video.title}',
      name: 'DownloadService',
    );

    final sanitizedTitle = video.title
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    // Append video ID to prevent filename collisions
    final uniqueFilename = '${sanitizedTitle}_${video.videoId}';
    final outputPath = '$_downloadDirectory/$uniqueFilename.mp3';
    final metadataPath = '$_downloadDirectory/$uniqueFilename.json';
    final file = File(outputPath);

    // Fetch video metadata from server
    Map<String, dynamic>? metadata;
    try {
      final metadataResponse = await http.get(
        Uri.parse('$_serverUrl/video-info/${video.videoId}'),
      );
      if (metadataResponse.statusCode == 200) {
        metadata = json.decode(metadataResponse.body);
        developer.log('Fetched metadata: $metadata', name: 'DownloadService');
      }
    } catch (e) {
      developer.log('Error fetching metadata: $e', name: 'DownloadService');
    }

    try {
      final client = http.Client();
      final request = http.Request(
        'GET',
        Uri.parse('$_serverUrl/download-progress/${video.videoId}'),
      );

      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception(
          'Download failed: Server returned status ${response.statusCode}',
        );
      }

      String buffer = '';
      await for (var chunk in response.stream.transform(utf8.decoder)) {
        buffer += chunk;

        // Process SSE messages
        while (buffer.contains('\n\n')) {
          final endIndex = buffer.indexOf('\n\n');
          final message = buffer.substring(0, endIndex);
          buffer = buffer.substring(endIndex + 2);

          if (message.startsWith('data: ')) {
            final jsonStr = message.substring(6);
            try {
              final data = json.decode(jsonStr);
              final status = data['status'];

              if (status == 'downloading') {
                final totalBytes = data['total_bytes'] ?? 0;
                final downloadedBytes = data['downloaded_bytes'] ?? 0;

                if (totalBytes > 0) {
                  _downloadProgress[video.videoId] =
                      downloadedBytes / totalBytes;
                }

                _downloadDetails[video.videoId] = {
                  'downloaded_bytes': downloadedBytes,
                  'total_bytes': totalBytes,
                  'speed': data['speed'] ?? 0,
                  'eta': data['eta'] ?? 0,
                  'percent': data['percent'] ?? '0%',
                };
                notifyListeners();
              } else if (status == 'finished') {
                _downloadProgress[video.videoId] = 1.0;
                _downloadDetails[video.videoId] = {'status': 'converting'};
                notifyListeners();
              } else if (status == 'converting') {
                // Server is converting the file
                _downloadProgress[video.videoId] = 1.0;
                _downloadDetails[video.videoId] = {
                  'status': 'converting',
                  'elapsed': data['elapsed'] ?? 0,
                };
                notifyListeners();
              } else if (status == 'completed') {
                // Download completed, now download the file
                final serverPath = data['path'];
                developer.log(
                  'Download completed on server: $serverPath',
                  name: 'DownloadService',
                );

                // Now download the file from server using the download-file endpoint
                final fileUrl = '$_serverUrl/download-file/${video.videoId}';
                final fileResponse = await http.get(Uri.parse(fileUrl));

                if (fileResponse.statusCode == 200) {
                  await file.writeAsBytes(fileResponse.bodyBytes);
                  developer.log(
                    'File saved to: ${file.path}',
                    name: 'DownloadService',
                  );

                  // Save metadata JSON file
                  if (metadata != null) {
                    final metadataFile = File(metadataPath);
                    await metadataFile.writeAsString(json.encode(metadata));
                    developer.log(
                      'Metadata saved to: ${metadataFile.path}',
                      name: 'DownloadService',
                    );
                  }

                  return file.path;
                } else {
                  throw Exception('Failed to download file from server');
                }
              } else if (status == 'error') {
                throw Exception(data['message'] ?? 'Unknown error');
              }
            } catch (e) {
              developer.log(
                'Error parsing SSE data: $e',
                name: 'DownloadService',
              );
            }
          }
        }
      }

      throw Exception('Stream ended unexpectedly');
    } catch (e) {
      developer.log('Error during download: $e', name: 'DownloadService');
      // Clean up partially downloaded file
      if (await file.exists()) {
        await file.delete();
      }
      rethrow;
    }
  }

  // Legacy method for backwards compatibility
  Future<String> downloadAudio(
    YouTubeVideo video, {
    Function(double)? onProgress,
  }) async {
    if (_downloadDirectory == null) await initialize();
    developer.log(
      'Starting download for: ${video.title}',
      name: 'DownloadService',
    );

    final sanitizedTitle = video.title
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    // Append video ID to prevent filename collisions
    final uniqueFilename = '${sanitizedTitle}_${video.videoId}';
    final outputPath = '$_downloadDirectory/$uniqueFilename.mp3';
    final file = File(outputPath);

    try {
      final request = http.Request(
        'POST',
        Uri.parse('$_serverUrl/download/?video_id=${video.videoId}'),
      );
      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        throw Exception(
          'Download failed: Server returned status ${response.statusCode}',
        );
      }

      final contentLength = response.contentLength;
      int receivedBytes = 0;

      final sink = file.openWrite();
      await response.stream.listen((chunk) {
        receivedBytes += chunk.length;
        sink.add(chunk);
        if (contentLength != null) {
          final progress = receivedBytes / contentLength;
          onProgress?.call(progress);
        }
      }).asFuture();

      await sink.close();

      if (!await file.exists() || await file.length() == 0) {
        throw Exception('File not saved or is empty');
      }

      developer.log('Download complete: ${file.path}', name: 'DownloadService');
      return file.path;
    } catch (e) {
      developer.log('Error during download: $e', name: 'DownloadService');
      // Clean up partially downloaded file
      if (await file.exists()) {
        await file.delete();
      }
      rethrow;
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

  Future<String> downloadPlaylistSong(
      String playlistId, Map<String, dynamic> song) async {
    if (_downloadDirectory == null) await initialize();

    final videoId = song['video_id'];
    final title = song['title'];
    final sanitizedTitle = title
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    final uniqueFilename = '${sanitizedTitle}_$videoId';
    final outputPath = '$_downloadDirectory/$uniqueFilename.mp3';
    final metadataPath = '$_downloadDirectory/$uniqueFilename.json';
    final file = File(outputPath);

    final fileUrl = '$_serverUrl/download-playlist-file/$playlistId/$videoId';
    final fileResponse = await http.get(Uri.parse(fileUrl));

    if (fileResponse.statusCode == 200) {
      await file.writeAsBytes(fileResponse.bodyBytes);

      final metadataFile = File(metadataPath);
      await metadataFile.writeAsString(json.encode(song));

      return file.path;
    } else {
      throw Exception('Failed to download file from server');
    }
  }

  String get downloadDirectory => _downloadDirectory ?? '';
}
