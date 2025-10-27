class YouTubePlaylist {
  final String playlistId;
  final String title;
  final String channelTitle;
  final String thumbnailUrl;
  final String videoCount;

  YouTubePlaylist({
    required this.playlistId,
    required this.title,
    required this.channelTitle,
    required this.thumbnailUrl,
    required this.videoCount,
  });

  factory YouTubePlaylist.fromJson(Map<String, dynamic> json) {
    return YouTubePlaylist(
      playlistId: json['playlistId'] ?? json['playlist_id'] ?? '',
      title: json['title'] ?? 'Unknown',
      channelTitle: json['channelTitle'] ?? json['channel_title'] ?? 'Unknown',
      thumbnailUrl: json['thumbnail'] ?? json['thumbnailUrl'] ?? '',
      videoCount: json['videoCount'] ?? json['video_count'] ?? '0',
    );
  }

  YouTubePlaylist copyWith({
    String? playlistId,
    String? title,
    String? channelTitle,
    String? thumbnailUrl,
    String? videoCount,
  }) {
    return YouTubePlaylist(
      playlistId: playlistId ?? this.playlistId,
      title: title ?? this.title,
      channelTitle: channelTitle ?? this.channelTitle,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      videoCount: videoCount ?? this.videoCount,
    );
  }
}
