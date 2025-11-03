/**
 * Authentication Configuration API
 * Provides secure auth configuration for mobile app
 */

const express = require('express');
const router = express.Router();
const { SecretManagerServiceClient } = require('@google-cloud/secret-manager');

// Initialize Secret Manager client
const secretClient = new SecretManagerServiceClient();

/**
 * Get Twitter OAuth configuration
 * This endpoint provides Twitter API Key (public) only
 * The API Secret should NEVER be sent to the client
 */
router.get('/twitter-config', async (req, res) => {
  try {
    const projectId = process.env.GOOGLE_CLOUD_PROJECT || 'new-flutter-ai';
    
    // Fetch Twitter API Key from Secret Manager
    const [apiKeyVersion] = await secretClient.accessSecretVersion({
      name: `projects/${projectId}/secrets/twitter-api-key/versions/latest`,
    });
    
    const apiKey = apiKeyVersion.payload.data.toString('utf8');
    
    // Only send the API Key (public identifier)
    // The API Secret stays on the server
    res.json({
      success: true,
      config: {
        apiKey: apiKey,
        redirectUri: 'new-flutter-ai://',
        // API Secret is intentionally NOT included
      },
      message: 'Twitter configuration retrieved successfully'
    });
    
  } catch (error) {
    console.error('❌ Error fetching Twitter config:', error);
    res.status(500).json({
      success: false,
      error: 'Configuration error',
      message: 'Failed to retrieve Twitter configuration',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

/**
 * Twitter OAuth Server-Side Flow
 * Handle Twitter authentication on the server side for better security
 */
router.post('/twitter-auth', async (req, res) => {
  try {
    // This would implement server-side Twitter OAuth
    // For now, return not implemented
    res.status(501).json({
      success: false,
      message: 'Server-side Twitter authentication not yet implemented',
      note: 'Please use client-side Twitter login with twitter_login package'
    });
    
  } catch (error) {
    console.error('❌ Error in Twitter auth:', error);
    res.status(500).json({
      success: false,
      error: 'Authentication error',
      message: 'Twitter authentication failed'
    });
  }
});

module.exports = router;

