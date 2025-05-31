/// Mock Data Service for Flutter
/// Provides sample data when Firebase is unavailable
class MockDataService {
  static final MockDataService _instance = MockDataService._internal();
  factory MockDataService() => _instance;
  MockDataService._internal();

  // Mock user data
  Map<String, dynamic> get mockUser => {
    'email': 'demo@example.com',
    'displayName': 'Demo User',
    'photoURL': null,
    'role': 'user',
    'subscriptionType': 'free',
    'summariesUsed': 3,
    'summariesLimit': 10,
    'lastResetDate': DateTime.now().subtract(const Duration(days: 5)),
    'createdAt': DateTime.now().subtract(const Duration(days: 30)),
    'updatedAt': DateTime.now(),
  };

  // Mock stocks data
  List<Map<String, dynamic>> get mockStocks => [
    {'symbol': 'AAPL', 'name': 'Apple Inc.', 'price': 175.43, 'change': 2.15},
    {
      'symbol': 'GOOGL',
      'name': 'Alphabet Inc.',
      'price': 2847.52,
      'change': -1.23,
    },
    {
      'symbol': 'MSFT',
      'name': 'Microsoft Corporation',
      'price': 378.85,
      'change': 0.87,
    },
    {'symbol': 'TSLA', 'name': 'Tesla, Inc.', 'price': 248.42, 'change': -3.45},
    {
      'symbol': 'AMZN',
      'name': 'Amazon.com, Inc.',
      'price': 3127.78,
      'change': 1.92,
    },
    {
      'symbol': 'META',
      'name': 'Meta Platforms, Inc.',
      'price': 487.33,
      'change': 4.21,
    },
  ];

  // Mock news data
  List<Map<String, dynamic>> get mockNews => [
    {
      'title': 'Tech Stocks Rally Amid Strong Earnings Reports',
      'description':
          'Major technology companies continue to show strong performance in the latest quarterly earnings, driving market optimism.',
      'source': 'Financial Times',
      'publishedAt': DateTime.now().subtract(const Duration(hours: 2)),
    },
    {
      'title': 'Federal Reserve Signals Continued Interest Rate Stability',
      'description':
          'The Fed maintains its current monetary policy stance, providing clarity for investors and markets.',
      'source': 'Reuters',
      'publishedAt': DateTime.now().subtract(const Duration(hours: 4)),
    },
    {
      'title': 'Electric Vehicle Market Sees Major Growth',
      'description':
          'EV adoption rates continue to accelerate globally, with new models and charging infrastructure driving expansion.',
      'source': 'Bloomberg',
      'publishedAt': DateTime.now().subtract(const Duration(hours: 6)),
    },
    {
      'title': 'AI Companies Lead Innovation in Q4',
      'description':
          'Artificial intelligence firms demonstrate significant technological breakthroughs and market expansion.',
      'source': 'TechCrunch',
      'publishedAt': DateTime.now().subtract(const Duration(hours: 8)),
    },
    {
      'title': 'Renewable Energy Investments Reach Record High',
      'description':
          'Global investment in renewable energy technologies hits unprecedented levels, signaling shift toward sustainability.',
      'source': 'Energy Weekly',
      'publishedAt': DateTime.now().subtract(const Duration(hours: 12)),
    },
  ];

  // Mock favorite stocks
  List<Map<String, dynamic>> get mockFavorites => [
    {
      'stockId': 'AAPL',
      'addedAt': DateTime.now().subtract(const Duration(days: 3)),
    },
    {
      'stockId': 'TSLA',
      'addedAt': DateTime.now().subtract(const Duration(days: 7)),
    },
  ];

  // Mock AI summaries
  Map<String, Map<String, dynamic>> get mockSummaries => {
    'AAPL': {
      'content':
          'Apple Inc. shows strong fundamentals with consistent revenue growth and innovative product pipeline. Recent iPhone sales exceed expectations, while services revenue continues to expand. The company maintains solid cash flow and strong market position in premium technology segments.',
      'generatedAt': DateTime.now().subtract(const Duration(hours: 6)),
      'language': 'en',
    },
    'TSLA': {
      'content':
          'Tesla demonstrates robust performance in electric vehicle market with expanding global production capacity. Strong delivery numbers and innovative autonomous driving technology development position the company well for future growth. Energy storage business shows promising expansion.',
      'generatedAt': DateTime.now().subtract(const Duration(hours: 8)),
      'language': 'en',
    },
  };

  // Mock usage statistics
  Map<String, dynamic> get mockUsageStats => {
    'summariesGenerated': 3,
    'rewardAdsWatched': 1,
    'loginStreak': 5,
    'favoriteStocks': 2,
    'lastActivity': DateTime.now().subtract(const Duration(hours: 2)),
  };

  // Simulate async operations
  Future<List<Map<String, dynamic>>> getStocks() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return mockStocks;
  }

  Future<List<Map<String, dynamic>>> getNews() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return mockNews;
  }

  Future<List<Map<String, dynamic>>> getFavorites() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return mockFavorites;
  }

  Future<Map<String, dynamic>?> getSummary(String stockId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return mockSummaries[stockId];
  }

  Future<Map<String, dynamic>> getUserData() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return mockUser;
  }

  Future<Map<String, dynamic>> getUsageStats() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return mockUsageStats;
  }
}
