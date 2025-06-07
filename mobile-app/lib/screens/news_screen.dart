import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';
import '../services/news_api_service.dart';
import '../models/news_models.dart';
import '../services/language_service.dart';

/// News Screen - Yahoo Finance Integration
/// Displays financial news from all 25 supported tickers with rich UI
class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key, required this.firebaseEnabled});

  final bool firebaseEnabled;

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final NewsApiService _newsApiService = NewsApiService();
  final ScrollController _scrollController = ScrollController();

  // State management
  List<NewsArticle> _displayedArticles = [];
  List<NewsArticle> _allArticles = [];
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _isRefreshing = false;
  String? _errorMessage;
  bool _hasMoreData = true;
  bool _showOnlyRecent = true; // Start with recent articles from each ticker

  @override
  void initState() {
    super.initState();
    _loadInitialNews();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Load initial news data
  Future<void> _loadInitialNews() async {
    setState(() {
      _isInitialLoading = true;
      _errorMessage = null;
    });

    final result = await _newsApiService.getAllTickersNews();

    if (mounted) {
      if (result.hasData) {
        final newsResponse = result.data!;
        _allArticles = newsResponse.getAllArticlesChronological();
        _displayedArticles = newsResponse.getMostRecentFromEachTicker();

        setState(() {
          _isInitialLoading = false;
          _hasMoreData = _hasMoreUniqueArticles();
        });

        print(
          '📱 Initial load: ${_displayedArticles.length} unique articles from ${newsResponse.successfulTickersCount} tickers (${newsResponse.totalArticlesCount} total before deduplication)',
        );
      } else if (result.hasError) {
        setState(() {
          _isInitialLoading = false;
          _errorMessage = result.error;
        });
      }
    }
  }

  /// Handle pull-to-refresh
  Future<void> _refreshNews() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
      _errorMessage = null;
    });

    final result = await _newsApiService.getAllTickersNews();

    if (mounted) {
      if (result.hasData) {
        final newsResponse = result.data!;
        _allArticles = newsResponse.getAllArticlesChronological();

        // Reset to showing recent articles from each ticker
        _displayedArticles = newsResponse.getMostRecentFromEachTicker();
        _showOnlyRecent = true;

        setState(() {
          _isRefreshing = false;
          _hasMoreData = _hasMoreUniqueArticles();
        });

        print(
          '🔄 Refresh complete: ${_displayedArticles.length} unique articles (${newsResponse.totalArticlesCount} total before deduplication)',
        );
      } else if (result.hasError) {
        setState(() {
          _isRefreshing = false;
          _errorMessage = result.error;
        });
      }
    }
  }

  /// Load more articles (next 25 chronologically)
  Future<void> _loadMoreArticles() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    // Simulate loading delay for better UX
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      const pageSize = 25;
      List<NewsArticle> newArticles;

      if (_showOnlyRecent) {
        // Switch to chronological mode - add articles that aren't already displayed
        _showOnlyRecent = false;
        newArticles = _getUniqueArticles(_allArticles, pageSize);
        _displayedArticles.addAll(newArticles);

        print(
          '🔄 Switched to chronological mode, added ${newArticles.length} new articles',
        );
      } else {
        // Already in chronological mode - get next batch
        newArticles = _getUniqueArticles(_allArticles, pageSize);
        _displayedArticles.addAll(newArticles);

        print('📄 Added ${newArticles.length} more articles');
      }

      setState(() {
        _isLoadingMore = false;
        _hasMoreData = _hasMoreUniqueArticles();
      });

      print(
        '📊 Total displayed: ${_displayedArticles.length}/${_allArticles.length} articles (${newArticles.length} new)',
      );
    }
  }

  /// Get articles that aren't already displayed
  List<NewsArticle> _getUniqueArticles(
    List<NewsArticle> sourceArticles,
    int maxCount,
  ) {
    final displayedUrls = _displayedArticles.map((a) => a.url).toSet();
    return sourceArticles
        .where((article) => !displayedUrls.contains(article.url))
        .take(maxCount)
        .toList();
  }

  /// Check if there are more unique articles available
  bool _hasMoreUniqueArticles() {
    final displayedUrls = _displayedArticles.map((a) => a.url).toSet();
    return _allArticles.any((article) => !displayedUrls.contains(article.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LanguageService().translate('news_title')),
        backgroundColor: Color(AppConfig.primaryBlue),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isInitialLoading ? null : _refreshNews,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isInitialLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_displayedArticles.isEmpty) {
      return _buildEmptyState();
    }

    return _buildNewsList();
  }

  /// Build loading state with skeleton cards
  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => _buildSkeletonCard(),
    );
  }

  /// Build skeleton loading card
  Widget _buildSkeletonCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Skeleton image
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 12),

            // Skeleton title
            Container(
              width: double.infinity,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: MediaQuery.of(context).size.width * 0.7,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),

            // Skeleton text lines
            Container(
              width: double.infinity,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),

            // Skeleton footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 80,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Container(
                  width: 60,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState() {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                'Unable to load news',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Unknown error occurred',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadInitialNews,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(AppConfig.primaryBlue),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 100),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.article, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No news available',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Check back later for the latest financial news',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _refreshNews,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(AppConfig.primaryBlue),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build news list with pull-to-refresh and load more
  Widget _buildNewsList() {
    return RefreshIndicator(
      onRefresh: _refreshNews,
      child: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          // Load more when near bottom
          if (!_isLoadingMore &&
              _hasMoreData &&
              scrollInfo.metrics.pixels >=
                  scrollInfo.metrics.maxScrollExtent - 500) {
            _loadMoreArticles();
          }
          return false;
        },
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount:
              _displayedArticles.length +
              (_hasMoreData ? 1 : 0) +
              1, // +1 for header
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildHeader();
            }

            final articleIndex = index - 1;

            if (articleIndex == _displayedArticles.length) {
              return _buildLoadMoreIndicator();
            }

            return _buildNewsCard(_displayedArticles[articleIndex]);
          },
        ),
      ),
    );
  }

  /// Build header with stats
  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(AppConfig.primaryBlue).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(AppConfig.primaryBlue).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.trending_up,
            color: Color(AppConfig.primaryBlue),
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _showOnlyRecent ? 'Latest Unique News' : 'All Financial News',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(AppConfig.primaryBlue),
                  ),
                ),
                Text(
                  '${_displayedArticles.length} articles • ${_allArticles.length} total available',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build load more indicator
  Widget _buildLoadMoreIndicator() {
    if (_isLoadingMore) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Loading more articles...'),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ElevatedButton(
        onPressed: _loadMoreArticles,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade100,
          foregroundColor: Color(AppConfig.primaryBlue),
          elevation: 0,
          minimumSize: const Size(double.infinity, 48),
        ),
        child: const Text('Load More Articles'),
      ),
    );
  }

  /// Build rich news card
  Widget _buildNewsCard(NewsArticle article) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openArticle(article),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Article image
            if (article.hasImage)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.network(
                  article.img!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 200,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.image_not_supported, size: 50),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: double.infinity,
                      height: 200,
                      color: Colors.grey.shade300,
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              ),

            // Article content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ticker tag
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Color(AppConfig.primaryBlue).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Color(AppConfig.primaryBlue).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      article.primaryTicker,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(AppConfig.primaryBlue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Article title
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Article excerpt
                  Text(
                    article.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Footer: source and time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          article.source,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(AppConfig.primaryBlue),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        article.timeAgo,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Open article in external browser
  Future<void> _openArticle(NewsArticle article) async {
    try {
      final url = Uri.parse(article.url);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showErrorSnackBar('Cannot open article URL');
      }
    } catch (e) {
      _showErrorSnackBar('Error opening article: $e');
    }
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red.shade600),
      );
    }
  }
}
