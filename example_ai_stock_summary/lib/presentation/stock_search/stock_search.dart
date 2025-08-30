import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import './widgets/empty_search_widget.dart';
import './widgets/filter_bottom_sheet.dart';
import './widgets/popular_stocks_widget.dart';
import './widgets/recent_searches_widget.dart';
import './widgets/search_bar_widget.dart';
import './widgets/skeleton_loader_widget.dart';
import './widgets/stock_result_card.dart';

class StockSearch extends StatefulWidget {
  const StockSearch({super.key});

  @override
  State<StockSearch> createState() => _StockSearchState();
}

class _StockSearchState extends State<StockSearch> {
  final TextEditingController _searchController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  Timer? _debounceTimer;

  bool _isLoading = false;
  bool _isListening = false;
  bool _speechEnabled = false;
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _recentSearches = [];
  Map<String, dynamic> _currentFilters = {};

  // Mock data for popular stocks
  final List<Map<String, dynamic>> _popularStocks = [
    {
      "ticker": "AAPL",
      "companyName": "Apple Inc.",
      "price": 175.43,
      "change": 2.15,
      "changePercent": 1.24,
      "logo": "https://logo.clearbit.com/apple.com",
      "marketCap": "\$2.8T",
      "exchange": "NASDAQ",
      "chartData": [170.0, 172.5, 171.8, 174.2, 175.43],
    },
    {
      "ticker": "GOOGL",
      "companyName": "Alphabet Inc.",
      "price": 138.21,
      "change": -1.45,
      "changePercent": -1.04,
      "logo": "https://logo.clearbit.com/google.com",
      "marketCap": "\$1.7T",
      "exchange": "NASDAQ",
      "chartData": [140.0, 139.2, 138.8, 139.5, 138.21],
    },
    {
      "ticker": "MSFT",
      "companyName": "Microsoft Corporation",
      "price": 378.85,
      "change": 4.22,
      "changePercent": 1.13,
      "logo": "https://logo.clearbit.com/microsoft.com",
      "marketCap": "\$2.8T",
      "exchange": "NASDAQ",
      "chartData": [375.0, 376.8, 374.2, 377.1, 378.85],
    },
    {
      "ticker": "TSLA",
      "companyName": "Tesla, Inc.",
      "price": 248.50,
      "change": -3.75,
      "changePercent": -1.49,
      "logo": "https://logo.clearbit.com/tesla.com",
      "marketCap": "\$789B",
      "exchange": "NASDAQ",
      "chartData": [252.0, 250.5, 249.8, 251.2, 248.50],
    },
    {
      "ticker": "AMZN",
      "companyName": "Amazon.com, Inc.",
      "price": 145.86,
      "change": 1.92,
      "changePercent": 1.33,
      "logo": "https://logo.clearbit.com/amazon.com",
      "marketCap": "\$1.5T",
      "exchange": "NASDAQ",
      "chartData": [144.0, 145.2, 143.8, 144.9, 145.86],
    },
  ];

  // Mock search results data
  final List<Map<String, dynamic>> _allStocks = [
    {
      "ticker": "AAPL",
      "companyName": "Apple Inc.",
      "price": 175.43,
      "change": 2.15,
      "changePercent": 1.24,
      "logo": "https://logo.clearbit.com/apple.com",
      "marketCap": "\$2.8T",
      "exchange": "NASDAQ",
      "chartData": [170.0, 172.5, 171.8, 174.2, 175.43],
      "sector": "Technology",
    },
    {
      "ticker": "GOOGL",
      "companyName": "Alphabet Inc.",
      "price": 138.21,
      "change": -1.45,
      "changePercent": -1.04,
      "logo": "https://logo.clearbit.com/google.com",
      "marketCap": "\$1.7T",
      "exchange": "NASDAQ",
      "chartData": [140.0, 139.2, 138.8, 139.5, 138.21],
      "sector": "Technology",
    },
    {
      "ticker": "MSFT",
      "companyName": "Microsoft Corporation",
      "price": 378.85,
      "change": 4.22,
      "changePercent": 1.13,
      "logo": "https://logo.clearbit.com/microsoft.com",
      "marketCap": "\$2.8T",
      "exchange": "NASDAQ",
      "chartData": [375.0, 376.8, 374.2, 377.1, 378.85],
      "sector": "Technology",
    },
    {
      "ticker": "TSLA",
      "companyName": "Tesla, Inc.",
      "price": 248.50,
      "change": -3.75,
      "changePercent": -1.49,
      "logo": "https://logo.clearbit.com/tesla.com",
      "marketCap": "\$789B",
      "exchange": "NASDAQ",
      "chartData": [252.0, 250.5, 249.8, 251.2, 248.50],
      "sector": "Consumer Cyclical",
    },
    {
      "ticker": "AMZN",
      "companyName": "Amazon.com, Inc.",
      "price": 145.86,
      "change": 1.92,
      "changePercent": 1.33,
      "logo": "https://logo.clearbit.com/amazon.com",
      "marketCap": "\$1.5T",
      "exchange": "NASDAQ",
      "chartData": [144.0, 145.2, 143.8, 144.9, 145.86],
      "sector": "Consumer Cyclical",
    },
    {
      "ticker": "NVDA",
      "companyName": "NVIDIA Corporation",
      "price": 875.28,
      "change": 12.45,
      "changePercent": 1.44,
      "logo": "https://logo.clearbit.com/nvidia.com",
      "marketCap": "\$2.2T",
      "exchange": "NASDAQ",
      "chartData": [860.0, 865.5, 870.2, 872.8, 875.28],
      "sector": "Technology",
    },
    {
      "ticker": "META",
      "companyName": "Meta Platforms, Inc.",
      "price": 496.73,
      "change": -2.87,
      "changePercent": -0.57,
      "logo": "https://logo.clearbit.com/meta.com",
      "marketCap": "\$1.3T",
      "exchange": "NASDAQ",
      "chartData": [500.0, 498.5, 497.2, 499.1, 496.73],
      "sector": "Communication Services",
    },
    {
      "ticker": "JPM",
      "companyName": "JPMorgan Chase & Co.",
      "price": 178.92,
      "change": 1.23,
      "changePercent": 0.69,
      "logo": "https://logo.clearbit.com/jpmorganchase.com",
      "marketCap": "\$525B",
      "exchange": "NYSE",
      "chartData": [177.0, 178.2, 177.8, 179.1, 178.92],
      "sector": "Financial Services",
    },
  ];

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _initSpeech() async {
    _speechEnabled = await _speech.initialize();
    setState(() {});
  }

