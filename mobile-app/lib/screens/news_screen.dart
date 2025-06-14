import 'package:flutter/material.dart';
import '../services/news_service.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key, required this.firebaseEnabled});

  final bool firebaseEnabled;

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final NewsService _newsService = NewsService();
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _news = [];
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _connectivityInfo;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    try {
      print('📰 NewsScreen: Starting to load news...');
      setState(() {
        _isLoading = true;
        _error = null;
        _connectivityInfo = null;
      });

      // First test connectivity
      print('🔍 NewsScreen: Testing API connectivity...');
      final connectivityResult = await _apiService.testConnectivity();
      _connectivityInfo = connectivityResult;

      if (!connectivityResult['success']) {
        throw Exception(
          'API connectivity failed: ${connectivityResult['error']}',
        );
      }

      print(
        '✅ NewsScreen: API connectivity successful (${connectivityResult['responseTime']})',
      );

      print('📰 NewsScreen: Calling NewsService.getNews()...');
      final news = await _newsService.getNews();
      print('📰 NewsScreen: Received ${news.length} articles');

      setState(() {
        _news = news;
        _isLoading = false;
      });
      print('📰 NewsScreen: State updated successfully');
    } catch (e) {
      print('❌ NewsScreen: Error loading news: $e');
      setState(() {
        _error = 'Failed to load news: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial News'),
        actions: [
          if (AppConfig.isDevelopment)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: _showDebugInfo,
              tooltip: 'Debug Info',
            ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _news.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _news.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(_error!, style: TextStyle(fontSize: 18)),
            SizedBox(height: 16),
            ElevatedButton(onPressed: _loadNews, child: Text('Try Again')),
          ],
        ),
      );
    }

    if (_news.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No news available', style: TextStyle(fontSize: 18)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNews,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _news.length,
        itemBuilder: (context, index) => _buildNewsCard(_news[index]),
      ),
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> news) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (news['ticker'] != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(AppConfig.primaryBlue).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  news['ticker'],
                  style: TextStyle(
                    color: Color(AppConfig.primaryBlue),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              news['title'] ?? 'No title',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              news['text'] ?? news['description'] ?? 'No description available',
              style: TextStyle(color: Colors.grey.shade700),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  news['source'] ?? 'Unknown source',
                  style: TextStyle(
                    color: Color(AppConfig.primaryBlue),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatDate(news['published_date'] ?? news['publishedAt']),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDebugInfo() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Debug Information'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Environment: ${AppConfig.environmentName}'),
                  Text('API URL: ${AppConfig.apiBaseUrl}'),
                  if (AppConfig.isLocal)
                    Text('IP Config: ${AppConfig.currentIpConfig}'),
                  const SizedBox(height: 16),
                  if (_connectivityInfo != null) ...[
                    const Text(
                      'Connectivity Test:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Success: ${_connectivityInfo!['success']}'),
                    if (_connectivityInfo!['responseTime'] != null)
                      Text(
                        'Response Time: ${_connectivityInfo!['responseTime']}',
                      ),
                    if (_connectivityInfo!['error'] != null)
                      Text('Error: ${_connectivityInfo!['error']}'),
                    if (_connectivityInfo!['serverStatus'] != null)
                      Text(
                        'Server Status: ${_connectivityInfo!['serverStatus']}',
                      ),
                  ],
                  const SizedBox(height: 16),
                  Text('Articles Loaded: ${_news.length}'),
                  if (_error != null) Text('Last Error: $_error'),
                ],
              ),
            ),
            actions: [
              if (AppConfig.isLocal)
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _switchIpAndRetry();
                  },
                  child: Text(
                    AppConfig.useAlternativeLocalIp
                        ? 'Use 10.0.2.2'
                        : 'Use Direct IP',
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _loadNews();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
    );
  }

  void _switchIpAndRetry() {
    if (AppConfig.useAlternativeLocalIp) {
      AppConfig.switchToStandardIp();
      print('🔄 Switched to standard emulator IP (10.0.2.2)');
    } else {
      AppConfig.switchToAlternativeIp();
      print('🔄 Switched to direct IP (192.168.1.137)');
    }
    _loadNews();
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown date';
    try {
      DateTime date;
      if (timestamp is DateTime) {
        date = timestamp;
      } else if (timestamp is String) {
        date = DateTime.parse(timestamp);
      } else {
        date = timestamp.toDate();
      }
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown date';
    }
  }
}
