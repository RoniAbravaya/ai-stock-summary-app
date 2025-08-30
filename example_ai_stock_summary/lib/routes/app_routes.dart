import 'package:flutter/material.dart';
import '../presentation/stock_search/stock_search.dart';
import '../presentation/settings/settings.dart';
import '../presentation/onboarding/onboarding.dart';
import '../presentation/registration/registration.dart';
import '../presentation/notifications/notifications.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/portfolio/portfolio.dart';
import '../presentation/login/login.dart';
import '../presentation/stock_detail/stock_detail.dart';
import '../presentation/ai_summary/ai_summary.dart';
import '../presentation/dashboard/dashboard.dart';
import '../presentation/admin_dashboard/admin_dashboard.dart';
import '../presentation/ai_integration_monitor/ai_integration_monitor.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String stockSearch = '/stock-search';
  static const String settings = '/settings';
  static const String onboarding = '/onboarding';
  static const String registration = '/registration';
  static const String notifications = '/notifications';
  static const String splash = '/splash-screen';
  static const String portfolio = '/portfolio';
  static const String login = '/login';
  static const String stockDetail = '/stock-detail';
  static const String aiSummary = '/ai-summary';
  static const String dashboard = '/dashboard';
  static const String adminDashboard = '/admin-dashboard';
  static const String aiIntegrationMonitor = '/ai-integration-monitor';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    stockSearch: (context) => const StockSearch(),
    settings: (context) => const Settings(),
    onboarding: (context) => const Onboarding(),
    registration: (context) => const Registration(),
    notifications: (context) => const Notifications(),
    splash: (context) => const SplashScreen(),
    portfolio: (context) => const Portfolio(),
    login: (context) => const Login(),
    stockDetail: (context) => const StockDetail(),
    aiSummary: (context) => const AiSummary(),
    dashboard: (context) => const Dashboard(),
    adminDashboard: (context) => const AdminDashboard(),
    aiIntegrationMonitor: (context) => const AiIntegrationMonitor(),
    // TODO: Add your other routes here
  };
}
