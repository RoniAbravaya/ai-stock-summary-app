import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/empty_portfolio_widget.dart';
import './widgets/holding_card_widget.dart';
import './widgets/performance_chart_widget.dart';
import './widgets/portfolio_ai_summary_widget.dart';
import './widgets/portfolio_allocation_widget.dart';
import './widgets/portfolio_header_widget.dart';

class Portfolio extends StatefulWidget {
  const Portfolio({Key? key}) : super(key: key);

  @override
  State<Portfolio> createState() => _PortfolioState();
}

class _PortfolioState extends State<Portfolio> with TickerProviderStateMixin {
  bool _isLoading = false;
  bool _isOffline = false;
  String _sortBy = 'performance'; // performance, alphabetical, allocation
  DateTime _lastUpdated = DateTime.now();

  late TabController _tabController;

  // Mock portfolio data
  final List<Map<String, dynamic>> _holdings = [
    {
      "id": 1,
      "symbol": "AAPL",
      "companyName": "Apple Inc.",
      "shares": 50,
      "averageCost": 150.25,
      "currentPrice": 175.80,
      "currentValue": 8790.00,
      "gainLoss": 1277.50,
      "gainLossPercentage": 17.0,
      "allocationPercentage": 35.2,
    },
    {
      "id": 2,
      "symbol": "GOOGL",
      "companyName": "Alphabet Inc.",
      "shares": 25,
      "averageCost": 2450.00,
      "currentPrice": 2680.50,
      "currentValue": 6701.25,
      "gainLoss": 576.25,
      "gainLossPercentage": 9.4,
      "allocationPercentage": 26.8,
    },
    {
      "id": 3,
      "symbol": "TSLA",
      "companyName": "Tesla, Inc.",
      "shares": 30,
      "averageCost": 220.00,
      "currentPrice": 195.75,
      "currentValue": 5872.50,
      "gainLoss": -727.50,
      "gainLossPercentage": -11.0,
      "allocationPercentage": 23.5,
    },
    {
      "id": 4,
      "symbol": "MSFT",
      "companyName": "Microsoft Corporation",
      "shares": 20,
      "averageCost": 310.50,
      "currentPrice": 335.20,
      "currentValue": 6704.00,
      "gainLoss": 494.00,
      "gainLossPercentage": 7.9,
      "allocationPercentage": 14.5,
    },
  ];

