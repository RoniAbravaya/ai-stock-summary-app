import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// API Service for making HTTP requests
/// Uses the environment configuration to determine the correct endpoint
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // HTTP client with timeout - increased for development
  static const Duration _timeout = Duration(seconds: 60);

  /// Get the base URL for API calls based on current environment
  String get baseUrl => AppConfig.apiBaseUrl;

  /// Make a GET request
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      print('🌐 GET: $url (${AppConfig.environmentIndicator})');

      final response = await http
          .get(url, headers: _getHeaders(headers))
          .timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      print('❌ GET Error: $e');
      rethrow;
    }
  }

  /// Make a POST request
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      print('🌐 POST: $url (${AppConfig.environmentIndicator})');

      final response = await http
          .post(
            url,
            headers: _getHeaders(headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      print('❌ POST Error: $e');
      rethrow;
    }
  }

  /// Make a PUT request
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      print('🌐 PUT: $url (${AppConfig.environmentIndicator})');

      final response = await http
          .put(
            url,
            headers: _getHeaders(headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      print('❌ PUT Error: $e');
      rethrow;
    }
  }

  /// Make a DELETE request
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      print('🌐 DELETE: $url (${AppConfig.environmentIndicator})');

      final response = await http
          .delete(url, headers: _getHeaders(headers))
          .timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      print('❌ DELETE Error: $e');
      rethrow;
    }
  }

  /// Get default headers
  Map<String, String> _getHeaders(Map<String, String>? additionalHeaders) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Environment': AppConfig.environment.name,
      'X-App-Version': AppConfig.appVersion,
    };

    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  /// Handle HTTP response
  Map<String, dynamic> _handleResponse(http.Response response) {
    print('📊 Response: ${response.statusCode} - ${response.reasonPhrase}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        if (response.body.isEmpty) {
          return {'success': true};
        }
        return jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        print('⚠️ JSON Decode Error: $e');
        return {'success': true, 'data': response.body};
      }
    } else {
      // Handle error responses
      Map<String, dynamic> errorResponse;
      try {
        errorResponse = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        errorResponse = {
          'error': 'HTTP ${response.statusCode}',
          'message': response.reasonPhrase ?? 'Unknown error',
        };
      }

      throw ApiException(
        statusCode: response.statusCode,
        message:
            errorResponse['message'] ??
            errorResponse['error'] ??
            'Unknown error',
        data: errorResponse,
      );
    }
  }

  /// Check if the API is reachable
  Future<bool> checkConnection() async {
    try {
      final url = Uri.parse('$baseUrl/health');
      print('🔍 Health Check: $url (${AppConfig.environmentIndicator})');

      final response = await http.get(url).timeout(const Duration(seconds: 10));
      print('📊 Health Check Response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Health Check Failed: $e');
      return false;
    }
  }

  /// Test connectivity with detailed diagnostics
  Future<Map<String, dynamic>> testConnectivity() async {
    final result = <String, dynamic>{
      'baseUrl': baseUrl,
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      // Test health endpoint
      final healthUrl = Uri.parse('$baseUrl/health');
      print('🔍 Testing connectivity to: $healthUrl');

      final stopwatch = Stopwatch()..start();
      final response = await http
          .get(healthUrl)
          .timeout(const Duration(seconds: 15));
      stopwatch.stop();

      result['success'] = true;
      result['statusCode'] = response.statusCode;
      result['responseTime'] = '${stopwatch.elapsedMilliseconds}ms';
      result['contentLength'] = response.body.length;

      if (response.statusCode == 200) {
        try {
          final healthData = jsonDecode(response.body);
          result['serverStatus'] = healthData['status'];
          result['serverEnvironment'] = healthData['environment'];
          result['serverServices'] = healthData['services'];
        } catch (e) {
          result['parseError'] = e.toString();
        }
      }

      print('✅ Connectivity test successful: ${result['responseTime']}');
      return result;
    } catch (e) {
      result['success'] = false;
      result['error'] = e.toString();
      print('❌ Connectivity test failed: $e');
      return result;
    }
  }

  /// Get environment info
  Map<String, dynamic> getEnvironmentInfo() {
    return {
      'environment': AppConfig.environment.name,
      'environmentName': AppConfig.environmentName,
      'baseUrl': baseUrl,
      'isProduction': AppConfig.isProduction,
      'isDevelopment': AppConfig.isDevelopment,
      'isLocal': AppConfig.isLocal,
    };
  }
}

/// Custom API Exception
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? data;

  ApiException({required this.statusCode, required this.message, this.data});

  @override
  String toString() {
    return 'ApiException($statusCode): $message';
  }
}

/// Stock API Service
/// Example of how to use the ApiService for specific endpoints
class StockApiService {
  final ApiService _apiService = ApiService();

  /// Get trending stocks
  Future<List<Map<String, dynamic>>> getTrendingStocks() async {
    try {
      final response = await _apiService.get('/stocks/trending');
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    } catch (e) {
      print('❌ Error getting trending stocks: $e');
      rethrow;
    }
  }

  /// Search stocks
  Future<List<Map<String, dynamic>>> searchStocks(String query) async {
    try {
      final response = await _apiService.get(
        '/stocks/search?q=${Uri.encodeComponent(query)}',
      );
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    } catch (e) {
      print('❌ Error searching stocks: $e');
      rethrow;
    }
  }

  /// Get stock summary
  Future<Map<String, dynamic>> getStockSummary(String stockId) async {
    try {
      final response = await _apiService.get('/summary/get/$stockId');
      return response['data'] ?? {};
    } catch (e) {
      print('❌ Error getting stock summary: $e');
      rethrow;
    }
  }

  /// Generate stock summary
  Future<Map<String, dynamic>> generateStockSummary(
    String stockId,
    String language,
  ) async {
    try {
      final response = await _apiService.post(
        '/summary/generate',
        body: {'stockId': stockId, 'language': language},
      );
      return response['data'] ?? {};
    } catch (e) {
      print('❌ Error generating stock summary: $e');
      rethrow;
    }
  }
}
