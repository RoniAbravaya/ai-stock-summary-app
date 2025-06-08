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
      this.setupCleanupTask();
      
      this.isInitialized = true;
      console.log('✅ Scheduler service initialized successfully');
    } catch (error) {
      console.error('❌ Failed to initialize scheduler service:', error.message);
      throw error;
    }
  }

  /**
   * Setup periodic news update task
   */
  setupNewsUpdateTask() {
    if (!cron) return;

    // Run every hour
    const task = cron.schedule('0 * * * *', async () => {
      try {
        console.log('🔄 Running scheduled news update...');
        // Add your news update logic here
        console.log('✅ Scheduled news update completed');
      } catch (error) {
        console.error('❌ Scheduled news update failed:', error.message);
      }
    });

    this.tasks.set('newsUpdate', task);
  }

  /**
   * Setup cleanup task
   */
  setupCleanupTask() {
    if (!cron) return;

    // Run daily at midnight
    const task = cron.schedule('0 0 * * *', async () => {
      try {
        console.log('🧹 Running scheduled cleanup...');
        // Add your cleanup logic here
        console.log('✅ Scheduled cleanup completed');
      } catch (error) {
        console.error('❌ Scheduled cleanup failed:', error.message);
      }
    });

    this.tasks.set('cleanup', task);
  }

  /**
   * Stop all scheduled tasks
   */
  stopAll() {
    if (!cron) return;

    console.log('⏹️ Stopping all scheduled tasks...');
    for (const [name, task] of this.tasks) {
      task.stop();
      console.log(`✅ Stopped task: ${name}`);
    }
    this.tasks.clear();
  }

  /**
   * Start the daily news refresh scheduler
   * Runs every day at 9:00 PM UTC (21:00)
   */
  startDailyRefresh() {
    if (this.isSchedulerRunning) {
      console.log('⚠️ Scheduler is already running');
      return;
    }

    // Schedule: Daily at 9:00 PM UTC (0 21 * * *)
    this.cronJob = cron.schedule('0 21 * * *', async () => {
      console.log('🕘 Daily news refresh triggered at 9:00 PM UTC');
      await this.refreshAllTickersNews();
    }, {
      scheduled: false,
      timezone: 'UTC'
    });

    this.cronJob.start();
    this.isSchedulerRunning = true;
    this.calculateNextRefreshTime();
    
    console.log('✅ Daily news refresh scheduler started (9:00 PM UTC daily)');
    console.log(`📅 Next refresh scheduled for: ${this.nextRefreshTime}`);
  }

  /**
   * Stop the daily news refresh scheduler
   */
  stopDailyRefresh() {
    if (!this.isSchedulerRunning) {
      console.log('⚠️ Scheduler is not running');
      return;
    }

    if (this.cronJob) {
      this.cronJob.stop();
      this.cronJob.destroy();
    }

    this.isSchedulerRunning = false;
    this.nextRefreshTime = null;
    
    console.log('🛑 Daily news refresh scheduler stopped');
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
   * Calculate next refresh time (next 9:00 PM UTC)
   */
  calculateNextRefreshTime() {
    const now = new Date();
    const nextRefresh = new Date();
    
    // Set to 9:00 PM UTC today
    nextRefresh.setUTCHours(21, 0, 0, 0);
    
    // If we've already passed 9:00 PM UTC today, set to tomorrow
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
      scheduleExpression: '0 21 * * * (9:00 PM UTC daily)'
    };
  }
}

// Export singleton instance
module.exports = new SchedulerService();