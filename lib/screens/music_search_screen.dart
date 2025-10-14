
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/search_provider.dart';
import '../widgets/music_card.dart';

class MusicSearchScreen extends StatelessWidget {
  const MusicSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final searchProvider = context.watch<SearchProvider>();
    final searchController = TextEditingController(text: searchProvider.query);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search music...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          searchProvider.clearSearch();
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (query) => searchProvider.search(query),
              onChanged: (query) => searchProvider.search(query), // Optional: search as you type
            ),
          ),
          Expanded(
            child: searchProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : searchProvider.videos.isEmpty
                    ? const Center(child: Text('No results'))
                    : ListView.builder(
                        itemCount: searchProvider.videos.length,
                        itemBuilder: (context, index) {
                          return MusicCard(video: searchProvider.videos[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}