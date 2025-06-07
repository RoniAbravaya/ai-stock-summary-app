/// API Configuration
/// Handles environment-based URLs and API settings for backend communication
class ApiConfig {
  // Environment detection
  static const bool isDevelopment =
      bool.fromEnvironment('dart.vm.product') == false;

  // Base URLs for different environments
  // For Android emulator: use 10.0.2.2 to reach host machine
  // For iOS simulator: use localhost
  // For physical devices: use your machine's IP address
  static const String _developmentBaseUrl =
      'http://10.0.2.2:3000'; // Android emulator
  static const String _iosSimulatorBaseUrl =
      'http://localhost:3000'; // iOS simulator
  static const String _productionBaseUrl =
      'https://your-production-url.com'; // TODO: Update when deployed

  /// Get the appropriate base URL based on environment and platform
  static String get baseUrl {
    if (!isDevelopment) {
      return _productionBaseUrl;
    }

    // For development on physical devices, use machine's local network IP
    // Example: return 'http://192.168.1.100:3000';
    return 'http://192.168.1.137:3000'; // Replace with your machine's IP
  }

  /// API Endpoints
  static const String healthEndpoint = '/health';
  static const String newsEndpoint = '/api/yahoo-news';
  static const String newsStatsEndpoint = '/api/yahoo-news/stats';
  static const String newsTickersEndpoint = '/api/yahoo-news/tickers';

  /// Request configuration
  static const Duration requestTimeout = Duration(
    seconds: 60,
  ); // Increased for slower networks
  static const Duration connectionTimeout = Duration(
    seconds: 30,
  ); // Increased for physical devices

  /// Get full URL for an endpoint
  static String getFullUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }

  /// Development URL options:
  /// - Android Emulator: http://10.0.2.2:3000
  /// - iOS Simulator: http://localhost:3000
  /// - Physical Device: http://YOUR_MACHINE_IP:3000 (e.g., http://192.168.1.100:3000)
  ///
  /// To find your machine's IP:
  /// - Windows: ipconfig
  /// - macOS/Linux: ifconfig
  static String getCustomDevelopmentUrl(String host, int port) {
    return 'http://$host:$port';
  }

  /// News API specific URLs
  static String get newsUrl => getFullUrl(newsEndpoint);
  static String get newsStatsUrl => getFullUrl(newsStatsEndpoint);
  static String get newsTickersUrl => getFullUrl(newsTickersEndpoint);
  static String get healthUrl => getFullUrl(healthEndpoint);

  /// Get news URL with tickers parameter
  static String getNewsUrlWithTickers(String tickers) {
    return '$newsUrl?tickers=$tickers';
  }

  /// Get all tickers news URL
  static String get allTickersNewsUrl => getNewsUrlWithTickers('ALL');
}
