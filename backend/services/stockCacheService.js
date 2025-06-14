/**
 * Stock Cache Service
 * Handles caching of stock quotes and chart data in Firebase Realtime Database
 */

const firebaseService = require('./firebaseService');
const yahooFinanceService = require('./yahooFinanceService');

class StockCacheService {
  constructor() {
    this.cacheExpiryMs = 24 * 60 * 60 * 1000; // 24 hours in milliseconds
    this.isInitialized = false;
    
    // Predefined list of 20 main stocks
    this.mainStocks = [
      'BAC', 'ABBV', 'NVO', 'KO', 'PLTR', 'SMFG', 'ASML', 'BABA', 'PM', 'TMUS',
      'UNH', 'GE', 'AAPL', 'GOOGL', 'MSFT', 'TSLA', 'AMZN', 'NVDA', 'META',
      'JPM', 'V', 'WMT', 'JNJ', 'XOM', 'PG'
    ];
  }

  /**
   * Initialize the stock cache service
   */
  async initialize() {
    try {
      console.log('📊 Initializing Stock Cache Service...');
      this.isInitialized = true;
      console.log('✅ Stock Cache Service initialized successfully');
    } catch (error) {
      console.error('❌ Failed to initialize Stock Cache Service:', error.message);
      throw error;
    }
  }

  /**
   * Get stock data (quote + chart) for a single ticker
   * @param {string} ticker - Stock ticker symbol
   * @returns {Promise<Object>} Stock data with quote and chart
   */
  async getStockData(ticker) {
    try {
      console.log(`📊 Getting stock data for ${ticker}`);
      
      // Check cache first
      const cachedData = await this.getCachedStockData(ticker);
      if (cachedData && this.isCacheValid(cachedData.lastUpdated)) {
        console.log(`✅ Using cached data for ${ticker}`);
        return {
          success: true,
          data: cachedData,
          source: 'cache',
          ticker: ticker
        };
      }

      // Fetch fresh data from Yahoo Finance
      console.log(`🔄 Fetching fresh data for ${ticker}`);
      const [quoteResult, chartResult] = await Promise.all([
        yahooFinanceService.getBatchQuotes([ticker]),
        yahooFinanceService.getChartData(ticker, '1d', '1mo')
      ]);

      if (!quoteResult.success && !chartResult.success) {
        // Both failed, return cached data if available
        if (cachedData) {
          console.log(`⚠️ API failed, using stale cached data for ${ticker}`);
          return {
            success: true,
            data: cachedData,
            source: 'stale_cache',
            ticker: ticker,
            warning: 'Using stale data due to API failure'
          };
        }
        
        return {
          success: false,
          error: 'Failed to fetch data and no cache available',
          ticker: ticker
        };
      }

      // Prepare stock data object
      const stockData = {
        symbol: ticker,
        name: yahooFinanceService.getStockName(ticker),
        logo: yahooFinanceService.getCompanyLogo(ticker),
        quote: quoteResult.success ? quoteResult.data[0] : null,
        chart: chartResult.success ? chartResult.data : null,
        lastUpdated: Date.now()
      };

      // Cache the data
      await this.setCachedStockData(ticker, stockData);

      console.log(`✅ Successfully fetched and cached data for ${ticker}`);
      return {
        success: true,
        data: stockData,
        source: 'api',
        ticker: ticker
      };

    } catch (error) {
      console.error(`❌ Error getting stock data for ${ticker}:`, error.message);
      
      // Try to return cached data as fallback
      const cachedData = await this.getCachedStockData(ticker);
      if (cachedData) {
        console.log(`⚠️ Error occurred, using cached data for ${ticker}`);
        return {
          success: true,
          data: cachedData,
          source: 'error_fallback_cache',
          ticker: ticker,
          warning: 'Using cached data due to error'
        };
      }

      return {
        success: false,
        error: error.message,
        ticker: ticker
      };
    }
  }