  void _loadRecentSearches() {
    // Mock recent searches - in real app, load from SharedPreferences
    _recentSearches = [
      {
        "ticker": "AAPL",
        "companyName": "Apple Inc.",
        "price": 175.43,
        "logo": "https://logo.clearbit.com/apple.com",
      },
      {
        "ticker": "GOOGL",
        "companyName": "Alphabet Inc.",
        "price": 138.21,
        "logo": "https://logo.clearbit.com/google.com",
      },
    ];
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _performSearch(query);
      } else {
        setState(() {
          _searchResults.clear();
          _isLoading = false;
        });
      }
    });
  }

  void _performSearch(String query) async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Filter stocks based on search query and current filters
    List<Map<String, dynamic>> results = _allStocks.where((stock) {
      final matchesQuery = (stock['ticker'] as String)
              .toLowerCase()
              .contains(query.toLowerCase()) ||
          (stock['companyName'] as String)
              .toLowerCase()
              .contains(query.toLowerCase());

      if (!matchesQuery) return false;

      // Apply filters
      if (_currentFilters.isNotEmpty) {
        final price = stock['price'] as double;
        final minPrice = (_currentFilters['minPrice'] as double?) ?? 0;
        final maxPrice =
            (_currentFilters['maxPrice'] as double?) ?? double.infinity;

        if (price < minPrice || price > maxPrice) return false;

        final marketCap = _currentFilters['marketCap'] as String?;
        if (marketCap != null && marketCap != 'All') {
          // In real app, implement market cap filtering logic
        }

        final sector = _currentFilters['sector'] as String?;
        if (sector != null && sector != 'All') {
          if (stock['sector'] != sector) return false;
        }
      }

      return true;
    }).toList();

    setState(() {
      _searchResults = results;
      _isLoading = false;
    });
  }

  void _startListening() async {
    if (!_speechEnabled) return;

    await _speech.listen(
      onResult: (result) {
        setState(() {
          _searchController.text = result.recognizedWords;
          _onSearchChanged(result.recognizedWords);
        });
      },
    );
    setState(() {
      _isListening = true;
    });
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _onVoiceSearch() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        currentFilters: _currentFilters,
        onApplyFilters: (filters) {
          setState(() {
            _currentFilters = filters;
          });
          if (_searchController.text.isNotEmpty) {
            _performSearch(_searchController.text);
          }
        },
      ),
    );
  }

  void _onStockTap(Map<String, dynamic> stock) {
    // Add to recent searches
    _recentSearches.removeWhere((item) => item['ticker'] == stock['ticker']);
    _recentSearches.insert(0, {
      'ticker': stock['ticker'],
      'companyName': stock['companyName'],
      'price': stock['price'],
      'logo': stock['logo'],
    });

    // Keep only last 10 searches
    if (_recentSearches.length > 10) {
      _recentSearches = _recentSearches.take(10).toList();
    }

    // Navigate to stock detail
    Navigator.pushNamed(context, '/stock-detail', arguments: stock);
  }

  void _removeRecentSearch(String ticker) {
    setState(() {
      _recentSearches.removeWhere((item) => item['ticker'] == ticker);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: Column(
        children: [
          SearchBarWidget(
            controller: _searchController,
            onChanged: _onSearchChanged,
            onVoiceSearch: _onVoiceSearch,
            onFilter: _showFilterBottomSheet,
            isLoading: _isLoading,
          ),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_searchController.text.isEmpty) {
      return SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 2.h),
            RecentSearchesWidget(
              recentSearches: _recentSearches,
              onStockTap: _onStockTap,
              onRemoveSearch: _removeRecentSearch,
            ),
            SizedBox(height: 2.h),
            PopularStocksWidget(
              popularStocks: _popularStocks,
              onStockTap: _onStockTap,
            ),
            SizedBox(height: 2.h),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const SkeletonLoaderWidget();
    }

    if (_searchResults.isEmpty) {
      return EmptySearchWidget(searchQuery: _searchController.text);
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final stock = _searchResults[index];
        return StockResultCard(
          stock: stock,
          onTap: () => _onStockTap(stock),
        );
      },
    );
  }
}
