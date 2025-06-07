// ... existing code ...

// ==========================================
// Server Startup
// ==========================================

const PORT = process.env.PORT || 3000;
const server = app.listen(PORT, async () => {
  console.log(`🚀 AI Stock Summary Backend running on port ${PORT}`);
  console.log(`📊 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🔥 Firebase initialized: ${firebaseService.isInitialized}`);
  console.log(`🌍 Health check: http://localhost:${PORT}/health`);
  
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

module.exports = app;