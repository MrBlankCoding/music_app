import 'package:flutter/material.dart';
import '../services/download_service.dart';

enum SortOrder {
  nameAz,
  nameZa,
  dateNewest,
  dateOldest,
  sizeLargest,
  sizeSmallest,
}

class LibraryProvider with ChangeNotifier {
  final DownloadService _downloadService;

  List<Map<String, dynamic>> _songs = [];
  bool _isLoading = true;
  SortOrder _sortOrder = SortOrder.dateNewest;
  String _filterQuery = '';

  // Getters
  List<Map<String, dynamic>> get songs {
    // Create defensive copy to prevent mutation of stored list
    List<Map<String, dynamic>> filteredSongs = List.of(_songs);

    if (_filterQuery.isNotEmpty) {
      filteredSongs = filteredSongs
          .where(
            (song) =>
                song['name'].toLowerCase().contains(_filterQuery.toLowerCase()),
          )
          .toList();
    }

    switch (_sortOrder) {
      case SortOrder.nameAz:
        filteredSongs.sort((a, b) => a['name'].compareTo(b['name']));
        break;
      case SortOrder.nameZa:
        filteredSongs.sort((a, b) => b['name'].compareTo(a['name']));
        break;
      case SortOrder.dateNewest:
        filteredSongs.sort(
          (a, b) =>
              (b['modified'] as DateTime).compareTo(a['modified'] as DateTime),
        );
        break;
      case SortOrder.dateOldest:
        filteredSongs.sort(
          (a, b) =>
              (a['modified'] as DateTime).compareTo(b['modified'] as DateTime),
        );
        break;
      case SortOrder.sizeLargest:
        filteredSongs.sort(
          (a, b) => (b['size'] as int).compareTo(a['size'] as int),
        );
        break;
      case SortOrder.sizeSmallest:
        filteredSongs.sort(
          (a, b) => (a['size'] as int).compareTo(b['size'] as int),
        );
        break;
    }

    return filteredSongs;
  }

  bool get isLoading => _isLoading;
  SortOrder get sortOrder => _sortOrder;

  LibraryProvider({DownloadService? downloadService})
      : _downloadService = downloadService ?? DownloadService();

  void setSortOrder(SortOrder sortOrder) {
    _sortOrder = sortOrder;
    notifyListeners();
  }

  void setFilterQuery(String query) {
    _filterQuery = query;
    notifyListeners();
  }

  Future<void> loadSongs() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _downloadService.initialize();
      _songs = await _downloadService.getDownloadedSongs();
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteSong(String path) async {
    try {
      await _downloadService.deleteSong(path);
      await loadSongs();
    } catch (e) {
      // Handle error
    }
  }
}