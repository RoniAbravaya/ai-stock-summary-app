class PortfolioModel {
  final String id;
  final String userId;
  final String name;
  final String portfolioType;
  final double totalValue;
  final double totalGainLoss;
  final double totalGainLossPercentage;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  PortfolioModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.portfolioType,
    required this.totalValue,
    required this.totalGainLoss,
    required this.totalGainLossPercentage,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PortfolioModel.fromJson(Map<String, dynamic> json) {
    return PortfolioModel(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      portfolioType: json['portfolio_type'],
      totalValue: (json['total_value'] ?? 0.0).toDouble(),
      totalGainLoss: (json['total_gain_loss'] ?? 0.0).toDouble(),
      totalGainLossPercentage:
          (json['total_gain_loss_percentage'] ?? 0.0).toDouble(),
      isDefault: json['is_default'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'portfolio_type': portfolioType,
      'total_value': totalValue,
      'total_gain_loss': totalGainLoss,
      'total_gain_loss_percentage': totalGainLossPercentage,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Check if portfolio is profitable
  bool get isProfitable => totalGainLoss > 0;

  // Check if portfolio is losing
  bool get isLosing => totalGainLoss < 0;

  // Get formatted portfolio type
  String get formattedType {
    switch (portfolioType) {
      case 'individual':
        return 'Individual';
      case 'retirement':
        return 'Retirement';
      case 'business':
        return 'Business';
      default:
        return 'Individual';
    }
  }

  PortfolioModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? portfolioType,
    double? totalValue,
    double? totalGainLoss,
    double? totalGainLossPercentage,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PortfolioModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      portfolioType: portfolioType ?? this.portfolioType,
      totalValue: totalValue ?? this.totalValue,
      totalGainLoss: totalGainLoss ?? this.totalGainLoss,
      totalGainLossPercentage:
          totalGainLossPercentage ?? this.totalGainLossPercentage,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
