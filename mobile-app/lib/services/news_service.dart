import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// News Service for fetching news data from the backend API
class NewsService {
  static final NewsService _instance = NewsService._internal();
  factory NewsService() => _instance;
  NewsService._internal();

  final ApiService _apiService = ApiService();
  final String _articleIndexKey = 'article_indexes';
  Map<String, int> _currentArticleIndexes = {};

  /// Initialize article indexes from storage
  Future<void> initializeArticleIndexes() async {
    final prefs = await SharedPreferences.getInstance();
    final indexesJson = prefs.getString(_articleIndexKey);
    if (indexesJson != null) {
      final Map<String, dynamic> indexes = json.decode(indexesJson);
      _currentArticleIndexes = indexes.map(
        (key, value) => MapEntry(key, value as int),
      );
    }
  }

  /// Save current article indexes to storage
  Future<void> _saveArticleIndexes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _articleIndexKey,
      json.encode(_currentArticleIndexes),
    );
  }

  /// Get the next article index for a ticker
  int _getNextArticleIndex(String ticker, int maxArticles) {
    final currentIndex = _currentArticleIndexes[ticker] ?? 0;
    final nextIndex = (currentIndex + 1) % maxArticles;
    _currentArticleIndexes[ticker] = nextIndex;
    _saveArticleIndexes();
    return nextIndex;
  }

  /// Reset article indexes (called when switching environments)
  Future<void> resetArticleIndexes() async {
    _currentArticleIndexes.clear();
    await _saveArticleIndexes();
  }

  /// Get latest article for each ticker
  Future<List<Map<String, dynamic>>> getNews() async {
    try {
      print('📰 NewsService: Fetching general news...');
      final response = await _apiService.get('/news');
      print('📰 NewsService: Received response');

      final allArticles =
          List<Map<String, dynamic>>.from(response['data'] ?? []);
      final Map<String, List<Map<String, dynamic>>> articlesByTicker = {};

      // Group articles by ticker
      for (var article in allArticles) {
        // The ticker field seems to be incorrect, use the first ticker from tickers array
        final tickersList = article['tickers'] as List<dynamic>?;
        String? keyTicker;

        if (tickersList != null && tickersList.isNotEmpty) {
          // Get the first ticker and clean it up
          keyTicker = (tickersList.first as String)
              .replaceAll(r'$', '') // Remove $ prefix
              .replaceAll(r'#', '') // Remove # prefix
              .trim();
          print('📰 Extracted ticker: $keyTicker from ${tickersList.first}');
        }

        // Fallback to ticker field if tickers array is empty
        if (keyTicker == null || keyTicker.isEmpty) {
          keyTicker = article['ticker'] as String?;
          print('📰 Using fallback ticker: $keyTicker');
        }

        if (keyTicker != null && keyTicker.isNotEmpty) {
          articlesByTicker[keyTicker] = articlesByTicker[keyTicker] ?? [];
          // Add the cleaned ticker back to the article for display
          article['ticker'] = keyTicker;
          articlesByTicker[keyTicker]!.add(article);
          print(
              '📰 Added article to ticker $keyTicker (total: ${articlesByTicker[keyTicker]!.length})');
        } else {
          print(
              '📰 Skipping article with no valid ticker: ${article['title']}');
        }
      }

      print('📰 NewsService: Found ${articlesByTicker.length} unique tickers');
      print('📰 NewsService: Tickers: ${articlesByTicker.keys.join(', ')}');

      // Sort articles within each ticker by date/time
      for (var articles in articlesByTicker.values) {
        articles.sort((a, b) {
          // First try to use 'ago' field
          final aAgo = a['ago'] as String?;
          final bAgo = b['ago'] as String?;
          if (aAgo != null && bAgo != null) {
            // Convert "X hours/minutes ago" to rough minutes for comparison
            final aMinutes = _convertAgoToMinutes(aAgo);
            final bMinutes = _convertAgoToMinutes(bAgo);
            return aMinutes.compareTo(
                bMinutes); // Most recent first (smaller minutes = more recent)
          }
          // Fallback to time field
          final aTime = a['time'] as String? ?? '';
          final bTime = b['time'] as String? ?? '';
          return bTime.compareTo(aTime);
        });
      }

      // Get latest article from each ticker
      final latestArticles = articlesByTicker.entries.map((entry) {
        final tickerArticles = entry.value;
        final articleIndex = _currentArticleIndexes[entry.key] ?? 0;
        return tickerArticles[articleIndex % tickerArticles.length];
      }).toList();

      // Sort final list by time (most recent first)
      latestArticles.sort((a, b) {
        final aAgo = a['ago'] as String?;
        final bAgo = b['ago'] as String?;
        if (aAgo != null && bAgo != null) {
          final aMinutes = _convertAgoToMinutes(aAgo);
          final bMinutes = _convertAgoToMinutes(bAgo);
          return aMinutes.compareTo(bMinutes);
        }
        final aTime = a['time'] as String? ?? '';
        final bTime = b['time'] as String? ?? '';
        return bTime.compareTo(aTime);
      });

      print(
          '📰 NewsService: Returning ${latestArticles.length} articles (one per ticker)');
      return latestArticles;
    } catch (e) {
      print('❌ NewsService Error getting news: $e');
      rethrow;
    }
  }

  /// Convert "X hours/minutes ago" to minutes for comparison
  int _convertAgoToMinutes(String ago) {
    final parts = ago.toLowerCase().split(' ');
    if (parts.length < 2) return 0;

    final value = int.tryParse(parts[0]) ?? 0;
    if (parts[1].startsWith('minute')) {
      return value;
    } else if (parts[1].startsWith('hour')) {
      return value * 60;
    } else if (parts[1].startsWith('day')) {
      return value * 60 * 24;
    }
    return 0;
  }

  /// Get news for specific stock
  Future<List<Map<String, dynamic>>> getStockNews(String ticker) async {
    try {
      print('📰 NewsService: Fetching news for $ticker...');
      final response = await _apiService.get('/news/stock/$ticker');
      final articles = List<Map<String, dynamic>>.from(response['data'] ?? []);
      final articleIndex = _getNextArticleIndex(ticker, articles.length);
      return [articles[articleIndex]];
    } catch (e) {
      print('❌ NewsService Error getting stock news for $ticker: $e');
      rethrow;
    }
  }

  /// Open article URL in external browser
  Future<void> openArticleUrl(String url) async {
    try {
      if (await canLaunchUrlString(url)) {
        await launchUrlString(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      print('❌ NewsService Error opening URL: $e');
      rethrow;
    }
  }
}