  /**
   * Get stock data for multiple tickers (main 20 stocks)
   * @param {Array<string>} tickers - Array of ticker symbols (defaults to main 20)
   * @returns {Promise<Array>} Array of stock data objects
   */
  async getMainStocksData(tickers = this.mainStocks) {
    try {
      console.log(`📊 Getting data for ${tickers.length} main stocks`);
      
      const results = [];
      const tickersToFetch = [];
      const cachedResults = [];

      // Check cache for each ticker
      for (const ticker of tickers) {
        const cachedData = await this.getCachedStockData(ticker);
        if (cachedData && this.isCacheValid(cachedData.lastUpdated)) {
          console.log(`✅ Using cached data for ${ticker}`);
          cachedResults.push({
            success: true,
            data: cachedData,
            source: 'cache',
            ticker: ticker
          });
        } else {
          tickersToFetch.push(ticker);
        }
      }

      // Fetch fresh data for tickers not in cache or with stale data
      if (tickersToFetch.length > 0) {
        console.log(`🔄 Fetching fresh data for ${tickersToFetch.length} tickers: ${tickersToFetch.join(', ')}`);
        
        // Fetch quotes and charts in parallel
        const [quotesResult, ...chartResults] = await Promise.all([
          yahooFinanceService.getBatchQuotes(tickersToFetch),
          ...tickersToFetch.map(ticker => yahooFinanceService.getChartData(ticker, '1d', '1mo'))
        ]);

        // Process results
        for (let i = 0; i < tickersToFetch.length; i++) {
          const ticker = tickersToFetch[i];
          const quote = quotesResult.success ? quotesResult.data.find(q => q.symbol === ticker) : null;
          const chartResult = chartResults[i];

          if (quote || chartResult.success) {
            const stockData = {
              symbol: ticker,
              name: yahooFinanceService.getStockName(ticker),
              logo: yahooFinanceService.getCompanyLogo(ticker),
              quote: quote,
              chart: chartResult.success ? chartResult.data : null,
              lastUpdated: Date.now()
            };

            // Cache the data
            await this.setCachedStockData(ticker, stockData);

            results.push({
              success: true,
              data: stockData,
              source: 'api',
              ticker: ticker
            });
          } else {
            // Try to use stale cached data
            const cachedData = await this.getCachedStockData(ticker);
            if (cachedData) {
              console.log(`⚠️ API failed, using stale cached data for ${ticker}`);
              results.push({
                success: true,
                data: cachedData,
                source: 'stale_cache',
                ticker: ticker,
                warning: 'Using stale data due to API failure'
              });
            } else {
              results.push({
                success: false,
                error: 'Failed to fetch data and no cache available',
                ticker: ticker
              });
            }
          }
        }
      }

      // Combine cached and fresh results
      const allResults = [...cachedResults, ...results];
      
      // Sort results to match original ticker order
      const sortedResults = tickers.map(ticker => 
        allResults.find(result => result.ticker === ticker)
      ).filter(Boolean);

      console.log(`✅ Successfully retrieved data for ${sortedResults.filter(r => r.success).length}/${tickers.length} stocks`);
      return sortedResults;

    } catch (error) {
      console.error('❌ Error getting main stocks data:', error.message);
      throw error;
    }
  }

  /**
   * Search stocks using Yahoo Finance API
   * @param {string} query - Search query
   * @returns {Promise<Object>} Search results
   */
  async searchStocks(query) {
    try {
      console.log(`🔍 Searching stocks for: "${query}"`);
      const result = await yahooFinanceService.searchStocks(query);
      
      if (result.success) {
        console.log(`✅ Found ${result.data.length} search results for "${query}"`);
      }
      
      return result;
    } catch (error) {
      console.error(`❌ Error searching stocks for "${query}":`, error.message);
      return {
        success: false,
        error: error.message,
        query: query
      };
    }
  }

