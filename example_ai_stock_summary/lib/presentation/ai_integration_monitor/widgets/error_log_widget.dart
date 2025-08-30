import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class ErrorLogWidget extends StatelessWidget {
  final List<Map<String, dynamic>> errorLogs;

  const ErrorLogWidget({
    super.key,
    required this.errorLogs,
  });

  @override
  Widget build(BuildContext context) {
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
                Icons.error_outline,
                size: 24.sp,
                color: Colors.red,
              ),
              SizedBox(width: 12.w),
              Text(
                'Error Logs',
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: errorLogs.isEmpty
                      ? Colors.green.withAlpha(26)
                      : Colors.red.withAlpha(26),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Text(
                  errorLogs.isEmpty
                      ? 'No Errors'
                      : '${errorLogs.length} Errors',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: errorLogs.isEmpty ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),

          if (errorLogs.isEmpty) ...[
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64.sp,
                    color: Colors.green.withAlpha(128),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'No Recent Errors',
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'All integrations are running smoothly',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ...errorLogs.map((error) => _buildErrorLogItem(error)),
          ],

          SizedBox(height: 16.h),

          // Quick actions for error management
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Export error logs
                  },
                  icon: Icon(Icons.download, size: 16.sp),
                  label: Text(
                    'Export Logs',
                    style: GoogleFonts.inter(fontSize: 14.sp),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Clear error logs
                  },
                  icon: Icon(Icons.clear_all, size: 16.sp),
                  label: Text(
                    'Clear Logs',
                    style: GoogleFonts.inter(fontSize: 14.sp),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorLogItem(Map<String, dynamic> error) {
    final severity = error['severity'] as String;
    final color = _getSeverityColor(severity);
    final icon = _getSeverityIcon(severity);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20.sp, color: color),
              SizedBox(width: 8.w),
              Text(
                error['type'] ?? 'Unknown Error',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: color.withAlpha(51),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  error['statusCode']?.toString() ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            error['message'] ?? '',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(Icons.access_time, size: 14.sp, color: Colors.grey[500]),
              SizedBox(width: 4.w),
              Text(
                _formatErrorTimestamp(error['timestamp']),
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: Colors.grey[500],
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  _showErrorDetails(error);
                },
                child: Text(
                  'View Details',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'error':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'info':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getSeverityIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'error':
        return Icons.error;
      case 'warning':
        return Icons.warning;
      case 'info':
        return Icons.info;
      default:
        return Icons.help;
    }
  }

  String _formatErrorTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _showErrorDetails(Map<String, dynamic> error) {
    // Show detailed error information in a dialog
    // This would be implemented based on the specific error structure
  }
}