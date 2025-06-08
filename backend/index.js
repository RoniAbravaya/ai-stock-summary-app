<<<<<<< HEAD
/**
 * AI Stock Summary Backend
 * Main entry point for the Express API server
 */

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');

// Import services
const firebaseService = require('./services/firebaseService');
const mockData = require('./services/mockData');
const yahooFinanceService = require('./services/yahooFinanceService');
const newsCacheService = require('./services/newsCacheService');
const schedulerService = require('./services/schedulerService');

const app = express();

// Middleware
app.use(cors());
app.use(helmet());
app.use(express.json());

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.'
});
app.use('/api/', limiter);

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Request logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
  next();
});

// Firebase Auth middleware
const verifyFirebaseToken = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Unauthorized: No token provided' });
    }

    const idToken = authHeader.split('Bearer ')[1];
    const decodedToken = await firebaseService.verifyIdToken(idToken);
    req.user = decodedToken;
    next();
  } catch (error) {
    console.error('Error verifying Firebase token:', error);
    return res.status(401).json({ error: 'Unauthorized: Invalid token' });
  }
};

// Admin middleware
const requireAdmin = (req, res, next) => {
  if (!req.user || !req.user.admin) {
    return res.status(403).json({ error: 'Forbidden: Admin access required' });
  }
  next();
};

// Health check endpoint
app.get('/health', async (req, res) => {
  try {
    // Check Firebase connection
    const firebaseStatus = firebaseService.isInitialized;
    
    // Basic service health check
    const health = {
      status: 'ok',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      services: {
        firebase: firebaseStatus ? 'connected' : 'disconnected',
        server: 'running'
      }
    };

    // Return 200 if everything is OK, otherwise 503
    const httpStatus = (firebaseStatus) ? 200 : 503;
    res.status(httpStatus).json(health);
  } catch (error) {
    res.status(503).json({
      status: 'error',
      timestamp: new Date().toISOString(),
      error: error.message
    });
  }
});

// ==========================================
// Public API Routes (No Authentication)
// ==========================================

// Get all stocks (mock data)
app.get('/api/stocks', async (req, res) => {
  try {
    const stocks = mockData.getAllStocks();
    res.json({ success: true, data: stocks });
  } catch (error) {
    console.error('Error fetching stocks:', error);
    res.status(500).json({ error: 'Failed to fetch stocks' });
  }
});

// Get trending stocks
app.get('/api/stocks/trending', async (req, res) => {
  try {
    const trendingStocks = mockData.getTrendingStocks();
    res.json({ success: true, data: trendingStocks });
  } catch (error) {
    console.error('Error fetching trending stocks:', error);
    res.status(500).json({ error: 'Failed to fetch trending stocks' });
  }
});

// Get stock by ID
app.get('/api/stocks/:id', async (req, res) => {
  try {
    const stock = mockData.getStockById(req.params.id);
    if (!stock) {
      return res.status(404).json({ error: 'Stock not found' });
    }
    res.json({ success: true, data: stock });
  } catch (error) {
    console.error('Error fetching stock:', error);
    res.status(500).json({ error: 'Failed to fetch stock' });
  }
});

// Get all news
app.get('/api/news', async (req, res) => {
  try {
    const news = mockData.getAllNews();
    res.json({ success: true, data: news });
  } catch (error) {
    console.error('Error fetching news:', error);
    res.status(500).json({ error: 'Failed to fetch news' });
  }
});

// Get news for specific stock
app.get('/api/news/stock/:stockId', async (req, res) => {
  try {
    const news = mockData.getNewsByStock(req.params.stockId);
    res.json({ success: true, data: news });
  } catch (error) {
    console.error('Error fetching stock news:', error);
    res.status(500).json({ error: 'Failed to fetch stock news' });
  }
});

// ==========================================
// Yahoo Finance News API Routes
// ==========================================

