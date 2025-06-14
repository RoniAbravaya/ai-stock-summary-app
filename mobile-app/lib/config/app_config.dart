/// App Configuration
/// Central configuration file for the AI Stock Summary Flutter app
library;

class AppConfig {
  // App Information
  static const String appName = 'AI Stock Summary';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // Environment Configuration
  static const AppEnvironment environment =
      AppEnvironment.local; // Change this to switch environments

  // API Configuration - Multiple environments
  // Primary: Android emulator standard host access
  static const String localBaseUrl = 'http://10.0.2.2:8080/api';
  static const String localMockBaseUrl = 'http://10.0.2.2:8080/api/mock';

  // Alternative: Direct IP access (fallback if 10.0.2.2 doesn't work)
  static const String localIpBaseUrl = 'http://192.168.1.137:8080/api';
  static const String localIpMockBaseUrl = 'http://192.168.1.137:8080/api/mock';
  static const String hostedBaseUrl =
      'https://ai-stock-summary-app--new-flutter-ai.us-central1.hosted.app/api';
  static const String hostedMockBaseUrl =
      'https://ai-stock-summary-app--new-flutter-ai.us-central1.hosted.app/api/mock';

  // Firebase Configuration (to be filled from Firebase console)
  static const String firebaseProjectId = '492701567937';
  static const String firebaseApiKey =
      'AIzaSyCbnJWJg7btLbIYKPqzKdfvNmVSwx-Sikw';
  static const String firebaseAppId = 'new-flutter-ai';
  static const String firebaseSenderId = '492701567937';
  static const String firebaseStorageBucket =
      'new-flutter-ai.firebasestorage.app';

  // Google Sign-In Configuration
  static const String googleClientId =
      '192137780571-qf5cdsiaevisaespuegj7v0hnmceejos.apps.googleusercontent.com';

  // Facebook Configuration
  static const String facebookAppId = 'your-facebook-app-id';

  // AdMob Configuration
  static const String admobAppIdAndroid = 'ca-app-pub-your-app-id~android';
  static const String admobAppIdIOS = 'ca-app-pub-your-app-id~ios';
  static const String admobBannerUnitIdAndroid =
      'ca-app-pub-your-banner-unit-id/android';
  static const String admobBannerUnitIdIOS =
      'ca-app-pub-your-banner-unit-id/ios';
  static const String admobRewardedUnitIdAndroid =
      'ca-app-pub-your-rewarded-unit-id/android';
  static const String admobRewardedUnitIdIOS =
      'ca-app-pub-your-rewarded-unit-id/ios';

  // Test AdMob IDs (for development)
  static const String testBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String testRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  // App Limits & Features
  static const int freeSummariesPerMonth = 10;
  static const int premiumSummariesPerMonth = 100;
  static const int rewardedAdCooldownMinutes = 30;
  static const double subscriptionPriceUSD = 9.99;

  // UI Configuration
  static const int splashDurationSeconds = 3;
  static const int newsRefreshIntervalMinutes = 15;
  static const int stockDataRefreshIntervalMinutes = 5;

  // Supported Languages
  static const List<String> supportedLanguages = ['en', 'es', 'fr', 'de', 'pt'];

  // Mock Data Configuration
  static const bool enableMockData = false; // Disabled for production
  static const bool enableDebugMode = false; // Disabled for production

  // Environment Detection
  static bool get isProduction => environment == AppEnvironment.production;
  static bool get isDevelopment => environment == AppEnvironment.development;
  static bool get isLocal => environment == AppEnvironment.local;

  // Network Configuration
  static bool useAlternativeLocalIp = false;

  /// Switch to alternative IP configuration for local development
  static void switchToAlternativeIp() {
    useAlternativeLocalIp = true;
  }

  /// Switch back to standard emulator IP configuration
  static void switchToStandardIp() {
    useAlternativeLocalIp = false;
  }

  /// Get current IP configuration info
  static String get currentIpConfig {
    if (environment != AppEnvironment.local) return 'N/A (not local)';
    return useAlternativeLocalIp
        ? 'Direct IP (192.168.1.137)'
        : 'Emulator Standard (10.0.2.2)';
  }

