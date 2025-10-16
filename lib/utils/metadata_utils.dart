import 'package:flutter/foundation.dart';

class MetadataUtils {
  // Decode common HTML named and numeric entities
  static String decodeHtmlEntities(String input) {
    if (input.isEmpty) return input;
    var out = input
        .replaceAll('&quot;', '"')
        .replaceAll('&#34;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&#38;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&#60;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&#62;', '>');
    // Decimal numeric entities: &#NNNN;
    out = out.replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
      final code = int.tryParse(m.group(1)!);
      return code != null ? String.fromCharCode(code) : m.group(0)!;
    });
    // Hex numeric entities: &#xNNNN;
    out = out.replaceAllMapped(RegExp(r'&#x([0-9A-Fa-f]+);'), (m) {
      final code = int.tryParse(m.group(1)!, radix: 16);
      return code != null ? String.fromCharCode(code) : m.group(0)!;
    });
    // Handle broken patterns like I39 (common when &#39; is stripped)
    out = out.replaceAllMapped(RegExp(r'(?<=\w)I39(?=\w)'), (m) => "'");
    out = out.replaceAll(' I39 ', " '");
    return out;
  }

  // Parse "Artist - Title" from a name (already HTML-decoded)
  static ({String? artist, String? title}) extractArtistTitle(String name) {
    final decoded = decodeHtmlEntities(name).trim();
    final match = RegExp(r'^\s*(.+?)\s*-\s*(.+?)\s*$').firstMatch(decoded);
    if (match != null) {
      return (
        artist: match.group(1)?.trim(),
        title: match.group(2)?.trim(),
      );
    }
    return (artist: null, title: null);
  }

  // Remove common noise like (Official Video), [Lyrics], etc.
  static String cleanTitle(String title) {
    var t = title;
    t = t.replaceAll(RegExp(r'\s*\((official|lyrics|audio|video|hd|hq)[^)]*\)\s*', caseSensitive: false), ' ');
    t = t.replaceAll(RegExp(r'\s*\[(official|lyrics|audio|video|hd|hq)[^\]]*\]\s*', caseSensitive: false), ' ');
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t;
  }

  static String normalizeWhitespace(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();
}