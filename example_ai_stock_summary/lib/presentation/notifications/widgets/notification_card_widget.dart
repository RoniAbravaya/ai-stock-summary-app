import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class NotificationCardWidget extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback? onTap;
  final VoidCallback? onMarkAsRead;
  final VoidCallback? onDelete;
  final VoidCallback? onTurnOffSimilar;

  const NotificationCardWidget({
    Key? key,
    required this.notification,
    this.onTap,
    this.onMarkAsRead,
    this.onDelete,
    this.onTurnOffSimilar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isRead = notification['isRead'] ?? false;
    final String type = notification['type'] ?? 'general';
    final String title = notification['title'] ?? '';
    final String description = notification['description'] ?? '';
    final DateTime timestamp = notification['timestamp'] ?? DateTime.now();
    final String timeAgo = _getTimeAgo(timestamp);

    return Dismissible(
      key: Key(notification['id'].toString()),
      background: _buildSwipeBackground(context, isRead: isRead),
      secondaryBackground: _buildDeleteBackground(context),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onMarkAsRead?.call();
          return false;
        } else if (direction == DismissDirection.endToStart) {
          return await _showDeleteConfirmation(context);
        }
        return false;
      },
      child: GestureDetector(
        onTap: onTap,
        onLongPress: () => _showContextMenu(context),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          decoration: BoxDecoration(
            color: isRead
                ? AppTheme.lightTheme.colorScheme.surface
                : AppTheme.lightTheme.colorScheme.surface
                    .withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isRead
                  ? AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.3)
                  : AppTheme.lightTheme.primaryColor.withValues(alpha: 0.2),
              width: isRead ? 1 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.lightTheme.colorScheme.shadow,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNotificationIcon(type, isRead),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: AppTheme.lightTheme.textTheme.titleMedium
                                  ?.copyWith(
                                fontWeight:
                                    isRead ? FontWeight.w400 : FontWeight.w600,
                                color: isRead
                                    ? AppTheme.lightTheme.colorScheme.onSurface
                                        .withValues(alpha: 0.8)
                                    : AppTheme.lightTheme.colorScheme.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 2.w,
                              height: 2.w,
                              decoration: BoxDecoration(
                                color: AppTheme.lightTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        description,
                        style:
                            AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          color: isRead
                              ? AppTheme.lightTheme.colorScheme.onSurface
                                  .withValues(alpha: 0.6)
                              : AppTheme.lightTheme.colorScheme.onSurface
                                  .withValues(alpha: 0.8),
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 1.h),
                      Row(
                        children: [
                          Text(
                            timeAgo,
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                          const Spacer(),
                          if (notification['deliveryStatus'] != null)
                            _buildDeliveryStatus(
                                notification['deliveryStatus']),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 2.w),
                CustomIconWidget(
                  iconName: 'chevron_right',
                  color: AppTheme.lightTheme.colorScheme.onSurface
                      .withValues(alpha: 0.4),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(String type, bool isRead) {
    String iconName;
    Color iconColor;

    switch (type) {
      case 'price_alert':
        iconName = 'trending_up';
        iconColor = AppTheme.lightTheme.colorScheme.tertiary;
        break;
      case 'news':
        iconName = 'article';
        iconColor = AppTheme.lightTheme.colorScheme.secondary;
        break;
      case 'ai_update':
        iconName = 'psychology';
        iconColor = AppTheme.lightTheme.primaryColor;
        break;
      default:
        iconName = 'notifications';
        iconColor =
            AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.6);
    }

    return Container(
      width: 10.w,
      height: 10.w,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: isRead ? 0.1 : 0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: CustomIconWidget(
          iconName: iconName,
          color: iconColor.withValues(alpha: isRead ? 0.6 : 1.0),
          size: 24,
        ),
      ),
    );
  }

  Widget _buildSwipeBackground(BuildContext context, {required bool isRead}) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.only(left: 6.w),
      decoration: BoxDecoration(
        color: isRead
            ? AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2)
            : AppTheme.lightTheme.colorScheme.tertiary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: isRead ? 'mark_email_unread' : 'mark_email_read',
            color: isRead
                ? AppTheme.lightTheme.colorScheme.outline
                : AppTheme.lightTheme.colorScheme.tertiary,
            size: 24,
          ),
          SizedBox(width: 2.w),
          Text(
            isRead ? 'Mark Unread' : 'Mark Read',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: isRead
                  ? AppTheme.lightTheme.colorScheme.outline
                  : AppTheme.lightTheme.colorScheme.tertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteBackground(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: EdgeInsets.only(right: 6.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.error.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Delete',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.error,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 2.w),
          CustomIconWidget(
            iconName: 'delete',
            color: AppTheme.lightTheme.colorScheme.error,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryStatus(String status) {
    Color statusColor;
    String statusIcon;

    switch (status.toLowerCase()) {
      case 'delivered':
        statusColor = AppTheme.lightTheme.colorScheme.tertiary;
        statusIcon = 'check_circle';
        break;
      case 'failed':
        statusColor = AppTheme.lightTheme.colorScheme.error;
        statusIcon = 'error';
        break;
      case 'sent':
        statusColor = AppTheme.lightTheme.colorScheme.outline;
        statusIcon = 'schedule';
        break;
      default:
        statusColor = AppTheme.lightTheme.colorScheme.outline;
        statusIcon = 'help';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(
            iconName: statusIcon,
            color: statusColor,
            size: 12,
          ),
          SizedBox(width: 1.w),
          Text(
            status,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: statusColor,
              fontSize: 10.sp,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Delete Notification',
              style: AppTheme.lightTheme.textTheme.titleLarge,
            ),
            content: Text(
              'Are you sure you want to delete this notification? This action cannot be undone.',
              style: AppTheme.lightTheme.textTheme.bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style:
                      TextStyle(color: AppTheme.lightTheme.colorScheme.outline),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                  onDelete?.call();
                },
                child: Text(
                  'Delete',
                  style:
                      TextStyle(color: AppTheme.lightTheme.colorScheme.error),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 3.h),
            ListTile(
              leading: CustomIconWidget(
                iconName: notification['isRead'] == true
                    ? 'mark_email_unread'
                    : 'mark_email_read',
                color: AppTheme.lightTheme.colorScheme.onSurface,
                size: 24,
              ),
              title: Text(
                notification['isRead'] == true
                    ? 'Mark as Unread'
                    : 'Mark as Read',
                style: AppTheme.lightTheme.textTheme.bodyLarge,
              ),
              onTap: () {
                Navigator.pop(context);
                onMarkAsRead?.call();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'delete',
                color: AppTheme.lightTheme.colorScheme.error,
                size: 24,
              ),
              title: Text(
                'Delete',
                style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.error,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                onDelete?.call();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'notifications_off',
                color: AppTheme.lightTheme.colorScheme.onSurface,
                size: 24,
              ),
              title: Text(
                'Turn Off Similar',
                style: AppTheme.lightTheme.textTheme.bodyLarge,
              ),
              onTap: () {
                Navigator.pop(context);
                onTurnOffSimilar?.call();
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
