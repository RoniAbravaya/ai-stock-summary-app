/**
 * Main Server Entry Point
 */

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const dotenv = require('dotenv');
const firebaseService = require('./services/firebaseService');
const yahooFinanceService = require('./services/yahooFinanceService');
const schedulerService = require('./services/schedulerService');
const newsCacheService = require('./services/newsCacheService');
const mockData = require('./services/mockData');

// Load environment variables based on NODE_ENV
if (process.env.NODE_ENV !== 'production') {
  dotenv.config();
}

const app = express();

// Middleware
app.use(cors());
app.use(helmet());
app.use(express.json());

// Rate limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // default: 15 minutes
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100 // default: 100 requests per windowMs
});
app.use(limiter);

// Root endpoint for App Hosting health checks
app.get('/', (req, res) => {
  res.send('Hello from Firebase App Hosting backend!');
});

// Health check endpoint
app.get('/health', (req, res) => {
  const health = {
    status: 'OK',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV,
    services: {
      firebase: firebaseService.isInitialized || false,
      scheduler: schedulerService.isInitialized || false,
      yahooFinance: yahooFinanceService.isConfigured || false
    },
    config: {
      enableScheduler: process.env.ENABLE_SCHEDULER === 'true',
      enableCaching: process.env.ENABLE_CACHING === 'true',
      enableMockData: process.env.ENABLE_MOCK_DATA === 'true'
    }
  };
  res.json(health);
});

// API Routes
app.use('/api', require('./api/routes'));

// Error handling middleware
app.use((error, req, res, next) => {
  console.error('❌ API Error:', error);
  res.status(500).json({
    success: false,
    error: 'Internal server error',
    message: error.message,
    timestamp: new Date().toISOString()
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    error: 'Endpoint not found',
    path: req.originalUrl,
    timestamp: new Date().toISOString()
  });
});

// Server Startup
const PORT = process.env.PORT || 8080; // Default to 8080 for App Hosting
console.log(`Starting server on port ${PORT}`);
console.log(`Environment: ${process.env.NODE_ENV}`);
console.log(`Log Level: ${process.env.LOG_LEVEL}`);

const server = app.listen(PORT, () => { // Remove '0.0.0.0' to let the platform decide
  console.log(`🚀 AI Stock Summary Backend running on port ${PORT}`);
  console.log(`📊 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🔥 Firebase initialized: ${firebaseService.isInitialized}`);
  console.log(`🌍 Health check: /health`);
  console.log(`📡 API routes: /api/*`);
  
  // Initialize scheduler service if enabled
  if (process.env.ENABLE_SCHEDULER === 'true') {
    try {
      schedulerService.initialize();
      console.log(`⏰ Scheduler service initialized`);
    } catch (error) {
      console.error('❌ Failed to initialize scheduler service:', error.message);
    }
  } else {
    console.log('⏰ Scheduler service disabled');
  }
}).on('error', (err) => {
  console.error('❌ Failed to start server:', err.message);
  process.exit(1);
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

module.exports = app;