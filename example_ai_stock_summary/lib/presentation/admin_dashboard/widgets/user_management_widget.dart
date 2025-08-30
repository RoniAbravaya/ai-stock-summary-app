import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class UserManagementWidget extends StatefulWidget {
  const UserManagementWidget({super.key});

  @override
  State<UserManagementWidget> createState() => _UserManagementWidgetState();
}

class _UserManagementWidgetState extends State<UserManagementWidget> {
  final TextEditingController _searchController = TextEditingController();
  String selectedFilter = 'All Users';
  final List<String> filterOptions = [
    'All Users',
    'Free Users',
    'Premium Users',
    'Admins'
  ];

  final List<Map<String, dynamic>> recentUsers = [
    {
      "id": "1",
      "name": "Sarah Johnson",
      "email": "sarah.johnson@email.com",
      "avatar":
          "https://images.unsplash.com/photo-1494790108755-2616b612b786?w=150&h=150&fit=crop&crop=face",
      "subscriptionType": "Premium",
      "joinDate": "2025-08-26",
      "isActive": true,
      "role": "User"
    },
    {
      "id": "2",
      "name": "Michael Chen",
      "email": "michael.chen@email.com",
      "avatar":
          "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face",
      "subscriptionType": "Free",
      "joinDate": "2025-08-25",
      "isActive": true,
      "role": "User"
    },
    {
      "id": "3",
      "name": "Emily Rodriguez",
      "email": "emily.rodriguez@email.com",
      "avatar":
          "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face",
      "subscriptionType": "Premium",
      "joinDate": "2025-08-24",
      "isActive": false,
      "role": "User"
    },
    {
      "id": "4",
      "name": "David Park",
      "email": "david.park@email.com",
      "avatar":
          "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face",
      "subscriptionType": "Free",
      "joinDate": "2025-08-23",
      "isActive": true,
      "role": "Admin"
    },
    {
      "id": "5",
      "name": "Lisa Thompson",
      "email": "lisa.thompson@email.com",
      "avatar":
          "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&h=150&fit=crop&crop=face",
      "subscriptionType": "Premium",
      "joinDate": "2025-08-22",
      "isActive": true,
      "role": "User"
    },
  ];

  List<Map<String, dynamic>> get filteredUsers {
    List<Map<String, dynamic>> filtered = recentUsers;

    if (selectedFilter != 'All Users') {
      if (selectedFilter == 'Free Users') {
        filtered = filtered
            .where((user) => user["subscriptionType"] == "Free")
            .toList();
      } else if (selectedFilter == 'Premium Users') {
        filtered = filtered
            .where((user) => user["subscriptionType"] == "Premium")
            .toList();
      } else if (selectedFilter == 'Admins') {
        filtered = filtered.where((user) => user["role"] == "Admin").toList();
      }
    }

    if (_searchController.text.isNotEmpty) {
      filtered = filtered
          .where((user) =>
              (user["name"] as String)
                  .toLowerCase()
                  .contains(_searchController.text.toLowerCase()) ||
              (user["email"] as String)
                  .toLowerCase()
                  .contains(_searchController.text.toLowerCase()))
          .toList();
    }

    return filtered;
  }

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
                    'User Management',
                    style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'Recent registrations and user actions',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildActionButton(
                      'Bulk Actions', 'group_work', AppTheme.primaryLight),
                  SizedBox(width: 2.w),
                  _buildActionButton(
                      'Export', 'download', AppTheme.textSecondaryLight),
                ],
              ),
            ],
          ),
          SizedBox(height: 3.h),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderLight, width: 1),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search by name or email...',
                      prefixIcon: Padding(
                        padding: EdgeInsets.all(3.w),
                        child: CustomIconWidget(
                          iconName: 'search',
                          color: AppTheme.textSecondaryLight,
                          size: 20,
                        ),
                      ),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                    ),
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderLight, width: 1),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedFilter,
                      isExpanded: true,
                      items: filterOptions.map((String option) {
                        return DropdownMenuItem<String>(
                          value: option,
                          child: Text(
                            option,
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                              color: AppTheme.textPrimaryLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedFilter = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredUsers.length > 5 ? 5 : filteredUsers.length,
            separatorBuilder: (context, index) => SizedBox(height: 2.h),
            itemBuilder: (context, index) {
              final user = filteredUsers[index];
              return _buildUserCard(user);
            },
          ),
          if (filteredUsers.length > 5) ...[
            SizedBox(height: 2.h),
            Center(
              child: TextButton(
                onPressed: () {
                  // Navigate to full user list
                },
                child: Text(
                  'View All Users (${filteredUsers.length})',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.primaryLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, String iconName, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(
            iconName: iconName,
            color: color,
            size: 16,
          ),
          SizedBox(width: 1.w),
          Text(
            label,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return GestureDetector(
      onLongPress: () => _showUserActions(user),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppTheme.borderLight.withValues(alpha: 0.5), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderLight, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CustomImageWidget(
                  imageUrl: user["avatar"] as String,
                  width: 12.w,
                  height: 12.w,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user["name"] as String,
                          style: AppTheme.lightTheme.textTheme.titleSmall
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildStatusBadge(user["subscriptionType"] as String),
                    ],
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    user["email"] as String,
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 1.h),
                  Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'calendar_today',
                        color: AppTheme.textSecondaryLight,
                        size: 14,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        'Joined ${user["joinDate"]}',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryLight,
                          fontSize: 10.sp,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 2.w,
                        height: 2.w,
                        decoration: BoxDecoration(
                          color: (user["isActive"] as bool)
                              ? AppTheme.successLight
                              : AppTheme.textDisabledLight,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        (user["isActive"] as bool) ? 'Active' : 'Inactive',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: (user["isActive"] as bool)
                              ? AppTheme.successLight
                              : AppTheme.textDisabledLight,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            CustomIconWidget(
              iconName: 'more_vert',
              color: AppTheme.textSecondaryLight,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String subscriptionType) {
    Color badgeColor = subscriptionType == 'Premium'
        ? AppTheme.successLight
        : AppTheme.textSecondaryLight;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        subscriptionType,
        style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
          color: badgeColor,
          fontWeight: FontWeight.w500,
          fontSize: 9.sp,
        ),
      ),
    );
  }

  void _showUserActions(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                  color: AppTheme.borderLight,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(height: 3.h),
              Text(
                'User Actions',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              SizedBox(height: 3.h),
              _buildActionTile('View Profile', 'person', () {}),
              _buildActionTile('Send Direct Message', 'message', () {}),
              _buildActionTile('Manage Subscription', 'star', () {}),
              _buildActionTile(
                  'Promote to Admin', 'admin_panel_settings', () {}),
              SizedBox(height: 2.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionTile(String title, String iconName, VoidCallback onTap) {
    return ListTile(
      leading: CustomIconWidget(
        iconName: iconName,
        color: AppTheme.primaryLight,
        size: 24,
      ),
      title: Text(
        title,
        style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
          color: AppTheme.textPrimaryLight,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
