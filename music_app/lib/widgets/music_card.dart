import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/youtube_video.dart';
import 'video_details_sheet.dart';

class MusicCard extends StatelessWidget {
  final YouTubeVideo video;

  const MusicCard({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: video.thumbnailUrl,
          width: 80,
          height: 60,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 80,
            height: 60,
            color: Colors.grey[300],
            child: const Icon(Icons.music_note),
          ),
          errorWidget: (context, url, error) => Container(
            width: 80,
            height: 60,
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image),
          ),
        ),
      ),
      title: Text(
        video.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        video.channelTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => VideoDetailsSheet(video: video),
        );
      },
    );
  }
}