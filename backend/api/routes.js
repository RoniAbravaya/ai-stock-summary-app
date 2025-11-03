/**
 * API Routes
 * Main router for all API endpoints
 */

const express = require('express');
const router = express.Router();

// Import route modules
const newsRoutes = require('./news');
const stocksRoutes = require('./stocks');
const summaryRoutes = require('./summary');
const healthRoutes = require('./health');
const adminRoutes = require('./admin');
const usersRoutes = require('./users');
const authConfigRoutes = require('./auth-config');

// Use route modules
router.use('/news', newsRoutes);
router.use('/stocks', stocksRoutes);
router.use('/summary', summaryRoutes);
router.use('/health', healthRoutes);
router.use('/admin', adminRoutes);
router.use('/users', usersRoutes);
router.use('/auth-config', authConfigRoutes);

// API root endpoint
router.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'AI Stock Summary API',
    version: '1.0.0',
    endpoints: [
      'GET /api/news - Get general news',
      'GET /api/news/stock/{ticker} - Get news for specific stock',
      'GET /api/stocks - Get available stocks',
      'GET /api/stocks/trending - Get trending stocks',
      'GET /api/stocks/search?q={query} - Search stocks',
      'POST /api/summary/generate - Generate stock summary',
      'GET /api/summary/get/{stockId} - Get existing summary',
      'GET /api/health - API health check',
      'POST /api/admin/populate-cache - Manually populate cache',
      'GET /api/admin/cache-stats - Get cache statistics',
      'GET /api/admin/scheduler-status - Get scheduler status',
      'GET /api/admin/fcm-token-health - Check FCM token health',
      'POST /api/admin/trigger-fcm-refresh - Trigger FCM token refresh',
      'GET /api/users - Get users'
    ],
    timestamp: new Date().toISOString()
  });
});

module.exports = router; 