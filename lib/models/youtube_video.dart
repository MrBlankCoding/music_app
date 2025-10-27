class YouTubeVideo {
  final String videoId;
  final String title;
  final String channelTitle;
  final String thumbnailUrl;
  final String duration;

  YouTubeVideo({
    required this.videoId,
    required this.title,
    required this.channelTitle,
    required this.thumbnailUrl,
    required this.duration,
  });

  factory YouTubeVideo.fromJson(Map<String, dynamic> json) {
    return YouTubeVideo(
      videoId: json['videoId'] ?? '',
      title: json['title'] ?? 'Unknown',
      channelTitle: json['channelTitle'] ?? 'Unknown',
      thumbnailUrl: json['thumbnail'] ?? '',
      duration: json['duration'] ?? 'Unknown',
    );
  }
  YouTubeVideo copyWith({
    String? videoId,
    String? title,
    String? channelTitle,
    String? thumbnailUrl,
    String? duration,
  }) {
    return YouTubeVideo(
      videoId: videoId ?? this.videoId,
      title: title ?? this.title,
      channelTitle: channelTitle ?? this.channelTitle,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration ?? this.duration,
    );
  }
}
