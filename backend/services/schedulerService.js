/**
 * Scheduler Service
 * Handles scheduling of periodic tasks
 */

let cron;
try {
  cron = require('node-cron');
} catch (error) {
  console.warn('⚠️ node-cron module not found. Scheduler functionality will be limited.');
}

const yahooFinanceService = require('./yahooFinanceService');
const newsCacheService = require('./newsCacheService');
const stockCacheService = require('./stockCacheService');

class SchedulerService {
  constructor() {
    this.isSchedulerRunning = false;
    this.lastRefreshTime = null;
    this.nextRefreshTime = null;
    this.refreshStats = {
      totalRuns: 0,
      successfulRuns: 0,
      failedRuns: 0,
      lastRunResult: null
    };
    this.stockRefreshStats = {
      totalRuns: 0,
      successfulRuns: 0,
      failedRuns: 0,
      lastRunResult: null
    };
    this.isInitialized = false;
    this.tasks = new Map();
  }

  /**
   * Initialize the scheduler service
   */
  async initialize() {
    if (!cron) {
      console.warn('⚠️ Scheduler service initialization skipped (node-cron not available)');
      return;
    }

    try {
      // Initialize your scheduled tasks here
      this.setupNewsUpdateTask();
      this.setupStockUpdateTask();
      this.setupCleanupTask();
      
      this.isInitialized = true;
      console.log('✅ Scheduler service initialized successfully');
    } catch (error) {
      console.error('❌ Failed to initialize scheduler service:', error.message);
      throw error;
    }
  }

  /**
   * Setup periodic news update task - runs every 24 hours
   */
  setupNewsUpdateTask() {
    if (!cron) return;

    // Run every 24 hours at midnight UTC
    const task = cron.schedule('0 0 * * *', async () => {
      try {
        console.log('🔄 Running scheduled 24-hour news update...');
        const result = await this.refreshAllTickersNews();
        console.log(`✅ Scheduled news update completed: ${result.summary}`);
      } catch (error) {
        console.error('❌ Scheduled news update failed:', error.message);
      }
    }, {
      scheduled: true,
      timezone: 'UTC'
    });

    this.tasks.set('newsUpdate', task);
    console.log('✅ 24-hour news update scheduler started (runs daily at midnight UTC)');
  }

  /**
   * Setup periodic stock update task - runs every 24 hours
   */
  setupStockUpdateTask() {
    if (!cron) return;

    // Run every 24 hours at 1 AM UTC (1 hour after news update)
    const task = cron.schedule('0 1 * * *', async () => {
      try {
        console.log('📊 Running scheduled 24-hour stock update...');
        const result = await this.refreshMainStocksCache();
        console.log(`✅ Scheduled stock update completed: ${result.summary || 'Success'}`);
      } catch (error) {
        console.error('❌ Scheduled stock update failed:', error.message);
      }
    }, {
      scheduled: true,
      timezone: 'UTC'
    });

    this.tasks.set('stockUpdate', task);
    console.log('✅ 24-hour stock update scheduler started (runs daily at 1 AM UTC)');
  }

  /**
   * Setup cleanup task
   */
  setupCleanupTask() {
    if (!cron) return;

    // Run daily at 2 AM UTC
    const task = cron.schedule('0 2 * * *', async () => {
      try {
        console.log('🧹 Running scheduled cleanup...');
        // Add your cleanup logic here
        console.log('✅ Scheduled cleanup completed');
      } catch (error) {
        console.error('❌ Scheduled cleanup failed:', error.message);
      }
    });

    this.tasks.set('cleanup', task);
    console.log('✅ Cleanup scheduler started (runs daily at 2 AM UTC)');
  }

  /**
   * Manually trigger stock cache refresh
   * @returns {Promise<Object>} Refresh operation result
   */
  async refreshMainStocksCache() {
    const startTime = new Date();
    console.log(`📊 Starting stock cache refresh at ${startTime.toISOString()}`);
    
    try {
      this.stockRefreshStats.totalRuns++;
      
      // Use the stock cache service to refresh
      const result = await stockCacheService.refreshMainStocksCache();
      
      const endTime = new Date();
      const refreshResult = {
        ...result,
        startTime: startTime.toISOString(),
        endTime: endTime.toISOString(),
        summary: `Stock cache refresh: ${result.successCount}/${result.totalStocks} stocks updated`
      };
      
      // Update stats
      if (result.success) {
        this.stockRefreshStats.successfulRuns++;
      } else {
        this.stockRefreshStats.failedRuns++;
      }
      
      this.stockRefreshStats.lastRunResult = refreshResult;
      
      console.log(`✅ Stock cache refresh completed: ${refreshResult.summary}`);
      return refreshResult;
      
    } catch (error) {
      const endTime = new Date();
      const duration = Math.round((endTime - startTime) / 1000);
      
      console.error('❌ Error during stock cache refresh:', error.message);
      
      this.stockRefreshStats.failedRuns++;
      
      const errorResult = {
        success: false,
        startTime: startTime.toISOString(),
        endTime: endTime.toISOString(),
        durationSeconds: duration,
        error: error.message,
        summary: `Stock cache refresh failed after ${duration} seconds`
      };
      
      this.stockRefreshStats.lastRunResult = errorResult;
      
      return errorResult;
    }
  }

