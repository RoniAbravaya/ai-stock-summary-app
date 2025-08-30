class PriceAlertModel {
  final String id;
  final String userId;
  final String stockId;
  final String alertType;
  final double targetPrice;
  final bool isTriggered;
  final bool isActive;
  final DateTime? triggeredAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Stock info
  final String? stockSymbol;
  final String? stockName;
  final double? currentPrice;

  PriceAlertModel({
    required this.id,
    required this.userId,
    required this.stockId,
    required this.alertType,
    required this.targetPrice,
    required this.isTriggered,
    required this.isActive,
    this.triggeredAt,
    required this.createdAt,
    required this.updatedAt,
    this.stockSymbol,
    this.stockName,
    this.currentPrice,
  });

  factory PriceAlertModel.fromJson(Map<String, dynamic> json) {
    final stockData = json['stocks'];
    final priceData = stockData?['stock_prices'];

    double? currentPrice;
    if (priceData is List && priceData.isNotEmpty) {
      currentPrice = priceData[0]['current_price']?.toDouble();
    } else if (priceData != null) {
      currentPrice = priceData['current_price']?.toDouble();
    }

    return PriceAlertModel(
      id: json['id'],
      userId: json['user_id'],
      stockId: json['stock_id'],
      alertType: json['alert_type'],
      targetPrice: json['target_price'].toDouble(),
      isTriggered: json['is_triggered'] ?? false,
      isActive: json['is_active'] ?? true,
      triggeredAt: json['triggered_at'] != null
          ? DateTime.parse(json['triggered_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      stockSymbol: stockData?['symbol'],
      stockName: stockData?['name'],
      currentPrice: currentPrice,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'stock_id': stockId,
      'alert_type': alertType,
      'target_price': targetPrice,
      'is_triggered': isTriggered,
      'is_active': isActive,
      'triggered_at': triggeredAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Get alert type display name
  String get alertTypeDisplayName {
    switch (alertType) {
      case 'price_above':
        return 'Price Above';
      case 'price_below':
        return 'Price Below';
      case 'volume_spike':
        return 'Volume Spike';
      case 'news_alert':
        return 'News Alert';
      default:
        return 'Price Alert';
    }
  }

  // Get alert icon
  String get alertIcon {
    switch (alertType) {
      case 'price_above':
        return 'trending_up';
      case 'price_below':
        return 'trending_down';
      case 'volume_spike':
        return 'bar_chart';
      case 'news_alert':
        return 'article';
      default:
        return 'notifications';
    }
  }

  // Get status display
  String get statusDisplay {
    if (!isActive) return 'Inactive';
    if (isTriggered) return 'Triggered';
    return 'Active';
  }

  // Get status color
  String get statusColor {
    if (!isActive) return '#6B7280'; // Gray
    if (isTriggered) return '#EF4444'; // Red
    return '#10B981'; // Green
  }

  // Check if alert should trigger based on current price
  bool shouldTrigger(double currentStockPrice) {
    if (!isActive || isTriggered) return false;

    switch (alertType) {
      case 'price_above':
        return currentStockPrice >= targetPrice;
      case 'price_below':
        return currentStockPrice <= targetPrice;
      default:
        return false;
    }
  }

  // Get distance to target price
  double? get distanceToTarget {
    if (currentPrice == null) return null;

    switch (alertType) {
      case 'price_above':
        return targetPrice - currentPrice!;
      case 'price_below':
        return currentPrice! - targetPrice;
      default:
        return null;
    }
  }

  // Get distance percentage
  double? get distancePercentage {
    if (currentPrice == null || currentPrice == 0) return null;

    final distance = distanceToTarget;
    if (distance == null) return null;

    return (distance / currentPrice!) * 100;
  }

  PriceAlertModel copyWith({
    String? id,
    String? userId,
    String? stockId,
    String? alertType,
    double? targetPrice,
    bool? isTriggered,
    bool? isActive,
    DateTime? triggeredAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? stockSymbol,
    String? stockName,
    double? currentPrice,
  }) {
    return PriceAlertModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      stockId: stockId ?? this.stockId,
      alertType: alertType ?? this.alertType,
      targetPrice: targetPrice ?? this.targetPrice,
      isTriggered: isTriggered ?? this.isTriggered,
      isActive: isActive ?? this.isActive,
      triggeredAt: triggeredAt ?? this.triggeredAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      stockSymbol: stockSymbol ?? this.stockSymbol,
      stockName: stockName ?? this.stockName,
      currentPrice: currentPrice ?? this.currentPrice,
    );
  }
}
