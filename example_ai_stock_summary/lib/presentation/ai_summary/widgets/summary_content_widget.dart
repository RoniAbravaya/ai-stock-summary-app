import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SummaryContentWidget extends StatelessWidget {
  final Map<String, dynamic> summaryData;

  const SummaryContentWidget({
    super.key,
    required this.summaryData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Executive Summary'),
          SizedBox(height: 1.h),
          _buildSectionContent(
              summaryData['executiveSummary'] as String? ?? ''),
          SizedBox(height: 3.h),
          _buildSectionHeader('Financial Health'),
          SizedBox(height: 1.h),
          _buildBulletPoints(
              summaryData['financialHealth'] as List<String>? ?? []),
          SizedBox(height: 3.h),
          _buildSectionHeader('Market Position'),
          SizedBox(height: 1.h),
          _buildBulletPoints(
              summaryData['marketPosition'] as List<String>? ?? []),
          SizedBox(height: 3.h),
          _buildSectionHeader('Investment Outlook'),
          SizedBox(height: 1.h),
          _buildInvestmentOutlook(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppTheme.lightTheme.colorScheme.onSurface,
        height: 1.2,
      ),
    );
  }

  Widget _buildSectionContent(String content) {
    return Text(
      content,
      style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
        color: AppTheme.lightTheme.colorScheme.onSurface,
        height: 1.6,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildBulletPoints(List<String> points) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: points.map((point) => _buildBulletPoint(point)).toList(),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 0.8.h, right: 3.w),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentOutlook() {
    final outlook =
        summaryData['investmentOutlook'] as Map<String, dynamic>? ?? {};
    final recommendation = outlook['recommendation'] as String? ?? 'Hold';
    final reasoning = outlook['reasoning'] as String? ?? '';
    final riskLevel = outlook['riskLevel'] as String? ?? 'Medium';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          decoration: BoxDecoration(
            color:
                _getRecommendationColor(recommendation).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getRecommendationColor(recommendation)
                  .withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CustomIconWidget(
                    iconName: _getRecommendationIcon(recommendation),
                    color: _getRecommendationColor(recommendation),
                    size: 24,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Recommendation: $recommendation',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _getRecommendationColor(recommendation),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              Text(
                reasoning,
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            CustomIconWidget(
              iconName: 'warning',
              color: _getRiskColor(riskLevel),
              size: 20,
            ),
            SizedBox(width: 2.w),
            Text(
              'Risk Level: $riskLevel',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: _getRiskColor(riskLevel),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getRecommendationColor(String recommendation) {
    switch (recommendation.toLowerCase()) {
      case 'buy':
      case 'strong buy':
        return AppTheme.lightTheme.colorScheme.tertiary;
      case 'sell':
      case 'strong sell':
        return AppTheme.lightTheme.colorScheme.error;
      case 'hold':
      default:
        return AppTheme.lightTheme.colorScheme.primary;
    }
  }

  String _getRecommendationIcon(String recommendation) {
    switch (recommendation.toLowerCase()) {
      case 'buy':
      case 'strong buy':
        return 'trending_up';
      case 'sell':
      case 'strong sell':
        return 'trending_down';
      case 'hold':
      default:
        return 'trending_flat';
    }
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'low':
        return AppTheme.lightTheme.colorScheme.tertiary;
      case 'high':
        return AppTheme.lightTheme.colorScheme.error;
      case 'medium':
      default:
        return AppTheme.lightTheme.colorScheme.secondary;
    }
  }
}
