/**
 * Admin API Routes
 * Handles administrative endpoints for cache management and system monitoring
 */

const express = require('express');
const router = express.Router();
const newsCacheService = require('../services/newsCacheService');
const stockCacheService = require('../services/stockCacheService');
const yahooFinanceService = require('../services/yahooFinanceService');
const schedulerService = require('../services/schedulerService');

// GET /api/admin/cache-stats - Get cache statistics
router.get('/cache-stats', async (req, res) => {
  try {
    console.log('🔧 GET /api/admin/cache-stats - Getting cache statistics');
    
    // Get news cache stats
    const newsCacheStats = await newsCacheService.getCacheStats();
    
    // Get stock cache stats
    const stockCacheStats = await stockCacheService.getCacheStats();
    
    // Get scheduler stats
    const schedulerStats = schedulerService.getStats ? schedulerService.getStats() : { error: 'Scheduler stats not available' };
    
    const stats = {
      news: newsCacheStats,
      stocks: stockCacheStats,
      scheduler: schedulerStats,
      timestamp: new Date().toISOString()
    };
    
    console.log('✅ Successfully returned cache statistics');
    res.json({
      success: true,
      data: stats,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('❌ Error getting cache stats:', error.message);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// POST /api/admin/refresh-news-cache - Manually refresh news cache
router.post('/refresh-news-cache', async (req, res) => {
  try {
    console.log('🔧 POST /api/admin/refresh-news-cache - Manually refreshing news cache');
    
    const result = await newsCacheService.refreshAllCache();
    
    if (result.success) {
      console.log('✅ News cache refresh completed successfully');
      res.json({
        success: true,
        message: 'News cache refresh completed',
        data: result,
        timestamp: new Date().toISOString()
      });
    } else {
      console.warn('⚠️ News cache refresh completed with errors');
      res.status(207).json({
        success: false,
        message: 'News cache refresh completed with errors',
        data: result,
        timestamp: new Date().toISOString()
      });
    }
  } catch (error) {
    console.error('❌ Error refreshing news cache:', error.message);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// POST /api/admin/refresh-stock-cache - Manually refresh stock cache
router.post('/refresh-stock-cache', async (req, res) => {
  try {
    console.log('🔧 POST /api/admin/refresh-stock-cache - Manually refreshing stock cache');
    
    const result = await stockCacheService.refreshMainStocksCache();
    
    if (result.success) {
      console.log('✅ Stock cache refresh completed successfully');
      res.json({
        success: true,
        message: 'Stock cache refresh completed',
        data: result,
        timestamp: new Date().toISOString()
      });
    } else {
      console.warn('⚠️ Stock cache refresh failed');
      res.status(500).json({
        success: false,
        message: 'Stock cache refresh failed',
        data: result,
        timestamp: new Date().toISOString()
      });
    }
  } catch (error) {
    console.error('❌ Error refreshing stock cache:', error.message);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// POST /api/admin/refresh-all-cache - Refresh both news and stock caches
router.post('/refresh-all-cache', async (req, res) => {
  try {
    console.log('🔧 POST /api/admin/refresh-all-cache - Refreshing all caches');
    
    const [newsResult, stockResult] = await Promise.all([
      newsCacheService.refreshAllCache(),
      stockCacheService.refreshMainStocksCache()
    ]);
    
    const overallSuccess = newsResult.success && stockResult.success;
    
    console.log(`${overallSuccess ? '✅' : '⚠️'} All cache refresh completed`);
    res.json({
      success: overallSuccess,
      message: 'All cache refresh completed',
      data: {
        news: newsResult,
        stocks: stockResult
      },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('❌ Error refreshing all caches:', error.message);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// GET /api/admin/main-stocks - Get list of main stocks
router.get('/main-stocks', async (req, res) => {
  try {
    console.log('🔧 GET /api/admin/main-stocks - Getting main stocks list');
    
    const mainStocks = stockCacheService.getMainStocks();
    
    console.log(`✅ Successfully returned ${mainStocks.length} main stocks`);
    res.json({
      success: true,
      data: mainStocks,
      totalStocks: mainStocks.length,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('❌ Error getting main stocks:', error.message);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// GET /api/admin/system-status - Get overall system status
router.get('/system-status', async (req, res) => {
  try {
    console.log('🔧 GET /api/admin/system-status - Getting system status');
    
    const [newsCacheStats, stockCacheStats] = await Promise.all([
      newsCacheService.getCacheStats(),
      stockCacheService.getCacheStats()
    ]);
    
    const systemStatus = {
      services: {
        newsCache: newsCacheService.isInitialized || false,
        stockCache: stockCacheService.isInitialized || false,
        scheduler: schedulerService.isInitialized || false
      },
      caches: {
        news: newsCacheStats,
        stocks: stockCacheStats
      },
      environment: {
        nodeEnv: process.env.NODE_ENV,
        enableMockData: process.env.ENABLE_MOCK_DATA === 'true',
        enableScheduler: process.env.ENABLE_SCHEDULER === 'true',
        enableCaching: process.env.ENABLE_CACHING === 'true'
      },
      timestamp: new Date().toISOString()
    };
    
    console.log('✅ Successfully returned system status');
    res.json({
      success: true,
      data: systemStatus,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('❌ Error getting system status:', error.message);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// GET /api/admin/test-yahoo-api - Test Yahoo Finance API connection
router.get('/test-yahoo-api', async (req, res) => {
  try {
    console.log('🔧 GET /api/admin/test-yahoo-api - Testing Yahoo Finance API');
    
    const result = await yahooFinanceService.testApiConnection();
    
    if (result.success) {
      console.log('✅ Yahoo Finance API test successful');
      res.json({
        success: true,
        message: 'Yahoo Finance API test successful',
        data: result,
        timestamp: new Date().toISOString()
      });
    } else {
      console.warn('⚠️ Yahoo Finance API test failed');
      res.status(503).json({
        success: false,
        message: 'Yahoo Finance API test failed',
        data: result,
        timestamp: new Date().toISOString()
      });
    }
  } catch (error) {
    console.error('❌ Error testing Yahoo Finance API:', error.message);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

module.exports = router; 