import '../services/api_service.dart';

/// News Service for fetching news data from the backend API
class NewsService {
  static final NewsService _instance = NewsService._internal();
  factory NewsService() => _instance;
  NewsService._internal();

  final ApiService _apiService = ApiService();

  /// Get general news (trending stocks)
  Future<List<Map<String, dynamic>>> getNews() async {
    try {
      print('📰 NewsService: Fetching general news...');
      final response = await _apiService.get('/news');
      print(
        '📰 NewsService: Received response: ${response.toString().substring(0, 200)}...',
      );
      final articles = List<Map<String, dynamic>>.from(response['data'] ?? []);
      print('📰 NewsService: Parsed ${articles.length} articles');
      return articles;
    } catch (e) {
      print('❌ NewsService Error getting news: $e');
      rethrow;
    }
  }

  /// Get news for specific stock
  Future<List<Map<String, dynamic>>> getStockNews(String ticker) async {
    try {
      print('📰 NewsService: Fetching news for $ticker...');
      final response = await _apiService.get('/news/stock/$ticker');
      print(
        '📰 NewsService: Received response for $ticker: ${response.toString().substring(0, 200)}...',
      );
      final articles = List<Map<String, dynamic>>.from(response['data'] ?? []);
      print('📰 NewsService: Parsed ${articles.length} articles for $ticker');
      return articles;
    } catch (e) {
      print('❌ NewsService Error getting stock news for $ticker: $e');
      rethrow;
    }
  }
}