// Get cached news for multiple tickers
app.get('/api/yahoo-news', async (req, res) => {
  try {
    const { tickers } = req.query;
    
    if (!tickers) {
      return res.status(400).json({ 
        error: 'Missing required parameter: tickers',
        example: '/api/yahoo-news?tickers=AAPL,GOOGL,TSLA or /api/yahoo-news?tickers=ALL'
      });
    }

    let tickerArray;
    const supportedTickers = newsCacheService.getSupportedTickers();

    // Handle special case: tickers=ALL
    if (tickers.trim().toUpperCase() === 'ALL') {
      tickerArray = supportedTickers;
      console.log(`📊 Fetching news for ALL tickers: ${tickerArray.length} tickers`);
    } else {
      // Parse tickers from comma-separated string
      tickerArray = tickers.split(',').map(t => t.trim().toUpperCase());
      
      // Validate tickers
      const invalidTickers = tickerArray.filter(t => !supportedTickers.includes(t));
      
      if (invalidTickers.length > 0) {
        return res.status(400).json({
          error: 'Invalid tickers provided',
          invalidTickers: invalidTickers,
          supportedTickers: supportedTickers
        });
      }
    }

    // Get cached news
    const result = await newsCacheService.getNewsForTickers(tickerArray);
    
    if (result.success) {
      res.json(result);
    } else {
      res.status(500).json({ error: result.error });
    }
  } catch (error) {
    console.error('Error fetching Yahoo Finance news:', error);
    res.status(500).json({ error: 'Failed to fetch news' });
  }
});

// Get cache statistics
app.get('/api/yahoo-news/stats', async (req, res) => {
  try {
    const stats = await newsCacheService.getCacheStats();
    res.json(stats);
  } catch (error) {
    console.error('Error fetching cache stats:', error);
    res.status(500).json({ error: 'Failed to fetch cache statistics' });
  }
});

// Get supported tickers
app.get('/api/yahoo-news/tickers', (req, res) => {
  try {
    const tickers = newsCacheService.getSupportedTickers();
    res.json({ 
      success: true, 
      tickers: tickers,
      total: tickers.length 
    });
  } catch (error) {
    console.error('Error fetching supported tickers:', error);
    res.status(500).json({ error: 'Failed to fetch supported tickers' });
  }
});

// ==========================================
// Protected API Routes (Require Authentication)
// ==========================================

// Get user profile
app.get('/api/user/profile', verifyFirebaseToken, async (req, res) => {
  try {
    const userDoc = await firebaseService.firestore
      .collection('users')
      .doc(req.user.uid)
      .get();

    if (!userDoc.exists) {
      return res.status(404).json({ error: 'User profile not found' });
    }

    res.json({ success: true, data: userDoc.data() });
  } catch (error) {
    console.error('Error fetching user profile:', error);
    res.status(500).json({ error: 'Failed to fetch user profile' });
  }
});

// Generate AI summary for a stock (mock implementation)
app.post('/api/summary/generate', verifyFirebaseToken, async (req, res) => {
  try {
    const { stockId } = req.body;
    
    if (!stockId) {
      return res.status(400).json({ error: 'Stock ID is required' });
    }

    // Check user's remaining summaries
    const userDoc = await firebaseService.firestore
      .collection('users')
      .doc(req.user.uid)
      .get();

    if (!userDoc.exists) {
      return res.status(404).json({ error: 'User not found' });
    }

    const userData = userDoc.data();
    if (userData.summariesUsed >= userData.summariesLimit) {
      return res.status(403).json({ 
        error: 'Summary limit reached',
        message: 'You have reached your monthly summary limit. Watch a rewarded ad or upgrade to premium.'
      });
    }

    // Generate mock summary
    const summary = mockData.generateAISummary(stockId);
    
    // Save summary to Firestore
    await firebaseService.firestore
      .collection('summaries')
      .doc(stockId)
      .set({
        ...summary,
        userId: req.user.uid,
        createdAt: new Date().toISOString()
      });

    // Update user's summary usage
    await firebaseService.firestore
      .collection('users')
      .doc(req.user.uid)
      .update({
        summariesUsed: userData.summariesUsed + 1
      });

    res.json({ success: true, data: summary });
  } catch (error) {
    console.error('Error generating summary:', error);
    res.status(500).json({ error: 'Failed to generate summary' });
  }
});

