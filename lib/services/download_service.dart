import 'dart:collection';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:oktoast/oktoast.dart';
import '../models/youtube_video.dart';
import '../models/song_metadata.dart';
import '../providers/library_provider.dart';
import '../utils/song_utils.dart';

class DownloadService with ChangeNotifier {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  LibraryProvider? _libraryProvider;
  bool isQueueScreenVisible = false;
  String? _downloadDirectory;
  final String _serverUrl =
      'https://lasandra-sultriest-bumblingly.ngrok-free.dev';
  final Queue<YouTubeVideo> _downloadQueue = Queue<YouTubeVideo>();
  bool _isDownloading = false;

  Queue<YouTubeVideo> get downloadQueue => _downloadQueue;
  bool get isDownloading => _isDownloading;
  String? get currentlyDownloadingVideoId =>
      _isDownloading && _downloadQueue.isNotEmpty
      ? _downloadQueue.first.videoId
      : null;

  void setLibraryProvider(LibraryProvider libraryProvider) {
    _libraryProvider = libraryProvider;
  }

  Future<void> initialize() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    _downloadDirectory = '${appDocDir.path}/MusicDownloads';
    await Directory(_downloadDirectory!).create(recursive: true);
  }

  void addToQueue(YouTubeVideo video) {
    if (_downloadQueue.any((v) => v.videoId == video.videoId)) return;
    _downloadQueue.add(video);
    notifyListeners();
    _processQueue();
  }

  Future<void> _processQueue() async {
    if (_isDownloading || _downloadQueue.isEmpty) return;

    _isDownloading = true;
    final video = _downloadQueue.first;

    try {
      final response = await http.get(
        Uri.parse('$_serverUrl/download/${video.videoId}'),
      );
      if (response.statusCode != 200) throw Exception('Download failed');

      final sanitizedTitle = _sanitizeFilename(video.title);
      final filePath = '$_downloadDirectory/$sanitizedTitle.mp3';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      // Extract metadata using SongUtils
      SongMetadata songMetadata;
      try {
        songMetadata = await SongUtils.extractMetadata(filePath);
        // Update video ID
        songMetadata = songMetadata.copyWith(videoId: video.videoId);
      } catch (e) {
        print('Metadata extraction failed: $e');
        // Create metadata from video info
        songMetadata = SongMetadata(
          title: video.title,
          artist: 'Unknown Artist',
          album: 'Unknown Album',
          localPath: filePath,
          videoId: video.videoId,
        );
      }

      // Save metadata JSON
      final metadataPath = '$_downloadDirectory/$sanitizedTitle.json';
      final metadataMap = SongUtils.toStorageMap(songMetadata);
      await File(metadataPath).writeAsString(json.encode(metadataMap));

      _downloadQueue.removeFirst();
      if (!isQueueScreenVisible) {
        showToast(
          "✓ Downloaded: ${songMetadata.title}",
          duration: const Duration(seconds: 3),
        );
      }

      _libraryProvider?.loadSongs();
    } catch (e) {
      print('Download failed: $e');
      _downloadQueue.removeFirst();
      if (!isQueueScreenVisible) {
        showToast(
          "✗ Download failed: ${video.title}",
          duration: const Duration(seconds: 3),
        );
      }
    } finally {
      _isDownloading = false;
      notifyListeners();
      _processQueue();
    }
  }

  String _sanitizeFilename(String filename) {
    return SongUtils.sanitizeFilename(filename);
  }

  Future<List<Map<String, dynamic>>> getDownloadedSongs() async {
    if (_downloadDirectory == null) await initialize();
    final dir = Directory(_downloadDirectory!);
    if (!await dir.exists()) return [];

    final files = await dir
        .list()
        .where((f) => f is File && f.path.endsWith('.mp3'))
        .cast<File>()
        .toList();

    return Future.wait(
      files.map((file) async {
        final stat = await file.stat();
        final baseName = file.path.replaceAll('.mp3', '');
        Map<String, dynamic>? storedMetadata;
        try {
          final metadataFile = File('$baseName.json');
          if (await metadataFile.exists()) {
            storedMetadata = json.decode(await metadataFile.readAsString());
          }
        } catch (_) {}

        // Use stored metadata or extract from file
        SongMetadata songMetadata;
        if (storedMetadata != null) {
          songMetadata = SongMetadata.fromMap({
            'path': file.path,
            'title': storedMetadata['title'],
            'name': storedMetadata['name'] ?? storedMetadata['title'],
            'artist': storedMetadata['artist'],
            'album': storedMetadata['album'],
            'genre': storedMetadata['genre'],
            'duration': storedMetadata['duration'],
            'year': storedMetadata['year'],
            'albumArt': storedMetadata['albumArt'],
            'video_id': storedMetadata['video_id'],
          });
        } else {
          // Try to extract metadata from the file
          try {
            songMetadata = await SongUtils.extractMetadata(file.path);
          } catch (e) {
            // Fallback to filename
            final filename = file.path.split('/').last.replaceAll('.mp3', '');
            songMetadata = SongMetadata(
              title: filename,
              artist: 'Unknown Artist',
              album: 'Unknown Album',
              localPath: file.path,
            );
          }
        }

        final metadataMap = songMetadata.toMap();
        metadataMap['modified'] = stat.modified;
        metadataMap['size'] = stat.size;

        return metadataMap;
      }).toList(),
    );
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

    final metadataFile = File(path.replaceAll('.mp3', '.json'));
    if (await metadataFile.exists()) await metadataFile.delete();
  }

  String get downloadDirectory => _downloadDirectory ?? '';
}
