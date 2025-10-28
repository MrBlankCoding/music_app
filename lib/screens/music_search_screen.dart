import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/search_provider.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/music_card.dart';
import '../widgets/playlist_card.dart';
import '../widgets/playlist_download_progress.dart';
import 'package:html_unescape/html_unescape.dart';

class MusicSearchScreen extends StatefulWidget {
  const MusicSearchScreen({super.key});

  @override
  State<MusicSearchScreen> createState() => _MusicSearchScreenState();
}

class _MusicSearchScreenState extends State<MusicSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isPlaylistSearch = false;

  @override
  void initState() {
    super.initState();
    final searchProvider = Provider.of<SearchProvider>(context, listen: false);
    _searchController.text = searchProvider.query;
    _searchController.addListener(() {
      setState(() {}); // refresh suffixIcon visibility
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.trim().isNotEmpty) {
      final searchProvider = Provider.of<SearchProvider>(
        context,
        listen: false,
      );
      if (_isPlaylistSearch) {
        searchProvider.searchPlaylists(query);
      } else {
        searchProvider.search(query);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchProvider = context.watch<SearchProvider>();

    return Column(
      children: [
        // Playlist download progress indicator
        const PlaylistDownloadProgress(),
        Row(
          children: [
            Expanded(
              child: SearchBarWidget(
                controller: _searchController,
                hintText: _isPlaylistSearch
                    ? 'Search playlists...'
                    : 'Search music...',
                onChanged: (query) {
                  if (query.trim().isEmpty) {
                    searchProvider.clearSearch();
                  }
                },
                onSubmitted: (query) {
                  _performSearch(query);
                },
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          searchProvider.clearSearch();
                        },
                      )
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: IconButton(
                icon: Icon(
                  _isPlaylistSearch ? Icons.playlist_play : Icons.music_note,
                ),
                onPressed: () {
                  setState(() {
                    _isPlaylistSearch = !_isPlaylistSearch;
                    searchProvider.setPlaylistSearch(_isPlaylistSearch);
                    _searchController.clear();
                    searchProvider.clearSearch();
                  });
                },
                tooltip: _isPlaylistSearch
                    ? 'Switch to song search'
                    : 'Switch to playlist search',
              ),
            ),
          ],
        ),
        Expanded(
          child: searchProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : (_searchController.text.trim().isEmpty &&
                    searchProvider.recentSearches.isNotEmpty)
              ? ListView(
                  children: [
                    ListTile(
                      title: const Text('Recent searches'),
                      trailing: TextButton(
                        onPressed: () => searchProvider.clearRecentSearches(),
                        child: const Text('Clear'),
                      ),
                    ),
                    const Divider(height: 0),
                    ...searchProvider.recentSearches.map(
                      (q) => ListTile(
                        leading: const Icon(Icons.history),
                        title: Text(q),
                        onTap: () {
                          _searchController.text = q;
                          _performSearch(q);
                        },
                      ),
                    ),
                  ],
                )
              : _isPlaylistSearch
              ? _buildPlaylistResults(searchProvider)
              : _buildVideoResults(searchProvider),
        ),
      ],
    );
  }

  Widget _buildVideoResults(SearchProvider searchProvider) {
    if (searchProvider.videos.isEmpty) {
      return const Center(child: Text('No results'));
    }

    return ListView.builder(
      itemCount: searchProvider.videos.length,
      itemBuilder: (context, index) {
        final video = searchProvider.videos[index];
        final unescape = HtmlUnescape();
        final parsedVideo = video.copyWith(
          title: unescape.convert(video.title),
        );
        return MusicCard(video: parsedVideo);
      },
    );
  }

  Widget _buildPlaylistResults(SearchProvider searchProvider) {
    if (searchProvider.playlists.isEmpty) {
      return const Center(child: Text('No playlists found'));
    }

    return ListView.builder(
      itemCount: searchProvider.playlists.length,
      itemBuilder: (context, index) {
        final playlist = searchProvider.playlists[index];
        return PlaylistCard(playlist: playlist);
      },
    );
  }
}
