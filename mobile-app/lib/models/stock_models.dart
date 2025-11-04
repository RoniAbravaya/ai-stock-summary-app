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
    // Parse date from multiple possible shapes
    DateTime parsedDate;
    final dynamic rawTimestamp = json['date_utc'] ?? json['timestamp'];
    if (rawTimestamp is num) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(rawTimestamp.toInt() * 1000);
    } else if (json['date'] is String) {
      // ISO string like 2025-07-26
      parsedDate = DateTime.tryParse(json['date'] as String) ?? DateTime.fromMillisecondsSinceEpoch(0);
    } else {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(0);
    }

    double toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0;
      return 0;
    }

    return ChartDataPoint(
      date: parsedDate,
      open: toDouble(json['open'] ?? json['o']),
      high: toDouble(json['high'] ?? json['h']),
      low: toDouble(json['low'] ?? json['l']),
      close: toDouble(json['close'] ?? json['c'] ?? json['adjClose'] ?? json['Close'] ?? json['price']),
      volume: (json['volume'] is String)
          ? (int.tryParse(json['volume']) ?? 0)
          : (json['volume'] as int? ?? 0),
    );
  }
}

class StockProfile {
  final String? companyName;
  final String? sector;
  final String? industry;
  final double? marketCap;
  final double? fiftyTwoWeekHigh;
  final double? fiftyTwoWeekLow;
  final String? exchange;
  final String? exchangeTimezone;
  final String? country;
  final String? website;
  final String? longBusinessSummary;

  const StockProfile({
    this.companyName,
    this.sector,
    this.industry,
    this.marketCap,
    this.fiftyTwoWeekHigh,
    this.fiftyTwoWeekLow,
    this.exchange,
    this.exchangeTimezone,
    this.country,
    this.website,
    this.longBusinessSummary,
  });

  factory StockProfile.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return StockProfile(
      companyName: json['companyName']?.toString(),
      sector: json['sector']?.toString(),
      industry: json['industry']?.toString(),
      marketCap: toDouble(json['marketCap']),
      fiftyTwoWeekHigh: toDouble(json['fiftyTwoWeekHigh']),
      fiftyTwoWeekLow: toDouble(json['fiftyTwoWeekLow']),
      exchange: json['exchange']?.toString(),
      exchangeTimezone: json['exchangeTimezone']?.toString(),
      country: json['country']?.toString(),
      website: json['website']?.toString(),
      longBusinessSummary: json['longBusinessSummary']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'companyName': companyName,
      'sector': sector,
      'industry': industry,
      'marketCap': marketCap,
      'fiftyTwoWeekHigh': fiftyTwoWeekHigh,
      'fiftyTwoWeekLow': fiftyTwoWeekLow,
      'exchange': exchange,
      'exchangeTimezone': exchangeTimezone,
      'country': country,
      'website': website,
      'longBusinessSummary': longBusinessSummary,
    };
  }

  bool get hasWebsite => website != null && website!.isNotEmpty;
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
    final dataPoints = <ChartDataPoint>[];

    // Case 1: items is a map of timestamp -> OHLC
    final items = json['items'];
    if (items is Map<String, dynamic>) {
      items.forEach((timestamp, data) {
        if (data is Map<String, dynamic>) {
          dataPoints.add(ChartDataPoint.fromJson({
            ...data,
            'timestamp': int.tryParse(timestamp) ?? 0,
          }));
        }
      });
    }

    // Case 2: data is an array of OHLC rows
    if (dataPoints.isEmpty && json['data'] is List) {
      for (final row in (json['data'] as List)) {
        if (row is Map<String, dynamic>) {
          dataPoints.add(ChartDataPoint.fromJson(row));
        }
      }
    }

    // Case 3: body is an array of OHLC rows
    if (dataPoints.isEmpty && json['body'] is List) {
      for (final row in (json['body'] as List)) {
        if (row is Map<String, dynamic>) {
          dataPoints.add(ChartDataPoint.fromJson(row));
        }
      }
    }

    // Sort by date
    dataPoints.sort((a, b) => a.date.compareTo(b.date));

    // Meta fallbacks
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    final symbol = (meta['symbol'] ?? json['symbol'] ?? '').toString();
    final interval = (meta['dataGranularity'] ?? json['interval'] ?? '1d').toString();
    final range = (meta['range'] ?? json['range'] ?? '1mo').toString();

    return StockChart(
      symbol: symbol,
      interval: interval,
      range: range,
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
  final StockProfile? profile;

  Stock({
    required this.symbol,
    required this.name,
    required this.logo,
    this.quote,
    this.chart,
    required this.lastUpdated,
    this.profile,
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
      profile: json['profile'] is Map<String, dynamic>
          ? StockProfile.fromJson(json['profile'] as Map<String, dynamic>)
          : null,
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
        'profile': profile?.toJson(),
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
      ticker: (json['ticker'] ?? json['symbol'] ?? '').toString(),
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