  final List<Map<String, dynamic>> _chartData = [
    {"date": "2025-08-21", "value": 24500.00},
    {"date": "2025-08-22", "value": 24750.00},
    {"date": "2025-08-23", "value": 24200.00},
    {"date": "2025-08-24", "value": 25100.00},
    {"date": "2025-08-25", "value": 24800.00},
    {"date": "2025-08-26", "value": 25300.00},
    {"date": "2025-08-27", "value": 25067.75},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadPortfolioData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPortfolioData() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 1500));

    setState(() {
      _isLoading = false;
      _lastUpdated = DateTime.now();
    });
  }

  Future<void> _refreshPortfolio() async {
    HapticFeedback.lightImpact();
    await _loadPortfolioData();
  }

  void _sortHoldings(String sortBy) {
    setState(() {
      _sortBy = sortBy;
      switch (sortBy) {
        case 'performance':
          _holdings.sort((a, b) => (b['gainLossPercentage'] as num)
              .compareTo(a['gainLossPercentage'] as num));
          break;
        case 'alphabetical':
          _holdings.sort((a, b) =>
              (a['symbol'] as String).compareTo(b['symbol'] as String));
          break;
        case 'allocation':
          _holdings.sort((a, b) => (b['allocationPercentage'] as num)
              .compareTo(a['allocationPercentage'] as num));
          break;
      }
    });
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Sort Holdings',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            _buildSortOption('Performance', 'performance', 'trending_up'),
            _buildSortOption('Alphabetical', 'alphabetical', 'sort_by_alpha'),
            _buildSortOption('Allocation %', 'allocation', 'pie_chart'),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String title, String value, String icon) {
    final bool isSelected = _sortBy == value;
    return ListTile(
      leading: CustomIconWidget(
        iconName: icon,
        color: isSelected
            ? AppTheme.lightTheme.colorScheme.primary
            : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
        size: 24,
      ),
      title: Text(
        title,
        style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
          color: isSelected
              ? AppTheme.lightTheme.colorScheme.primary
              : AppTheme.lightTheme.colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: isSelected
          ? CustomIconWidget(
              iconName: 'check',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 24,
            )
          : null,
      onTap: () {
        Navigator.pop(context);
        _sortHoldings(value);
      },
    );
  }

  void _addInvestment() {
    Navigator.pushNamed(context, '/stock-search');
  }

  void _exportPortfolio() {
    // Generate portfolio summary without values
    final StringBuffer summary = StringBuffer();
    summary.writeln(
        'Portfolio Summary - ${DateTime.now().toString().split('.')[0]}');
    summary.writeln('=' * 50);
    summary.writeln('Holdings Summary:');
    summary.writeln('');

    for (final holding in _holdings) {
      summary.writeln('${holding['symbol']} - ${holding['companyName']}');
      summary.writeln('  Shares: ${holding['shares']}');
      summary.writeln(
          '  Performance: ${(holding['gainLossPercentage'] as num).toStringAsFixed(2)}%');
      summary.writeln('');
    }

    // Show share dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Export Portfolio'),
        content: Text('Portfolio summary has been prepared for sharing.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // In a real app, this would use the platform share sheet
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Portfolio exported successfully')),
              );
            },
            child: Text('Share'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = _holdings.isEmpty;

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Portfolio'),
        actions: [
          if (!isEmpty) ...[
            IconButton(
              onPressed: _showFilterOptions,
              icon: CustomIconWidget(
                iconName: 'filter_list',
                color: AppTheme.lightTheme.colorScheme.onSurface,
                size: 24,
              ),
            ),
            IconButton(
              onPressed: _exportPortfolio,
              icon: CustomIconWidget(
                iconName: 'share',
                color: AppTheme.lightTheme.colorScheme.onSurface,
                size: 24,
              ),
            ),
          ],
        ],
      ),
      body: isEmpty
          ? EmptyPortfolioWidget(
              onAddInvestment: _addInvestment,
            )
          : RefreshIndicator(
              onRefresh: _refreshPortfolio,
              color: AppTheme.lightTheme.colorScheme.primary,
              child: CustomScrollView(
                slivers: [
                  // Sticky header
                  SliverToBoxAdapter(
                    child: PortfolioHeaderWidget(
                      onRefresh: _refreshPortfolio,
                    ),
                  ),

                  // AI Summary section
                  SliverToBoxAdapter(
                    child: PortfolioAiSummaryWidget(
                      holdings: _holdings,
                      onRefresh: _refreshPortfolio,
                    ),
                  ),

                  // Tab bar
                  SliverToBoxAdapter(
                    child: Container(
                      margin:
                          EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        tabs: const [
                          Tab(text: 'Holdings'),
                          Tab(text: 'Performance'),
                          Tab(text: 'Allocation'),
                          Tab(text: 'AI Insights'),
                        ],
                      ),
                    ),
                  ),

                  // Tab content
                  SliverFillRemaining(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Holdings tab
                        _buildHoldingsTab(),

                        // Performance tab
                        SingleChildScrollView(
                          child: PerformanceChartWidget(
                            chartData: _chartData,
                            onPeriodChanged: () {
                              // Handle period change
                            },
                          ),
                        ),

                        // Allocation tab
                        SingleChildScrollView(
                          child: PortfolioAllocationWidget(
                            holdings: _holdings,
                            onSegmentTap: () {
                              // Handle segment tap
                            },
                          ),
                        ),

                        // AI Insights tab
                        SingleChildScrollView(
                          child: Padding(
                            padding: EdgeInsets.all(4.w),
                            child: PortfolioAiSummaryWidget(
                              holdings: _holdings,
                              onRefresh: _refreshPortfolio,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: isEmpty
          ? null
          : FloatingActionButton(
              onPressed: _addInvestment,
              child: CustomIconWidget(
                iconName: 'add',
                color: Colors.white,
                size: 24,
              ),
            ),
    );
  }

  Widget _buildHoldingsTab() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppTheme.lightTheme.colorScheme.primary,
            ),
            SizedBox(height: 2.h),
            Text(
              'Loading portfolio...',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Offline indicator
        if (_isOffline)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            color: AppTheme.lightTheme.colorScheme.error.withValues(alpha: 0.1),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'cloud_off',
                  color: AppTheme.lightTheme.colorScheme.error,
                  size: 16,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Offline - Last updated: ${_lastUpdated.toString().split('.')[0]}',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ),

        // Holdings list
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.only(bottom: 10.h),
            itemCount: _holdings.length,
            itemBuilder: (context, index) {
              final holding = _holdings[index];
              return HoldingCardWidget(
                holding: holding,
                onTap: () {
                  // Handle tap to expand/collapse
                },
                onSell: () {
                  _showSellDialog(holding);
                },
                onAddShares: () {
                  _showAddSharesDialog(holding);
                },
                onRemove: () {
                  _showRemoveDialog(holding);
                },
                onViewDetails: () {
                  Navigator.pushNamed(
                    context,
                    '/stock-detail',
                    arguments: holding['symbol'],
                  );
                },
                onGetAIAnalysis: () {
                  Navigator.pushNamed(
                    context,
                    '/ai-summary',
                    arguments: holding['symbol'],
                  );
                },
                onSetPriceAlert: () {
                  _showPriceAlertDialog(holding);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showSellDialog(Map<String, dynamic> holding) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sell ${holding['symbol']}'),
        content: Text('How many shares would you like to sell?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                        Text('Sell order placed for ${holding['symbol']}')),
              );
            },
            child: Text('Sell'),
          ),
        ],
      ),
    );
  }

  void _showAddSharesDialog(Map<String, dynamic> holding) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Shares - ${holding['symbol']}'),
        content: Text('How many additional shares would you like to purchase?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Buy order placed for ${holding['symbol']}')),
              );
            },
            child: Text('Buy'),
          ),
        ],
      ),
    );
  }

  void _showRemoveDialog(Map<String, dynamic> holding) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${holding['symbol']}'),
        content: Text(
            'Are you sure you want to remove this stock from your portfolio?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _holdings.removeWhere((h) => h['id'] == holding['id']);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                        Text('${holding['symbol']} removed from portfolio')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.colorScheme.error,
            ),
            child: Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showPriceAlertDialog(Map<String, dynamic> holding) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Price Alert - ${holding['symbol']}'),
        content: Text('Set a price alert for ${holding['companyName']}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Price alert set for ${holding['symbol']}')),
              );
            },
            child: Text('Set Alert'),
          ),
        ],
      ),
    );
  }
}
