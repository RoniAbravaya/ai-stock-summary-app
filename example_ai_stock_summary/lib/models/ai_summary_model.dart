class AiSummaryModel {
  final String id;
  final String stockId;
  final String title;
  final String summary;
  final String sentiment;
  final double? confidenceScore;
  final List<String>? keyPoints;
  final DateTime generatedAt;
  final bool isActive;

  // Stock info
  final String? stockSymbol;
  final String? stockName;
  final String? stockExchange;
  final String? stockSector;
  final String? stockIndustry;

  AiSummaryModel({
    required this.id,
    required this.stockId,
    required this.title,
    required this.summary,
    required this.sentiment,
    this.confidenceScore,
    this.keyPoints,
    required this.generatedAt,
    required this.isActive,
    this.stockSymbol,
    this.stockName,
    this.stockExchange,
    this.stockSector,
    this.stockIndustry,
  });

  factory AiSummaryModel.fromJson(Map<String, dynamic> json) {
    final stockData = json['stocks'];

    List<String>? keyPoints;
    if (json['key_points'] != null) {
      if (json['key_points'] is List) {
        keyPoints = List<String>.from(json['key_points']);
      }
    }

    return AiSummaryModel(
      id: json['id'],
      stockId: json['stock_id'],
      title: json['title'],
      summary: json['summary'],
      sentiment: json['sentiment'],
      confidenceScore: json['confidence_score']?.toDouble(),
      keyPoints: keyPoints,
      generatedAt: DateTime.parse(json['generated_at']),
      isActive: json['is_active'] ?? true,
      stockSymbol: stockData?['symbol'],
      stockName: stockData?['name'],
      stockExchange: stockData?['exchange'],
      stockSector: stockData?['sector'],
      stockIndustry: stockData?['industry'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stock_id': stockId,
      'title': title,
      'summary': summary,
      'sentiment': sentiment,
      'confidence_score': confidenceScore,
      'key_points': keyPoints,
      'generated_at': generatedAt.toIso8601String(),
      'is_active': isActive,
    };
  }

  // Get sentiment display name
  String get sentimentDisplayName {
    switch (sentiment.toLowerCase()) {
      case 'bullish':
        return 'Bullish';
      case 'bearish':
        return 'Bearish';
      case 'neutral':
        return 'Neutral';
      default:
        return 'Unknown';
    }
  }

  // Get sentiment color
  String get sentimentColor {
    switch (sentiment.toLowerCase()) {
      case 'bullish':
        return '#10B981'; // Green
      case 'bearish':
        return '#EF4444'; // Red
      case 'neutral':
        return '#6B7280'; // Gray
      default:
        return '#6B7280';
    }
  }

  // Get confidence level
  String get confidenceLevel {
    if (confidenceScore == null) return 'Unknown';

    if (confidenceScore! >= 0.8) {
      return 'High';
    } else if (confidenceScore! >= 0.6) {
      return 'Medium';
    } else if (confidenceScore! >= 0.4) {
      return 'Low';
    } else {
      return 'Very Low';
    }
  }

  // Get formatted time ago
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(generatedAt);

    if (difference.inDays > 7) {
      return '${difference.inDays ~/ 7}w ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Check if summary is recent (within 24 hours)
  bool get isRecent {
    final now = DateTime.now();
    final difference = now.difference(generatedAt);
    return difference.inHours < 24;
  }

  // Get preview text (first 150 characters)
  String get preview {
    if (summary.length <= 150) return summary;
    return '${summary.substring(0, 147)}...';
  }

  AiSummaryModel copyWith({
    String? id,
    String? stockId,
    String? title,
    String? summary,
    String? sentiment,
    double? confidenceScore,
    List<String>? keyPoints,
    DateTime? generatedAt,
    bool? isActive,
    String? stockSymbol,
    String? stockName,
    String? stockExchange,
    String? stockSector,
    String? stockIndustry,
  }) {
    return AiSummaryModel(
      id: id ?? this.id,
      stockId: stockId ?? this.stockId,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      sentiment: sentiment ?? this.sentiment,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      keyPoints: keyPoints ?? this.keyPoints,
      generatedAt: generatedAt ?? this.generatedAt,
      isActive: isActive ?? this.isActive,
      stockSymbol: stockSymbol ?? this.stockSymbol,
      stockName: stockName ?? this.stockName,
      stockExchange: stockExchange ?? this.stockExchange,
      stockSector: stockSector ?? this.stockSector,
      stockIndustry: stockIndustry ?? this.stockIndustry,
    );
  }
}
