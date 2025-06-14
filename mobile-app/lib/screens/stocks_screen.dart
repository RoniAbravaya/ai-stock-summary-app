import 'package:flutter/material.dart';
import '../services/stock_service.dart';
import '../services/firebase_service.dart';
import '../config/app_config.dart';
import '../models/stock_models.dart';
import '../widgets/environment_switcher.dart';

class StocksScreen extends StatefulWidget {
  const StocksScreen({super.key, required this.firebaseEnabled});

  final bool firebaseEnabled;

  @override
  State<StocksScreen> createState() => _StocksScreenState();
}

class _StocksScreenState extends State<StocksScreen> {
  final StockService _stockService = StockService();
  final TextEditingController _searchController = TextEditingController();

  List<Stock> _mainStocks = [];
  List<StockSearchResult> _searchResults = [];
  List<String> _favoriteSymbols = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String? _error;
  Map<String, dynamic>? _connectivityInfo;
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _initializeAndLoad();
  }

  Future<void> _initializeAndLoad() async {
    await _loadUserData();
    await _loadMainStocks();
  }

  Future<void> _loadUserData() async {
    if (widget.firebaseEnabled) {
      try {
        final user = FirebaseService().auth.currentUser;
        if (user != null) {
          _currentUserId = user.uid;
          await _loadFavorites();
        }
      } catch (e) {
        print('⚠️ StocksScreen: Error loading user data: $e');
      }
    }
  }

  Future<void> _loadFavorites() async {
    if (_currentUserId.isEmpty) return;

    try {
      final favorites = await _stockService.getFavorites(_currentUserId);
      setState(() {
        _favoriteSymbols = favorites.map((f) => f.ticker).toList();
      });
    } catch (e) {
      print('⚠️ StocksScreen: Error loading favorites: $e');
    }
  }

  Future<void> _loadMainStocks() async {
    try {
      print('📊 StocksScreen: Starting to load main stocks...');
      setState(() {
        _isLoading = true;
        _error = null;
        _connectivityInfo = null;
      });

      // First test connectivity
      print('🔍 StocksScreen: Testing API connectivity...');
      final connectivityResult = await _stockService.testConnectivity();
      _connectivityInfo = connectivityResult;

      if (!connectivityResult['success']) {
        throw Exception(
          'API connectivity failed: ${connectivityResult['error']}',
        );
      }

      print(
          '✅ StocksScreen: API connectivity successful (${connectivityResult['responseTime']})');

      print('📊 StocksScreen: Calling StockService.getMainStocks()...');
      final stocks = await _stockService.getMainStocks();
      print('📊 StocksScreen: Received ${stocks.length} stocks');

      setState(() {
        _mainStocks = stocks;
        _isLoading = false;
      });
      print('📊 StocksScreen: State updated successfully');
    } catch (e) {
      print('❌ StocksScreen: Error loading stocks: $e');
      setState(() {
        _error = 'Failed to load stocks: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _searchStocks(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    try {
      setState(() {
        _isSearching = true;
      });

      final results = await _stockService.searchStocks(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      print('❌ StocksScreen: Error searching stocks: $e');
      setState(() {
        _isSearching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search failed: $e')),
      );
    }
  }

  Future<void> _toggleFavorite(String symbol) async {
    if (_currentUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to manage favorites')),
      );
      return;
    }

    try {
      final isFavorite = _favoriteSymbols.contains(symbol);

      if (isFavorite) {
        await _stockService.removeFromFavorites(_currentUserId, symbol);
        setState(() {
          _favoriteSymbols.remove(symbol);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Removed $symbol from favorites')),
        );
      } else {
        await _stockService.addToFavorites(_currentUserId, symbol);
        setState(() {
          _favoriteSymbols.add(symbol);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added $symbol to favorites')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Prices'),
        actions: [
          if (_mainStocks.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_mainStocks.length}',
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ),
          EnvironmentSwitcher(onEnvironmentChanged: _loadMainStocks),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showDebugInfo,
            tooltip: 'Debug Info',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search stocks (e.g., AAPL, Tesla)...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchStocks('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _searchStocks,
            ),
          ),

          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_searchController.text.isNotEmpty) {
      return _buildSearchResults();
    }

    if (_isLoading && _mainStocks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _mainStocks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMainStocks,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_mainStocks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No stocks available', style: TextStyle(fontSize: 18)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMainStocks,
      child: _buildStockList(),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No search results', style: TextStyle(fontSize: 18)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        final isFavorite = _favoriteSymbols.contains(result.symbol);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(AppConfig.primaryBlue),
              child: Text(
                result.symbol.substring(0, result.symbol.length > 2 ? 2 : 1),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            title: Text(
              result.symbol,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.name),
                Text(
                  '${result.exchange} • ${result.type}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : Colors.grey,
              ),
              onPressed: () => _toggleFavorite(result.symbol),
            ),
            onTap: () => _showStockDetails(result.symbol),
          ),
        );
      },
    );
  }

  Widget _buildStockList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _mainStocks.length,
      itemBuilder: (context, index) {
        final stock = _mainStocks[index];
        return _buildStockCard(stock);
      },
    );
  }

  Widget _buildStockCard(Stock stock) {
    final isFavorite = _favoriteSymbols.contains(stock.symbol);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(AppConfig.primaryBlue),
          child: Text(
            stock.symbol.substring(0, stock.symbol.length > 2 ? 2 : 1),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          stock.symbol,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(stock.name),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              stock.formattedPrice,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              '${stock.formattedChange} (${stock.formattedChangePercent})',
              style: TextStyle(
                color: stock.isPositiveChange ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        onTap: () {
          // TODO: Navigate to stock details
        },
      ),
    );
  }

  Color _getMarketStatusColor() {
    // This would typically check the actual market status
    final now = DateTime.now();
    final isWeekend =
        now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
    final hour = now.hour;

    if (isWeekend || hour < 9 || hour >= 16) {
      return Colors.red; // Market closed
    } else {
      return Colors.green; // Market open
    }
  }

  String _getMarketStatusText() {
    final now = DateTime.now();
    final isWeekend =
        now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
    final hour = now.hour;

    if (isWeekend) {
      return 'Market Closed (Weekend)';
    } else if (hour < 9) {
      return 'Market Closed (Pre-market)';
    } else if (hour >= 16) {
      return 'Market Closed (After-hours)';
    } else {
      return 'Market Open';
    }
  }

  String _getLastUpdatedText() {
    if (_mainStocks.isEmpty) return 'Never';

    final lastUpdated = _mainStocks.first.lastUpdated;
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _showStockDetails(String symbol) {
    // Navigate to detailed stock view
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StockDetailsScreen(
          symbol: symbol,
          firebaseEnabled: widget.firebaseEnabled,
        ),
      ),
    );
  }

  void _showDebugInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Environment: ${AppConfig.environmentName}'),
              Text('API URL: ${AppConfig.apiBaseUrl}'),
              if (AppConfig.isLocal)
                Text('IP Config: ${AppConfig.currentIpConfig}'),
              const SizedBox(height: 16),
              if (_connectivityInfo != null) ...[
                const Text(
                  'Connectivity Test:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Success: ${_connectivityInfo!['success']}'),
                if (_connectivityInfo!['responseTime'] != null)
                  Text('Response Time: ${_connectivityInfo!['responseTime']}'),
                if (_connectivityInfo!['error'] != null)
                  Text('Error: ${_connectivityInfo!['error']}'),
                if (_connectivityInfo!['serverStatus'] != null)
                  Text('Server Status: ${_connectivityInfo!['serverStatus']}'),
              ],
              const SizedBox(height: 16),
              Text('Stocks Loaded: ${_mainStocks.length}'),
              Text('Favorites: ${_favoriteSymbols.length}'),
              Text(
                  'User ID: ${_currentUserId.isNotEmpty ? _currentUserId : 'Not signed in'}'),
              if (_error != null) Text('Last Error: $_error'),
            ],
          ),
        ),
        actions: [
          if (AppConfig.isLocal)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _switchIpAndRetry();
              },
              child: Text(
                AppConfig.useAlternativeLocalIp
                    ? 'Use 10.0.2.2'
                    : 'Use Direct IP',
              ),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _loadMainStocks();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _switchIpAndRetry() {
    if (AppConfig.useAlternativeLocalIp) {
      AppConfig.switchToStandardIp();
      print('🔄 Switched to standard emulator IP (10.0.2.2)');
    } else {
      AppConfig.switchToAlternativeIp();
      print('🔄 Switched to direct IP (192.168.1.137)');
    }
    _loadMainStocks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Placeholder screens for navigation
class StockDetailsScreen extends StatelessWidget {
  const StockDetailsScreen({
    super.key,
    required this.symbol,
    required this.firebaseEnabled,
  });

  final String symbol;
  final bool firebaseEnabled;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$symbol Details'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Stock Details for $symbol',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Detailed view coming soon...'),
          ],
        ),
      ),
    );
  }
}

class StockChartScreen extends StatelessWidget {
  const StockChartScreen({super.key, required this.stock});

  final Stock stock;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${stock.symbol} Chart'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Full Chart for ${stock.symbol}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Full-screen chart coming soon...'),
          ],
        ),
      ),
    );
  }
}
