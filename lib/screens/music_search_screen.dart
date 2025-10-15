
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/search_provider.dart';
import '../widgets/music_card.dart';

class MusicSearchScreen extends StatefulWidget {
  const MusicSearchScreen({super.key});

  @override
  State<MusicSearchScreen> createState() => _MusicSearchScreenState();
}

class _MusicSearchScreenState extends State<MusicSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

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
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchProvider = context.watch<SearchProvider>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search music...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        searchProvider.clearSearch();
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (query) => searchProvider.search(query),
            onChanged: (query) {
              _debounce?.cancel();
              if (query.trim().isEmpty) {
                searchProvider.clearSearch();
                return;
              }
              _debounce = Timer(const Duration(milliseconds: 450), () {
                searchProvider.search(query);
              });
            },
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
    );
  }
}