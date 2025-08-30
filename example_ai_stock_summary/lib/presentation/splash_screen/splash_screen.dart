import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_export.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoAnimationController;
  late AnimationController _fadeAnimationController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _isInitializing = true;
  bool _hasError = false;
  String _errorMessage = '';
  int _retryCount = 0;
  static const int _maxRetries = 3;
  static const Duration _splashDuration = Duration(seconds: 3);
  static const Duration _timeoutDuration = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startInitialization();
  }

  void _initializeAnimations() {
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _logoScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    ));

    _logoAnimationController.forward();
    _fadeAnimationController.forward();
  }

  Future<void> _startInitialization() async {
    try {
      setState(() {
        _isInitializing = true;
        _hasError = false;
      });

      // Simulate initialization tasks with timeout
      await Future.wait([
        _initializeFirebaseServices(),
        _checkAuthenticationStatus(),
        _loadUserPreferences(),
        _fetchMarketStatus(),
        _prepareCachedData(),
        Future.delayed(_splashDuration), // Minimum splash duration
      ]).timeout(_timeoutDuration);

      await _navigateToNextScreen();
    } catch (e) {
      _handleInitializationError(e);
    }
  }

  Future<void> _initializeFirebaseServices() async {
    // Simulate Firebase initialization
    await Future.delayed(const Duration(milliseconds: 800));
  }

  Future<void> _checkAuthenticationStatus() async {
    // Simulate authentication check
    await Future.delayed(const Duration(milliseconds: 600));
  }

  Future<void> _loadUserPreferences() async {
    // Simulate loading user preferences
    await Future.delayed(const Duration(milliseconds: 400));
  }

  Future<void> _fetchMarketStatus() async {
    // Simulate market status fetch
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _prepareCachedData() async {
    // Simulate cached data preparation
    await Future.delayed(const Duration(milliseconds: 700));
  }

  void _handleInitializationError(dynamic error) {
    setState(() {
      _hasError = true;
      _isInitializing = false;
      _errorMessage = 'Failed to initialize app services';
    });

    if (_retryCount < _maxRetries) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _retryInitialization();
        }
      });
    }
  }

  void _retryInitialization() {
    setState(() {
      _retryCount++;
    });
    _startInitialization();
  }

  Future<void> _navigateToNextScreen() async {
    if (!mounted) return;

    // Simulate authentication check result
    final bool isAuthenticated = DateTime.now().millisecondsSinceEpoch % 3 == 0;
    final bool isFirstTime = DateTime.now().millisecondsSinceEpoch % 4 == 0;

    String nextRoute;
    if (isAuthenticated) {
      nextRoute = '/dashboard';
    } else if (isFirstTime) {
      nextRoute = '/onboarding';
    } else {
      nextRoute = '/login';
    }

    // Smooth fade transition
    await _fadeAnimationController.reverse();

    if (mounted) {
      Navigator.pushReplacementNamed(context, nextRoute);
    }
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _fadeAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppTheme.lightTheme.primaryColor,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.lightTheme.primaryColor,
                AppTheme.lightTheme.primaryColor.withValues(alpha: 0.8),
                AppTheme.primaryVariantLight,
              ],
            ),
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  _buildLogo(),
                  SizedBox(height: 4.h),
                  _buildAppName(),
                  SizedBox(height: 2.h),
                  _buildTagline(),
                  const Spacer(flex: 2),
                  _buildLoadingSection(),
                  SizedBox(height: 8.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _logoScaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScaleAnimation.value,
          child: Container(
            width: 25.w,
            height: 25.w,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6.w),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomIconWidget(
                    iconName: 'trending_up',
                    color: AppTheme.lightTheme.primaryColor,
                    size: 8.w,
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'AI',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.lightTheme.primaryColor,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppName() {
    return Text(
      'AI Stock Summary',
      style: GoogleFonts.inter(
        fontSize: 20.sp,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 0.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildTagline() {
    return Text(
      'Intelligent Market Insights',
      style: GoogleFonts.inter(
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        color: Colors.white.withValues(alpha: 0.9),
        letterSpacing: 0.3,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildLoadingSection() {
    if (_hasError) {
      return _buildErrorSection();
    }

    return Column(
      children: [
        SizedBox(
          width: 6.w,
          height: 6.w,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          _getLoadingText(),
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w400,
            color: Colors.white.withValues(alpha: 0.8),
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorSection() {
    return Column(
      children: [
        CustomIconWidget(
          iconName: 'error_outline',
          color: Colors.white.withValues(alpha: 0.9),
          size: 6.w,
        ),
        SizedBox(height: 2.h),
        Text(
          _errorMessage,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w400,
            color: Colors.white.withValues(alpha: 0.8),
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
        ),
        if (_retryCount < _maxRetries) ...[
          SizedBox(height: 2.h),
          Text(
            'Retrying... (${_retryCount + 1}/$_maxRetries)',
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              fontWeight: FontWeight.w300,
              color: Colors.white.withValues(alpha: 0.7),
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
          ),
        ] else ...[
          SizedBox(height: 2.h),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _retryCount = 0;
              });
              _startInitialization();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2.w),
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
            child: Text(
              'Retry',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _getLoadingText() {
    if (!_isInitializing) return 'Ready';

    final loadingMessages = [
      'Initializing services...',
      'Checking authentication...',
      'Loading preferences...',
      'Fetching market data...',
      'Preparing your dashboard...',
    ];

    final index =
        (DateTime.now().millisecondsSinceEpoch ~/ 800) % loadingMessages.length;
    return loadingMessages[index];
  }
}