import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';


class UsageAnalyticsWidget extends StatelessWidget {
  final Map<String, dynamic> usageData;
  final bool detailed;

  const UsageAnalyticsWidget({
    super.key,
    required this.usageData,
    this.detailed = false,
  });

  @override
  Widget build(BuildContext context) {
    final currentUsage = usageData['currentUsage'] ?? 0;
    final monthlyLimit = usageData['monthlyLimit'] ?? 10;
    final usagePercentage = (currentUsage / monthlyLimit).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                size: 24.sp,
                color: Colors.blue,
              ),
              SizedBox(width: 12.w),
              Text(
                'Usage Analytics',
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),

          // Usage progress bar
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Monthly Usage',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          '$currentUsage / $monthlyLimit',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    LinearProgressIndicator(
                      value: usagePercentage,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        usagePercentage > 0.8 ? Colors.red : Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (detailed) ...[
            SizedBox(height: 24.h),
            _buildDetailedStats(),
          ],

          SizedBox(height: 20.h),

          // Recent usage items
          Text(
            'Recent Activity',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 12.h),

          if (usageData['recentUsage'] != null) ...[
            ...List.generate(
              (usageData['recentUsage'] as List).take(3).length,
              (index) {
                final usage = (usageData['recentUsage'] as List)[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Row(
                    children: [
                      Container(
                        width: 8.w,
                        height: 8.h,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          usage['ai_summaries']?['title'] ??
                              'AI Summary Generated',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      Text(
                        _formatTimestamp(usage['created_at']),
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailedStats() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Subscription Tier',
                  usageData['tier']?.toString().toUpperCase() ?? 'FREE',
                  Icons.card_membership,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildStatItem(
                  'Total Requests',
                  usageData['totalUsage']?.toString() ?? '0',
                  Icons.insights,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Success Rate',
                  '98.5%',
                  Icons.check_circle,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildStatItem(
                  'Avg Response',
                  '1.2s',
                  Icons.timer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20.sp, color: Colors.blue),
        SizedBox(height: 8.h),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return '';
    }
  }
}