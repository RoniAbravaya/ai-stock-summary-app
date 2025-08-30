import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import './widgets/navigation_controls.dart';
import './widgets/onboarding_card.dart';
import './widgets/page_indicator.dart';
import './widgets/subscription_preview.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({Key? key}) : super(key: key);

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _onboardingData = [
    {
      "title": "AI-Powered Stock Analysis",
      "description":
          "Get intelligent stock summaries powered by advanced AI. Make informed investment decisions with comprehensive market insights at your fingertips.",
      "imageUrl":
          "https://images.unsplash.com/photo-1551288049-bebda4e38f71?fm=jpg&q=80&w=1000&ixlib=rb-4.0.3",
    },
    {
      "title": "Smart Portfolio Tracking",
      "description":
          "Monitor your investments in real-time with advanced analytics. Track performance, diversification, and get personalized recommendations.",
      "imageUrl":
          "https://images.pexels.com/photos/6801648/pexels-photo-6801648.jpeg?auto=compress&cs=tinysrgb&w=1000",
    },
    {
      "title": "Real-Time Notifications",
      "description":
          "Never miss important market movements. Get instant alerts for price changes, earnings reports, and breaking news that affects your portfolio.",
      "imageUrl":
          "https://images.pixabay.com/photo/2016/11/27/21/42/stock-1863880_1280.jpg?auto=compress&cs=tinysrgb&w=1000",
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Haptic feedback for page changes
    HapticFeedback.lightImpact();
  }

  void _nextPage() {
    if (_currentIndex < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipOnboarding() {
    HapticFeedback.selectionClick();
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _getStarted() {
    HapticFeedback.mediumImpact();
    Navigator.pushReplacementNamed(context, '/registration');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Skip button in top-right corner
              if (_currentIndex < _onboardingData.length - 1)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _skipOnboarding,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              horizontal: 4.w, vertical: 1.h),
                        ),
                        child: Text(
                          'Skip',
                          style:
                              AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Main content area
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _onboardingData.length,
                  itemBuilder: (context, index) {
                    final data = _onboardingData[index];

                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          // Onboarding card
                          OnboardingCard(
                            title: data["title"] as String,
                            description: data["description"] as String,
                            imageUrl: data["imageUrl"] as String,
                            isActive: index == _currentIndex,
                          ),

                          // Show subscription preview on last page
                          if (index == _onboardingData.length - 1) ...[
                            SizedBox(height: 4.h),
                            const SubscriptionPreview(),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Page indicator
              Container(
                padding: EdgeInsets.symmetric(vertical: 2.h),
                child: PageIndicator(
                  currentIndex: _currentIndex,
                  totalPages: _onboardingData.length,
                ),
              ),

              // Navigation controls
              NavigationControls(
                currentIndex: _currentIndex,
                totalPages: _onboardingData.length,
                onNext: _nextPage,
                onSkip: _skipOnboarding,
                onGetStarted: _getStarted,
              ),

              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
    );
  }
}
