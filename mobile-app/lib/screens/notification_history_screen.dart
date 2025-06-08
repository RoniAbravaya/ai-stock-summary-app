import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/app_config.dart';
import '../services/firebase_service.dart';
import '../services/language_service.dart';

/// Notification History Screen
/// Displays all notifications ever received by the user
class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key, required this.firebaseEnabled});

  final bool firebaseEnabled;

  @override
  State<NotificationHistoryScreen> createState() =>
      _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends State<NotificationHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = false;
  bool _hasMoreData = true;
  DocumentSnapshot? _lastDocument;
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _scrollController.addListener(_onScroll);
    // Force a rebuild after the first frame to ensure translations are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (!_isLoading && _hasMoreData) {
        _loadMoreNotifications();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LanguageService().translate('notif_history_title')),
        backgroundColor: Color(AppConfig.primaryBlue),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshNotifications,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_notifications.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshNotifications,
      child: Column(
        children: [
          // Header Stats
          _buildHeader(),

          // Notifications List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length + (_hasMoreData ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _notifications.length) {
                  return _buildLoadingIndicator();
                }
                return _buildNotificationTile(_notifications[index], index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final unreadCount =
        _notifications.where((n) => !(n['isRead'] ?? false)).length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(AppConfig.primaryBlue), Colors.blue.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.notifications_active,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LanguageService().translate('notif_history_title'),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  LanguageService().translateWithParams('notif_history_stats', {
                    'total': _notifications.length.toString(),
                    'unread': unreadCount.toString(),
                  }),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade500,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(Map<String, dynamic> notification, int index) {
    final isRead = notification['isRead'] ?? false;
    final timestamp = notification['timestamp'] as Timestamp?;
    final title =
        notification['title'] ?? LanguageService().translate('notif_no_title');
    final body = notification['body'] ?? '';
    final type = notification['type'] ?? 'system';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isRead ? 1 : 3,
      child: InkWell(
        onTap: () => _markAsRead(notification['id'], index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border:
                isRead
                    ? null
                    : Border.all(
                      color: Color(AppConfig.primaryBlue).withOpacity(0.3),
                      width: 1,
                    ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Notification Type Icon
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _getTypeColor(type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      _getTypeIcon(type),
                      size: 16,
                      color: _getTypeColor(type),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title and Read Status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                isRead ? FontWeight.w500 : FontWeight.w600,
                            color:
                                isRead ? Colors.grey.shade700 : Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!isRead)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              LanguageService().translate('notif_new'),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Timestamp
                  Text(
                    _formatTimestamp(timestamp),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),

              // Body
              if (body.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 13,
                    color: isRead ? Colors.grey.shade600 : Colors.grey.shade800,
                    height: 1.4,
                  ),
                ),
              ],

              // Footer
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _getTypeColor(type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getTypeLabel(type),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: _getTypeColor(type),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (!isRead)
                    TextButton(
                      onPressed: () => _markAsRead(notification['id'], index),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        LanguageService().translate('notif_mark_read'),
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(AppConfig.primaryBlue),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            LanguageService().translate('notif_empty_title'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            LanguageService().translate('notif_empty_desc'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshNotifications,
            icon: const Icon(Icons.refresh),
            label: Text(LanguageService().translate('notif_check')),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(AppConfig.primaryBlue),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  // Helper methods for notification types
  Color _getTypeColor(String type) {
    switch (type) {
      case 'admin_broadcast':
        return Colors.purple.shade600;
      case 'system':
        return Colors.blue.shade600;
      case 'stock_alert':
        return Colors.green.shade600;
      case 'news_update':
        return Colors.orange.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'admin_broadcast':
        return Icons.campaign;
      case 'system':
        return Icons.settings;
      case 'stock_alert':
        return Icons.trending_up;
      case 'news_update':
        return Icons.article;
      default:
        return Icons.notifications;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'admin_broadcast':
        return LanguageService().translate('notif_type_admin');
      case 'system':
        return LanguageService().translate('notif_type_system');
      case 'stock_alert':
        return LanguageService().translate('notif_type_stock');
      case 'news_update':
        return LanguageService().translate('notif_type_news');
      default:
        return LanguageService().translate('notif_type_general');
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) {
      return LanguageService().translate('notif_time_unknown');
    }

    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return LanguageService().translate('notif_time_now');
    } else if (difference.inMinutes < 60) {
      return LanguageService().translateWithParams('notif_time_minutes', {
        'minutes': difference.inMinutes.toString(),
      });
    } else if (difference.inHours < 24) {
      return LanguageService().translateWithParams('notif_time_hours', {
        'hours': difference.inHours.toString(),
      });
    } else if (difference.inDays < 7) {
      return LanguageService().translateWithParams('notif_time_days', {
        'days': difference.inDays.toString(),
      });
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Data loading methods
  Future<void> _loadNotifications() async {
    if (!widget.firebaseEnabled) {
      _loadMockNotifications();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _loadNotificationsFromFirestore();
    } catch (e) {
      print('Error loading notifications: $e');
      _showErrorSnackBar('Error loading notifications: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadNotificationsFromFirestore() async {
    final user = FirebaseService().currentUser;
    if (user == null) return;

    Query query = FirebaseFirestore.instance
        .collection('user_notifications')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(_pageSize);

    final querySnapshot = await query.get();

    final notifications =
        querySnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();

    setState(() {
      _notifications = notifications;
      _hasMoreData = querySnapshot.docs.length == _pageSize;
      _lastDocument =
          querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null;
    });
  }

  Future<void> _loadMoreNotifications() async {
    if (!widget.firebaseEnabled || _lastDocument == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseService().currentUser;
      if (user == null) return;

      final query = FirebaseFirestore.instance
          .collection('user_notifications')
          .doc(user.uid)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_pageSize);

      final querySnapshot = await query.get();

      final newNotifications =
          querySnapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();

      setState(() {
        _notifications.addAll(newNotifications);
        _hasMoreData = querySnapshot.docs.length == _pageSize;
        _lastDocument =
            querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null;
      });
    } catch (e) {
      print('Error loading more notifications: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadMockNotifications() {
    // Mock data for demo mode
    final mockNotifications = List.generate(
      5,
      (index) => {
        'id': 'mock_$index',
        'title': 'Welcome to AI Stock Summary!',
        'body':
            'Thank you for using our app. You can now track stocks and get AI-powered summaries.',
        'type': 'admin_broadcast',
        'isRead': index > 2,
        'timestamp': Timestamp.fromDate(
          DateTime.now().subtract(Duration(days: index)),
        ),
      },
    );

    setState(() {
      _notifications = mockNotifications;
      _hasMoreData = false;
    });
  }

  Future<void> _refreshNotifications() async {
    setState(() {
      _notifications.clear();
      _lastDocument = null;
      _hasMoreData = true;
    });

    await _loadNotifications();
  }

  Future<void> _markAsRead(String notificationId, int index) async {
    if (!widget.firebaseEnabled) {
      // Mock mode - just update locally
      setState(() {
        _notifications[index]['isRead'] = true;
      });
      return;
    }

    try {
      final user = FirebaseService().currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('user_notifications')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});

      setState(() {
        _notifications[index]['isRead'] = true;
      });
    } catch (e) {
      print('Error marking notification as read: $e');
      _showErrorSnackBar('Error updating notification');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Color(AppConfig.primaryRed),
      ),
    );
  }
}
