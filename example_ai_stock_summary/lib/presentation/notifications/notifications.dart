import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/empty_notifications_widget.dart';
import './widgets/notification_card_widget.dart';
import './widgets/notification_filter_widget.dart';
import './widgets/notification_search_widget.dart';

class Notifications extends StatefulWidget {
  const Notifications({Key? key}) : super(key: key);

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications>
    with TickerProviderStateMixin {
  String _selectedFilter = 'all';
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isSearchActive = false;
  late TabController _tabController;

  // Mock notification data
  final List<Map<String, dynamic>> _allNotifications = [
    {
      "id": 1,
      "type": "price_alert",
      "title": "AAPL Price Alert",
      "description":
          "Apple Inc. (AAPL) has reached your target price of \$175.00. Current price: \$175.25 (+2.1%)",
      "timestamp": DateTime.now().subtract(const Duration(minutes: 15)),
      "isRead": false,
      "stockSymbol": "AAPL",
      "deliveryStatus": "delivered",
    },
    {
      "id": 2,
      "type": "ai_update",
      "title": "AI Market Summary",
      "description":
          "Your portfolio shows strong momentum with tech stocks leading gains. NVDA and MSFT showing bullish patterns.",
      "timestamp": DateTime.now().subtract(const Duration(hours: 2)),
      "isRead": false,
      "deliveryStatus": "delivered",
    },
    {
      "id": 3,
      "type": "news",
      "title": "Tesla Earnings Report",
      "description":
          "Tesla (TSLA) beats Q4 earnings expectations with \$0.85 EPS vs \$0.73 expected. Revenue up 15% YoY.",
      "timestamp": DateTime.now().subtract(const Duration(hours: 4)),
      "isRead": true,
      "stockSymbol": "TSLA",
      "deliveryStatus": "delivered",
    },
    {
      "id": 4,
      "type": "price_alert",
      "title": "GOOGL Price Drop",
      "description":
          "Alphabet Inc. (GOOGL) has dropped below your alert threshold of \$140.00. Current price: \$138.75 (-3.2%)",
      "timestamp": DateTime.now().subtract(const Duration(hours: 6)),
      "isRead": true,
      "stockSymbol": "GOOGL",
      "deliveryStatus": "delivered",
    },
    {
      "id": 5,
      "type": "news",
      "title": "Federal Reserve Decision",
      "description":
          "Fed maintains interest rates at 5.25-5.50% range. Markets react positively to dovish commentary.",
      "timestamp": DateTime.now().subtract(const Duration(days: 1)),
      "isRead": false,
      "deliveryStatus": "delivered",
    },
    {
      "id": 6,
      "type": "ai_update",
      "title": "Weekly Portfolio Analysis",
      "description":
          "Your portfolio gained 3.2% this week, outperforming S&P 500 by 1.1%. Consider rebalancing tech allocation.",
      "timestamp": DateTime.now().subtract(const Duration(days: 2)),
      "isRead": true,
      "deliveryStatus": "delivered",
    },
    {
      "id": 7,
      "type": "price_alert",
      "title": "AMZN Breakout Alert",
      "description":
          "Amazon (AMZN) has broken above resistance at \$155.00. Current price: \$157.30 (+4.8%)",
      "timestamp": DateTime.now().subtract(const Duration(days: 3)),
      "isRead": false,
      "stockSymbol": "AMZN",
      "deliveryStatus": "failed",
    },
    {
      "id": 8,
      "type": "news",
      "title": "Crypto Market Update",
      "description":
          "Bitcoin surges past \$45,000 as institutional adoption continues. Ethereum also showing strength.",
      "timestamp": DateTime.now().subtract(const Duration(days: 4)),
      "isRead": true,
      "deliveryStatus": "delivered",
    },
  ];

  List<Map<String, dynamic>> _filteredNotifications = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _filteredNotifications = List.from(_allNotifications);
    _applyFilters();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    setState(() {
      _filteredNotifications = _allNotifications.where((notification) {
        // Apply type filter
        bool matchesFilter = true;
        if (_selectedFilter != 'all') {
          String filterType = _selectedFilter
              .replaceAll('_alerts', '_alert')
              .replaceAll('_updates', '_update');
          matchesFilter = notification['type'] == filterType;
        }

        // Apply search filter
        bool matchesSearch = true;
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          matchesSearch = notification['title'].toLowerCase().contains(query) ||
              notification['description'].toLowerCase().contains(query) ||
              (notification['stockSymbol']?.toLowerCase().contains(query) ??
                  false);
        }

        return matchesFilter && matchesSearch;
      }).toList();

      // Sort by timestamp (newest first)
      _filteredNotifications.sort((a, b) =>
          (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));
    });
  }

  Map<String, int> _getFilterCounts() {
    return {
      'all': _allNotifications.length,
      'price_alerts':
          _allNotifications.where((n) => n['type'] == 'price_alert').length,
      'news': _allNotifications.where((n) => n['type'] == 'news').length,
      'ai_updates':
          _allNotifications.where((n) => n['type'] == 'ai_update').length,
    };
  }

  int _getUnreadCount() {
    return _allNotifications.where((n) => n['isRead'] == false).length;
  }

  Future<void> _refreshNotifications() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    // Add haptic feedback
    HapticFeedback.lightImpact();

    setState(() {
      _isLoading = false;
    });

    // Show refresh confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Notifications refreshed'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _applyFilters();

    // Update tab controller
    final filterIndex =
        ['all', 'price_alerts', 'news', 'ai_updates'].indexOf(filter);
    if (filterIndex != -1) {
      _tabController.animateTo(filterIndex);
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
  }

  void _onNotificationTap(Map<String, dynamic> notification) {
    // Mark as read
    _markNotificationAsRead(notification['id']);

    // Navigate based on notification type
    switch (notification['type']) {
      case 'price_alert':
        if (notification['stockSymbol'] != null) {
          Navigator.pushNamed(context, '/stock-detail', arguments: {
            'symbol': notification['stockSymbol'],
            'fromNotification': true,
          });
        }
        break;
      case 'ai_update':
        Navigator.pushNamed(context, '/ai-summary');
        break;
      case 'news':
        if (notification['stockSymbol'] != null) {
          Navigator.pushNamed(context, '/stock-detail', arguments: {
            'symbol': notification['stockSymbol'],
            'tab': 'news',
          });
        }
        break;
    }
  }

  void _markNotificationAsRead(int notificationId) {
    setState(() {
      final index =
          _allNotifications.indexWhere((n) => n['id'] == notificationId);
      if (index != -1) {
        _allNotifications[index]['isRead'] =
            !(_allNotifications[index]['isRead'] ?? false);
      }
    });
    _applyFilters();
  }

  void _deleteNotification(int notificationId) {
    setState(() {
      _allNotifications.removeWhere((n) => n['id'] == notificationId);
    });
    _applyFilters();

    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Notification deleted'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _turnOffSimilarNotifications(Map<String, dynamic> notification) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Turn Off Similar Notifications',
          style: AppTheme.lightTheme.textTheme.titleLarge,
        ),
        content: Text(
          'Do you want to turn off all ${_getNotificationTypeLabel(notification['type'])} notifications?',
          style: AppTheme.lightTheme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.lightTheme.colorScheme.outline),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
            child: Text(
              'Settings',
              style: TextStyle(color: AppTheme.lightTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  String _getNotificationTypeLabel(String type) {
    switch (type) {
      case 'price_alert':
        return 'Price Alert';
      case 'news':
        return 'News';
      case 'ai_update':
        return 'AI Update';
      default:
        return 'General';
    }
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _allNotifications) {
        notification['isRead'] = true;
      }
    });
    _applyFilters();

    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('All notifications marked as read'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _getUnreadCount();
    final hasUnreadNotifications = unreadCount > 0;

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: AppTheme.lightTheme.colorScheme.onSurface,
            size: 24,
          ),
        ),
        title: NotificationSearchWidget(
          onSearchChanged: _onSearchChanged,
          onClearSearch: () {
            setState(() {
              _searchQuery = '';
            });
            _applyFilters();
          },
          searchQuery: _searchQuery,
        ),
        actions: [
          if (hasUnreadNotifications && _searchQuery.isEmpty)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Mark All Read',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            icon: CustomIconWidget(
              iconName: 'settings',
              color: AppTheme.lightTheme.colorScheme.onSurface
                  .withValues(alpha: 0.7),
              size: 24,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_searchQuery.isEmpty) ...[
            NotificationFilterWidget(
              selectedFilter: _selectedFilter,
              onFilterChanged: _onFilterChanged,
              filterCounts: _getFilterCounts(),
            ),
            Divider(
              height: 1,
              color: AppTheme.lightTheme.colorScheme.outline
                  .withValues(alpha: 0.2),
            ),
          ],
          Expanded(
            child: _filteredNotifications.isEmpty
                ? EmptyNotificationsWidget(
                    filterType: _selectedFilter,
                    onSetupNotifications: () =>
                        Navigator.pushNamed(context, '/settings'),
                  )
                : RefreshIndicator(
                    onRefresh: _refreshNotifications,
                    color: AppTheme.lightTheme.primaryColor,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.only(top: 1.h, bottom: 10.h),
                      itemCount: _filteredNotifications.length,
                      itemBuilder: (context, index) {
                        final notification = _filteredNotifications[index];
                        return NotificationCardWidget(
                          notification: notification,
                          onTap: () => _onNotificationTap(notification),
                          onMarkAsRead: () =>
                              _markNotificationAsRead(notification['id']),
                          onDelete: () =>
                              _deleteNotification(notification['id']),
                          onTurnOffSimilar: () =>
                              _turnOffSimilarNotifications(notification),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