  /**
   * Manually trigger both news and stock cache refresh
   * @returns {Promise<Object>} Combined refresh operation result
   */
  async refreshAllCaches() {
    const startTime = new Date();
    console.log(`🔄 Starting combined cache refresh at ${startTime.toISOString()}`);
    
    try {
      // Run both refreshes in parallel
      const [newsResult, stockResult] = await Promise.all([
        this.refreshAllTickersNews(),
        this.refreshMainStocksCache()
      ]);
      
      const endTime = new Date();
      const duration = Math.round((endTime - startTime) / 1000);
      
      const combinedResult = {
        success: newsResult.success && stockResult.success,
        startTime: startTime.toISOString(),
        endTime: endTime.toISOString(),
        durationSeconds: duration,
        news: newsResult,
        stocks: stockResult,
        summary: `Combined refresh: News ${newsResult.success ? 'success' : 'failed'}, Stocks ${stockResult.success ? 'success' : 'failed'}`
      };
      
      console.log(`✅ Combined cache refresh completed: ${combinedResult.summary}`);
      return combinedResult;
      
    } catch (error) {
      const endTime = new Date();
      const duration = Math.round((endTime - startTime) / 1000);
      
      console.error('❌ Error during combined cache refresh:', error.message);
      
      return {
        success: false,
        startTime: startTime.toISOString(),
        endTime: endTime.toISOString(),
        durationSeconds: duration,
        error: error.message,
        summary: `Combined cache refresh failed after ${duration} seconds`
      };
    }
  }

  /**
   * Get scheduler statistics
   * @returns {Object} Scheduler statistics
   */
  getStats() {
    return {
      isInitialized: this.isInitialized,
      tasksRunning: this.tasks.size,
      tasks: Array.from(this.tasks.keys()),
      news: {
        ...this.refreshStats,
        lastRefreshTime: this.lastRefreshTime,
        nextRefreshTime: this.nextRefreshTime
      },
      stocks: {
        ...this.stockRefreshStats
      },
      currentTime: new Date().toISOString(),
      timezone: 'UTC'
    };
  }

  /**
   * Manually trigger news refresh for all tickers
   * @returns {Promise<Object>} Refresh operation result
   */
  async refreshAllTickersNews() {
    const startTime = new Date();
    console.log(`🚀 Starting news refresh for all tickers at ${startTime.toISOString()}`);
    
    try {
      this.refreshStats.totalRuns++;
      
      // Get all supported tickers
      const tickers = newsCacheService.getSupportedTickers();
      console.log(`📋 Refreshing news for ${tickers.length} tickers: ${tickers.join(', ')}`);
      
      // Fetch news for all tickers with delay to avoid rate limiting
      const fetchResults = await yahooFinanceService.fetchNewsForMultipleTickers(tickers, 2000); // 2 second delay
      
      // Store results in cache
      const storeResults = [];
      let successCount = 0;
      let errorCount = 0;
      
      for (const result of fetchResults) {
        if (result.success && result.data && result.data.length > 0) {
          const storeResult = await newsCacheService.storeNewsForTicker(result.ticker, result.data);
          storeResults.push(storeResult);
          
          if (storeResult.success) {
            successCount++;
          } else {
            errorCount++;
          }
        } else {
          errorCount++;
          storeResults.push({
            success: false,
            ticker: result.ticker,
            error: result.error || 'No news data received'
          });
        }
      }
      
      const endTime = new Date();
      const duration = Math.round((endTime - startTime) / 1000); // seconds
      
      const refreshResult = {
        success: successCount > 0,
        startTime: startTime.toISOString(),
        endTime: endTime.toISOString(),
        durationSeconds: duration,
        totalTickers: tickers.length,
        successfulTickers: successCount,
        failedTickers: errorCount,
        fetchResults: fetchResults,
        storeResults: storeResults,
        summary: `Refreshed ${successCount}/${tickers.length} tickers successfully in ${duration} seconds`
      };
      
      // Update stats
      if (refreshResult.success) {
        this.refreshStats.successfulRuns++;
      } else {
        this.refreshStats.failedRuns++;
      }
      
      this.refreshStats.lastRunResult = refreshResult;
      this.lastRefreshTime = endTime.toISOString();
      this.calculateNextRefreshTime();
      
      console.log(`✅ News refresh completed: ${refreshResult.summary}`);
      return refreshResult;
      
    } catch (error) {
      const endTime = new Date();
      const duration = Math.round((endTime - startTime) / 1000);
      
      console.error('❌ Error during news refresh:', error.message);
      
      this.refreshStats.failedRuns++;
      
      const errorResult = {
        success: false,
        startTime: startTime.toISOString(),
        endTime: endTime.toISOString(),
        durationSeconds: duration,
        error: error.message,
        summary: `News refresh failed after ${duration} seconds`
      };
      
      this.refreshStats.lastRunResult = errorResult;
      this.lastRefreshTime = endTime.toISOString();
      
      return errorResult;
    }
  }