  /**
   * Refresh cache for all main stocks
   * @returns {Promise<Object>} Refresh results
   */
  async refreshMainStocksCache() {
    try {
      console.log('🔄 Starting cache refresh for main stocks...');
      const startTime = Date.now();
      
      const results = await this.getMainStocksData(this.mainStocks);
      const successCount = results.filter(r => r.success).length;
      const duration = Date.now() - startTime;
      
      console.log(`✅ Cache refresh completed: ${successCount}/${this.mainStocks.length} stocks updated in ${duration}ms`);
      
      return {
        success: true,
        totalStocks: this.mainStocks.length,
        successCount: successCount,
        failureCount: this.mainStocks.length - successCount,
        duration: duration,
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      console.error('❌ Error refreshing main stocks cache:', error.message);
      return {
        success: false,
        error: error.message,
        timestamp: new Date().toISOString()
      };
    }
  }

  /**
   * Get cached stock data from Firebase
   * @param {string} ticker - Stock ticker symbol
   * @returns {Promise<Object|null>} Cached stock data or null
   */
  async getCachedStockData(ticker) {
    try {
      if (!firebaseService.database) {
        console.warn('⚠️ Firebase database not available');
        return null;
      }

      const snapshot = await firebaseService.database
        .ref(`stockPrices/${ticker}`)
        .once('value');
      
      return snapshot.val();
    } catch (error) {
      console.error(`❌ Error getting cached data for ${ticker}:`, error.message);
      return null;
    }
  }

  /**
   * Set cached stock data in Firebase
   * @param {string} ticker - Stock ticker symbol
   * @param {Object} data - Stock data to cache
   * @returns {Promise<boolean>} Success status
   */
  async setCachedStockData(ticker, data) {
    try {
      if (!firebaseService.database) {
        console.warn('⚠️ Firebase database not available, skipping cache');
        return false;
      }

      await firebaseService.database
        .ref(`stockPrices/${ticker}`)
        .set(data);
      
      console.log(`💾 Cached data for ${ticker}`);
      return true;
    } catch (error) {
      console.error(`❌ Error caching data for ${ticker}:`, error.message);
      return false;
    }
  }

  /**
   * Check if cached data is still valid
   * @param {number} lastUpdated - Timestamp when data was last updated
   * @returns {boolean} True if cache is still valid
   */
  isCacheValid(lastUpdated) {
    if (!lastUpdated) return false;
    const age = Date.now() - lastUpdated;
    return age < this.cacheExpiryMs;
  }

  /**
   * Get cache statistics
   * @returns {Promise<Object>} Cache statistics
   */
  async getCacheStats() {
    try {
      const stats = {
        mainStocks: this.mainStocks.length,
        cacheExpiryHours: this.cacheExpiryMs / (60 * 60 * 1000),
        cachedStocks: 0,
        validCachedStocks: 0,
        staleCachedStocks: 0,
        lastChecked: new Date().toISOString()
      };

      if (!firebaseService.database) {
        stats.error = 'Firebase database not available';
        return stats;
      }

      // Check cache status for main stocks
      const snapshot = await firebaseService.database
        .ref('stockPrices')
        .once('value');
      
      const cachedData = snapshot.val() || {};
      stats.cachedStocks = Object.keys(cachedData).length;

      // Count valid vs stale cache entries
      for (const ticker of this.mainStocks) {
        if (cachedData[ticker]) {
          if (this.isCacheValid(cachedData[ticker].lastUpdated)) {
            stats.validCachedStocks++;
          } else {
            stats.staleCachedStocks++;
          }
        }
      }

      return stats;
    } catch (error) {
      console.error('❌ Error getting cache stats:', error.message);
      return {
        error: error.message,
        lastChecked: new Date().toISOString()
      };
    }
  }

  /**
   * Get the list of main stocks
   * @returns {Array<string>} Array of main stock tickers
   */
  getMainStocks() {
    return [...this.mainStocks];
  }
}

// Export singleton instance
module.exports = new StockCacheService(); 