class YouTubeVideo {
  final String videoId;
  final String title;
  final String channelTitle;
  final String thumbnailUrl;
  final DateTime publishedAt;

  YouTubeVideo({
    required this.videoId,
    required this.title,
    required this.channelTitle,
    required this.thumbnailUrl,
    required this.publishedAt,
  });

  factory YouTubeVideo.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final snippet = json['snippet'];

    final videoId = id is Map ? id['videoId'] ?? '' : id?.toString() ?? '';
    final thumbnails = snippet['thumbnails'];

    return YouTubeVideo(
      videoId: videoId,
      title: snippet['title'] ?? 'Unknown',
      channelTitle: snippet['channelTitle'] ?? 'Unknown',
      thumbnailUrl:
          thumbnails?['high']?['url'] ??
          thumbnails?['medium']?['url'] ??
          thumbnails?['default']?['url'] ??
          '',
      publishedAt:
          DateTime.tryParse(snippet['publishedAt'] ?? '') ?? DateTime.now(),
    );
  }
}
