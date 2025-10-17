class MetadataUtils {
  // Comprehensive HTML entity decoding
  static String decodeHtmlEntities(String input) {
    if (input.isEmpty) return input;
    
    var out = input
        // Common named entities
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&mdash;', '—')
        .replaceAll('&ndash;', '–')
        .replaceAll('&hellip;', '…')
        .replaceAll('&rsquo;', ''')
        .replaceAll('&lsquo;', ''')
        .replaceAll('&rdquo;', '"')
        .replaceAll('&ldquo;', '"')
        // Numeric entities
        .replaceAll('&#34;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&#38;', '&')
        .replaceAll('&#60;', '<')
        .replaceAll('&#62;', '>');
    
    // Decimal numeric entities: &#NNNN;
    out = out.replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
      final code = int.tryParse(m.group(1)!);
      return code != null && code > 0 && code <= 0x10FFFF 
          ? String.fromCharCode(code) 
          : m.group(0)!;
    });
    
    // Hex numeric entities: &#xNNNN; or &#XNNNN;
    out = out.replaceAllMapped(RegExp(r'&#[xX]([0-9A-Fa-f]+);'), (m) {
      final code = int.tryParse(m.group(1)!, radix: 16);
      return code != null && code > 0 && code <= 0x10FFFF
          ? String.fromCharCode(code) 
          : m.group(0)!;
    });
    
    // Handle broken patterns like I39, I34 (stripped entity remnants)
    out = out.replaceAllMapped(RegExp(r'(?<=\w)I39(?=\w)'), (m) => "'");
    out = out.replaceAll(' I39 ', " ' ");
    out = out.replaceAllMapped(RegExp(r'(?<=\w)I34(?=\w)'), (m) => '"');
    out = out.replaceAll(' I34 ', ' " ');
    
    return out;
  }

  // Enhanced artist-title extraction with multiple separator support
  static ({String? artist, String? title}) extractArtistTitle(String name) {
    final decoded = decodeHtmlEntities(name).trim();
    
    // Try common separators in order of reliability
    final separators = [
      ' - ',      // Most common
      ' – ',      // En dash
      ' — ',      // Em dash
      ' | ',      // Pipe
      ' / ',      // Slash (less reliable, could be legitimate)
    ];
    
    for (final sep in separators) {
      final parts = decoded.split(sep);
      if (parts.length == 2) {
        final artist = parts[0].trim();
        final title = parts[1].trim();
        
        // Validate both parts are non-empty and reasonable length
        if (artist.isNotEmpty && title.isNotEmpty && 
            artist.length > 1 && title.length > 1) {
          return (artist: artist, title: title);
        }
      }
    }
    
    // Fallback: check for "by" pattern (e.g., "Title by Artist")
    final byMatch = RegExp(r'^(.+?)\s+by\s+(.+?)$', caseSensitive: false)
        .firstMatch(decoded);
    if (byMatch != null) {
      return (
        artist: byMatch.group(2)?.trim(),
        title: byMatch.group(1)?.trim(),
      );
    }
    
    return (artist: null, title: null);
  }

  // Comprehensive title cleaning
  static String cleanTitle(String title) {
    var t = title;
    
    // Remove common video-related tags (parentheses)
    t = t.replaceAll(
      RegExp(
        r'\s*\((official|lyrics?|audio|video|music video|visuali[sz]er|'
        r'hd|hq|4k|8k|explicit|clean|remaster(ed)?|'
        r'live|acoustic|unplugged|remix|cover|instrumental|'
        r'feat\.?|ft\.?|prod\.?|mv|lyric video)[^)]*\)\s*',
        caseSensitive: false,
      ),
      ' ',
    );
    
    // Remove common video-related tags (square brackets)
    t = t.replaceAll(
      RegExp(
        r'\s*\[(official|lyrics?|audio|video|music video|visuali[sz]er|'
        r'hd|hq|4k|8k|explicit|clean|remaster(ed)?|'
        r'live|acoustic|unplugged|remix|cover|instrumental|'
        r'feat\.?|ft\.?|prod\.?|mv|lyric video)[^\]]*\]\s*',
        caseSensitive: false,
      ),
      ' ',
    );
    
    // Remove year tags like (2023), [2024], etc.
    t = t.replaceAll(RegExp(r'\s*[\(\[](?:19|20)\d{2}[\)\]]\s*'), ' ');
    
    // Remove "Official" prefix/suffix
    t = t.replaceAll(RegExp(r'^\s*official\s+', caseSensitive: false), '');
    t = t.replaceAll(RegExp(r'\s+official\s*$', caseSensitive: false), '');
    
    // Remove trailing/leading special chars and normalize
    t = normalizeWhitespace(t);
    t = t.replaceAll(RegExp(r'^[\s\-_|:;,\.]+|[\s\-_|:;,\.]+$'), '');
    
    return normalizeWhitespace(t);
  }

  // Extract featuring artists
  static ({String mainTitle, List<String> featuring}) extractFeaturing(String title) {
    final cleaned = cleanTitle(title);
    
    // Match feat., ft., featuring patterns
    final featMatch = RegExp(
      r'^(.+?)\s+(?:feat\.?|ft\.?|featuring|with)\s+(.+?)$',
      caseSensitive: false,
    ).firstMatch(cleaned);
    
    if (featMatch != null) {
      final mainTitle = featMatch.group(1)!.trim();
      final featArtists = featMatch.group(2)!
          .split(RegExp(r'\s*[&,]\s*|\s+and\s+', caseSensitive: false))
          .map((a) => a.trim())
          .where((a) => a.isNotEmpty)
          .toList();
      
      return (mainTitle: mainTitle, featuring: featArtists);
    }
    
    return (mainTitle: cleaned, featuring: <String>[]);
  }

  // Remove common channel name suffixes
  static String cleanChannelName(String channel) {
    var c = channel.trim();
    
    // Remove common suffixes
    c = c.replaceAll(RegExp(r'\s*-?\s*(VEVO|Topic|Official|Music)$', caseSensitive: false), '');
    
    return normalizeWhitespace(c);
  }

  // Normalize whitespace and trim
  static String normalizeWhitespace(String s) => 
      s.replaceAll(RegExp(r'\s+'), ' ').trim();

  // Full metadata extraction from YouTube title
  static ({
    String? artist,
    String? title,
    List<String> featuring,
    String? cleanedFullTitle,
  }) parseYouTubeTitle(String rawTitle) {
    // First decode HTML entities
    final decoded = decodeHtmlEntities(rawTitle);
    
    // Try to extract artist and title
    final extracted = extractArtistTitle(decoded);
    
    if (extracted.artist != null && extracted.title != null) {
      // We have artist - title format
      final titleWithFeat = extractFeaturing(extracted.title!);
      
      return (
        artist: cleanTitle(extracted.artist!),
        title: titleWithFeat.mainTitle,
        featuring: titleWithFeat.featuring,
        cleanedFullTitle: '${cleanTitle(extracted.artist!)} - ${titleWithFeat.mainTitle}',
      );
    } else {
      // No separator found, treat as title only
      final titleWithFeat = extractFeaturing(decoded);
      
      return (
        artist: null,
        title: titleWithFeat.mainTitle,
        featuring: titleWithFeat.featuring,
        cleanedFullTitle: titleWithFeat.mainTitle,
      );
    }
  }
  
  // Validate if metadata looks reasonable
  static bool isValidMetadata({String? artist, String? title}) {
    if (artist != null && artist.length < 2) return false;
    if (title != null && title.length < 2) return false;
    
    // Check for common garbage patterns
    final garbage = RegExp(r'^(unknown|untitled|n/?a|null|undefined)$', caseSensitive: false);
    if (artist != null && garbage.hasMatch(artist)) return false;
    if (title != null && garbage.hasMatch(title)) return false;
    
    return true;
  }
}