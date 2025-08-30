import './stock_model.dart';

class HoldingModel {
  final String id;
  final String portfolioId;
  final String stockId;
  final double quantity;
  final double averageCost;
  final double? currentValue;
  final double? totalGainLoss;
  final double? gainLossPercentage;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Stock info
  final StockModel? stock;

  HoldingModel({
    required this.id,
    required this.portfolioId,
    required this.stockId,
    required this.quantity,
    required this.averageCost,
    this.currentValue,
    this.totalGainLoss,
    this.gainLossPercentage,
    required this.createdAt,
    required this.updatedAt,
    this.stock,
  });

  factory HoldingModel.fromJson(Map<String, dynamic> json) {
    StockModel? stock;
    if (json['stocks'] != null) {
      stock = StockModel.fromJson(json['stocks']);
    }

    return HoldingModel(
      id: json['id'],
      portfolioId: json['portfolio_id'],
      stockId: json['stock_id'],
      quantity: json['quantity'].toDouble(),
      averageCost: json['average_cost'].toDouble(),
      currentValue: json['current_value']?.toDouble(),
      totalGainLoss: json['total_gain_loss']?.toDouble(),
      gainLossPercentage: json['gain_loss_percentage']?.toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      stock: stock,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'portfolio_id': portfolioId,
      'stock_id': stockId,
      'quantity': quantity,
      'average_cost': averageCost,
      'current_value': currentValue,
      'total_gain_loss': totalGainLoss,
      'gain_loss_percentage': gainLossPercentage,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Calculate total cost basis
  double get totalCost => quantity * averageCost;

  // Calculate current market value
  double get marketValue {
    if (stock?.currentPrice != null) {
      return quantity * stock!.currentPrice!;
    }
    return currentValue ?? totalCost;
  }

  // Calculate gain/loss
  double get gainLoss => marketValue - totalCost;

  // Calculate gain/loss percentage
  double get gainLossPercent {
    if (totalCost > 0) {
      return (gainLoss / totalCost) * 100;
    }
    return 0.0;
  }

  // Check if holding is profitable
  bool get isProfitable => gainLoss > 0;

  // Check if holding is losing
  bool get isLosing => gainLoss < 0;

  // Get stock symbol
  String get symbol => stock?.symbol ?? 'N/A';

  // Get stock name
  String get name => stock?.name ?? 'Unknown';

  // Get current price
  double? get currentPrice => stock?.currentPrice;

  // Get price change for the day
  double? get dayChange => stock?.priceChange;

  // Get price change percentage for the day
  double? get dayChangePercent => stock?.priceChangePercentage;

  HoldingModel copyWith({
    String? id,
    String? portfolioId,
    String? stockId,
    double? quantity,
    double? averageCost,
    double? currentValue,
    double? totalGainLoss,
    double? gainLossPercentage,
    DateTime? createdAt,
    DateTime? updatedAt,
    StockModel? stock,
  }) {
    return HoldingModel(
      id: id ?? this.id,
      portfolioId: portfolioId ?? this.portfolioId,
      stockId: stockId ?? this.stockId,
      quantity: quantity ?? this.quantity,
      averageCost: averageCost ?? this.averageCost,
      currentValue: currentValue ?? this.currentValue,
      totalGainLoss: totalGainLoss ?? this.totalGainLoss,
      gainLossPercentage: gainLossPercentage ?? this.gainLossPercentage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      stock: stock ?? this.stock,
    );
  }
}
