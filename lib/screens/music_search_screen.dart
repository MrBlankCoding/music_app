import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/search_provider.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/music_card.dart';
import 'package:html_unescape/html_unescape.dart';

class MusicSearchScreen extends StatefulWidget {
  const MusicSearchScreen({super.key});

  @override
  State<MusicSearchScreen> createState() => _MusicSearchScreenState();
}

class _MusicSearchScreenState extends State<MusicSearchScreen> {
  final TextEditingController _searchController = TextEditingController();

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

  @override
  Widget build(BuildContext context) {
    final searchProvider = context.watch<SearchProvider>();

    return Column(
      children: [
        SearchBarWidget(
          controller: _searchController,
          hintText: 'Search music...',
          onChanged: (query) {
            if (query.trim().isEmpty) {
              searchProvider.clearSearch();
            }
          },
          onSubmitted: (query) {
            if (query.trim().isNotEmpty) {
              searchProvider.search(query);
            }
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
                          searchProvider.search(q);
                        },
                      ),
                    ),
                  ],
                )
              : searchProvider.videos.isEmpty
              ? const Center(child: Text('No results'))
              : ListView.builder(
                  itemCount: searchProvider.videos.length,
                  itemBuilder: (context, index) {
                    final video = searchProvider.videos[index];
                    final unescape = HtmlUnescape();
                    // If video has a title or other fields with HTML entities, decode them here
                    final parsedVideo = video.copyWith(
                      title: unescape.convert(video.title),
                    );
                    return MusicCard(video: parsedVideo);
                  },
                ),
        ),
      ],
    );
  }
}
