/**
 * Admin API Routes
 * Administrative endpoints for cache management and testing
 */

const express = require('express');
const router = express.Router();
const schedulerService = require('../services/schedulerService');
const newsCacheService = require('../services/newsCacheService');

// POST /api/admin/populate-cache - Manually trigger cache population
router.post('/populate-cache', async (req, res) => {
  try {
    console.log('🔄 Admin: Manual cache population triggered');
    
    const result = await schedulerService.refreshAllTickersNews();
    
    res.json({
      success: result.success,
      message: 'Cache population completed',
      result: result,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('❌ Admin: Error during cache population:', error);
    res.status(500).json({
      success: false,
      error: 'Cache population failed',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// GET /api/admin/cache-stats - Get cache statistics
router.get('/cache-stats', async (req, res) => {
  try {
    console.log('📊 Admin: Getting cache statistics');
    
    const stats = await newsCacheService.getCacheStats();
    
    res.json({
      success: true,
      stats: stats,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('❌ Admin: Error getting cache stats:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get cache statistics',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// POST /api/admin/clear-cache - Clear all cache
router.post('/clear-cache', async (req, res) => {
  try {
    console.log('🗑️ Admin: Clearing all cache');
    
    const result = await newsCacheService.clearAllCache();
    
    res.json({
      success: result.success,
      message: 'Cache cleared',
      result: result,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('❌ Admin: Error clearing cache:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to clear cache',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// GET /api/admin/scheduler-status - Get scheduler status
router.get('/scheduler-status', (req, res) => {
  try {
    console.log('⏰ Admin: Getting scheduler status');
    
    const status = schedulerService.getStatus();
    
    res.json({
      success: true,
      status: status,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('❌ Admin: Error getting scheduler status:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get scheduler status',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

module.exports = router; 