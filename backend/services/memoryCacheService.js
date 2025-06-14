/**
 * Memory Cache Service
 * Simple in-memory cache for testing caching logic without Firebase
 * This is a fallback when Firebase is not configured
 */

const yahooFinanceService = require('./yahooFinanceService');

class MemoryCacheService {
  constructor() {
    this.cache = new Map();
    this.tickers = [
      'BAC', 'ABBV', 'NVO', 'KO', 'PLTR', 'SMFG', 'ASML', 'BABA', 'PM', 'TMUS',
      'UNH', 'GE', 'AAPL', 'GOOGL', 'MSFT', 'TSLA', 'AMZN', 'NVDA', 'META',
      'JPM', 'V', 'WMT', 'JNJ', 'XOM', 'PG'
    ];
  }

  /**
   * Store news data for a specific ticker
   * @param {string} ticker - Stock ticker symbol
   * @param {Array} newsData - Array of news articles
   * @returns {Promise<Object>} Result of the operation
   */
  async storeNewsForTicker(ticker, newsData) {
    try {
      console.log(`💾 [MEMORY] Storing ${newsData.length} news articles for ${ticker}`);
      
      const cacheData = {
        ticker: ticker,
        lastUpdated: new Date().toISOString(),
        totalArticles: newsData.length,
        articles: newsData.map((article, index) => ({
          ...article,
          cached_at: new Date().toISOString(),
          ticker: ticker,
          id: this.generateArticleId(article, index)
        }))
      };

      this.cache.set(ticker.toLowerCase(), cacheData);
      
      console.log(`✅ [MEMORY] Successfully cached ${newsData.length} articles for ${ticker}`);
      return {
        success: true,
        ticker: ticker,
        articlesStored: newsData.length,
        storedAt: cacheData.lastUpdated
      };
    } catch (error) {
      console.error(`❌ [MEMORY] Error storing news for ${ticker}:`, error.message);
      return {
        success: false,
        ticker: ticker,
        error: error.message
      };
    }
  }

  /**
   * Retrieve cached news data for specific tickers
   * @param {Array<string>} tickers - Array of ticker symbols
   * @returns {Promise<Object>} Cached news data
   */
  async getNewsForTickers(tickers) {
    try {
      console.log(`📖 [MEMORY] Retrieving cached news for tickers: ${tickers.join(', ')}`);
      
      const results = {};
      
      for (const ticker of tickers) {
        const cacheKey = ticker.toLowerCase();
        
        if (this.cache.has(cacheKey)) {
          const data = this.cache.get(cacheKey);
          results[ticker] = {
            success: true,
            ticker: ticker,
            lastUpdated: data.lastUpdated,
            totalArticles: data.totalArticles,
            articles: data.articles,
            cacheAge: this.calculateCacheAge(data.lastUpdated),
            source: 'memory_cache'
          };
          console.log(`✅ [MEMORY] Found ${data.totalArticles} cached articles for ${ticker}`);
        } else {
          console.log(`⚠️ [MEMORY] No cached data found for ${ticker}`);
          results[ticker] = {
            success: false,
            ticker: ticker,
            error: 'No cached data available',
            note: 'Data will be available after the next scheduled refresh',
            source: 'memory_cache'
          };
        }
      }
      
      return {
        success: true,
        results: results,
        requestedTickers: tickers,
        retrievedAt: new Date().toISOString(),
        source: 'memory_cache'
      };
    } catch (error) {
      console.error(`❌ [MEMORY] Error retrieving news for tickers:`, error.message);
      return {
        success: false,
        error: error.message,
        requestedTickers: tickers,
        source: 'memory_cache'
      };
    }
  }

  /**
   * Check if cached data exists and is fresh for a ticker
   * @param {string} ticker - Stock ticker symbol
   * @param {number} maxAgeHours - Maximum age in hours (default: 24)
   * @returns {Promise<Object>} Cache status information
   */
  async checkCacheStatus(ticker, maxAgeHours = 24) {
    try {
      const cacheKey = ticker.toLowerCase();
      
      if (!this.cache.has(cacheKey)) {
        return {
          exists: false,
          fresh: false,
          ticker: ticker,
          message: 'No cached data found',
          source: 'memory_cache'
        };
      }
      
      const data = this.cache.get(cacheKey);
      const cacheAge = this.calculateCacheAge(data.lastUpdated);
      const isFresh = cacheAge < maxAgeHours;
      
      return {
        exists: true,
        fresh: isFresh,
        ticker: ticker,
        lastUpdated: data.lastUpdated,
        cacheAgeHours: cacheAge,
        totalArticles: data.totalArticles,
        message: isFresh ? 'Cache is fresh' : `Cache is stale (${cacheAge.toFixed(1)} hours old)`,
        source: 'memory_cache'
      };
    } catch (error) {
      console.error(`❌ [MEMORY] Error checking cache status for ${ticker}:`, error.message);
      return {
        exists: false,
        fresh: false,
        ticker: ticker,
        error: error.message,
        source: 'memory_cache'
      };
    }
  }

