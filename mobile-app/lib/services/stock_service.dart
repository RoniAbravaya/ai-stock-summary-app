import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/stock_models.dart';

class StockService {
  static final StockService _instance = StockService._internal();
  factory StockService() => _instance;
  StockService._internal();

  final String _baseUrl = AppConfig.apiBaseUrl;

  /// Get main stocks (25 predefined stocks with charts)
  Future<List<Stock>> getMainStocks() async {
    try {
      print('📊 StockService: Fetching main stocks from $_baseUrl/stocks/main');

      final response = await http.get(
        Uri.parse('$_baseUrl/stocks/main'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      print('📊 StockService: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(
            '📊 StockService: Received data with ${data['totalStocks']} stocks');

        if (data['success'] == true && data['data'] != null) {
          final stocksData = data['data'] as List;
          final stocks =
              stocksData.map((stockJson) => Stock.fromJson(stockJson)).toList();
          print('📊 StockService: Successfully parsed ${stocks.length} stocks');
          return stocks;
        } else {
          throw Exception(
              'API returned unsuccessful response: ${data['error'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ StockService: Error fetching main stocks: $e');
      rethrow;
    }
  }

  /// Get individual stock data
  Future<Stock> getStock(String ticker) async {
    try {
      print(
          '📊 StockService: Fetching stock $ticker from $_baseUrl/stocks/$ticker');

      final response = await http.get(
        Uri.parse('$_baseUrl/stocks/$ticker'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      print('📊 StockService: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final stock = Stock.fromJson(data['data']);
          print('📊 StockService: Successfully fetched stock $ticker');
          return stock;
        } else {
          throw Exception(
              'API returned unsuccessful response: ${data['error'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ StockService: Error fetching stock $ticker: $e');
      rethrow;
    }
  }

  /// Search for stocks
  Future<List<StockSearchResult>> searchStocks(String query) async {
    try {
      print('📊 StockService: Searching stocks with query "$query"');

      final response = await http.get(
        Uri.parse('$_baseUrl/stocks/search?q=${Uri.encodeComponent(query)}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      print('📊 StockService: Search response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final resultsData = data['data'] as List;
          final results = resultsData
              .map((resultJson) => StockSearchResult.fromJson(resultJson))
              .toList();
          print('📊 StockService: Found ${results.length} search results');
          return results;
        } else {
          throw Exception(
              'API returned unsuccessful response: ${data['error'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ StockService: Error searching stocks: $e');
      rethrow;
    }
  }

  /// Get user's favorite stocks
  Future<List<StockFavorite>> getFavorites(String userId) async {
    try {
      print('📊 StockService: Fetching favorites for user $userId');

      final response = await http.get(
        Uri.parse('$_baseUrl/users/$userId/favorites'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      print(
          '📊 StockService: Favorites response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final favoritesData = data['data'] as List;
          final favorites = favoritesData
              .map((favoriteJson) => StockFavorite.fromJson(favoriteJson))
              .toList();
          print('📊 StockService: Found ${favorites.length} favorites');
          return favorites;
        } else {
          throw Exception(
              'API returned unsuccessful response: ${data['error'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ StockService: Error fetching favorites: $e');
      rethrow;
    }
  }

  /// Add stock to favorites
  Future<void> addToFavorites(String userId, String ticker) async {
    try {
      print('📊 StockService: Adding $ticker to favorites for user $userId');

      final response = await http
          .post(
            Uri.parse('$_baseUrl/users/$userId/favorites'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'ticker': ticker}),
          )
          .timeout(const Duration(seconds: 30));

      print(
          '📊 StockService: Add favorite response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          print('📊 StockService: Successfully added $ticker to favorites');
        } else {
          throw Exception(
              'API returned unsuccessful response: ${data['error'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ StockService: Error adding to favorites: $e');
      rethrow;
    }
  }

  /// Remove stock from favorites
  Future<void> removeFromFavorites(String userId, String ticker) async {
    try {
      print(
          '📊 StockService: Removing $ticker from favorites for user $userId');

      final response = await http.delete(
        Uri.parse('$_baseUrl/users/$userId/favorites/$ticker'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      print(
          '📊 StockService: Remove favorite response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          print('📊 StockService: Successfully removed $ticker from favorites');
        } else {
          throw Exception(
              'API returned unsuccessful response: ${data['error'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ StockService: Error removing from favorites: $e');
      rethrow;
    }
  }

  /// Get favorite stocks with full data
  Future<List<Stock>> getFavoriteStocks(String userId) async {
    try {
      final favorites = await getFavorites(userId);
      final stocks = <Stock>[];

      for (final favorite in favorites) {
        try {
          final stock = await getStock(favorite.ticker);
          stocks.add(stock);
        } catch (e) {
          print(
              '⚠️ StockService: Failed to fetch favorite stock ${favorite.ticker}: $e');
          // Continue with other stocks
        }
      }

      return stocks;
    } catch (e) {
      print('❌ StockService: Error fetching favorite stocks: $e');
      rethrow;
    }
  }

  /// Generate AI summary for a ticker
  Future<String> generateAISummary(
    String ticker, {
    String language = 'en',
    String? idToken,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/summary/generate');
      
      // Build headers with authentication if token is provided
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      if (idToken != null && idToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $idToken';
        print('📊 StockService: Sending authenticated request for summary generation');
      } else {
        print('⚠️ StockService: No authentication token provided for summary generation');
      }
      
      final response = await http
          .post(
            uri,
            headers: headers,
            body: json.encode({'stockId': ticker.toUpperCase(), 'language': language}),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final content = (data['data']['content'] ?? '').toString();
          return content.isNotEmpty ? content : 'No summary generated.';
        }
        throw Exception('API returned unsuccessful response: ${data['error'] ?? 'Unknown error'}');
      } else if (response.statusCode == 501) {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Summary generation not available');
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ StockService: Error generating AI summary: $e');
      rethrow;
    }
  }

  /// Test API connectivity
  Future<Map<String, dynamic>> testConnectivity() async {
    try {
      print('🔍 StockService: Testing API connectivity...');
      final stopwatch = Stopwatch()..start();

      final response = await http.get(
        Uri.parse('${_baseUrl.replaceAll('/api', '')}/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      stopwatch.stop();
      final responseTime = '${stopwatch.elapsedMilliseconds}ms';

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(
            '✅ StockService: API connectivity test successful ($responseTime)');

        return {
          'success': true,
          'responseTime': responseTime,
          'serverStatus': data['status'],
          'environment': data['environment'],
          'services': data['services'],
        };
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ StockService: API connectivity test failed: $e');
      return {
        'success': false,
        'error': e.toString(),
        'responseTime': null,
      };
    }
  }

  /// Get mock data for development/testing
  Future<List<Stock>> getMockStocks() async {
    // Return mock data for testing
    return [
      Stock(
        symbol: 'AAPL',
        name: 'Apple Inc.',
        logo: 'https://logo.clearbit.com/apple.com',
        quote: StockQuote(
          symbol: 'AAPL',
          shortName: 'Apple Inc.',
          longName: 'Apple Inc.',
          regularMarketPrice: 182.52,
          regularMarketChange: 2.34,
          regularMarketChangePercent: 1.30,
          currency: 'USD',
          marketState: 'CLOSED',
          regularMarketTime: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          regularMarketDayHigh: 184.95,
          regularMarketDayLow: 180.17,
          regularMarketVolume: 45678900,
          marketCap: 2847000000000,
        ),
        lastUpdated: DateTime.now(),
      ),
      Stock(
        symbol: 'GOOGL',
        name: 'Alphabet Inc.',
        logo: 'https://logo.clearbit.com/google.com',
        quote: StockQuote(
          symbol: 'GOOGL',
          shortName: 'Alphabet Inc.',
          longName: 'Alphabet Inc.',
          regularMarketPrice: 142.56,
          regularMarketChange: -1.23,
          regularMarketChangePercent: -0.85,
          currency: 'USD',
          marketState: 'CLOSED',
          regularMarketTime: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          regularMarketDayHigh: 144.20,
          regularMarketDayLow: 141.80,
          regularMarketVolume: 23456789,
          marketCap: 1789000000000,
        ),
        lastUpdated: DateTime.now(),
      ),
      Stock(
        symbol: 'TSLA',
        name: 'Tesla, Inc.',
        logo: 'https://logo.clearbit.com/tesla.com',
        quote: StockQuote(
          symbol: 'TSLA',
          shortName: 'Tesla, Inc.',
          longName: 'Tesla, Inc.',
          regularMarketPrice: 248.87,
          regularMarketChange: 12.45,
          regularMarketChangePercent: 5.26,
          currency: 'USD',
          marketState: 'CLOSED',
          regularMarketTime: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          regularMarketDayHigh: 252.30,
          regularMarketDayLow: 245.10,
          regularMarketVolume: 67890123,
          marketCap: 789000000000,
        ),
        lastUpdated: DateTime.now(),
      ),
    ];
  }
}
