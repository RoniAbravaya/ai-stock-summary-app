class StockPriceModel {
  final String id;
  final String stockId;
  final double currentPrice;
  final double? openPrice;
  final double? highPrice;
  final double? lowPrice;
  final double? previousClose;
  final int? volume;
  final double? marketCap;
  final double? peRatio;
  final double? eps;
  final double? dividendYield;
  final double? fiftyTwoWeekHigh;
  final double? fiftyTwoWeekLow;
  final DateTime priceDate;
  final DateTime createdAt;

  StockPriceModel({
    required this.id,
    required this.stockId,
    required this.currentPrice,
    this.openPrice,
    this.highPrice,
    this.lowPrice,
    this.previousClose,
    this.volume,
    this.marketCap,
    this.peRatio,
    this.eps,
    this.dividendYield,
    this.fiftyTwoWeekHigh,
    this.fiftyTwoWeekLow,
    required this.priceDate,
    required this.createdAt,
  });

  factory StockPriceModel.fromJson(Map<String, dynamic> json) {
    return StockPriceModel(
      id: json['id'],
      stockId: json['stock_id'],
      currentPrice: json['current_price'].toDouble(),
      openPrice: json['open_price']?.toDouble(),
      highPrice: json['high_price']?.toDouble(),
      lowPrice: json['low_price']?.toDouble(),
      previousClose: json['previous_close']?.toDouble(),
      volume: json['volume']?.toInt(),
      marketCap: json['market_cap']?.toDouble(),
      peRatio: json['pe_ratio']?.toDouble(),
      eps: json['eps']?.toDouble(),
      dividendYield: json['dividend_yield']?.toDouble(),
      fiftyTwoWeekHigh: json['fifty_two_week_high']?.toDouble(),
      fiftyTwoWeekLow: json['fifty_two_week_low']?.toDouble(),
      priceDate: DateTime.parse(json['price_date']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stock_id': stockId,
      'current_price': currentPrice,
      'open_price': openPrice,
      'high_price': highPrice,
      'low_price': lowPrice,
      'previous_close': previousClose,
      'volume': volume,
      'market_cap': marketCap,
      'pe_ratio': peRatio,
      'eps': eps,
      'dividend_yield': dividendYield,
      'fifty_two_week_high': fiftyTwoWeekHigh,
      'fifty_two_week_low': fiftyTwoWeekLow,
      'price_date': priceDate.toIso8601String().split('T')[0],
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Calculate price change from previous close
  double? get priceChange {
    if (previousClose != null) {
      return currentPrice - previousClose!;
    }
    return null;
  }

  // Calculate price change percentage from previous close
  double? get priceChangePercentage {
    if (previousClose != null && previousClose! > 0) {
      return ((currentPrice - previousClose!) / previousClose!) * 100;
    }
    return null;
  }

  // Calculate intraday change from open price
  double? get intradayChange {
    if (openPrice != null) {
      return currentPrice - openPrice!;
    }
    return null;
  }

  // Calculate intraday change percentage
  double? get intradayChangePercentage {
    if (openPrice != null && openPrice! > 0) {
      return ((currentPrice - openPrice!) / openPrice!) * 100;
    }
    return null;
  }

  // Check if price is up from previous close
  bool get isPriceUp {
    final change = priceChange;
    return change != null && change > 0;
  }

  // Check if price is down from previous close
  bool get isPriceDown {
    final change = priceChange;
    return change != null && change < 0;
  }

  // Calculate distance from 52-week high
  double? get distanceFromHigh {
    if (fiftyTwoWeekHigh != null) {
      return fiftyTwoWeekHigh! - currentPrice;
    }
    return null;
  }

  // Calculate distance from 52-week low
  double? get distanceFromLow {
    if (fiftyTwoWeekLow != null) {
      return currentPrice - fiftyTwoWeekLow!;
    }
    return null;
  }

  // Calculate percentage from 52-week high
  double? get percentageFromHigh {
    if (fiftyTwoWeekHigh != null && fiftyTwoWeekHigh! > 0) {
      return ((fiftyTwoWeekHigh! - currentPrice) / fiftyTwoWeekHigh!) * 100;
    }
    return null;
  }

  // Calculate percentage from 52-week low
  double? get percentageFromLow {
    if (fiftyTwoWeekLow != null && fiftyTwoWeekLow! > 0) {
      return ((currentPrice - fiftyTwoWeekLow!) / fiftyTwoWeekLow!) * 100;
    }
    return null;
  }

  StockPriceModel copyWith({
    String? id,
    String? stockId,
    double? currentPrice,
    double? openPrice,
    double? highPrice,
    double? lowPrice,
    double? previousClose,
    int? volume,
    double? marketCap,
    double? peRatio,
    double? eps,
    double? dividendYield,
    double? fiftyTwoWeekHigh,
    double? fiftyTwoWeekLow,
    DateTime? priceDate,
    DateTime? createdAt,
  }) {
    return StockPriceModel(
      id: id ?? this.id,
      stockId: stockId ?? this.stockId,
      currentPrice: currentPrice ?? this.currentPrice,
      openPrice: openPrice ?? this.openPrice,
      highPrice: highPrice ?? this.highPrice,
      lowPrice: lowPrice ?? this.lowPrice,
      previousClose: previousClose ?? this.previousClose,
      volume: volume ?? this.volume,
      marketCap: marketCap ?? this.marketCap,
      peRatio: peRatio ?? this.peRatio,
      eps: eps ?? this.eps,
      dividendYield: dividendYield ?? this.dividendYield,
      fiftyTwoWeekHigh: fiftyTwoWeekHigh ?? this.fiftyTwoWeekHigh,
      fiftyTwoWeekLow: fiftyTwoWeekLow ?? this.fiftyTwoWeekLow,
      priceDate: priceDate ?? this.priceDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
