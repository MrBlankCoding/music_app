class Playlist {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final List<String> songPaths;

  Playlist({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    required this.songPaths,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      songPaths: List<String>.from(json['songPaths'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'songPaths': songPaths,
    };
  }

  Playlist copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    List<String>? songPaths,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      songPaths: songPaths ?? this.songPaths,
    );
  }
}