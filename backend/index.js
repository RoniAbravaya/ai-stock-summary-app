const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const firebaseService = require('./services/firebaseService');
const yahooFinanceService = require('./services/yahooFinanceService');
const schedulerService = require('./services/schedulerService');

const app = express();

// Middleware
app.use(cors());
app.use(helmet());
app.use(express.json());

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use(limiter);

// Health check endpoint
app.get('/health', (req, res) => {
  const health = {
    status: 'OK',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    services: {
      firebase: firebaseService.isInitialized || false,
      scheduler: schedulerService.isInitialized || false
    }
  };
  res.json(health);
});

// ==========================================
// Server Startup
// ==========================================

const PORT = process.env.PORT || 8080;
const server = app.listen(PORT, '0.0.0.0', async () => {
  console.log(`🚀 AI Stock Summary Backend running on port ${PORT}`);
  console.log(`📊 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🔥 Firebase initialized: ${firebaseService.isInitialized}`);
  console.log(`🌍 Health check: http://0.0.0.0:${PORT}/health`);
  
  // Initialize scheduler service
  try {
    await schedulerService.initialize();
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

module.exports = app;