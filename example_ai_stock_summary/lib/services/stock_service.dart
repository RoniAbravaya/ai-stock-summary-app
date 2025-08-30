import '../services/supabase_service.dart';
import '../models/stock_model.dart';
import '../models/stock_price_model.dart';
import '../models/watchlist_model.dart';

class StockService {
  static StockService? _instance;
  static StockService get instance => _instance ??= StockService._();

  StockService._();

  final client = SupabaseService.instance.client;

  // Get all stocks with current prices
  Future<List<StockModel>> getAllStocks({int limit = 100}) async {
    try {
      final response = await client
          .from('stocks')
          .select('''
            *,
            stock_prices(
              current_price,
              previous_close,
              volume,
              market_cap,
              pe_ratio,
              eps,
              dividend_yield,
              fifty_two_week_high,
              fifty_two_week_low
            )
          ''')
          .eq('is_active', true)
          .order('market_cap', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => StockModel.fromJson(json))
          .toList();
    } catch (error) {
      throw Exception('Failed to fetch stocks: $error');
    }
  }

  // Search stocks by symbol or name
  Future<List<StockModel>> searchStocks(String query) async {
    try {
      final response = await client
          .from('stocks')
          .select('''
            *,
            stock_prices(
              current_price,
              previous_close,
              volume,
              market_cap,
              pe_ratio,
              eps
            )
          ''')
          .or('symbol.ilike.%$query%,name.ilike.%$query%')
          .eq('is_active', true)
          .order('market_cap', ascending: false)
          .limit(20);

      return (response as List)
          .map((json) => StockModel.fromJson(json))
          .toList();
    } catch (error) {
      throw Exception('Failed to search stocks: $error');
    }
  }

  // Get stock by symbol with latest price
  Future<StockModel?> getStockBySymbol(String symbol) async {
    try {
      final response = await client.from('stocks').select('''
            *,
            stock_prices(
              current_price,
              open_price,
              high_price,
              low_price,
              previous_close,
              volume,
              market_cap,
              pe_ratio,
              eps,
              dividend_yield,
              fifty_two_week_high,
              fifty_two_week_low,
              price_date
            )
          ''').eq('symbol', symbol).eq('is_active', true).single();

      return StockModel.fromJson(response);
    } catch (error) {
      throw Exception('Failed to fetch stock: $error');
    }
  }

  // Get user's watchlist stocks
  Future<List<WatchlistModel>> getUserWatchlistStocks(String userId) async {
    try {
      final response = await client
          .from('watchlist_items')
          .select('''
            *,
            stocks!inner(
              *,
              stock_prices(
                current_price,
                previous_close,
                volume
              )
            ),
            watchlists!inner(user_id)
          ''')
          .eq('watchlists.user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => WatchlistModel.fromJson(json))
          .toList();
    } catch (error) {
      throw Exception('Failed to fetch watchlist: $error');
    }
  }

  // Add stock to watchlist
  Future<void> addToWatchlist(String stockId, String userId,
      {String? notes}) async {
    try {
      // Get or create default watchlist
      var watchlistResponse = await client
          .from('watchlists')
          .select('id')
          .eq('user_id', userId)
          .eq('is_default', true)
          .maybeSingle();

      String watchlistId;
      if (watchlistResponse == null) {
        // Create default watchlist
        final newWatchlist = await client
            .from('watchlists')
            .insert({
              'user_id': userId,
              'name': 'My Watchlist',
              'is_default': true,
            })
            .select('id')
            .single();
        watchlistId = newWatchlist['id'];
      } else {
        watchlistId = watchlistResponse['id'];
      }

      // Add stock to watchlist
      await client.from('watchlist_items').insert({
        'watchlist_id': watchlistId,
        'stock_id': stockId,
        'notes': notes,
      });
    } catch (error) {
      throw Exception('Failed to add to watchlist: $error');
    }
  }

  // Remove stock from watchlist
  Future<void> removeFromWatchlist(String stockId, String userId) async {
    try {
      await client
          .from('watchlist_items')
          .delete()
          .eq('stock_id', stockId)
          .eq('watchlists.user_id', userId);
    } catch (error) {
      throw Exception('Failed to remove from watchlist: $error');
    }
  }

  // Get trending stocks (based on volume)
  Future<List<StockModel>> getTrendingStocks({int limit = 10}) async {
    try {
      final response = await client
          .from('stock_prices')
          .select('''
            *,
            stocks!inner(*)
          ''')
          .eq('price_date', DateTime.now().toIso8601String().split('T')[0])
          .order('volume', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => StockModel.fromStockPrice(json))
          .toList();
    } catch (error) {
      throw Exception('Failed to fetch trending stocks: $error');
    }
  }

  // Get stock price history
  Future<List<StockPriceModel>> getStockPriceHistory(
    String stockId, {
    int days = 30,
  }) async {
    try {
      final fromDate = DateTime.now().subtract(Duration(days: days));

      final response = await client
          .from('stock_prices')
          .select('*')
          .eq('stock_id', stockId)
          .gte('price_date', fromDate.toIso8601String().split('T')[0])
          .order('price_date', ascending: true);

      return (response as List)
          .map((json) => StockPriceModel.fromJson(json))
          .toList();
    } catch (error) {
      throw Exception('Failed to fetch price history: $error');
    }
  }
}