  /**
   * Clear cached data for a specific ticker
   * @param {string} ticker - Stock ticker symbol
   * @returns {Promise<Object>} Result of the operation
   */
  async clearCacheForTicker(ticker) {
    try {
      console.log(`🗑️ [MEMORY] Clearing cache for ${ticker}`);
      
      const cacheKey = ticker.toLowerCase();
      this.cache.delete(cacheKey);
      
      console.log(`✅ [MEMORY] Successfully cleared cache for ${ticker}`);
      return {
        success: true,
        ticker: ticker,
        message: 'Cache cleared successfully',
        source: 'memory_cache'
      };
    } catch (error) {
      console.error(`❌ [MEMORY] Error clearing cache for ${ticker}:`, error.message);
      return {
        success: false,
        ticker: ticker,
        error: error.message,
        source: 'memory_cache'
      };
    }
  }

  /**
   * Clear all cached news data
   * @returns {Promise<Object>} Result of the operation
   */
  async clearAllCache() {
    try {
      console.log('🗑️ [MEMORY] Clearing all news cache...');
      
      const clearedCount = this.cache.size;
      this.cache.clear();
      
      console.log(`✅ [MEMORY] Cache cleared for ${clearedCount} tickers`);
      
      return {
        success: true,
        message: `Cache cleared for ${clearedCount} tickers`,
        clearedCount: clearedCount,
        source: 'memory_cache'
      };
    } catch (error) {
      console.error('❌ [MEMORY] Error clearing all cache:', error.message);
      return {
        success: false,
        error: error.message,
        source: 'memory_cache'
      };
    }
  }

  /**
   * Get cache statistics for all tickers
   * @returns {Promise<Object>} Cache statistics
   */
  async getCacheStats() {
    try {
      console.log('📊 [MEMORY] Generating cache statistics...');
      
      const stats = {
        totalTickers: this.tickers.length,
        cachedTickers: this.cache.size,
        freshTickers: 0,
        staleTickers: 0,
        totalArticles: 0,
        tickers: {},
        source: 'memory_cache'
      };
      
      for (const ticker of this.tickers) {
        const status = await this.checkCacheStatus(ticker);
        stats.tickers[ticker] = status;
        
        if (status.exists) {
          stats.totalArticles += status.totalArticles || 0;
          
          if (status.fresh) {
            stats.freshTickers++;
          } else {
            stats.staleTickers++;
          }
        }
      }
      
      return {
        success: true,
        stats: stats,
        generatedAt: new Date().toISOString(),
        source: 'memory_cache'
      };
    } catch (error) {
      console.error('❌ [MEMORY] Error generating cache stats:', error.message);
      return {
        success: false,
        error: error.message,
        source: 'memory_cache'
      };
    }
  }

  /**
   * Generate a unique article ID
   * @param {Object} article - News article object
   * @param {number} index - Article index
   * @returns {string} Unique article ID
   */
  generateArticleId(article, index) {
    if (article.url) {
      return article.url.split('/').pop().replace(/[^a-zA-Z0-9]/g, '_').substring(0, 50) + '_' + index;
    }
    if (article.title) {
      return article.title.replace(/[^a-zA-Z0-9]/g, '_').substring(0, 50) + '_' + index;
    }
    return `article_${index}_${Date.now()}`;
  }

  /**
   * Calculate cache age in hours
   * @param {string} lastUpdated - ISO timestamp string
   * @returns {number} Age in hours
   */
  calculateCacheAge(lastUpdated) {
    const now = new Date();
    const updated = new Date(lastUpdated);
    const diffMs = now - updated;
    return diffMs / (1000 * 60 * 60); // Convert to hours
  }

  /**
   * Get list of supported tickers
   * @returns {Array<string>} Array of ticker symbols
   */
  getSupportedTickers() {
    return [...this.tickers];
  }

  /**
   * Get cache size info
   * @returns {Object} Cache size information
   */
  getCacheInfo() {
    return {
      type: 'memory_cache',
      size: this.cache.size,
      supportedTickers: this.tickers.length,
      cachedTickers: Array.from(this.cache.keys()),
      lastAccessed: new Date().toISOString()
    };
  }
}

// Export singleton instance
module.exports = new MemoryCacheService(); 