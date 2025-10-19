class Playlist {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final List<Map<String, dynamic>>
  songs; // Store complete song objects with metadata

  Playlist({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    required this.songs,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    // Handle both old format (songPaths) and new format (songs)
    List<Map<String, dynamic>> songsList;

    if (json.containsKey('songs')) {
      songsList = (json['songs'] as List)
          .map((s) => Map<String, dynamic>.from(s as Map))
          .toList();
    } else if (json.containsKey('songPaths')) {
      // Migration: convert old songPaths to song objects
      songsList = (json['songPaths'] as List).map((path) {
        return <String, dynamic>{
          'path': path as String,
          'name': (path).split('/').last.replaceAll('.mp3', ''),
          'artist': 'Unknown Artist',
          'size': 0,
          'modified': DateTime.now().toIso8601String(),
        };
      }).toList();
    } else {
      songsList = [];
    }

    return Playlist(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      songs: songsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'songs': songs.map((song) {
        // Ensure DateTime objects are serialized as strings
        final serialized = Map<String, dynamic>.from(song);
        if (serialized['modified'] is DateTime) {
          serialized['modified'] = (serialized['modified'] as DateTime)
              .toIso8601String();
        }
        return serialized;
      }).toList(),
    };
  }

  Playlist copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    List<Map<String, dynamic>>? songs,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      songs: songs ?? this.songs,
    );
  }

  // Helper getters for backwards compatibility
  List<String> get songPaths => songs.map((s) => s['path'] as String).toList();
  int get songCount => songs.length;
}
