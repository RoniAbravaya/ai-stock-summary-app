class SubscriptionModel {
  final String id;
  final String userId;
  final String tier;
  final String status;
  final int monthlySummaryLimit;
  final int currentMonthUsage;
  final DateTime usageResetDate;
  final DateTime subscriptionStartDate;
  final DateTime? subscriptionEndDate;
  final bool autoRenew;
  final String? purchaseReceipt;
  final DateTime createdAt;
  final DateTime updatedAt;

  SubscriptionModel({
    required this.id,
    required this.userId,
    required this.tier,
    required this.status,
    required this.monthlySummaryLimit,
    required this.currentMonthUsage,
    required this.usageResetDate,
    required this.subscriptionStartDate,
    this.subscriptionEndDate,
    required this.autoRenew,
    this.purchaseReceipt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'],
      userId: json['user_id'],
      tier: json['tier'],
      status: json['status'],
      monthlySummaryLimit: json['monthly_summary_limit'],
      currentMonthUsage: json['current_month_usage'],
      usageResetDate: DateTime.parse(json['usage_reset_date']),
      subscriptionStartDate: DateTime.parse(json['subscription_start_date']),
      subscriptionEndDate: json['subscription_end_date'] != null
          ? DateTime.parse(json['subscription_end_date'])
          : null,
      autoRenew: json['auto_renew'] ?? false,
      purchaseReceipt: json['purchase_receipt'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'tier': tier,
      'status': status,
      'monthly_summary_limit': monthlySummaryLimit,
      'current_month_usage': currentMonthUsage,
      'usage_reset_date': usageResetDate.toIso8601String(),
      'subscription_start_date': subscriptionStartDate.toIso8601String(),
      'subscription_end_date': subscriptionEndDate?.toIso8601String(),
      'auto_renew': autoRenew,
      'purchase_receipt': purchaseReceipt,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper getters
  bool get isPremium => tier == 'premium';
  bool get isFree => tier == 'free';
  bool get isActive => status == 'active';
  bool get canGenerateSummary => currentMonthUsage < monthlySummaryLimit;

  int get remainingSummaries => monthlySummaryLimit - currentMonthUsage;
  double get usagePercentage => (currentMonthUsage / monthlySummaryLimit) * 100;

  String get tierDisplayName {
    switch (tier) {
      case 'premium':
        return 'Premium';
      case 'free':
        return 'Free';
      default:
        return 'Free';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case 'active':
        return 'Active';
      case 'expired':
        return 'Expired';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  // Get days until reset
  int get daysUntilReset {
    final now = DateTime.now();
    final difference = usageResetDate.difference(now);
    return difference.inDays;
  }

  SubscriptionModel copyWith({
    String? id,
    String? userId,
    String? tier,
    String? status,
    int? monthlySummaryLimit,
    int? currentMonthUsage,
    DateTime? usageResetDate,
    DateTime? subscriptionStartDate,
    DateTime? subscriptionEndDate,
    bool? autoRenew,
    String? purchaseReceipt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubscriptionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tier: tier ?? this.tier,
      status: status ?? this.status,
      monthlySummaryLimit: monthlySummaryLimit ?? this.monthlySummaryLimit,
      currentMonthUsage: currentMonthUsage ?? this.currentMonthUsage,
      usageResetDate: usageResetDate ?? this.usageResetDate,
      subscriptionStartDate:
          subscriptionStartDate ?? this.subscriptionStartDate,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
      autoRenew: autoRenew ?? this.autoRenew,
      purchaseReceipt: purchaseReceipt ?? this.purchaseReceipt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class AdInteractionModel {
  final String id;
  final String userId;
  final String adType;
  final String adUnitId;
  final bool rewardEarned;
  final int rewardAmount;
  final DateTime interactionDate;
  final String? sessionId;
  final DateTime createdAt;

  AdInteractionModel({
    required this.id,
    required this.userId,
    required this.adType,
    required this.adUnitId,
    required this.rewardEarned,
    required this.rewardAmount,
    required this.interactionDate,
    this.sessionId,
    required this.createdAt,
  });

  factory AdInteractionModel.fromJson(Map<String, dynamic> json) {
    return AdInteractionModel(
      id: json['id'],
      userId: json['user_id'],
      adType: json['ad_type'],
      adUnitId: json['ad_unit_id'],
      rewardEarned: json['reward_earned'] ?? false,
      rewardAmount: json['reward_amount'] ?? 1,
      interactionDate: DateTime.parse(json['interaction_date']),
      sessionId: json['session_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'ad_type': adType,
      'ad_unit_id': adUnitId,
      'reward_earned': rewardEarned,
      'reward_amount': rewardAmount,
      'interaction_date': interactionDate.toIso8601String(),
      'session_id': sessionId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class SummaryTranslationModel {
  final String id;
  final String originalSummaryId;
  final String languageCode;
  final String translatedTitle;
  final String translatedSummary;
  final List<String>? translatedKeyPoints;
  final String? translationService;
  final double? translationQualityScore;
  final DateTime createdAt;
  final DateTime updatedAt;

  SummaryTranslationModel({
    required this.id,
    required this.originalSummaryId,
    required this.languageCode,
    required this.translatedTitle,
    required this.translatedSummary,
    this.translatedKeyPoints,
    this.translationService,
    this.translationQualityScore,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SummaryTranslationModel.fromJson(Map<String, dynamic> json) {
    return SummaryTranslationModel(
      id: json['id'],
      originalSummaryId: json['original_summary_id'],
      languageCode: json['language_code'],
      translatedTitle: json['translated_title'],
      translatedSummary: json['translated_summary'],
      translatedKeyPoints: json['translated_key_points'] != null
          ? List<String>.from(json['translated_key_points'])
          : null,
      translationService: json['translation_service'],
      translationQualityScore: json['translation_quality_score']?.toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'original_summary_id': originalSummaryId,
      'language_code': languageCode,
      'translated_title': translatedTitle,
      'translated_summary': translatedSummary,
      'translated_key_points': translatedKeyPoints,
      'translation_service': translationService,
      'translation_quality_score': translationQualityScore,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