  /**
   * Manually trigger news refresh for a specific ticker
   * @param {string} ticker - Stock ticker symbol
   * @returns {Promise<Object>} Refresh operation result
   */
  async refreshTickerNews(ticker) {
    const startTime = new Date();
    console.log(`🚀 Starting news refresh for ticker: ${ticker}`);
    
    try {
      // Validate ticker
      const supportedTickers = newsCacheService.getSupportedTickers();
      if (!supportedTickers.includes(ticker.toUpperCase())) {
        return {
          success: false,
          ticker: ticker,
          error: 'Ticker not supported',
          supportedTickers: supportedTickers
        };
      }
      
      // Fetch news for the ticker
      const fetchResult = await yahooFinanceService.fetchNewsForTicker(ticker);
      
      if (!fetchResult.success) {
        return {
          success: false,
          ticker: ticker,
          error: fetchResult.error,
          fetchResult: fetchResult
        };
      }
      
      // Store in cache
      const storeResult = await newsCacheService.storeNewsForTicker(ticker, fetchResult.data);
      
      const endTime = new Date();
      const duration = Math.round((endTime - startTime) / 1000);
      
      const result = {
        success: storeResult.success,
        ticker: ticker,
        startTime: startTime.toISOString(),
        endTime: endTime.toISOString(),
        durationSeconds: duration,
        articlesCount: fetchResult.data ? fetchResult.data.length : 0,
        fetchResult: fetchResult,
        storeResult: storeResult,
        summary: storeResult.success 
          ? `Successfully refreshed ${fetchResult.data.length} articles for ${ticker}`
          : `Failed to refresh news for ${ticker}: ${storeResult.error}`
      };
      
      console.log(`✅ Single ticker refresh completed: ${result.summary}`);
      return result;
      
    } catch (error) {
      const endTime = new Date();
      const duration = Math.round((endTime - startTime) / 1000);
      
      console.error(`❌ Error refreshing ticker ${ticker}:`, error.message);
      
      return {
        success: false,
        ticker: ticker,
        startTime: startTime.toISOString(),
        endTime: endTime.toISOString(),
        durationSeconds: duration,
        error: error.message,
        summary: `Failed to refresh news for ${ticker}: ${error.message}`
      };
    }
  }

  /**
   * Calculate next refresh time (next midnight UTC)
   */
  calculateNextRefreshTime() {
    const now = new Date();
    const nextRefresh = new Date();
    
    // Set to midnight UTC today
    nextRefresh.setUTCHours(0, 0, 0, 0);
    
    // If we've already passed midnight UTC today, set to tomorrow
    if (now >= nextRefresh) {
      nextRefresh.setUTCDate(nextRefresh.getUTCDate() + 1);
    }
    
    this.nextRefreshTime = nextRefresh.toISOString();
  }

  /**
   * Get scheduler status and statistics
   * @returns {Object} Scheduler status information
   */
  getStatus() {
    return {
      isRunning: this.isSchedulerRunning,
      lastRefreshTime: this.lastRefreshTime,
      nextRefreshTime: this.nextRefreshTime,
      stats: { ...this.refreshStats },
      supportedTickers: newsCacheService.getSupportedTickers(),
      currentTime: new Date().toISOString(),
      timezone: 'UTC',
      scheduleExpression: '0 0 * * * (midnight UTC daily)'
    };
  }
}

// Export singleton instance
module.exports = new SchedulerService();