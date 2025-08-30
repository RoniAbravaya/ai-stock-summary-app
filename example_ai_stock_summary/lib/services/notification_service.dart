import '../services/supabase_service.dart';
import '../models/notification_model.dart';
import '../models/price_alert_model.dart';

class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance =>
      _instance ??= NotificationService._();

  NotificationService._();

  final client = SupabaseService.instance.client;

  // Get user notifications
  Future<List<NotificationModel>> getUserNotifications(
    String userId, {
    int limit = 50,
    bool unreadOnly = false,
  }) async {
    try {
      var query = client.from('notifications').select('''
            *,
            stocks(symbol, name)
          ''').eq('user_id', userId);

      if (unreadOnly) {
        query = query.eq('is_read', false);
      }

      final response =
          await query.order('created_at', ascending: false).limit(limit);

      return (response as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
    } catch (error) {
      throw Exception('Failed to fetch notifications: $error');
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await client
          .from('notifications')
          .update({'is_read': true}).eq('id', notificationId);
    } catch (error) {
      throw Exception('Failed to mark notification as read: $error');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      await client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (error) {
      throw Exception('Failed to mark all notifications as read: $error');
    }
  }

  // Create notification
  Future<void> createNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    String? stockId,
    String? alertId,
  }) async {
    try {
      await client.from('notifications').insert({
        'user_id': userId,
        'notification_type': type,
        'title': title,
        'message': message,
        'stock_id': stockId,
        'alert_id': alertId,
      });
    } catch (error) {
      throw Exception('Failed to create notification: $error');
    }
  }

  // Get unread count
  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await client
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false)
          .count();

      return response.count ?? 0;
    } catch (error) {
      throw Exception('Failed to get unread count: $error');
    }
  }

  // Price Alert Methods

  // Get user's price alerts
  Future<List<PriceAlertModel>> getUserPriceAlerts(String userId) async {
    try {
      final response = await client.from('price_alerts').select('''
            *,
            stocks!inner(symbol, name, stock_prices(current_price))
          ''').eq('user_id', userId).order('created_at', ascending: false);

      return (response as List)
          .map((json) => PriceAlertModel.fromJson(json))
          .toList();
    } catch (error) {
      throw Exception('Failed to fetch price alerts: $error');
    }
  }

  // Create price alert
  Future<void> createPriceAlert({
    required String userId,
    required String stockId,
    required String alertType,
    required double targetPrice,
  }) async {
    try {
      await client.from('price_alerts').insert({
        'user_id': userId,
        'stock_id': stockId,
        'alert_type': alertType,
        'target_price': targetPrice,
        'is_active': true,
      });
    } catch (error) {
      throw Exception('Failed to create price alert: $error');
    }
  }

  // Update price alert
  Future<void> updatePriceAlert({
    required String alertId,
    double? targetPrice,
    bool? isActive,
    bool? isTriggered,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (targetPrice != null) updateData['target_price'] = targetPrice;
      if (isActive != null) updateData['is_active'] = isActive;
      if (isTriggered != null) {
        updateData['is_triggered'] = isTriggered;
        if (isTriggered) {
          updateData['triggered_at'] = DateTime.now().toIso8601String();
        }
      }

      updateData['updated_at'] = DateTime.now().toIso8601String();

      await client.from('price_alerts').update(updateData).eq('id', alertId);
    } catch (error) {
      throw Exception('Failed to update price alert: $error');
    }
  }

  // Delete price alert
  Future<void> deletePriceAlert(String alertId) async {
    try {
      await client.from('price_alerts').delete().eq('id', alertId);
    } catch (error) {
      throw Exception('Failed to delete price alert: $error');
    }
  }

  // Get active alerts for a stock
  Future<List<PriceAlertModel>> getActiveAlertsForStock(
    String stockId,
    String userId,
  ) async {
    try {
      final response = await client
          .from('price_alerts')
          .select('''
            *,
            stocks!inner(symbol, name)
          ''')
          .eq('stock_id', stockId)
          .eq('user_id', userId)
          .eq('is_active', true)
          .eq('is_triggered', false);

      return (response as List)
          .map((json) => PriceAlertModel.fromJson(json))
          .toList();
    } catch (error) {
      throw Exception('Failed to fetch active alerts: $error');
    }
  }
}
