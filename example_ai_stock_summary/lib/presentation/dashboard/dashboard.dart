import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/ai_summary_card_widget.dart';
import './widgets/market_insights_card_widget.dart';
import './widgets/market_status_widget.dart';
import './widgets/portfolio_overview_widget.dart';
import './widgets/quick_actions_bottom_sheet.dart';
import './widgets/watchlist_item_widget.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with TickerProviderStateMixin {
  bool isPercentageView = false;
  bool isLoading = false;
  int _selectedIndex = 0;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;

  // Mock data for portfolio
  final double totalPortfolioValue = 125847.32;
  final double portfolioChange = 2.47;

  // Mock data for market insights
  final List<Map<String, dynamic>> marketInsights = [
    {
      "title": "Today's Movers",
      "subtitle": "5 stocks with significant price changes",
      "icon": "trending_up",
      "color": const Color(0xFF10B981),
    },
    {
      "title": "AI Insights Available",
      "subtitle": "3 new AI summaries ready to view",
      "icon": "psychology",
      "color": const Color(0xFF4A90E2),
    },
    {
      "title": "Recent Alerts",
      "subtitle": "2 price alerts triggered today",
      "icon": "notifications_active",
      "color": const Color(0xFFFF6B35),
    },
  ];

  // Mock data for watchlist
  final List<Map<String, dynamic>> watchlistStocks = [
    {
      "symbol": "AAPL",
      "name": "Apple Inc.",
      "price": 175.84,
      "change": 2.31,
    },
    {
      "symbol": "GOOGL",
      "name": "Alphabet Inc.",
      "price": 2847.92,
      "change": -1.24,
    },
    {
      "symbol": "MSFT",
      "name": "Microsoft Corporation",
      "price": 378.85,
      "change": 0.87,
    },
    {
      "symbol": "TSLA",
      "name": "Tesla, Inc.",
      "price": 248.50,
      "change": -3.45,
    },
    {
      "symbol": "AMZN",
      "name": "Amazon.com, Inc.",
      "price": 3342.88,
      "change": 1.92,
    },
  ];

  // Mock data for AI summaries
  final List<Map<String, dynamic>> aiSummaries = [
    {
      "symbol": "AAPL",
      "title": "Strong Q4 Performance Expected",
      "preview":
          "Apple's upcoming earnings report shows positive indicators with iPhone 15 sales exceeding expectations and services revenue growing steadily...",
      "timestamp": DateTime.now().subtract(const Duration(hours: 2)),
    },
    {
      "symbol": "GOOGL",
      "title": "AI Integration Driving Growth",
      "preview":
          "Google's integration of AI across its product suite is showing promising results, with advertising revenue benefiting from improved targeting...",
      "timestamp": DateTime.now().subtract(const Duration(hours: 5)),
    },
    {
      "symbol": "TSLA",
      "title": "Production Challenges Ahead",
      "preview":
          "Tesla faces potential production bottlenecks in Q1 2024 due to supply chain constraints, but long-term outlook remains positive...",
      "timestamp": DateTime.now().subtract(const Duration(days: 1)),
    },
  ];

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(() {
      isLoading = true;
    });

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      isLoading = false;
    });

    // Show success feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Data updated successfully'),
          backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navigate to different screens based on index
    switch (index) {
      case 0:
        // Dashboard - already here
        break;
      case 1:
        Navigator.pushNamed(context, '/portfolio');
        break;
      case 2:
        Navigator.pushNamed(context, '/stock-search');
        break;
      case 3:
        Navigator.pushNamed(context, '/notifications');
        break;
      case 4:
        Navigator.pushNamed(context, '/settings');
        break;
    }
  }

  void _showQuickActions(String stockSymbol) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => QuickActionsBottomSheet(
        stockSymbol: stockSymbol,
        onViewDetails: () => Navigator.pushNamed(context, '/stock-detail'),
        onGetAiSummary: () => Navigator.pushNamed(context, '/ai-summary'),
        onSetAlert: () => _showSetAlertDialog(stockSymbol),
      ),
    );
  }

  void _showSetAlertDialog(String stockSymbol) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Price Alert for $stockSymbol'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Target Price',
                prefixText: '\$ ',
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 2.h),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Alert Type',
              ),
              items: const [
                DropdownMenuItem(value: 'above', child: Text('Price Above')),
                DropdownMenuItem(value: 'below', child: Text('Price Below')),
              ],
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Price alert created successfully'),
                ),
              );
            },
            child: const Text('Create Alert'),
          ),
        ],
      ),
    );
  }

  bool _isMarketOpen() {
    final now = DateTime.now();
    final hour = now.hour;
    final weekday = now.weekday;

    // Market is open Monday-Friday, 9:30 AM - 4:00 PM EST
    return weekday >= 1 && weekday <= 5 && hour >= 9 && hour < 16;
  }

  String _getMarketStatusText() {
    return _isMarketOpen() ? 'Market Open' : 'Market Closed';
  }

  String _getNextSessionTime() {
    final now = DateTime.now();
    if (_isMarketOpen()) {
      return 'Closes at 4:00 PM EST';
    } else {
      return 'Opens at 9:30 AM EST';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: AppTheme.lightTheme.colorScheme.primary,
          child: CustomScrollView(
            slivers: [
              // Sticky header with portfolio overview
              SliverAppBar(
                expandedHeight: 20.h,
                floating: false,
                pinned: true,
                backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: PortfolioOverviewWidget(
                    totalValue: totalPortfolioValue,
                    percentageChange: portfolioChange,
                    isPercentageView: isPercentageView,
                    onToggleView: () {
                      setState(() {
                        isPercentageView = !isPercentageView;
                      });
                      HapticFeedback.selectionClick();
                    },
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/notifications'),
                    icon: Stack(
                      children: [
                        CustomIconWidget(
                          iconName: 'notifications',
                          color: AppTheme.lightTheme.colorScheme.onSurface,
                          size: 24,
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppTheme.lightTheme.colorScheme.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Market insights horizontal scroll
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                      child: Text(
                        'Market Insights',
                        style:
                            AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 15.h,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        itemCount: marketInsights.length,
                        itemBuilder: (context, index) {
                          final insight = marketInsights[index];
                          return MarketInsightsCardWidget(
                            title: insight["title"] as String,
                            subtitle: insight["subtitle"] as String,
                            iconName: insight["icon"] as String,
                            backgroundColor: insight["color"] as Color,
                            onTap: () {
                              // Navigate based on insight type
                              if (index == 0) {
                                Navigator.pushNamed(context, '/stock-search');
                              } else if (index == 1) {
                                Navigator.pushNamed(context, '/ai-summary');
                              } else {
                                Navigator.pushNamed(context, '/notifications');
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Market status indicator
              SliverToBoxAdapter(
                child: MarketStatusWidget(
                  isMarketOpen: _isMarketOpen(),
                  statusText: _getMarketStatusText(),
                  nextSessionTime: _getNextSessionTime(),
                ),
              ),

              // Watchlist section
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Watchlist',
                        style:
                            AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/portfolio'),
                        child: Text(
                          'View All',
                          style: AppTheme.lightTheme.textTheme.bodyMedium
                              ?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Watchlist items
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= 5) return null; // Show only top 5
                      final stock = watchlistStocks[index];
                      return WatchlistItemWidget(
                        stock: stock,
                        onTap: () =>
                            Navigator.pushNamed(context, '/stock-detail'),
                        onLongPress: () =>
                            _showQuickActions(stock["symbol"] as String),
                      );
                    },
                  ),
                ),
              ),

              // Recent AI summaries section
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent AI Summaries',
                        style:
                            AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/ai-summary'),
                        child: Text(
                          'View All',
                          style: AppTheme.lightTheme.textTheme.bodyMedium
                              ?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // AI summaries list
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= aiSummaries.length) return null;
                      final summary = aiSummaries[index];
                      return AiSummaryCardWidget(
                        summary: summary,
                        onTap: () =>
                            Navigator.pushNamed(context, '/ai-summary'),
                      );
                    },
                  ),
                ),
              ),

              // Bottom padding for FAB
              SliverToBoxAdapter(
                child: SizedBox(height: 10.h),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnimation,
        child: FloatingActionButton(
          onPressed: () {
            _fabAnimationController.forward().then((_) {
              _fabAnimationController.reverse();
            });
            Navigator.pushNamed(context, '/stock-search');
          },
          child: CustomIconWidget(
            iconName: 'search',
            color:
                AppTheme.lightTheme.floatingActionButtonTheme.foregroundColor!,
            size: 24,
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor:
            AppTheme.lightTheme.bottomNavigationBarTheme.backgroundColor,
        selectedItemColor:
            AppTheme.lightTheme.bottomNavigationBarTheme.selectedItemColor,
        unselectedItemColor:
            AppTheme.lightTheme.bottomNavigationBarTheme.unselectedItemColor,
        items: [
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'dashboard',
              color: _selectedIndex == 0
                  ? AppTheme
                      .lightTheme.bottomNavigationBarTheme.selectedItemColor!
                  : AppTheme
                      .lightTheme.bottomNavigationBarTheme.unselectedItemColor!,
              size: 24,
            ),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'account_balance_wallet',
              color: _selectedIndex == 1
                  ? AppTheme
                      .lightTheme.bottomNavigationBarTheme.selectedItemColor!
                  : AppTheme
                      .lightTheme.bottomNavigationBarTheme.unselectedItemColor!,
              size: 24,
            ),
            label: 'Portfolio',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'search',
              color: _selectedIndex == 2
                  ? AppTheme
                      .lightTheme.bottomNavigationBarTheme.selectedItemColor!
                  : AppTheme
                      .lightTheme.bottomNavigationBarTheme.unselectedItemColor!,
              size: 24,
            ),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                CustomIconWidget(
                  iconName: 'notifications',
                  color: _selectedIndex == 3
                      ? AppTheme.lightTheme.bottomNavigationBarTheme
                          .selectedItemColor!
                      : AppTheme.lightTheme.bottomNavigationBarTheme
                          .unselectedItemColor!,
                  size: 24,
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'settings',
              color: _selectedIndex == 4
                  ? AppTheme
                      .lightTheme.bottomNavigationBarTheme.selectedItemColor!
                  : AppTheme
                      .lightTheme.bottomNavigationBarTheme.unselectedItemColor!,
              size: 24,
            ),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
