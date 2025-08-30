import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class QuickActionsFabWidget extends StatefulWidget {
  const QuickActionsFabWidget({super.key});

  @override
  State<QuickActionsFabWidget> createState() => _QuickActionsFabWidgetState();
}

class _QuickActionsFabWidgetState extends State<QuickActionsFabWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isExpanded = false;

  final List<Map<String, dynamic>> quickActions = [
    {
      "title": "User Search",
      "icon": "search",
      "color": AppTheme.primaryLight,
      "action": "search"
    },
    {
      "title": "Send Broadcast",
      "icon": "send",
      "color": AppTheme.secondaryLight,
      "action": "broadcast"
    },
    {
      "title": "Export Analytics",
      "icon": "download",
      "color": AppTheme.successLight,
      "action": "export"
    },
    {
      "title": "System Status",
      "icon": "monitor_heart",
      "color": AppTheme.warningLight,
      "action": "status"
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Backdrop overlay
        if (_isExpanded)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleExpanded,
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
              ),
            ),
          ),

        // Action buttons
        ...quickActions.asMap().entries.map((entry) {
          int index = entry.key;
          Map<String, dynamic> action = entry.value;

          return AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              double offset = (index + 1) * 15.h * _animation.value;
              return Positioned(
                bottom: offset,
                right: 0,
                child: Transform.scale(
                  scale: _animation.value,
                  child: Opacity(
                    opacity: _animation.value,
                    child: _buildActionButton(action),
                  ),
                ),
              );
            },
          );
        }).toList(),

        // Main FAB
        Positioned(
          bottom: 0,
          right: 0,
          child: FloatingActionButton(
            onPressed: _toggleExpanded,
            backgroundColor:
                _isExpanded ? AppTheme.errorLight : AppTheme.primaryLight,
            child: AnimatedRotation(
              turns: _isExpanded ? 0.125 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: CustomIconWidget(
                iconName: _isExpanded ? 'close' : 'admin_panel_settings',
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(Map<String, dynamic> action) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h, right: 2.w),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.shadowLight,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              action["title"] as String,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textPrimaryLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(width: 2.w),

          // Action button
          GestureDetector(
            onTap: () => _handleAction(action["action"] as String),
            child: Container(
              width: 14.w,
              height: 14.w,
              decoration: BoxDecoration(
                color: action["color"] as Color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (action["color"] as Color).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: action["icon"] as String,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleAction(String action) {
    _toggleExpanded();

    switch (action) {
      case 'search':
        _showUserSearchDialog();
        break;
      case 'broadcast':
        _showBroadcastDialog();
        break;
      case 'export':
        _exportAnalytics();
        break;
      case 'status':
        _showSystemStatus();
        break;
    }
  }

  void _showUserSearchDialog() {
    final TextEditingController searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.lightTheme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              CustomIconWidget(
                iconName: 'search',
                color: AppTheme.primaryLight,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text(
                'User Search',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 80.w,
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: 'Search by email address...',
                prefixIcon: Icon(Icons.email),
              ),
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textPrimaryLight,
              ),
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
                Navigator.pop(context);
                if (searchController.text.isNotEmpty) {
                  _performUserSearch(searchController.text);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
              ),
              child: Text(
                'Search',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showBroadcastDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController messageController = TextEditingController();
    String selectedTarget = 'All Users';
    final List<String> targets = [
      'All Users',
      'Free Users',
      'Premium Users',
      'Specific Users'
    ];

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
              title: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'send',
                    color: AppTheme.secondaryLight,
                    size: 24,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Quick Broadcast',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 80.w,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedTarget,
                      decoration: const InputDecoration(
                        labelText: 'Target Audience',
                        prefixIcon: Icon(Icons.group),
                      ),
                      items: targets.map((String target) {
                        return DropdownMenuItem<String>(
                          value: target,
                          child: Text(target),
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
                    SizedBox(height: 2.h),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'Notification title...',
                        prefixIcon: Icon(Icons.title),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    TextField(
                      controller: messageController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        hintText: 'Your message...',
                        prefixIcon: Icon(Icons.message),
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
                    Navigator.pop(context);
                    if (titleController.text.isNotEmpty &&
                        messageController.text.isNotEmpty) {
                      _sendQuickBroadcast(titleController.text,
                          messageController.text, selectedTarget);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryLight,
                  ),
                  child: Text(
                    'Send',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
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

  void _exportAnalytics() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.lightTheme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              CustomIconWidget(
                iconName: 'download',
                color: AppTheme.successLight,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text(
                'Export Analytics',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildExportOption(
                  'User Analytics', 'CSV format with user data', 'people'),
              SizedBox(height: 2.h),
              _buildExportOption('Notification Reports',
                  'Delivery statistics and metrics', 'send'),
              SizedBox(height: 2.h),
              _buildExportOption(
                  'System Metrics', 'Performance and usage data', 'analytics'),
            ],
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
          ],
        );
      },
    );
  }

  Widget _buildExportOption(String title, String description, String iconName) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _performExport(title);
      },
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderLight, width: 1),
        ),
        child: Row(
          children: [
            CustomIconWidget(
              iconName: iconName,
              color: AppTheme.successLight,
              size: 24,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                  Text(
                    description,
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            CustomIconWidget(
              iconName: 'arrow_forward_ios',
              color: AppTheme.textSecondaryLight,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showSystemStatus() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.lightTheme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              CustomIconWidget(
                iconName: 'monitor_heart',
                color: AppTheme.warningLight,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text(
                'System Status',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusItem('API Server', 'Operational',
                  AppTheme.successLight, 'check_circle'),
              _buildStatusItem(
                  'Database', 'Operational', AppTheme.successLight, 'storage'),
              _buildStatusItem('Push Notifications', 'Operational',
                  AppTheme.successLight, 'notifications'),
              _buildStatusItem('AI Services', 'Degraded', AppTheme.warningLight,
                  'psychology'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _refreshSystemStatus();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warningLight,
              ),
              child: Text(
                'Refresh',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusItem(
      String service, String status, Color statusColor, String iconName) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: iconName,
            color: statusColor,
            size: 20,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              service,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textPrimaryLight,
                fontWeight: FontWeight.w500,
              ),
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
              status,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w500,
                fontSize: 9.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _performUserSearch(String email) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Searching for user: $email'),
        backgroundColor: AppTheme.primaryLight,
      ),
    );
  }

  void _sendQuickBroadcast(String title, String message, String target) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Broadcast "$title" sent to $target'),
        backgroundColor: AppTheme.secondaryLight,
      ),
    );
  }

  void _performExport(String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting $type...'),
        backgroundColor: AppTheme.successLight,
      ),
    );
  }

  void _refreshSystemStatus() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('System status refreshed'),
        backgroundColor: AppTheme.warningLight,
      ),
    );
  }
}
