/**
 * Simple Express server for Firebase App Hosting
 */

const express = require('express');
const app = express();

// Root endpoint for App Hosting health checks
app.get('/', (req, res) => {
  res.send('Hello from Firebase App Hosting backend!');
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString()
  });
});

// Server Startup
const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
}); 