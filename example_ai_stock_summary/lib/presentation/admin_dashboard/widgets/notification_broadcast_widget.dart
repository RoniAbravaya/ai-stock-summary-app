import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class NotificationBroadcastWidget extends StatefulWidget {
  const NotificationBroadcastWidget({super.key});

  @override
  State<NotificationBroadcastWidget> createState() =>
      _NotificationBroadcastWidgetState();
}

class _NotificationBroadcastWidgetState
    extends State<NotificationBroadcastWidget> {
  String selectedRecipient = 'All Users';
  final List<String> recipientOptions = [
    'All Users',
    'Free Users',
    'Premium Users',
    'Specific Users'
  ];

  final List<Map<String, dynamic>> recentNotifications = [
    {
      "id": "1",
      "title": "Market Alert: AAPL",
      "message": "Apple stock reached new high of \$195.50",
      "recipient": "All Users",
      "sentTime": "2025-08-28 05:45:00",
      "deliveryStatus": "Delivered",
      "recipientCount": 2847,
      "deliveredCount": 2831,
    },
    {
      "id": "2",
      "title": "Premium Feature Update",
      "message": "New AI analysis tools now available for premium users",
      "recipient": "Premium Users",
      "sentTime": "2025-08-28 04:30:00",
      "deliveryStatus": "Delivered",
      "recipientCount": 456,
      "deliveredCount": 451,
    },
    {
      "id": "3",
      "title": "Weekly Market Summary",
      "message": "Your personalized market insights are ready",
      "recipient": "All Users",
      "sentTime": "2025-08-28 03:15:00",
      "deliveryStatus": "Pending",
      "recipientCount": 2847,
      "deliveredCount": 1923,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notification Broadcasting',
                    style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'Send targeted messages to user groups',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () => _showBroadcastDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryLight,
                  foregroundColor: AppTheme.onSecondaryLight,
                  padding:
                      EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomIconWidget(
                      iconName: 'send',
                      color: AppTheme.onSecondaryLight,
                      size: 18,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Send Broadcast',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.onSecondaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          Row(
            children: [
              Expanded(
                child: _buildQuickStat(
                    'Total Sent', '8,247', 'send', AppTheme.primaryLight),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildQuickStat('Delivered', '8,156', 'check_circle',
                    AppTheme.successLight),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildQuickStat(
                    'Pending', '91', 'schedule', AppTheme.warningLight),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          Text(
            'Recent Broadcasts',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentNotifications.length,
            separatorBuilder: (context, index) => SizedBox(height: 2.h),
            itemBuilder: (context, index) {
              final notification = recentNotifications[index];
              return _buildNotificationCard(notification);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(
      String title, String value, String iconName, Color color) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomIconWidget(
                iconName: iconName,
                color: color,
                size: 20,
              ),
              Text(
                value,
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            title,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondaryLight,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    Color statusColor = notification["deliveryStatus"] == "Delivered"
        ? AppTheme.successLight
        : AppTheme.warningLight;

    double deliveryRate = (notification["deliveredCount"] as int) /
        (notification["recipientCount"] as int);

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppTheme.borderLight.withValues(alpha: 0.5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  notification["title"] as String,
                  style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: statusColor.withValues(alpha: 0.3), width: 1),
                ),
                child: Text(
                  notification["deliveryStatus"] as String,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 9.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            notification["message"] as String,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondaryLight,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              CustomIconWidget(
                iconName: 'group',
                color: AppTheme.textSecondaryLight,
                size: 14,
              ),
              SizedBox(width: 1.w),
              Text(
                notification["recipient"] as String,
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryLight,
                  fontSize: 10.sp,
                ),
              ),
              const Spacer(),
              CustomIconWidget(
                iconName: 'schedule',
                color: AppTheme.textSecondaryLight,
                size: 14,
              ),
              SizedBox(width: 1.w),
              Text(
                _formatTime(notification["sentTime"] as String),
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryLight,
                  fontSize: 10.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery Rate: ${(deliveryRate * 100).toStringAsFixed(1)}%',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryLight,
                        fontSize: 10.sp,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    LinearProgressIndicator(
                      value: deliveryRate,
                      backgroundColor: AppTheme.borderLight,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      minHeight: 0.5.h,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 4.w),
              Text(
                '${notification["deliveredCount"]}/${notification["recipientCount"]}',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textPrimaryLight,
                  fontWeight: FontWeight.w500,
                  fontSize: 10.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(String timestamp) {
    DateTime dateTime = DateTime.parse(timestamp);
    DateTime now = DateTime.now();
    Duration difference = now.difference(dateTime);

    if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _showBroadcastDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController messageController = TextEditingController();
    String selectedTarget = 'All Users';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.lightTheme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Send Broadcast Notification',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              content: SizedBox(
                width: 80.w,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Target Audience',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Container(
                      width: double.infinity,
                      padding:
                          EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: AppTheme.borderLight, width: 1),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedTarget,
                          isExpanded: true,
                          items: recipientOptions.map((String option) {
                            return DropdownMenuItem<String>(
                              value: option,
                              child: Text(
                                option,
                                style: AppTheme.lightTheme.textTheme.bodyMedium
                                    ?.copyWith(
                                  color: AppTheme.textPrimaryLight,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                selectedTarget = newValue;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Notification Title',
                        hintText: 'Enter notification title...',
                      ),
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    TextField(
                      controller: messageController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        hintText: 'Enter your message...',
                      ),
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty &&
                        messageController.text.isNotEmpty) {
                      Navigator.pop(context);
                      _sendBroadcast(titleController.text,
                          messageController.text, selectedTarget);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryLight,
                    foregroundColor: AppTheme.onSecondaryLight,
                  ),
                  child: Text(
                    'Send',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.onSecondaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _sendBroadcast(String title, String message, String target) {
    // Simulate sending broadcast
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Broadcast sent to $target successfully!'),
        backgroundColor: AppTheme.successLight,
      ),
    );
  }
}
