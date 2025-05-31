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

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet());

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.'
});
app.use('/api/', limiter);

// CORS configuration
app.use(cors({
  origin: ['http://localhost:3000', 'http://localhost:8080', 'capacitor://localhost', 'ionic://localhost', 'http://localhost', 'http://localhost:8100'],
  credentials: true
}));

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
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development',
    firebase: firebaseService.isInitialized
  });
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

// ==========================================
// Server Startup
// ==========================================

app.listen(PORT, () => {
  console.log(`🚀 AI Stock Summary Backend running on port ${PORT}`);
  console.log(`📊 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🔥 Firebase initialized: ${firebaseService.isInitialized}`);
  console.log(`🌍 Health check: http://localhost:${PORT}/health`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('🔄 SIGTERM received, shutting down gracefully...');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('🔄 SIGINT received, shutting down gracefully...');
  process.exit(0);
});

module.exports = app; 