  // App Colors
  static const int primaryBlue = 0xFF2196F3;
  static const int primaryGreen = 0xFF4CAF50;
  static const int primaryRed = 0xFFF44336;
  static const int backgroundGray = 0xFFF5F5F5;
  static const int textDark = 0xFF212121;
  static const int textLight = 0xFF757575;
  static const int cardBackground = 0xFFFFFFFF;
  static const int dividerColor = 0xFFE0E0E0;

  // Get appropriate API base URL based on environment
  static String get apiBaseUrl {
    switch (environment) {
      case AppEnvironment.local:
        if (enableMockData) {
          return useAlternativeLocalIp ? localIpMockBaseUrl : localMockBaseUrl;
        } else {
          return useAlternativeLocalIp ? localIpBaseUrl : localBaseUrl;
        }
      case AppEnvironment.development:
        return enableMockData ? hostedMockBaseUrl : hostedBaseUrl;
      case AppEnvironment.production:
        return hostedBaseUrl;
    }
  }

  // Get current environment info
  static String get environmentName {
    switch (environment) {
      case AppEnvironment.local:
        return 'Local Development';
      case AppEnvironment.development:
        return 'Hosted Development';
      case AppEnvironment.production:
        return 'Production';
    }
  }

  // Get environment status indicator
  static String get environmentIndicator {
    switch (environment) {
      case AppEnvironment.local:
        return '🏠 LOCAL';
      case AppEnvironment.development:
        return '🔧 DEV';
      case AppEnvironment.production:
        return '🚀 LIVE';
    }
  }

  // Get appropriate AdMob IDs
  static String getBannerAdUnitId() {
    if (isDevelopment || isLocal) {
      return testBannerAdUnitId;
    }
    // Return platform-specific ID based on Platform.isAndroid/Platform.isIOS
    return admobBannerUnitIdAndroid; // Placeholder - implement platform check
  }

  static String getRewardedAdUnitId() {
    if (isDevelopment || isLocal) {
      return testRewardedAdUnitId;
    }
    // Return platform-specific ID based on Platform.isAndroid/Platform.isIOS
    return admobRewardedUnitIdAndroid; // Placeholder - implement platform check
  }
}

// Environment enum for easy switching
enum AppEnvironment {
  local, // Local development server (localhost:3000)
  development, // Hosted development environment
  production, // Production hosted environment
}

// API Endpoints
class ApiEndpoints {
  // Authentication
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String forgotPassword = '/auth/forgot-password';

  // User Management
  static const String userProfile = '/user/profile';
  static const String updateProfile = '/user/update';
  static const String deleteAccount = '/user/delete';
  static const String grantAdmin = '/auth/grant-admin';

  // Stock Data
  static const String stocks = '/stocks';
  static const String stockDetails = '/stocks/{id}';
  static const String trendingStocks = '/stocks/trending';
  static const String searchStocks = '/stocks/search';

  // Summaries
  static const String generateSummary = '/summary/generate';
  static const String getSummary = '/summary/get/{stockId}';
  static const String translateSummary = '/summary/translate';
  static const String userSummaries = '/summary/user';

  // News
  static const String news = '/news';
  static const String newsDetails = '/news/{id}';
  static const String stockNews = '/news/stock/{stockId}';

  // Push Notifications
  static const String sendPushNotification = '/push/send';
  static const String registerFCMToken = '/push/register';

  // Subscriptions
  static const String verifyPurchase = '/subscription/verify';
  static const String subscriptionStatus = '/subscription/status';

  // Mock Data Endpoints
  static const String mockStocks = '/stocks';
  static const String mockNews = '/news';
  static const String mockSummary = '/summary/{stockId}';
}

// App Text Styles
class AppTextStyles {
  static const String fontFamily = 'Roboto';

  // Font sizes
  static const double headingLarge = 28.0;
  static const double headingMedium = 24.0;
  static const double headingSmall = 20.0;
  static const double bodyLarge = 18.0;
  static const double bodyMedium = 16.0;
  static const double bodySmall = 14.0;
  static const double caption = 12.0;
}
