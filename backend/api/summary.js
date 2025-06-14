/**
 * Summary API Routes
 * Handles AI summary-related endpoints
 */

const express = require('express');
const router = express.Router();
const mockData = require('../services/mockData');

// POST /api/summary/generate - Generate new summary
router.post('/generate', async (req, res) => {
  try {
    const { stockId, language = 'en' } = req.body;
    console.log(`🤖 POST /api/summary/generate - Generating summary for ${stockId} in ${language}`);
    
    if (!stockId) {
      return res.status(400).json({
        success: false,
        error: 'stockId is required',
        timestamp: new Date().toISOString()
      });
    }
    
    // Check if mock data is enabled
    if (process.env.ENABLE_MOCK_DATA === 'true') {
      console.log('🎭 Mock data enabled, returning mock summary');
      const mockSummary = mockData.generateAISummary(stockId);
      return res.json({
        success: true,
        data: mockSummary,
        stockId: stockId,
        language: language,
        source: 'mock',
        timestamp: new Date().toISOString()
      });
    }
    
    // For now, return placeholder response
    res.status(501).json({
      success: false,
      error: 'Summary generation not yet implemented',
      message: 'AI summary generation is not yet available',
      stockId: stockId,
      language: language,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('❌ Error in POST /api/summary/generate:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// GET /api/summary/get/:stockId - Get existing summary
router.get('/get/:stockId', async (req, res) => {
  try {
    const stockId = req.params.stockId.toUpperCase();
    console.log(`🤖 GET /api/summary/get/${stockId} - Fetching existing summary`);
    
    // Check if mock data is enabled
    if (process.env.ENABLE_MOCK_DATA === 'true') {
      console.log('🎭 Mock data enabled, returning mock summary');
      const mockSummary = mockData.generateAISummary(stockId);
      return res.json({
        success: true,
        data: mockSummary,
        stockId: stockId,
        source: 'mock',
        timestamp: new Date().toISOString()
      });
    }
    
    // For now, return placeholder response
    res.status(404).json({
      success: false,
      error: 'Summary not found',
      message: 'No summary available for this stock',
      stockId: stockId,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error(`❌ Error in GET /api/summary/get/${req.params.stockId}:`, error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message,
      stockId: req.params.stockId,
      timestamp: new Date().toISOString()
    });
  }
});

// POST /api/summary/translate - Translate summary
router.post('/translate', async (req, res) => {
  try {
    const { summaryId, targetLanguage } = req.body;
    console.log(`🌐 POST /api/summary/translate - Translating summary ${summaryId} to ${targetLanguage}`);
    
    if (!summaryId || !targetLanguage) {
      return res.status(400).json({
        success: false,
        error: 'summaryId and targetLanguage are required',
        timestamp: new Date().toISOString()
      });
    }
    
    // For now, return placeholder response
    res.status(501).json({
      success: false,
      error: 'Translation not yet implemented',
      message: 'Summary translation is not yet available',
      summaryId: summaryId,
      targetLanguage: targetLanguage,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('❌ Error in POST /api/summary/translate:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// GET /api/summary/user - Get user's summaries
router.get('/user', async (req, res) => {
  try {
    console.log('🤖 GET /api/summary/user - Fetching user summaries');
    
    // For now, return empty array
    res.json({
      success: true,
      data: [],
      message: 'User summaries feature not yet implemented',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('❌ Error in GET /api/summary/user:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

module.exports = router; 