import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/youtube_video.dart';

class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  String? _ytDlpPath;
  String? _downloadDirectory;

  Future<void> initialize() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    _downloadDirectory = '${appDocDir.path}/MusicDownloads';
    
    await Directory(_downloadDirectory!).create(recursive: true);
    await _findYtDlp();
  }

  Future<void> _findYtDlp() async {
    // Check ENV vars
    final envPath = Platform.environment['YTDLP_PATH'];
    if (envPath != null && File(envPath).existsSync()) {
      _ytDlpPath = envPath;
      return;
    }

    // Look in bianarys for YT DLP
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

  Future<String> downloadAudio(YouTubeVideo video, {Function(double)? onProgress}) async {
    if (_ytDlpPath == null) await initialize();

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
      final match = RegExp(r'(\d+\.?\d*)%').firstMatch(data);
      if (match != null) {
        final progress = double.tryParse(match.group(1) ?? '0') ?? 0;
        onProgress?.call(progress / 100);
      }
    });

    final exitCode = await process.exitCode;
    if (exitCode != 0) throw Exception('Download failed');

    final file = File('$_downloadDirectory/$sanitizedTitle.mp3');
    if (!await file.exists()) throw Exception('File not found');
    
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

  Future<void> deleteSong(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  String get downloadDirectory => _downloadDirectory ?? '';
}