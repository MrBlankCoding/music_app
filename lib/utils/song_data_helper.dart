class SongData {
  final Map<String, dynamic> _songData;

  SongData(this._songData);

  String? get thumbnailUrl {
    return _songData['thumbnailUrl'] as String? ??
        _songData['thumbnail_url'] as String?;
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
