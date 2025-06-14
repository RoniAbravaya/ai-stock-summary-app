class StockQuote {
  final String symbol;
  final String shortName;
  final String longName;
  final double regularMarketPrice;
  final double regularMarketChange;
  final double regularMarketChangePercent;
  final String currency;
  final String marketState;
  final int regularMarketTime;
  final double? regularMarketDayHigh;
  final double? regularMarketDayLow;
  final int? regularMarketVolume;
  final int? marketCap;
  final double? fiftyTwoWeekHigh;
  final double? fiftyTwoWeekLow;
  final double? trailingPE;
  final double? dividendYield;

  StockQuote({
    required this.symbol,
    required this.shortName,
    required this.longName,
    required this.regularMarketPrice,
    required this.regularMarketChange,
    required this.regularMarketChangePercent,
    required this.currency,
    required this.marketState,
    required this.regularMarketTime,
    this.regularMarketDayHigh,
    this.regularMarketDayLow,
    this.regularMarketVolume,
    this.marketCap,
    this.fiftyTwoWeekHigh,
    this.fiftyTwoWeekLow,
    this.trailingPE,
    this.dividendYield,
  });

  factory StockQuote.fromJson(Map<String, dynamic> json) {
    return StockQuote(
      symbol: json['symbol'] ?? '',
      shortName: json['shortName'] ?? json['name'] ?? '',
      longName: json['longName'] ?? json['name'] ?? '',
      regularMarketPrice: (json['regularMarketPrice'] ?? 0).toDouble(),
      regularMarketChange: (json['regularMarketChange'] ?? 0).toDouble(),
      regularMarketChangePercent:
          (json['regularMarketChangePercent'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'USD',
      marketState: json['marketState'] ?? 'CLOSED',
      regularMarketTime: json['regularMarketTime'] ?? 0,
      regularMarketDayHigh: json['regularMarketDayHigh']?.toDouble(),
      regularMarketDayLow: json['regularMarketDayLow']?.toDouble(),
      regularMarketVolume: json['regularMarketVolume'],
      marketCap: json['marketCap'],
      fiftyTwoWeekHigh: json['fiftyTwoWeekHigh']?.toDouble(),
      fiftyTwoWeekLow: json['fiftyTwoWeekLow']?.toDouble(),
      trailingPE: json['trailingPE']?.toDouble(),
      dividendYield: json['dividendYield']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'shortName': shortName,
      'longName': longName,
      'regularMarketPrice': regularMarketPrice,
      'regularMarketChange': regularMarketChange,
      'regularMarketChangePercent': regularMarketChangePercent,
      'currency': currency,
      'marketState': marketState,
      'regularMarketTime': regularMarketTime,
      'regularMarketDayHigh': regularMarketDayHigh,
      'regularMarketDayLow': regularMarketDayLow,
      'regularMarketVolume': regularMarketVolume,
      'marketCap': marketCap,
      'fiftyTwoWeekHigh': fiftyTwoWeekHigh,
      'fiftyTwoWeekLow': fiftyTwoWeekLow,
      'trailingPE': trailingPE,
      'dividendYield': dividendYield,
    };
  }

  bool get isPositiveChange => regularMarketChange >= 0;

  String get formattedPrice => '\$${regularMarketPrice.toStringAsFixed(2)}';

  String get formattedChange =>
      '${isPositiveChange ? '+' : ''}\$${regularMarketChange.toStringAsFixed(2)}';

  String get formattedChangePercent =>
      '${isPositiveChange ? '+' : ''}${regularMarketChangePercent.toStringAsFixed(2)}%';
}

class ChartDataPoint {
  final DateTime date;
  final double open;
  final double high;
  final double low;
  final double close;
  final int volume;

  ChartDataPoint({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  factory ChartDataPoint.fromJson(Map<String, dynamic> json) {
    return ChartDataPoint(
      date: DateTime.fromMillisecondsSinceEpoch(
        (json['date_utc'] ?? json['timestamp'] ?? 0) * 1000,
      ),
      open: (json['open'] ?? 0).toDouble(),
      high: (json['high'] ?? 0).toDouble(),
      low: (json['low'] ?? 0).toDouble(),
      close: (json['close'] ?? 0).toDouble(),
      volume: json['volume'] ?? 0,
    );
  }
}

class StockChart {
  final String symbol;
  final String interval;
  final String range;
  final List<ChartDataPoint> dataPoints;
  final DateTime lastUpdated;

  StockChart({
    required this.symbol,
    required this.interval,
    required this.range,
    required this.dataPoints,
    required this.lastUpdated,
  });

  factory StockChart.fromJson(Map<String, dynamic> json) {
    final items = json['items'] as Map<String, dynamic>? ?? {};
    final dataPoints = <ChartDataPoint>[];

    items.forEach((timestamp, data) {
      if (data is Map<String, dynamic>) {
        dataPoints.add(ChartDataPoint.fromJson({
          ...data,
          'timestamp': int.tryParse(timestamp) ?? 0,
        }));
      }
    });

    // Sort by date
    dataPoints.sort((a, b) => a.date.compareTo(b.date));

    return StockChart(
      symbol: json['meta']?['symbol'] ?? '',
      interval: json['meta']?['dataGranularity'] ?? '1d',
      range: json['meta']?['range'] ?? '1mo',
      dataPoints: dataPoints,
      lastUpdated: DateTime.now(),
    );
  }

  double? get currentPrice =>
      dataPoints.isNotEmpty ? dataPoints.last.close : null;

  double? get previousPrice =>
      dataPoints.length > 1 ? dataPoints[dataPoints.length - 2].close : null;

  double? get priceChange {
    if (currentPrice == null || previousPrice == null) return null;
    return currentPrice! - previousPrice!;
  }

  double? get priceChangePercent {
    if (priceChange == null || previousPrice == null || previousPrice == 0)
      return null;
    return (priceChange! / previousPrice!) * 100;
  }
}

class Stock {
  final String symbol;
  final String name;
  final String logo;
  final StockQuote? quote;
  final StockChart? chart;
  final DateTime lastUpdated;

  Stock({
    required this.symbol,
    required this.name,
    required this.logo,
    this.quote,
    this.chart,
    required this.lastUpdated,
  });

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      logo: json['logo'] ?? '',
      quote: json['quote'] != null ? StockQuote.fromJson(json['quote']) : null,
      chart: json['chart'] != null ? StockChart.fromJson(json['chart']) : null,
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(
        json['lastUpdated'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'name': name,
      'logo': logo,
      'quote': quote?.toJson(),
      'chart': chart != null
          ? {
              'symbol': chart!.symbol,
              'interval': chart!.interval,
              'range': chart!.range,
              'dataPoints': chart!.dataPoints.length,
            }
          : null,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
    };
  }

  double? get currentPrice => quote?.regularMarketPrice ?? chart?.currentPrice;

  double? get priceChange => quote?.regularMarketChange ?? chart?.priceChange;

  double? get priceChangePercent =>
      quote?.regularMarketChangePercent ?? chart?.priceChangePercent;

  bool get isPositiveChange => (priceChange ?? 0) >= 0;

  String get formattedPrice =>
      currentPrice != null ? '\$${currentPrice!.toStringAsFixed(2)}' : 'N/A';

  String get formattedChange => priceChange != null
      ? '${isPositiveChange ? '+' : ''}\$${priceChange!.toStringAsFixed(2)}'
      : 'N/A';

  String get formattedChangePercent => priceChangePercent != null
      ? '${isPositiveChange ? '+' : ''}${priceChangePercent!.toStringAsFixed(2)}%'
      : 'N/A';
}

class StockSearchResult {
  final String symbol;
  final String name;
  final String exchange;
  final String type;

  StockSearchResult({
    required this.symbol,
    required this.name,
    required this.exchange,
    required this.type,
  });

  factory StockSearchResult.fromJson(Map<String, dynamic> json) {
    return StockSearchResult(
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? json['shortName'] ?? '',
      exchange: json['exch'] ?? json['exchange'] ?? '',
      type: json['type'] ?? json['typeDisp'] ?? '',
    );
  }
}

class StockFavorite {
  final String ticker;
  final DateTime addedAt;

  StockFavorite({
    required this.ticker,
    required this.addedAt,
  });

  factory StockFavorite.fromJson(Map<String, dynamic> json) {
    return StockFavorite(
      ticker: json['ticker'] ?? '',
      addedAt: DateTime.fromMillisecondsSinceEpoch(
        json['addedAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticker': ticker,
      'addedAt': addedAt.millisecondsSinceEpoch,
    };
  }
}