// Get summary for a stock
app.get('/api/summary/:stockId', verifyFirebaseToken, async (req, res) => {
  try {
    const summaryDoc = await firebaseService.firestore
      .collection('summaries')
      .doc(req.params.stockId)
      .get();

    if (!summaryDoc.exists) {
      return res.status(404).json({ error: 'Summary not found' });
    }

    res.json({ success: true, data: summaryDoc.data() });
  } catch (error) {
    console.error('Error fetching summary:', error);
    res.status(500).json({ error: 'Failed to fetch summary' });
  }
});

// Add reward for watching ad
app.post('/api/user/reward-ad', verifyFirebaseToken, async (req, res) => {
  try {
    const userDoc = await firebaseService.firestore
      .collection('users')
      .doc(req.user.uid)
      .get();

    if (!userDoc.exists) {
      return res.status(404).json({ error: 'User not found' });
    }

    const userData = userDoc.data();
    
    // Award one additional summary
    await firebaseService.firestore
      .collection('users')
      .doc(req.user.uid)
      .update({
        summariesLimit: userData.summariesLimit + 1,
        lastAdReward: new Date().toISOString()
      });

    res.json({ 
      success: true, 
      message: 'Reward added successfully',
      newLimit: userData.summariesLimit + 1
    });
  } catch (error) {
    console.error('Error adding reward:', error);
    res.status(500).json({ error: 'Failed to add reward' });
  }
});

// ==========================================
// Admin API Routes (Require Admin Access)
// ==========================================

// Grant admin role to user
app.post('/api/admin/grant-admin', verifyFirebaseToken, requireAdmin, async (req, res) => {
  try {
    const { userId } = req.body;
    
    if (!userId) {
      return res.status(400).json({ error: 'User ID is required' });
    }

    // Set custom claims
    await firebaseService.setCustomClaims(userId, { admin: true });

    // Update user document
    await firebaseService.firestore
      .collection('users')
      .doc(userId)
      .update({
        role: 'admin',
        updatedAt: new Date().toISOString()
      });

    res.json({ success: true, message: 'Admin role granted successfully' });
  } catch (error) {
    console.error('Error granting admin role:', error);
    res.status(500).json({ error: 'Failed to grant admin role' });
  }
});

// Send push notification to all users
app.post('/api/admin/send-notification', verifyFirebaseToken, requireAdmin, async (req, res) => {
  try {
    const { title, body, data } = req.body;

    if (!title || !body) {
      return res.status(400).json({ error: 'Title and body are required' });
    }

    // Get all FCM tokens
    const tokensSnapshot = await firebaseService.firestore
      .collection('fcmTokens')
      .get();

    const tokens = tokensSnapshot.docs.map(doc => doc.data().token);

    if (tokens.length === 0) {
      return res.status(404).json({ error: 'No FCM tokens found' });
    }

    // Send multicast notification
    const response = await firebaseService.sendMulticastNotification(tokens, {
      title,
      body,
      data: data || {}
    });

    res.json({ 
      success: true, 
      message: 'Notification sent successfully',
      results: response
    });
  } catch (error) {
    console.error('Error sending notification:', error);
    res.status(500).json({ error: 'Failed to send notification' });
  }
});

// Manual refresh news for specific ticker
app.post('/api/admin/refresh-news/:ticker', verifyFirebaseToken, requireAdmin, async (req, res) => {
  try {
    const { ticker } = req.params;
    
    if (!ticker) {
      return res.status(400).json({ error: 'Ticker parameter is required' });
    }

    console.log(`🔧 Admin triggered manual refresh for ticker: ${ticker}`);
    
    const result = await schedulerService.refreshTickerNews(ticker.toUpperCase());
    
    if (result.success) {
      res.json({ 
        success: true, 
        message: `News refresh completed for ${ticker}`,
        result: result
      });
    } else {
      res.status(500).json({ 
        error: result.error,
        result: result 
      });
    }
  } catch (error) {
    console.error('Error in manual ticker refresh:', error);
    res.status(500).json({ error: 'Failed to refresh ticker news' });
  }
});

