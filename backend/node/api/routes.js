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

// Use route modules
router.use('/news', newsRoutes);
router.use('/stocks', stocksRoutes);
router.use('/summary', summaryRoutes);
router.use('/health', healthRoutes);

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
      'GET /api/health - API health check'
    ],
    timestamp: new Date().toISOString()
  });
});

module.exports = router; 