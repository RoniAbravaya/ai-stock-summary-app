/**
 * News Cache Service
 * Handles caching news data in Firebase Realtime Database
 */

const firebaseService = require('./firebaseService');
const yahooFinanceService = require('./yahooFinanceService');

class NewsCacheService {
  constructor() {
    this.tickers = [
      'BAC', 'ABBV', 'NVO', 'KO', 'PLTR', 'SMFG', 'ASML', 'BABA', 'PM', 'TMUS',
      'UNH', 'GE', 'AAPL', 'GOOGL', 'MSFT', 'TSLA', 'AMZN', 'NVDA', 'META',
      'JPM', 'V', 'WMT', 'JNJ', 'XOM', 'PG'
    ];
  }

  /**
   * Get the database reference for a specific ticker's news
   * @param {string} ticker - Stock ticker symbol
   * @returns {Object} Firebase Realtime Database reference
   */
  getTickerNewsRef(ticker) {
    if (!firebaseService.isInitialized) {
      throw new Error('Firebase is not initialized. Please configure Firebase credentials.');
    }
    return firebaseService.database.ref(`news_${ticker.toLowerCase()}`);
  }

  /**
   * Store news data for a specific ticker
   * @param {string} ticker - Stock ticker symbol
   * @param {Array} newsData - Array of news articles
   * @returns {Promise<Object>} Result of the operation
   */
  async storeNewsForTicker(ticker, newsData) {
    try {
      console.log(`💾 Storing ${newsData.length} news articles for ${ticker}`);
      
      // Check if Firebase is initialized
      if (!firebaseService.isInitialized) {
        console.warn(`⚠️ Firebase not initialized. Simulating storage for ${ticker}`);
        return {
          success: true,
          ticker: ticker,
          articlesStored: newsData.length,
          storedAt: new Date().toISOString(),
          note: 'Firebase not configured - data not actually stored'
        };
      }
      
      const tickerRef = this.getTickerNewsRef(ticker);
      
      // Create the data structure
      const cacheData = {
        ticker: ticker,
        lastUpdated: new Date().toISOString(),
        totalArticles: newsData.length,
        articles: {}
      };

      // Convert news array to object with unique keys
      newsData.forEach((article, index) => {
        const articleId = this.generateArticleId(article, index);
        cacheData.articles[articleId] = {
          ...article,
          cached_at: new Date().toISOString(),
          ticker: ticker
        };
      });

      // Store in Firebase
      await tickerRef.set(cacheData);
      
      console.log(`✅ Successfully cached ${newsData.length} articles for ${ticker}`);
      return {
        success: true,
        ticker: ticker,
        articlesStored: newsData.length,
        storedAt: cacheData.lastUpdated
      };
    } catch (error) {
      console.error(`❌ Error storing news for ${ticker}:`, error.message);
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
      console.log(`📖 Retrieving cached news for tickers: ${tickers.join(', ')}`);
      
      // Check if Firebase is initialized
      if (!firebaseService.isInitialized) {
        console.warn(`⚠️ Firebase not initialized. Falling back to Yahoo Finance API for all tickers...`);
        const results = {};
        
        // Fetch fresh data for all tickers since no cache is available
        for (const ticker of tickers) {
          try {
            console.log(`📡 Fetching fresh data for ${ticker} (no cache available)...`);
            const freshDataResult = await yahooFinanceService.fetchNewsForTicker(ticker);
            
            if (freshDataResult.success && freshDataResult.data && freshDataResult.data.length > 0) {
              console.log(`✅ Fetched ${freshDataResult.data.length} fresh articles for ${ticker}`);
              results[ticker] = {
                success: true,
                ticker: ticker,
                lastUpdated: new Date().toISOString(),
                totalArticles: freshDataResult.data.length,
                articles: freshDataResult.data,
                cacheAge: 0,
                freshlyFetched: true,
                note: 'Data fetched directly from Yahoo Finance (no cache available)'
              };
            } else {
              console.log(`❌ Failed to fetch fresh data for ${ticker}: ${freshDataResult.error || 'No data available'}`);
              results[ticker] = {
                success: false,
                ticker: ticker,
                error: 'No cached data available and failed to fetch fresh data',
                details: freshDataResult.error || 'No data available from Yahoo Finance'
              };
            }
          } catch (error) {
            console.error(`❌ Error fetching fresh data for ${ticker}:`, error.message);
            results[ticker] = {
              success: false,
              ticker: ticker,
              error: 'No cached data available and error fetching fresh data',
              details: error.message
            };
          }
        }
        
        return {
          success: Object.values(results).some(r => r.success),
          results: results,
          requestedTickers: tickers,
          retrievedAt: new Date().toISOString(),
          note: 'Firebase not configured - data fetched directly from Yahoo Finance'
        };
      }
      
      const results = {};
      
      for (const ticker of tickers) {
        try {
          const tickerRef = this.getTickerNewsRef(ticker);
          const snapshot = await tickerRef.once('value');
          
          if (snapshot.exists()) {
            const data = snapshot.val();
            results[ticker] = {
              success: true,
              ticker: ticker,
              lastUpdated: data.lastUpdated,
              totalArticles: data.totalArticles,
              articles: data.articles ? Object.values(data.articles) : [],
              cacheAge: this.calculateCacheAge(data.lastUpdated)
            };
            console.log(`✅ Found ${data.totalArticles} cached articles for ${ticker}`);
          } else {
            console.log(`⚠️ No cached data found for ${ticker}, fetching fresh data from Yahoo Finance...`);
            
            // Try to fetch fresh data from Yahoo Finance API
            try {
              const freshDataResult = await yahooFinanceService.fetchNewsForTicker(ticker);
              
              if (freshDataResult.success && freshDataResult.data && freshDataResult.data.length > 0) {
                console.log(`📡 Fetched ${freshDataResult.data.length} fresh articles for ${ticker}`);
                
                // Store the fresh data in cache
                const storeResult = await this.storeNewsForTicker(ticker, freshDataResult.data);
                
                if (storeResult.success) {
                  console.log(`💾 Successfully cached fresh data for ${ticker}`);
                  results[ticker] = {
                    success: true,
                    ticker: ticker,
                    lastUpdated: new Date().toISOString(),
                    totalArticles: freshDataResult.data.length,
                    articles: freshDataResult.data,
                    cacheAge: 0, // Fresh data
                    freshlyFetched: true // Flag to indicate this was just fetched
                  };
                } else {
                  console.log(`⚠️ Failed to cache fresh data for ${ticker}, but returning fresh data anyway`);
                  results[ticker] = {
                    success: true,
                    ticker: ticker,
                    lastUpdated: new Date().toISOString(),
                    totalArticles: freshDataResult.data.length,
                    articles: freshDataResult.data,
                    cacheAge: 0,
                    freshlyFetched: true,
                    note: 'Fresh data not cached due to storage error'
                  };
                }
              } else {
                console.log(`❌ Failed to fetch fresh data for ${ticker}: ${freshDataResult.error || 'No data available'}`);
                results[ticker] = {
                  success: false,
                  ticker: ticker,
                  error: 'No cached data found and failed to fetch fresh data',
                  details: freshDataResult.error || 'No data available from Yahoo Finance'
                };
              }
            } catch (freshDataError) {
              console.error(`❌ Error fetching fresh data for ${ticker}:`, freshDataError.message);
              results[ticker] = {
                success: false,
                ticker: ticker,
                error: 'No cached data found and error fetching fresh data',
                details: freshDataError.message
              };
            }
          }
        } catch (error) {
          console.error(`❌ Error retrieving data for ${ticker}:`, error.message);
          results[ticker] = {
            success: false,
            ticker: ticker,
            error: error.message
          };
        }
      }
      
      return {
        success: true,
        results: results,
        requestedTickers: tickers,
        retrievedAt: new Date().toISOString()
      };
    } catch (error) {
      console.error(`❌ Error retrieving news for tickers:`, error.message);
      return {
        success: false,
        error: error.message,
        requestedTickers: tickers
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
      const tickerRef = this.getTickerNewsRef(ticker);
      const snapshot = await tickerRef.once('value');
      
      if (!snapshot.exists()) {
        return {
          exists: false,
          fresh: false,
          ticker: ticker,
          message: 'No cached data found'
        };
      }
      
      const data = snapshot.val();
      const cacheAge = this.calculateCacheAge(data.lastUpdated);
      const isFresh = cacheAge < maxAgeHours;
      
      return {
        exists: true,
        fresh: isFresh,
        ticker: ticker,
        lastUpdated: data.lastUpdated,
        cacheAgeHours: cacheAge,
        totalArticles: data.totalArticles,
        message: isFresh ? 'Cache is fresh' : `Cache is stale (${cacheAge.toFixed(1)} hours old)`
      };
    } catch (error) {
      console.error(`❌ Error checking cache status for ${ticker}:`, error.message);
      return {
        exists: false,
        fresh: false,
        ticker: ticker,
        error: error.message
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
      console.log(`🗑️ Clearing cache for ${ticker}`);
      
      const tickerRef = this.getTickerNewsRef(ticker);
      await tickerRef.remove();
      
      console.log(`✅ Successfully cleared cache for ${ticker}`);
      return {
        success: true,
        ticker: ticker,
        message: 'Cache cleared successfully'
      };
    } catch (error) {
      console.error(`❌ Error clearing cache for ${ticker}:`, error.message);
      return {
        success: false,
        ticker: ticker,
        error: error.message
      };
    }
  }

  /**
   * Clear all cached news data
   * @returns {Promise<Object>} Result of the operation
   */
  async clearAllCache() {
    try {
      console.log('🗑️ Clearing all news cache...');
      
      const results = [];
      for (const ticker of this.tickers) {
        const result = await this.clearCacheForTicker(ticker);
        results.push(result);
      }
      
      const successCount = results.filter(r => r.success).length;
      console.log(`✅ Cache cleared for ${successCount}/${this.tickers.length} tickers`);
      
      return {
        success: true,
        message: `Cache cleared for ${successCount}/${this.tickers.length} tickers`,
        results: results
      };
    } catch (error) {
      console.error('❌ Error clearing all cache:', error.message);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * Get cache statistics for all tickers
   * @returns {Promise<Object>} Cache statistics
   */
  async getCacheStats() {
    try {
      console.log('📊 Generating cache statistics...');
      
      const stats = {
        totalTickers: this.tickers.length,
        cachedTickers: 0,
        freshTickers: 0,
        staleTickers: 0,
        totalArticles: 0,
        tickers: {}
      };
      
      for (const ticker of this.tickers) {
        const status = await this.checkCacheStatus(ticker);
        stats.tickers[ticker] = status;
        
        if (status.exists) {
          stats.cachedTickers++;
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
        generatedAt: new Date().toISOString()
      };
    } catch (error) {
      console.error('❌ Error generating cache stats:', error.message);
      return {
        success: false,
        error: error.message
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
    // Try to create ID from URL or title, fallback to index
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
}

// Export singleton instance
module.exports = new NewsCacheService();