import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/news_models.dart';

/// News API Service
/// Handles HTTP requests to the Yahoo Finance news backend
class NewsApiService {
  static final NewsApiService _instance = NewsApiService._internal();
  factory NewsApiService() => _instance;
  NewsApiService._internal();

  // Each request creates its own client for better connection management

  /// Get news for all supported tickers
  Future<NewsApiResult<NewsApiResponse>> getAllTickersNews() async {
    final client = http.Client();
    try {
      print('📡 Fetching news for all tickers...');

      final uri = Uri.parse(ApiConfig.allTickersNewsUrl);
      final response = await client
          .get(uri, headers: _getHeaders())
          .timeout(ApiConfig.requestTimeout);

      return _handleNewsResponse(response);
    } catch (e) {
      return _handleError(e);
    } finally {
      client.close();
    }
  }

  /// Get news for specific tickers
  Future<NewsApiResult<NewsApiResponse>> getNewsForTickers(
    List<String> tickers,
  ) async {
    final client = http.Client();
    try {
      print('📡 Fetching news for tickers: ${tickers.join(", ")}');

      final tickersParam = tickers.join(',');
      final uri = Uri.parse(ApiConfig.getNewsUrlWithTickers(tickersParam));
      final response = await client
          .get(uri, headers: _getHeaders())
          .timeout(ApiConfig.requestTimeout);

      return _handleNewsResponse(response);
    } catch (e) {
      return _handleError(e);
    } finally {
      client.close();
    }
  }

  /// Check backend health
  Future<NewsApiResult<Map<String, dynamic>>> checkHealth() async {
    final client = http.Client();
    try {
      print('🏥 Checking backend health...');

      final uri = Uri.parse(ApiConfig.healthUrl);
      final response = await client
          .get(uri, headers: _getHeaders())
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return NewsApiResult.success(data);
      } else {
        return NewsApiResult.error(
          'Health check failed: ${response.statusCode}',
        );
      }
    } catch (e) {
      return _handleError(e);
    } finally {
      client.close();
    }
  }

  /// Get supported tickers
  Future<NewsApiResult<List<String>>> getSupportedTickers() async {
    final client = http.Client();
    try {
      print('📋 Fetching supported tickers...');

      final uri = Uri.parse(ApiConfig.newsTickersUrl);
      final response = await client
          .get(uri, headers: _getHeaders())
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['success'] == true && data['tickers'] is List) {
          final tickers = List<String>.from(data['tickers']);
          return NewsApiResult.success(tickers);
        } else {
          return NewsApiResult.error('Failed to parse tickers response');
        }
      } else {
        return NewsApiResult.error(
          'Failed to fetch tickers: ${response.statusCode}',
        );
      }
    } catch (e) {
      return _handleError(e);
    } finally {
      client.close();
    }
  }

  /// Handle news API response
  NewsApiResult<NewsApiResponse> _handleNewsResponse(http.Response response) {
    if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final newsResponse = NewsApiResponse.fromJson(data);

        print(
          '✅ News API response: ${newsResponse.successfulTickersCount} successful tickers, ${newsResponse.totalArticlesCount} total articles',
        );

        return NewsApiResult.success(newsResponse);
      } catch (e) {
        print('❌ Error parsing news response: $e');
        return NewsApiResult.error('Failed to parse response: $e');
      }
    } else if (response.statusCode == 400) {
      try {
        final errorData = json.decode(response.body) as Map<String, dynamic>;
        final errorMessage = errorData['error'] ?? 'Bad request';
        return NewsApiResult.error(errorMessage);
      } catch (e) {
        return NewsApiResult.error('Bad request: ${response.statusCode}');
      }
    } else if (response.statusCode == 500) {
      return NewsApiResult.error('Server error. Please try again later.');
    } else {
      return NewsApiResult.error('Request failed: ${response.statusCode}');
    }
  }

  /// Handle errors and exceptions
  NewsApiResult<T> _handleError<T>(dynamic error) {
    print('❌ API Error: $error');

    if (error is SocketException) {
      return NewsApiResult.error(
        'No internet connection. Please check your network.',
      );
    } else if (error is HttpException) {
      return NewsApiResult.error('Network error: ${error.message}');
    } else if (error.toString().contains('TimeoutException')) {
      return NewsApiResult.error('Request timeout. Please try again.');
    } else {
      return NewsApiResult.error('Unexpected error: ${error.toString()}');
    }
  }

  /// Get HTTP headers
  Map<String, String> _getHeaders() {
    return {'Content-Type': 'application/json', 'Accept': 'application/json'};
  }

  /// Dispose resources (no-op since we manage clients per request)
  void dispose() {}
}

/// API Result wrapper for handling success/error states
class NewsApiResult<T> {
  final bool isSuccess;
  final T? data;
  final String? error;
  final bool isLoading;

  NewsApiResult._({
    required this.isSuccess,
    this.data,
    this.error,
    this.isLoading = false,
  });

  /// Create success result
  factory NewsApiResult.success(T data) {
    return NewsApiResult._(isSuccess: true, data: data);
  }

  /// Create error result
  factory NewsApiResult.error(String error) {
    return NewsApiResult._(isSuccess: false, error: error);
  }

  /// Create loading result
  factory NewsApiResult.loading() {
    return NewsApiResult._(isSuccess: false, isLoading: true);
  }

  /// Check if result has data
  bool get hasData => isSuccess && data != null;

  /// Check if result has error
  bool get hasError => !isSuccess && !isLoading && error != null;
}
