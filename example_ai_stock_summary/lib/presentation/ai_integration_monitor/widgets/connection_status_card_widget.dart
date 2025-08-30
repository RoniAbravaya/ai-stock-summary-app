import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';


class ConnectionStatusCardWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isConnected;
  final IconData icon;
  final VoidCallback? onTap;

  const ConnectionStatusCardWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isConnected,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isConnected
                ? Colors.green.withAlpha(77)
                : Colors.red.withAlpha(77),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(26),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color:
                        (isConnected ? Colors.green : Colors.red).withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 20.sp,
                    color: isConnected ? Colors.green : Colors.red,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 8.w,
                  height: 8.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isConnected ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}