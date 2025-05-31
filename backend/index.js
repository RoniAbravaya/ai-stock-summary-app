/**
 * AI Stock Summary Backend
 * Main entry point for the Express API server
 */

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');

// Import route modules (to be created)
// const authRoutes = require('./api/auth');
// const summaryRoutes = require('./api/summary');
// const pushRoutes = require('./api/push');
// const userRoutes = require('./api/user');

// Import services
// const firebaseService = require('./services/firebaseService');
// const aiService = require('./services/aiService');

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet());

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use('/api/', limiter);

// CORS configuration
app.use(cors({
  origin: process.env.NODE_ENV === 'production' 
    ? ['your-production-domains.com'] 
    : true,
  credentials: true
}));

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    version: process.env.APP_VERSION || '1.0.0',
    environment: process.env.NODE_ENV || 'development'
  });
});

// Mock data endpoints (for testing)
if (process.env.ENABLE_MOCK_DATA === 'true') {
  app.get('/api/mock/stocks', (req, res) => {
    const mockStocks = require('./services/mockData').getMockStocks();
    res.json(mockStocks);
  });

  app.get('/api/mock/news', (req, res) => {
    const mockNews = require('./services/mockData').getMockNews();
    res.json(mockNews);
  });

  app.get('/api/mock/summary/:stockId', (req, res) => {
    const mockSummary = require('./services/mockData').getMockSummary(req.params.stockId);
    res.json(mockSummary);
  });
}

// API Routes (placeholder endpoints)
app.use('/api/auth', (req, res, next) => {
  res.status(501).json({ message: 'Auth endpoints coming soon', endpoint: req.path });
});

app.use('/api/summary', (req, res, next) => {
  res.status(501).json({ message: 'Summary endpoints coming soon', endpoint: req.path });
});

app.use('/api/push', (req, res, next) => {
  res.status(501).json({ message: 'Push notification endpoints coming soon', endpoint: req.path });
});

app.use('/api/user', (req, res, next) => {
  res.status(501).json({ message: 'User management endpoints coming soon', endpoint: req.path });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Endpoint not found',
    path: req.originalUrl,
    method: req.method
  });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error('Global error handler:', err);
  
  const statusCode = err.statusCode || 500;
  const message = process.env.NODE_ENV === 'production' 
    ? 'Internal server error' 
    : err.message;

  res.status(statusCode).json({
    error: message,
    ...(process.env.NODE_ENV !== 'production' && { stack: err.stack })
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 AI Stock Summary Backend running on port ${PORT}`);
  console.log(`📊 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🔧 Mock data enabled: ${process.env.ENABLE_MOCK_DATA === 'true'}`);
  console.log(`📱 Health check: http://localhost:${PORT}/health`);
});

module.exports = app; 