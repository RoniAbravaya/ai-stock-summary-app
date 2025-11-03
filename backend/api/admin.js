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
const firebaseService = require('../services/firebaseService');
const { authenticateUser, requireAdmin } = require('../middleware/auth');

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

// GET /api/admin/usage-statistics - Get AI summary usage statistics
router.get('/usage-statistics', authenticateUser, requireAdmin, async (req, res) => {
  try {
    console.log('🔧 GET /api/admin/usage-statistics - Getting usage statistics');
    
    if (!firebaseService.firestore) {
      return res.status(503).json({
        success: false,
        error: 'Firebase Firestore not available',
        timestamp: new Date().toISOString()
      });
    }

    // Get all users
    const usersSnapshot = await firebaseService.firestore
      .collection('users')
      .get();

    const stats = {
      totalUsers: 0,
      usersByType: {
        free: 0,
        premium: 0,
        admin: 0
      },
      summaryUsage: {
        totalGenerated: 0,
        thisMonth: 0,
        byType: {
          free: 0,
          premium: 0,
          admin: 0
        }
      },
      usageLimits: {
        usersAtLimit: 0,
        usersNearLimit: 0,
        averageUsage: 0
      },
      topUsers: []
    };

    const userUsageList = [];
    let totalUsage = 0;

    usersSnapshot.forEach((doc) => {
      const userData = doc.data();
      stats.totalUsers++;

      const subscriptionType = userData.subscriptionType || 'free';
      const summariesUsed = userData.summariesUsed || 0;
      const summariesLimit = userData.summariesLimit || 5;

      // Count by subscription type
      stats.usersByType[subscriptionType] = (stats.usersByType[subscriptionType] || 0) + 1;

      // Track usage
      totalUsage += summariesUsed;
      stats.summaryUsage.byType[subscriptionType] = (stats.summaryUsage.byType[subscriptionType] || 0) + summariesUsed;

      // Check limits
      if (summariesUsed >= summariesLimit) {
        stats.usageLimits.usersAtLimit++;
      } else if (summariesUsed >= summariesLimit * 0.8) {
        stats.usageLimits.usersNearLimit++;
      }

      // Track for top users
      userUsageList.push({
        email: userData.email,
        displayName: userData.displayName,
        used: summariesUsed,
        limit: summariesLimit,
        subscriptionType: subscriptionType
      });
    });

    // Calculate average usage
    stats.usageLimits.averageUsage = stats.totalUsers > 0 ? 
      Number((totalUsage / stats.totalUsers).toFixed(2)) : 0;

    // Get top 10 users by usage
    stats.topUsers = userUsageList
      .sort((a, b) => b.used - a.used)
      .slice(0, 10);

    // Get total generated from usage logs
    const usageLogsSnapshot = await firebaseService.firestore
      .collection('usage_logs')
      .where('action', '==', 'ai_summary_generated')
      .get();

    stats.summaryUsage.totalGenerated = usageLogsSnapshot.size;

    // Get this month's usage
    const now = new Date();
    const firstDayOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    
    const thisMonthSnapshot = await firebaseService.firestore
      .collection('usage_logs')
      .where('action', '==', 'ai_summary_generated')
      .where('timestamp', '>=', firstDayOfMonth)
      .get();

    stats.summaryUsage.thisMonth = thisMonthSnapshot.size;

    console.log(`✅ Usage statistics retrieved: ${stats.totalUsers} users, ${stats.summaryUsage.totalGenerated} total summaries`);
    
    res.json({
      success: true,
      data: stats,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('❌ Error getting usage statistics:', error.message);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// GET /api/admin/user-usage/:userId - Get specific user's usage details
router.get('/user-usage/:userId', authenticateUser, requireAdmin, async (req, res) => {
  try {
    const { userId } = req.params;
    console.log(`🔧 GET /api/admin/user-usage/${userId} - Getting user usage details`);
    
    if (!firebaseService.firestore) {
      return res.status(503).json({
        success: false,
        error: 'Firebase Firestore not available',
        timestamp: new Date().toISOString()
      });
    }

    // Get user document
    const userDoc = await firebaseService.firestore
      .collection('users')
      .doc(userId)
      .get();

    if (!userDoc.exists) {
      return res.status(404).json({
        success: false,
        error: 'User not found',
        timestamp: new Date().toISOString()
      });
    }

    const userData = userDoc.data();

    // Get user's usage logs
    const usageLogsSnapshot = await firebaseService.firestore
      .collection('usage_logs')
      .where('userId', '==', userId)
      .where('action', '==', 'ai_summary_generated')
      .orderBy('timestamp', 'desc')
      .limit(50)
      .get();

    const recentUsage = [];
    usageLogsSnapshot.forEach((doc) => {
      const logData = doc.data();
      recentUsage.push({
        ticker: logData.ticker,
        language: logData.language,
        timestamp: logData.timestamp?.toDate()?.toISOString() || null
      });
    });

    const usageDetails = {
      user: {
        email: userData.email,
        displayName: userData.displayName,
        subscriptionType: userData.subscriptionType || 'free',
        role: userData.role || 'user'
      },
      currentMonth: {
        used: userData.summariesUsed || 0,
        limit: userData.summariesLimit || 5,
        remaining: (userData.summariesLimit || 5) - (userData.summariesUsed || 0),
        lastUsedAt: userData.lastUsedAt?.toDate()?.toISOString() || null,
        lastResetDate: userData.lastResetDate?.toDate()?.toISOString() || null
      },
      history: userData.usageHistory || {},
      recentUsage: recentUsage
    };

    console.log(`✅ User usage details retrieved for ${userData.email}`);
    
    res.json({
      success: true,
      data: usageDetails,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('❌ Error getting user usage details:', error.message);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// GET /api/admin/fcm-token-health - Check FCM token health for all users
router.get('/fcm-token-health', async (req, res) => {
  try {
    console.log('🔧 GET /api/admin/fcm-token-health - Checking FCM token health');
    
    const firebaseService = require('../services/firebaseService');
    
    if (!firebaseService.firestore) {
      return res.status(503).json({
        success: false,
        error: 'Firebase Firestore not available',
        timestamp: new Date().toISOString()
      });
    }

    // Get all users from Firestore
    const usersSnapshot = await firebaseService.firestore
      .collection('users')
      .get();

    const stats = {
      totalUsers: 0,
      usersWithTokens: 0,
      usersWithoutTokens: 0,
      usersWithoutTokensList: [],
      lastTokenUpdates: []
    };

    usersSnapshot.forEach((doc) => {
      const userData = doc.data();
      const userId = doc.id;
      
      stats.totalUsers++;
      
      if (userData.fcmToken && userData.fcmToken.trim() !== '') {
        stats.usersWithTokens++;
        
        // Track recent token updates
        if (userData.fcmTokenUpdatedAt) {
          const updatedAt = userData.fcmTokenUpdatedAt.toDate ? 
            userData.fcmTokenUpdatedAt.toDate() : 
            new Date(userData.fcmTokenUpdatedAt);
          
          stats.lastTokenUpdates.push({
            email: userData.email,
            userId: userId,
            updatedAt: updatedAt.toISOString(),
            tokenPrefix: userData.fcmToken.substring(0, 20) + '...'
          });
        }
      } else {
        stats.usersWithoutTokens++;
        stats.usersWithoutTokensList.push({
          userId: userId,
          email: userData.email,
          displayName: userData.displayName,
          createdAt: userData.createdAt ? 
            (userData.createdAt.toDate ? userData.createdAt.toDate().toISOString() : userData.createdAt) : 
            'Unknown'
        });
      }
    });

    // Sort by most recent token updates
    stats.lastTokenUpdates.sort((a, b) => new Date(b.updatedAt) - new Date(a.updatedAt));
    stats.lastTokenUpdates = stats.lastTokenUpdates.slice(0, 10); // Keep only last 10

    console.log(`✅ FCM token health check complete: ${stats.usersWithTokens}/${stats.totalUsers} users have tokens`);
    
    res.json({
      success: true,
      data: stats,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('❌ Error checking FCM token health:', error.message);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// POST /api/admin/trigger-fcm-refresh - Trigger FCM token refresh for users without tokens
router.post('/trigger-fcm-refresh', async (req, res) => {
  try {
    console.log('🔧 POST /api/admin/trigger-fcm-refresh - Triggering FCM token refresh');
    
    const firebaseService = require('../services/firebaseService');
    
    if (!firebaseService.firestore) {
      return res.status(503).json({
        success: false,
        error: 'Firebase Firestore not available',
        timestamp: new Date().toISOString()
      });
    }

    // Get users without FCM tokens
    const usersSnapshot = await firebaseService.firestore
      .collection('users')
      .where('fcmToken', '==', null)
      .get();

    const usersWithoutTokens = [];
    usersSnapshot.forEach((doc) => {
      const userData = doc.data();
      usersWithoutTokens.push({
        userId: doc.id,
        email: userData.email,
        displayName: userData.displayName
      });
    });

    // Also check for users with empty string tokens
    const usersWithEmptyTokensSnapshot = await firebaseService.firestore
      .collection('users')
      .where('fcmToken', '==', '')
      .get();

    usersWithEmptyTokensSnapshot.forEach((doc) => {
      const userData = doc.data();
      usersWithoutTokens.push({
        userId: doc.id,
        email: userData.email,
        displayName: userData.displayName
      });
    });

    if (usersWithoutTokens.length === 0) {
      return res.json({
        success: true,
        message: 'All users already have FCM tokens',
        data: {
          usersProcessed: 0,
          usersWithoutTokens: []
        },
        timestamp: new Date().toISOString()
      });
    }

    // Create admin notification to trigger FCM token refresh for these users
    const refreshNotification = {
      title: 'FCM Token Refresh Required',
      message: 'Please restart the app to enable push notifications',
      target: 'specific_users_bulk',
      targetUserIds: usersWithoutTokens.map(u => u.userId),
      sentBy: 'admin_system',
      sentAt: new Date(),
      processed: false,
      processing: false,
      isTokenRefreshTrigger: true // Special flag to identify this type of notification
    };

    // Store the refresh trigger notification
    const notificationRef = await firebaseService.firestore
      .collection('admin_notifications')
      .add(refreshNotification);

    console.log(`✅ FCM token refresh triggered for ${usersWithoutTokens.length} users`);
    
    res.json({
      success: true,
      message: `FCM token refresh triggered for ${usersWithoutTokens.length} users`,
      data: {
        notificationId: notificationRef.id,
        usersProcessed: usersWithoutTokens.length,
        usersWithoutTokens: usersWithoutTokens.slice(0, 10) // Return first 10 for reference
      },
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('❌ Error triggering FCM token refresh:', error.message);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

module.exports = router; 