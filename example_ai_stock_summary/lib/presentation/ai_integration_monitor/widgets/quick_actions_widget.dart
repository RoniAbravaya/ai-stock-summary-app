import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';


class QuickActionsWidget extends StatelessWidget {
  final VoidCallback onTestSupabase;
  final VoidCallback onTestOpenAI;
  final VoidCallback onFullTest;
  final VoidCallback onExportReport;

  const QuickActionsWidget({
    super.key,
    required this.onTestSupabase,
    required this.onTestOpenAI,
    required this.onFullTest,
    required this.onExportReport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
                Icons.flash_on,
                size: 24.sp,
                color: Colors.amber,
              ),
              SizedBox(width: 12.w),
              Text(
                'Quick Actions',
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),

          // Action buttons grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12.h,
            crossAxisSpacing: 12.w,
            childAspectRatio: 2.5,
            children: [
              _buildActionButton(
                'Test Supabase',
                Icons.storage,
                Colors.green,
                onTestSupabase,
              ),
              _buildActionButton(
                'Test OpenAI',
                Icons.psychology,
                Colors.blue,
                onTestOpenAI,
              ),
              _buildActionButton(
                'Full Test',
                Icons.play_circle_filled,
                Colors.purple,
                onFullTest,
              ),
              _buildActionButton(
                'Export Report',
                Icons.download,
                Colors.orange,
                onExportReport,
              ),
            ],
          ),

          SizedBox(height: 20.h),

          // Emergency actions
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.red.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withAlpha(77)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning, size: 20.sp, color: Colors.red),
                    SizedBox(width: 8.w),
                    Text(
                      'Emergency Actions',
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showDisableApiDialog(context);
                        },
                        icon: Icon(Icons.power_off,
                            size: 16.sp, color: Colors.red),
                        label: Text(
                          'Disable API',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            color: Colors.red,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showResetCacheDialog(context);
                        },
                        icon:
                            Icon(Icons.refresh, size: 16.sp, color: Colors.red),
                        label: Text(
                          'Reset Cache',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            color: Colors.red,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withAlpha(26),
        foregroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withAlpha(77)),
        ),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20.sp, color: color),
          SizedBox(height: 4.h),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showDisableApiDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable API Access'),
        content: const Text(
          'This will temporarily disable OpenAI API calls to prevent further charges. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement API disable logic
            },
            child: const Text('Disable', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showResetCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Cache'),
        content: const Text(
          'This will clear all cached data and force fresh API calls. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement cache reset logic
            },
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}