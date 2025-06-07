/// News Article Model
/// Represents a single news article from Yahoo Finance API
class NewsArticle {
  final String url;
  final String? img;
  final String title;
  final String text;
  final String source;
  final String type;
  final List<String> tickers;
  final String time;
  final String ago;
  final DateTime? cachedAt;
  final String ticker;

  NewsArticle({
    required this.url,
    this.img,
    required this.title,
    required this.text,
    required this.source,
    required this.type,
    required this.tickers,
    required this.time,
    required this.ago,
    this.cachedAt,
    required this.ticker,
  });

  /// Create NewsArticle from JSON
  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      url: json['url'] ?? '',
      img: json['img'],
      title: json['title'] ?? 'No title',
      text: json['text'] ?? '',
      source: json['source'] ?? 'Unknown',
      type: json['type'] ?? 'Article',
      tickers: List<String>.from(json['tickers'] ?? []),
      time: json['time'] ?? '',
      ago: json['ago'] ?? '',
      cachedAt:
          json['cached_at'] != null
              ? DateTime.tryParse(json['cached_at'])
              : null,
      ticker: json['ticker'] ?? '',
    );
  }

  /// Convert NewsArticle to JSON
  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'img': img,
      'title': title,
      'text': text,
      'source': source,
      'type': type,
      'tickers': tickers,
      'time': time,
      'ago': ago,
      'cached_at': cachedAt?.toIso8601String(),
      'ticker': ticker,
    };
  }

  /// Get time ago as a more readable format
  String get timeAgo {
    if (ago.isNotEmpty) return ago;
    if (cachedAt != null) {
      final now = DateTime.now();
      final difference = now.difference(cachedAt!);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    }
    return time;
  }

  /// Get primary ticker symbol
  String get primaryTicker {
    if (tickers.isNotEmpty) {
      return tickers.first.replaceAll('\$', '');
    }
    return ticker;
  }

  /// Check if article has image
  bool get hasImage => img != null && img!.isNotEmpty;
}

/// Ticker News Result Model
/// Represents the result for a specific ticker from the API
class TickerNewsResult {
  final bool success;
  final String ticker;
  final String? lastUpdated;
  final int? totalArticles;
  final List<NewsArticle>? articles;
  final double? cacheAge;
  final String? error;

  TickerNewsResult({
    required this.success,
    required this.ticker,
    this.lastUpdated,
    this.totalArticles,
    this.articles,
    this.cacheAge,
    this.error,
  });

  /// Create TickerNewsResult from JSON
  factory TickerNewsResult.fromJson(String ticker, Map<String, dynamic> json) {
    return TickerNewsResult(
      success: json['success'] ?? false,
      ticker: ticker,
      lastUpdated: json['lastUpdated'],
      totalArticles: json['totalArticles'],
      articles:
          json['articles'] != null
              ? (json['articles'] as List)
                  .map((article) => NewsArticle.fromJson(article))
                  .toList()
              : null,
      cacheAge: json['cacheAge']?.toDouble(),
      error: json['error'],
    );
  }
}

/// News API Response Model
/// Represents the complete response from the /api/yahoo-news endpoint
class NewsApiResponse {
  final bool success;
  final Map<String, TickerNewsResult> results;
  final List<String> requestedTickers;
  final DateTime retrievedAt;
  final String? error;

  NewsApiResponse({
    required this.success,
    required this.results,
    required this.requestedTickers,
    required this.retrievedAt,
    this.error,
  });

  /// Create NewsApiResponse from JSON
  factory NewsApiResponse.fromJson(Map<String, dynamic> json) {
    final results = <String, TickerNewsResult>{};

    if (json['results'] != null) {
      (json['results'] as Map<String, dynamic>).forEach((ticker, result) {
        results[ticker] = TickerNewsResult.fromJson(ticker, result);
      });
    }

    return NewsApiResponse(
      success: json['success'] ?? false,
      results: results,
      requestedTickers: List<String>.from(json['requestedTickers'] ?? []),
      retrievedAt:
          DateTime.tryParse(json['retrievedAt'] ?? '') ?? DateTime.now(),
      error: json['error'],
    );
  }

  /// Get all successful articles in chronological order (deduplicated by URL)
  List<NewsArticle> getAllArticlesChronological() {
    final allArticles = <NewsArticle>[];
    final seenUrls = <String>{};

    for (final result in results.values) {
      if (result.success && result.articles != null) {
        for (final article in result.articles!) {
          // Only add if we haven't seen this URL before
          if (!seenUrls.contains(article.url)) {
            seenUrls.add(article.url);
            allArticles.add(article);
          }
        }
      }
    }

    // Sort by cached_at time (newest first)
    allArticles.sort((a, b) {
      if (a.cachedAt != null && b.cachedAt != null) {
        return b.cachedAt!.compareTo(a.cachedAt!);
      }
      return 0;
    });

    return allArticles;
  }

  /// Get the most recent unique articles (deduplicated by URL)
  List<NewsArticle> getMostRecentFromEachTicker() {
    // Get all articles chronologically and deduplicated
    final allUniqueArticles = getAllArticlesChronological();

    // Take the most recent articles up to the number of successful tickers
    final maxArticles = successfulTickersCount;

    return allUniqueArticles.take(maxArticles).toList();
  }

  /// Get total number of successful tickers
  int get successfulTickersCount {
    return results.values.where((result) => result.success).length;
  }

  /// Get total number of articles
  int get totalArticlesCount {
    return results.values
        .where((result) => result.success && result.articles != null)
        .fold(0, (sum, result) => sum + result.articles!.length);
  }
}
