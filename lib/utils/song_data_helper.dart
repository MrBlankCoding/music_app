import 'dart:typed_data';

class SongData {
  final Map<String, dynamic> _songData;

  SongData(this._songData);

  Uint8List? get albumArt {
    return _songData['albumArt'] as Uint8List? ??
        _songData['album_art'] as Uint8List?;
  }

  String get title {
    return _songData['title'] as String? ??
        _songData['name'] as String? ??
        'Unknown Title';
  }

  String get artist {
    return _songData['artist'] as String? ?? 'Unknown Artist';
  }

  String get path {
    return _songData['path'] as String;
  }

  String get id {
    return _songData['id']?.toString() ?? path;
  }
}