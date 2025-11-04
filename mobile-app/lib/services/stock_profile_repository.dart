/// StockProfileRepository
/// Provides network access for company profile data with basic in-memory caching.

import '../models/stock_models.dart';
import 'api_service.dart';

class StockProfileRepository {
  StockProfileRepository._internal();

  static final StockProfileRepository _instance = StockProfileRepository._internal();
  factory StockProfileRepository() => _instance;

  final ApiService _apiService = ApiService();
  final Map<String, StockProfile> _cache = {};

  Future<StockProfile?> fetchProfile(String ticker) async {
    final symbol = ticker.toUpperCase();

    if (_cache.containsKey(symbol)) {
      return _cache[symbol];
    }

    final response = await _apiService.get('/stocks/$symbol/profile');
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      return null;
    }

    final profile = StockProfile.fromJson(data);
    _cache[symbol] = profile;
    return profile;
  }
}
