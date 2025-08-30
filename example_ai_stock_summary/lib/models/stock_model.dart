class StockModel {
  final String id;
  final String symbol;
  final String name;
  final String exchange;
  final String? sector;
  final String? industry;
  final double? marketCap;
  final String? description;
  final String? websiteUrl;
  final String? logoUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Current price data (from stock_prices table)
  final double? currentPrice;
  final double? openPrice;
  final double? highPrice;
  final double? lowPrice;
  final double? previousClose;
  final int? volume;
  final double? peRatio;
  final double? eps;
  final double? dividendYield;
  final double? fiftyTwoWeekHigh;
  final double? fiftyTwoWeekLow;

  StockModel({
    required this.id,
    required this.symbol,
    required this.name,
    required this.exchange,
    this.sector,
    this.industry,
    this.marketCap,
    this.description,
    this.websiteUrl,
    this.logoUrl,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.currentPrice,
    this.openPrice,
    this.highPrice,
    this.lowPrice,
    this.previousClose,
    this.volume,
    this.peRatio,
    this.eps,
    this.dividendYield,
    this.fiftyTwoWeekHigh,
    this.fiftyTwoWeekLow,
  });

  factory StockModel.fromJson(Map<String, dynamic> json) {
    // Handle nested stock_prices data
    final priceData = json['stock_prices'] is List
        ? (json['stock_prices'] as List).isNotEmpty
            ? json['stock_prices'][0]
            : null
        : json['stock_prices'];

    return StockModel(
      id: json['id'],
      symbol: json['symbol'],
      name: json['name'],
      exchange: json['exchange'],
      sector: json['sector'],
      industry: json['industry'],
      marketCap: json['market_cap']?.toDouble(),
      description: json['description'],
      websiteUrl: json['website_url'],
      logoUrl: json['logo_url'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      currentPrice: priceData?['current_price']?.toDouble(),
      openPrice: priceData?['open_price']?.toDouble(),
      highPrice: priceData?['high_price']?.toDouble(),
      lowPrice: priceData?['low_price']?.toDouble(),
      previousClose: priceData?['previous_close']?.toDouble(),
      volume: priceData?['volume']?.toInt(),
      peRatio: priceData?['pe_ratio']?.toDouble(),
      eps: priceData?['eps']?.toDouble(),
      dividendYield: priceData?['dividend_yield']?.toDouble(),
      fiftyTwoWeekHigh: priceData?['fifty_two_week_high']?.toDouble(),
      fiftyTwoWeekLow: priceData?['fifty_two_week_low']?.toDouble(),
    );
  }

  factory StockModel.fromStockPrice(Map<String, dynamic> json) {
    final stockData = json['stocks'];

    return StockModel(
      id: stockData['id'],
      symbol: stockData['symbol'],
      name: stockData['name'],
      exchange: stockData['exchange'],
      sector: stockData['sector'],
      industry: stockData['industry'],
      marketCap: stockData['market_cap']?.toDouble(),
      description: stockData['description'],
      websiteUrl: stockData['website_url'],
      logoUrl: stockData['logo_url'],
      isActive: stockData['is_active'] ?? true,
      createdAt: DateTime.parse(stockData['created_at']),
      updatedAt: DateTime.parse(stockData['updated_at']),
      currentPrice: json['current_price']?.toDouble(),
      openPrice: json['open_price']?.toDouble(),
      highPrice: json['high_price']?.toDouble(),
      lowPrice: json['low_price']?.toDouble(),
      previousClose: json['previous_close']?.toDouble(),
      volume: json['volume']?.toInt(),
      peRatio: json['pe_ratio']?.toDouble(),
      eps: json['eps']?.toDouble(),
      dividendYield: json['dividend_yield']?.toDouble(),
      fiftyTwoWeekHigh: json['fifty_two_week_high']?.toDouble(),
      fiftyTwoWeekLow: json['fifty_two_week_low']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'name': name,
      'exchange': exchange,
      'sector': sector,
      'industry': industry,
      'market_cap': marketCap,
      'description': description,
      'website_url': websiteUrl,
      'logo_url': logoUrl,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Calculate price change
  double? get priceChange {
    if (currentPrice != null && previousClose != null) {
      return currentPrice! - previousClose!;
    }
    return null;
  }

  // Calculate price change percentage
  double? get priceChangePercentage {
    if (currentPrice != null && previousClose != null && previousClose! > 0) {
      return ((currentPrice! - previousClose!) / previousClose!) * 100;
    }
    return null;
  }

  // Check if price is up
  bool get isPriceUp {
    final change = priceChange;
    return change != null && change > 0;
  }

  // Check if price is down
  bool get isPriceDown {
    final change = priceChange;
    return change != null && change < 0;
  }

  StockModel copyWith({
    String? id,
    String? symbol,
    String? name,
    String? exchange,
    String? sector,
    String? industry,
    double? marketCap,
    String? description,
    String? websiteUrl,
    String? logoUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? currentPrice,
    double? openPrice,
    double? highPrice,
    double? lowPrice,
    double? previousClose,
    int? volume,
    double? peRatio,
    double? eps,
    double? dividendYield,
    double? fiftyTwoWeekHigh,
    double? fiftyTwoWeekLow,
  }) {
    return StockModel(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      exchange: exchange ?? this.exchange,
      sector: sector ?? this.sector,
      industry: industry ?? this.industry,
      marketCap: marketCap ?? this.marketCap,
      description: description ?? this.description,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      logoUrl: logoUrl ?? this.logoUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currentPrice: currentPrice ?? this.currentPrice,
      openPrice: openPrice ?? this.openPrice,
      highPrice: highPrice ?? this.highPrice,
      lowPrice: lowPrice ?? this.lowPrice,
      previousClose: previousClose ?? this.previousClose,
      volume: volume ?? this.volume,
      peRatio: peRatio ?? this.peRatio,
      eps: eps ?? this.eps,
      dividendYield: dividendYield ?? this.dividendYield,
      fiftyTwoWeekHigh: fiftyTwoWeekHigh ?? this.fiftyTwoWeekHigh,
      fiftyTwoWeekLow: fiftyTwoWeekLow ?? this.fiftyTwoWeekLow,
    );
  }
}
