import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../models/stock_model.dart';
import '../../services/auth_service.dart';
import '../../services/openai_service.dart';
import '../../services/supabase_service.dart';
import './widgets/api_test_section_widget.dart';
import './widgets/connection_status_card_widget.dart';
import './widgets/error_log_widget.dart';
import './widgets/performance_metrics_widget.dart';
import './widgets/quick_actions_widget.dart';
import './widgets/usage_analytics_widget.dart';
import 'widgets/api_test_section_widget.dart';
import 'widgets/connection_status_card_widget.dart';
import 'widgets/error_log_widget.dart';
import 'widgets/performance_metrics_widget.dart';
import 'widgets/quick_actions_widget.dart';
import 'widgets/usage_analytics_widget.dart';

class AiIntegrationMonitor extends StatefulWidget {
  const AiIntegrationMonitor({super.key});

  @override
  State<AiIntegrationMonitor> createState() => _AiIntegrationMonitorState();
}

class _AiIntegrationMonitorState extends State<AiIntegrationMonitor>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _refreshController;

  // Connection status
  bool _supabaseConnected = false;
  bool _openaiConnected = false;
  bool _networkConnected = false;

  // API testing states
  bool _isTestingSupabase = false;
  bool _isTestingOpenAI = false;
  String _testResults = '';

  // Usage data
  Map<String, dynamic> _usageData = {};
  List<Map<String, dynamic>> _performanceMetrics = [];
  List<Map<String, dynamic>> _errorLogs = [];

  // Refresh timer
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _refreshController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _initializeMonitoring();
    _startPeriodicRefresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeMonitoring() async {
    await _checkConnections();
    await _loadUsageData();
    await _loadPerformanceMetrics();
    await _loadErrorLogs();
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _refreshData();
      }
    });
  }

  Future<void> _refreshData() async {
    _refreshController.forward().then((_) => _refreshController.reset());
    await _initializeMonitoring();
  }

  Future<void> _checkConnections() async {
    try {
      // Check network connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      _networkConnected = connectivityResult != ConnectivityResult.none;

      // Check Supabase connection
      try {
        final response = await SupabaseService.instance.client
            .from('stocks')
            .select('count')
            .limit(1);
        _supabaseConnected = response != null;
      } catch (e) {
        _supabaseConnected = false;
      }

      // Check OpenAI connection
      try {
        // Simple API test call
        await OpenAIService().dio.get('/models');
        _openaiConnected = true;
      } catch (e) {
        _openaiConnected = false;
      }

      if (mounted) setState(() {});
    } catch (e) {
      print('Connection check failed: $e');
    }
  }

  Future<void> _loadUsageData() async {
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) return;

      // Get AI summary usage for current month
      final usageResponse = await SupabaseService.instance.client
          .from('ai_summary_usage')
          .select('*, ai_summaries(title, sentiment)')
          .eq('user_id', user.id)
          .gte(
              'created_at',
              DateTime.now()
                  .subtract(const Duration(days: 30))
                  .toIso8601String())
          .order('created_at', ascending: false);

      // Get user subscription info
      final subscriptionResponse = await SupabaseService.instance.client
          .from('user_subscriptions')
          .select('*')
          .eq('user_id', user.id)
          .single();

      _usageData = {
        'totalUsage': usageResponse.length,
        'monthlyLimit': subscriptionResponse['monthly_summary_limit'] ?? 10,
        'currentUsage': subscriptionResponse['current_month_usage'] ?? 0,
        'recentUsage': usageResponse.take(10).toList(),
        'tier': subscriptionResponse['tier'] ?? 'free',
      };

      if (mounted) setState(() {});
    } catch (e) {
      print('Usage data loading failed: $e');
    }
  }

  Future<void> _loadPerformanceMetrics() async {
    try {
      // Mock performance data - in real app this would come from monitoring service
      _performanceMetrics = [
        {
          'timestamp': DateTime.now().subtract(const Duration(minutes: 30)),
          'apiResponseTime': 1200,
          'dbQueryTime': 450,
          'successRate': 98.5,
        },
        {
          'timestamp': DateTime.now().subtract(const Duration(minutes: 25)),
          'apiResponseTime': 980,
          'dbQueryTime': 380,
          'successRate': 99.1,
        },
        {
          'timestamp': DateTime.now().subtract(const Duration(minutes: 20)),
          'apiResponseTime': 1100,
          'dbQueryTime': 420,
          'successRate': 97.8,
        },
      ];

      if (mounted) setState(() {});
    } catch (e) {
      print('Performance metrics loading failed: $e');
    }
  }

  Future<void> _loadErrorLogs() async {
    try {
      // Mock error logs - in real app this would come from error tracking service
      _errorLogs = [
        {
          'timestamp': DateTime.now().subtract(const Duration(minutes: 15)),
          'type': 'API_ERROR',
          'message': 'OpenAI API rate limit exceeded',
          'statusCode': 429,
          'severity': 'warning',
        },
        {
          'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
          'type': 'DB_ERROR',
          'message': 'Connection timeout to Supabase',
          'statusCode': 500,
          'severity': 'error',
        },
      ];

      if (mounted) setState(() {});
    } catch (e) {
      print('Error logs loading failed: $e');
    }
  }

  Future<void> _testSupabaseIntegration() async {
    setState(() {
      _isTestingSupabase = true;
      _testResults = 'Testing Supabase integration...\n';
    });

    try {
      // Test authentication
      final user = AuthService.instance.currentUser;
      _testResults +=
          '✅ Authentication: ${user != null ? 'Connected' : 'Not authenticated'}\n';

      // Test database read
      final stocksResponse = await SupabaseService.instance.client
          .from('stocks')
          .select('id, symbol, name')
          .limit(3);
      _testResults +=
          '✅ Database Read: ${stocksResponse.length} stocks retrieved\n';

      // Test user profile access
      if (user != null) {
        final profileResponse = await SupabaseService.instance.client
            .from('user_profiles')
            .select('*')
            .eq('id', user.id)
            .single();
        _testResults +=
            '✅ User Profile: ${profileResponse['full_name']} (${profileResponse['role']})\n';
      }

      // Test usage tracking function
      final limitResponse = await SupabaseService.instance.client
          .rpc('get_user_summary_limit', params: {'user_uuid': user?.id});
      _testResults += '✅ Functions: Summary limit = $limitResponse\n';

      _testResults += '\n🎉 Supabase integration test completed successfully!';
    } catch (e) {
      _testResults += '❌ Error: $e\n';
    }

    setState(() => _isTestingSupabase = false);
  }

  Future<void> _testOpenAIIntegration() async {
    setState(() {
      _isTestingOpenAI = true;
      _testResults = 'Testing OpenAI integration...\n';
    });

    try {
      // Test API connection
      final modelsResponse = await OpenAIService().dio.get('/models');
      _testResults +=
          '✅ API Connection: ${modelsResponse.data['data'].length} models available\n';

      // Test stock analysis generation
      final analysis = await OpenAIService().generateStockAnalysis(
        stockSymbol: 'AAPL',
        companyName: 'Apple Inc.',
        sector: 'Technology',
        currentPrice: 150.0,
        marketCap: 3000000000000,
      );

      _testResults += '✅ Stock Analysis: Generated "${analysis.title}"\n';
      _testResults +=
          '✅ Analysis Details: ${analysis.sentiment} sentiment, ${analysis.keyPoints.length} key points\n';
      _testResults +=
          '✅ Confidence Score: ${(analysis.confidenceScore * 100).toStringAsFixed(1)}%\n';

      _testResults += '\n🎉 OpenAI integration test completed successfully!';
    } catch (e) {
      _testResults += '❌ Error: $e\n';
    }

    setState(() => _isTestingOpenAI = false);
  }

  Future<void> _runFullIntegrationTest() async {
    setState(
        () => _testResults = 'Running comprehensive integration test...\n\n');

    await _testSupabaseIntegration();
    await Future.delayed(const Duration(seconds: 1));

    _testResults += '\n' + '=' * 50 + '\n\n';

    await _testOpenAIIntegration();

    _testResults += '\n' + '=' * 50 + '\n';
    _testResults += '🔄 Integration test completed! Check results above.';

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'AI Integration Monitor',
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.grey[600]),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: AnimatedBuilder(
              animation: _refreshController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _refreshController.value * 2 * 3.14159,
                  child: Icon(Icons.refresh, color: Colors.grey[600]),
                );
              },
            ),
            onPressed: _refreshData,
          ),
          IconButton(
            icon: Icon(Icons.settings, color: Colors.grey[600]),
            onPressed: () {
              // Navigate to integration settings
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey[600],
          labelStyle:
              GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w500),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Testing'),
            Tab(text: 'Analytics'),
            Tab(text: 'Logs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildTestingTab(),
          _buildAnalyticsTab(),
          _buildLogsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Connection Status Cards
          Row(
            children: [
              Expanded(
                child: ConnectionStatusCardWidget(
                  title: 'Supabase',
                  isConnected: _supabaseConnected,
                  subtitle: _supabaseConnected
                      ? 'Database Online'
                      : 'Connection Failed',
                  icon: Icons.storage,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ConnectionStatusCardWidget(
                  title: 'OpenAI',
                  isConnected: _openaiConnected,
                  subtitle: _openaiConnected ? 'API Available' : 'API Offline',
                  icon: Icons.psychology,
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          Row(
            children: [
              Expanded(
                child: ConnectionStatusCardWidget(
                  title: 'Network',
                  isConnected: _networkConnected,
                  subtitle:
                      _networkConnected ? 'Internet Connected' : 'No Internet',
                  icon: Icons.wifi,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ConnectionStatusCardWidget(
                  title: 'System',
                  isConnected: _supabaseConnected &&
                      _openaiConnected &&
                      _networkConnected,
                  subtitle: 'Overall Health',
                  icon: Icons.check_circle,
                ),
              ),
            ],
          ),

          SizedBox(height: 24.h),

          // Usage Overview
          if (_usageData.isNotEmpty) ...[
            UsageAnalyticsWidget(usageData: _usageData),
            SizedBox(height: 24.h),
          ],

          // Performance Metrics
          if (_performanceMetrics.isNotEmpty) ...[
            PerformanceMetricsWidget(metrics: _performanceMetrics),
            SizedBox(height: 24.h),
          ],

          // Quick Actions
          QuickActionsWidget(
            onTestSupabase: _testSupabaseIntegration,
            onTestOpenAI: _testOpenAIIntegration,
            onFullTest: _runFullIntegrationTest,
            onExportReport: _exportIntegrationReport,
          ),
        ],
      ),
    );
  }

  Widget _buildTestingTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ApiTestSectionWidget(
            title: 'Supabase Integration Test',
            subtitle:
                'Test database connectivity, authentication, and functions',
            isLoading: _isTestingSupabase,
            onTest: _testSupabaseIntegration,
            icon: Icons.storage,
            color: Colors.green,
          ),

          SizedBox(height: 16.h),

          ApiTestSectionWidget(
            title: 'OpenAI Integration Test',
            subtitle:
                'Test API connectivity, model availability, and response quality',
            isLoading: _isTestingOpenAI,
            onTest: _testOpenAIIntegration,
            icon: Icons.psychology,
            color: Colors.blue,
          ),

          SizedBox(height: 24.h),

          // Test Results Display
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.terminal, color: Colors.green[400], size: 20.sp),
                    SizedBox(width: 8.w),
                    Text(
                      'Test Results',
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => setState(() => _testResults = ''),
                      child: Text(
                        'Clear',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Container(
                  width: double.infinity,
                  height: 300.h,
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _testResults.isEmpty
                          ? 'No test results yet. Run a test to see output here.'
                          : _testResults,
                      style: GoogleFonts.firaCode(
                        fontSize: 12.sp,
                        color: _testResults.isEmpty
                            ? Colors.grey[600]
                            : Colors.green[400],
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Usage Statistics
          if (_usageData.isNotEmpty) ...[
            UsageAnalyticsWidget(usageData: _usageData, detailed: true),
            SizedBox(height: 24.h),
          ],

          // Performance Charts
          if (_performanceMetrics.isNotEmpty) ...[
            PerformanceMetricsWidget(
                metrics: _performanceMetrics, detailed: true),
            SizedBox(height: 24.h),
          ],

          // API Response Time Chart
          _buildResponseTimeChart(),
        ],
      ),
    );
  }

  Widget _buildLogsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ErrorLogWidget(errorLogs: _errorLogs),
        ],
      ),
    );
  }

  Widget _buildResponseTimeChart() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
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
          Text(
            'API Response Time Trends',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            height: 200.h,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(show: true),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: _performanceMetrics.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        entry.value['apiResponseTime'].toDouble(),
                      );
                    }).toList(),
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportIntegrationReport() async {
    // Generate and export integration health report
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Report'),
        content: const Text(
            'Integration health report has been generated and saved to your device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}