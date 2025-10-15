import 'dart:collection';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/youtube_video.dart';
import 'dart:developer' as developer;

class DownloadService with ChangeNotifier {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  String? _ytDlpPath;
  String? _downloadDirectory;

  final Queue<YouTubeVideo> _downloadQueue = Queue<YouTubeVideo>();
  final Map<String, double> _downloadProgress = {};
  bool _isDownloading = false;

  Queue<YouTubeVideo> get downloadQueue => _downloadQueue;
  Map<String, double> get downloadProgress => _downloadProgress;
  bool get isDownloading => _isDownloading;

  Future<void> initialize() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    _downloadDirectory = '${appDocDir.path}/MusicDownloads';
    
    await Directory(_downloadDirectory!).create(recursive: true);
    await _findYtDlp();
  }

  Future<void> _findYtDlp() async {
    final envPath = Platform.environment['YTDLP_PATH'];
    if (envPath != null && File(envPath).existsSync()) {
      _ytDlpPath = envPath;
      return;
    }

    final execDir = File(Platform.resolvedExecutable).parent.parent;
    Directory dir = execDir;
    for (int i = 0; i < 10; i++) {
      final candidate = File('${dir.path}/binaries/yt-dlp');
      if (candidate.existsSync()) {
        _ytDlpPath = candidate.path;
        return;
      }
      if (dir.parent.path == dir.path) break;
      dir = dir.parent;
    }

    throw Exception('yt-dlp not found');
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

    try {
      await downloadAudio(video, onProgress: (progress) {
        _downloadProgress[video.videoId] = progress;
        notifyListeners();
      });
      _downloadQueue.removeFirst();
      _downloadProgress.remove(video.videoId);
    } catch (e, s) {
      developer.log('Download failed for ${video.title}', name: 'DownloadService', error: e, stackTrace: s);
      _downloadProgress.remove(video.videoId);
    } finally {
      _isDownloading = false;
      notifyListeners();
      _processQueue();
    }
  }

  Future<String> downloadAudio(YouTubeVideo video, {Function(double)? onProgress}) async {
    if (_ytDlpPath == null) await initialize();
    developer.log('Starting download for: ${video.title}', name: 'DownloadService');

    final sanitizedTitle = video.title
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    
    final outputPath = '$_downloadDirectory/$sanitizedTitle.%(ext)s';

    final process = await Process.start(_ytDlpPath!, [
      '-x',
      '--audio-format', 'mp3',
      '--audio-quality', '0',
      '-o', outputPath,
      '--no-playlist',
      'https://www.youtube.com/watch?v=${video.videoId}',
    ]);

    process.stdout.transform(const SystemEncoding().decoder).listen((data) {
      developer.log('yt-dlp stdout: $data', name: 'DownloadService');
      final match = RegExp(r'(\d+\.?\d*)%').firstMatch(data);
      if (match != null) {
        final progress = double.tryParse(match.group(1) ?? '0') ?? 0;
        onProgress?.call(progress / 100);
      }
    });
    
    process.stderr.transform(const SystemEncoding().decoder).listen((data) {
      developer.log('yt-dlp stderr: $data', name: 'DownloadService');
    });

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      developer.log('yt-dlp process exited with code $exitCode', name: 'DownloadService');
      throw Exception('Download failed');
    }

    final file = File('$_downloadDirectory/$sanitizedTitle.mp3');
    if (!await file.exists()) {
      developer.log('File not found after download: ${file.path}', name: 'DownloadService');
      throw Exception('File not found');
    }
    
    developer.log('Download complete: ${file.path}', name: 'DownloadService');
    return file.path;
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

    final songs = await Future.wait(files.map((file) async {
      final stat = await file.stat();
      return {
        'path': file.path,
        'name': file.path.split('/').last.replaceAll('.mp3', '').replaceAll('_', ' '),
        'size': stat.size,
        'modified': stat.modified,
      };
    }));

    songs.sort((a, b) => (b['modified'] as DateTime).compareTo(a['modified'] as DateTime));
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
