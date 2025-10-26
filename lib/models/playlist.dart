class Playlist {
  final String id;
  final String name;
  final DateTime createdAt;
  final List<Map<String, dynamic>> songs; // Store complete song objects with metadata

  Playlist({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.songs,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    final songsList = (json['songs'] as List)
        .map((s) => Map<String, dynamic>.from(s as Map))
        .toList();

    return Playlist(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      songs: songsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'songs': songs.map((song) {
        // Ensure DateTime objects are serialized as strings
        final serialized = Map<String, dynamic>.from(song);
        if (serialized['modified'] is DateTime) {
          serialized['modified'] =
              (serialized['modified'] as DateTime).toIso8601String();
        }
        return serialized;
      }).toList(),
    };
  }

  Playlist copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    List<Map<String, dynamic>>? songs,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      songs: songs ?? this.songs,
    );
  }

  // Helper getters
  List<String> get songPaths => songs.map((s) => s['path'] as String).toList();
  int get songCount => songs.length;
}
