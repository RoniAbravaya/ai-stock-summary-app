class MarketInsightModel {
  final String id;
  final String title;
  final String description;
  final String insightType;
  final String? iconName;
  final String? colorHex;
  final List<String>? stockSymbols;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  MarketInsightModel({
    required this.id,
    required this.title,
    required this.description,
    required this.insightType,
    this.iconName,
    this.colorHex,
    this.stockSymbols,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MarketInsightModel.fromJson(Map<String, dynamic> json) {
    List<String>? stockSymbols;
    if (json['stock_symbols'] != null) {
      if (json['stock_symbols'] is List) {
        stockSymbols = List<String>.from(json['stock_symbols']);
      }
    }

    return MarketInsightModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      insightType: json['insight_type'],
      iconName: json['icon_name'],
      colorHex: json['color_hex'],
      stockSymbols: stockSymbols,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'insight_type': insightType,
      'icon_name': iconName,
      'color_hex': colorHex,
      'stock_symbols': stockSymbols,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Get insight type display name
  String get typeDisplayName {
    switch (insightType) {
      case 'price_movement':
        return 'Price Movement';
      case 'ai_analysis':
        return 'AI Analysis';
      case 'alerts':
        return 'Alerts';
      case 'market_news':
        return 'Market News';
      case 'volume_analysis':
        return 'Volume Analysis';
      default:
        return 'Market Insight';
    }
  }

  // Get default icon if not specified
  String get displayIcon {
    return iconName ?? _getDefaultIcon();
  }

  String _getDefaultIcon() {
    switch (insightType) {
      case 'price_movement':
        return 'trending_up';
      case 'ai_analysis':
        return 'psychology';
      case 'alerts':
        return 'notifications_active';
      case 'market_news':
        return 'article';
      case 'volume_analysis':
        return 'bar_chart';
      default:
        return 'insights';
    }
  }

  // Get default color if not specified
  String get displayColor {
    return colorHex ?? _getDefaultColor();
  }

  String _getDefaultColor() {
    switch (insightType) {
      case 'price_movement':
        return '#10B981'; // Green
      case 'ai_analysis':
        return '#4A90E2'; // Blue
      case 'alerts':
        return '#FF6B35'; // Orange
      case 'market_news':
        return '#8B5CF6'; // Purple
      case 'volume_analysis':
        return '#F59E0B'; // Amber
      default:
        return '#6B7280'; // Gray
    }
  }

  // Get stocks count
  int get stocksCount => stockSymbols?.length ?? 0;

  // Check if insight is recent (within 24 hours)
  bool get isRecent {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inHours < 24;
  }

  MarketInsightModel copyWith({
    String? id,
    String? title,
    String? description,
    String? insightType,
    String? iconName,
    String? colorHex,
    List<String>? stockSymbols,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MarketInsightModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      insightType: insightType ?? this.insightType,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      stockSymbols: stockSymbols ?? this.stockSymbols,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
