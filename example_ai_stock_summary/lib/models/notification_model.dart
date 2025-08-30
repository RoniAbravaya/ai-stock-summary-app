class NotificationModel {
  final String id;
  final String userId;
  final String notificationType;
  final String title;
  final String message;
  final String? stockId;
  final String? alertId;
  final bool isRead;
  final DateTime createdAt;

  // Optional stock info
  final String? stockSymbol;
  final String? stockName;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.notificationType,
    required this.title,
    required this.message,
    this.stockId,
    this.alertId,
    required this.isRead,
    required this.createdAt,
    this.stockSymbol,
    this.stockName,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final stockData = json['stocks'];

    return NotificationModel(
      id: json['id'],
      userId: json['user_id'],
      notificationType: json['notification_type'],
      title: json['title'],
      message: json['message'],
      stockId: json['stock_id'],
      alertId: json['alert_id'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      stockSymbol: stockData?['symbol'],
      stockName: stockData?['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'notification_type': notificationType,
      'title': title,
      'message': message,
      'stock_id': stockId,
      'alert_id': alertId,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Get notification type display name
  String get typeDisplayName {
    switch (notificationType) {
      case 'price_alert':
        return 'Price Alert';
      case 'system':
        return 'System';
      case 'market_news':
        return 'Market News';
      case 'ai_insight':
        return 'AI Insight';
      default:
        return 'Notification';
    }
  }

  // Get notification icon based on type
  String get iconName {
    switch (notificationType) {
      case 'price_alert':
        return 'notifications_active';
      case 'system':
        return 'settings';
      case 'market_news':
        return 'article';
      case 'ai_insight':
        return 'psychology';
      default:
        return 'notifications';
    }
  }

  // Check if notification is recent (within 24 hours)
  bool get isRecent {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inHours < 24;
  }

  // Get formatted time ago
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

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

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? notificationType,
    String? title,
    String? message,
    String? stockId,
    String? alertId,
    bool? isRead,
    DateTime? createdAt,
    String? stockSymbol,
    String? stockName,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      notificationType: notificationType ?? this.notificationType,
      title: title ?? this.title,
      message: message ?? this.message,
      stockId: stockId ?? this.stockId,
      alertId: alertId ?? this.alertId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      stockSymbol: stockSymbol ?? this.stockSymbol,
      stockName: stockName ?? this.stockName,
    );
  }
}
