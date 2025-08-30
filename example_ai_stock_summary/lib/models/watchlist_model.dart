import './stock_model.dart';

class WatchlistModel {
  final String id;
  final String watchlistId;
  final String stockId;
  final String? notes;
  final DateTime createdAt;

  // Stock info
  final StockModel? stock;

  WatchlistModel({
    required this.id,
    required this.watchlistId,
    required this.stockId,
    this.notes,
    required this.createdAt,
    this.stock,
  });

  factory WatchlistModel.fromJson(Map<String, dynamic> json) {
    StockModel? stock;
    if (json['stocks'] != null) {
      stock = StockModel.fromJson(json['stocks']);
    }

    return WatchlistModel(
      id: json['id'],
      watchlistId: json['watchlist_id'],
      stockId: json['stock_id'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      stock: stock,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'watchlist_id': watchlistId,
      'stock_id': stockId,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Get stock symbol
  String get symbol => stock?.symbol ?? 'N/A';

  // Get stock name
  String get name => stock?.name ?? 'Unknown';

  // Get current price
  double? get currentPrice => stock?.currentPrice;

  // Get price change
  double? get priceChange => stock?.priceChange;

  // Get price change percentage
  double? get priceChangePercentage => stock?.priceChangePercentage;

  // Check if price is up
  bool get isPriceUp => stock?.isPriceUp ?? false;

  // Check if price is down
  bool get isPriceDown => stock?.isPriceDown ?? false;

  // Get exchange
  String get exchange => stock?.exchange ?? '';

  // Get sector
  String? get sector => stock?.sector;

  // Get industry
  String? get industry => stock?.industry;

  // Get market cap
  double? get marketCap => stock?.marketCap;

  WatchlistModel copyWith({
    String? id,
    String? watchlistId,
    String? stockId,
    String? notes,
    DateTime? createdAt,
    StockModel? stock,
  }) {
    return WatchlistModel(
      id: id ?? this.id,
      watchlistId: watchlistId ?? this.watchlistId,
      stockId: stockId ?? this.stockId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      stock: stock ?? this.stock,
    );
  }
}