// Manual refresh news for all tickers
app.post('/api/admin/refresh-news/all', verifyFirebaseToken, requireAdmin, async (req, res) => {
  try {
    console.log('🔧 Admin triggered manual refresh for all tickers');
    
    const result = await schedulerService.refreshAllTickersNews();
    
    if (result.success) {
      res.json({ 
        success: true, 
        message: 'News refresh completed for all tickers',
        result: result
      });
    } else {
      res.status(500).json({ 
        error: result.error || 'Refresh failed',
        result: result 
      });
    }
  } catch (error) {
    console.error('Error in manual all tickers refresh:', error);
    res.status(500).json({ error: 'Failed to refresh all ticker news' });
  }
});

// Get scheduler status
app.get('/api/admin/scheduler/status', verifyFirebaseToken, requireAdmin, (req, res) => {
  try {
    const status = schedulerService.getStatus();
    res.json({ success: true, status: status });
  } catch (error) {
    console.error('Error fetching scheduler status:', error);
    res.status(500).json({ error: 'Failed to fetch scheduler status' });
  }
});

// ==========================================
// Error Handling
// ==========================================

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

// Global error handler
app.use((error, req, res, next) => {
  console.error('Global error handler:', error);
  res.status(500).json({ 
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? error.message : 'Something went wrong'
  });
});
=======
// ... existing code ...
>>>>>>> 9086ac07f16d0c3d26eadb9e7df4bec407f515e0

// ==========================================
// Server Startup
// ==========================================

<<<<<<< HEAD
const PORT = process.env.PORT || 8080; // Default to 8080 for App Hosting
const server = app.listen(PORT, '0.0.0.0', async () => { // Listen on all network interfaces
  console.log(`🚀 Server is running on port ${PORT}`);
  console.log(`📊 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🔥 Firebase initialized: ${firebaseService.isInitialized}`);
  console.log(`🌍 Health check: http://0.0.0.0:${PORT}/health`);
=======
const PORT = process.env.PORT || 3000;
const server = app.listen(PORT, async () => {
  console.log(`🚀 AI Stock Summary Backend running on port ${PORT}`);
  console.log(`📊 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🔥 Firebase initialized: ${firebaseService.isInitialized}`);
  console.log(`🌍 Health check: http://localhost:${PORT}/health`);
>>>>>>> 9086ac07f16d0c3d26eadb9e7df4bec407f515e0
  
  // Initialize scheduler service
  try {
    schedulerService.initialize();
    console.log(`⏰ Scheduler service initialized`);
  } catch (error) {
    console.error('❌ Failed to initialize scheduler service:', error.message);
  }
  
  // Test Yahoo Finance API connection (optional)
  if (process.env.NODE_ENV !== 'production') {
    try {
      const isConnected = await yahooFinanceService.testConnection();
      console.log(`📡 Yahoo Finance API: ${isConnected ? '✅ Connected' : '❌ Failed'}`);
    } catch (error) {
      console.warn('⚠️ Yahoo Finance API test failed:', error.message);
    }
  }
});

// Graceful shutdown
const shutdown = () => {
  console.log('🔄 Received shutdown signal, closing server...');
  server.close(() => {
    console.log('✅ Server closed');
    process.exit(0);
  });

  // Force close after 10s
  setTimeout(() => {
    console.error('⚠️ Could not close connections in time, forcefully shutting down');
    process.exit(1);
  }, 10000);
};

process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);

<<<<<<< HEAD
// Export for testing
module.exports = { app, server }; 
=======
module.exports = app;
>>>>>>> 9086ac07f16d0c3d26eadb9e7df4bec407f515e0
