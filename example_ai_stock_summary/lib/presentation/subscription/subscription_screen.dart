import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../models/subscription_model.dart';
import '../../services/subscription_service.dart';
import '../../widgets/custom_error_widget.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();

  bool _isLoading = true;
  bool _isProcessing = false;
  SubscriptionModel? _subscription;
  Map<String, dynamic> _usageStats = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();
  }

  Future<void> _loadSubscriptionData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final subscription = await _subscriptionService.getUserSubscription();
      final stats = await _subscriptionService.getUsageStats();

      setState(() {
        _subscription = subscription;
        _usageStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _upgradeToPremium(bool isYearly) async {
    setState(() => _isProcessing = true);

    try {
      final success =
          await _subscriptionService.purchasePremium(isYearly: isYearly);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Processing your upgrade...'),
            backgroundColor: Colors.green,
          ),
        );
        // Reload data after a delay to allow processing
        await Future.delayed(const Duration(seconds: 2));
        await _loadSubscriptionData();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upgrade failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _watchRewardedAd() async {
    setState(() => _isProcessing = true);

    try {
      final canWatch = await _subscriptionService.canWatchAdToday();
      if (!canWatch) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'You have already watched an ad today. Try again tomorrow!'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final success = await _subscriptionService.showRewardedAd();
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Congratulations! You earned 1 extra summary!'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadSubscriptionData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ad not available. Please try again later.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading ad: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? CustomErrorWidget(
                  message: _error!,
                  onRetry: _loadSubscriptionData,
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCurrentPlanCard(),
                      SizedBox(height: 3.h),
                      _buildUsageStatsCard(),
                      SizedBox(height: 3.h),
                      if (_subscription?.isFree == true) ...[
                        _buildPremiumOffersCard(),
                        SizedBox(height: 3.h),
                      ],
                      _buildRewardAdCard(),
                      SizedBox(height: 3.h),
                      _buildFeaturesComparison(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildCurrentPlanCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _subscription?.isPremium == true
              ? [Colors.purple, Colors.deepPurple]
              : [Colors.blue, Colors.indigo],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Plan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _subscription?.statusDisplayName ?? 'Active',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            _subscription?.tierDisplayName ?? 'Free',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            '${_subscription?.monthlySummaryLimit ?? 10} AI summaries per month',
            style: TextStyle(
              color: Colors.white.withAlpha(230),
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageStatsCard() {
    final totalUsage = _usageStats['total_usage'] ?? 0;
    final usageLimit = _usageStats['usage_limit'] ?? 10;
    final remaining = _usageStats['remaining'] ?? 0;
    final usagePercentage = _usageStats['usage_percentage'] ?? 0.0;
    final daysUntilReset = _usageStats['days_until_reset'] ?? 0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Usage This Month',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Used',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 10.sp,
                    ),
                  ),
                  Text(
                    '$totalUsage',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Remaining',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 10.sp,
                    ),
                  ),
                  Text(
                    '$remaining',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Limit',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 10.sp,
                    ),
                  ),
                  Text(
                    '$usageLimit',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 2.h),
          LinearProgressIndicator(
            value: usagePercentage / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              usagePercentage > 80 ? Colors.red : Colors.blue,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Resets in $daysUntilReset days',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumOffersCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber, size: 20.sp),
              SizedBox(width: 2.w),
              Text(
                'Upgrade to Premium',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            '• 100 AI summaries per month\n• Priority support\n• Advanced analytics\n• Ad-free experience',
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          SizedBox(height: 3.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      _isProcessing ? null : () => _upgradeToPremium(false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Monthly',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$4.99/mo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      _isProcessing ? null : () => _upgradeToPremium(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Yearly',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$49.99/yr',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                        ),
                      ),
                      Text(
                        'Save 17%',
                        style: TextStyle(
                          color: Colors.yellow[300],
                          fontSize: 9.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRewardAdCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.play_circle, color: Colors.green, size: 20.sp),
              SizedBox(width: 2.w),
              Text(
                'Earn Extra Summaries',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Watch a short video ad to earn 1 extra AI summary. Limit: 1 per day.',
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _watchRewardedAd,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isProcessing
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.video_library, color: Colors.white),
                        SizedBox(width: 2.w),
                        Text(
                          'Watch Ad (+1 Summary)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesComparison() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Plan Comparison',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          _buildFeatureRow('AI Summaries', '10/month', '100/month'),
          _buildFeatureRow('Stock Alerts', '✓', '✓'),
          _buildFeatureRow('Portfolio Tracking', '✓', '✓'),
          _buildFeatureRow('Multilingual Support', '✓', '✓'),
          _buildFeatureRow('Priority Support', '✗', '✓'),
          _buildFeatureRow('Advanced Analytics', '✗', '✓'),
          _buildFeatureRow('Ad-free Experience', '✗', '✓'),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(
      String feature, String freeValue, String premiumValue) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              feature,
              style: TextStyle(fontSize: 10.sp),
            ),
          ),
          Expanded(
            child: Text(
              freeValue,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              premiumValue,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.purple,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
