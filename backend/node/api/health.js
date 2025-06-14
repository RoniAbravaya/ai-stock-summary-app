/**
 * Health API Routes
 * API health check endpoints
 */

const express = require('express');
const router = express.Router();
const firebaseService = require('../services/firebaseService');
const yahooFinanceService = require('../services/yahooFinanceService');
const schedulerService = require('../services/schedulerService');
const newsCacheService = require('../services/newsCacheService');

// GET /api/health - API health check
router.get('/', (req, res) => {
  const health = {
    status: 'OK',
    api: {
      version: '1.0.0',
      environment: process.env.NODE_ENV || 'development',
      uptime: process.uptime(),
      timestamp: new Date().toISOString()
    },
    services: {
      firebase: {
        initialized: firebaseService.isInitialized || false,
        status: firebaseService.isInitialized ? 'healthy' : 'unavailable'
      },
      scheduler: {
        initialized: schedulerService.isInitialized || false,
        status: schedulerService.isInitialized ? 'healthy' : 'unavailable'
      },
      yahooFinance: {
        configured: yahooFinanceService.isConfigured || false,
        status: yahooFinanceService.isConfigured ? 'healthy' : 'unavailable'
      },
      newsCache: {
        available: true,
        supportedTickers: newsCacheService.getSupportedTickers().length
      }
    },
    config: {
      enableScheduler: process.env.ENABLE_SCHEDULER === 'true',
      enableCaching: process.env.ENABLE_CACHING === 'true',
      enableMockData: process.env.ENABLE_MOCK_DATA === 'true'
    },
    endpoints: {
      news: [
        'GET /api/news',
        'GET /api/news/stock/:ticker'
      ],
      stocks: [
        'GET /api/stocks',
        'GET /api/stocks/trending',
        'GET /api/stocks/search',
        'GET /api/stocks/:id'
      ],
      summary: [
        'POST /api/summary/generate',
        'GET /api/summary/get/:stockId'
      ]
    }
  };
  
  res.json(health);
});

module.exports = router; 