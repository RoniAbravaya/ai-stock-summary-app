/**
 * Users API Routes
 * Handles user-related endpoints including favorites
 */

const express = require('express');
const router = express.Router();
const firebaseService = require('../services/firebaseService');
const stockCacheService = require('../services/stockCacheService');

/**
 * Middleware to validate user ID
 */
function validateUserId(req, res, next) {
  const uid = req.params.uid;
  if (!uid || uid.length < 3) {
    return res.status(400).json({
      success: false,
      error: 'Invalid user ID',
      timestamp: new Date().toISOString()
    });
  }
  next();
}

/**
 * GET /api/users/:uid/favorites - Get user's favorite stocks
 */
router.get('/:uid/favorites', validateUserId, async (req, res) => {
  try {
    const uid = req.params.uid;
    console.log(`👤 GET /api/users/${uid}/favorites - Getting user favorites`);

    if (!firebaseService.database) {
      return res.status(503).json({
        success: false,
        error: 'Firebase database not available',
        timestamp: new Date().toISOString()
      });
    }

    // Get user's favorite tickers from Firebase
    const snapshot = await firebaseService.database
      .ref(`users/${uid}/favorites`)
      .once('value');
    
    const favoritesData = snapshot.val() || {};
    const favoriteTickers = Object.keys(favoritesData);

    if (favoriteTickers.length === 0) {
      console.log(`✅ User ${uid} has no favorites`);
      return res.json({
        success: true,
        data: [],
        totalFavorites: 0,
        uid: uid,
        timestamp: new Date().toISOString()
      });
    }

    // Get stock data for each favorite ticker
    console.log(`📊 Fetching data for ${favoriteTickers.length} favorite stocks`);
    const stockDataPromises = favoriteTickers.map(ticker => 
      stockCacheService.getStockData(ticker)
    );
    
    const stockResults = await Promise.all(stockDataPromises);
    
    // Combine stock data with favorite metadata
    const favorites = stockResults
      .filter(result => result.success)
      .map(result => ({
        ...result.data,
        addedAt: favoritesData[result.data.symbol]?.addedAt || Date.now(),
        source: result.source
      }))
      .sort((a, b) => b.addedAt - a.addedAt); // Sort by most recently added

    console.log(`✅ Successfully returned ${favorites.length} favorites for user ${uid}`);
    res.json({
      success: true,
      data: favorites,
      totalFavorites: favorites.length,
      uid: uid,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error(`❌ Error getting favorites for user ${req.params.uid}:`, error.message);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message,
      uid: req.params.uid,
      timestamp: new Date().toISOString()
    });
  }
});

/**
 * POST /api/users/:uid/favorites - Add a stock to user's favorites
 */
router.post('/:uid/favorites', validateUserId, async (req, res) => {
  try {
    const uid = req.params.uid;
    const { ticker } = req.body;

    console.log(`👤 POST /api/users/${uid}/favorites - Adding ${ticker} to favorites`);

    if (!ticker || typeof ticker !== 'string') {
      return res.status(400).json({
        success: false,
        error: 'Ticker symbol is required',
        timestamp: new Date().toISOString()
      });
    }

    // Reject ticker symbols containing characters that are invalid for Firebase keys
    if (!/^[A-Za-z]+$/.test(ticker)) {
      return res.status(400).json({
        success: false,
        error: 'Ticker symbol contains invalid characters',
        timestamp: new Date().toISOString()
      });
    }

    const normalizedTicker = ticker.toUpperCase();

    if (!firebaseService.database) {
      return res.status(503).json({
        success: false,
        error: 'Firebase database not available',
        timestamp: new Date().toISOString()
      });
    }

    // Check if ticker is already in favorites
    const existingSnapshot = await firebaseService.database
      .ref(`users/${uid}/favorites/${normalizedTicker}`)
      .once('value');

    if (existingSnapshot.exists()) {
      return res.status(409).json({
        success: false,
        error: `${normalizedTicker} is already in favorites`,
        ticker: normalizedTicker,
        uid: uid,
        timestamp: new Date().toISOString()
      });
    }

    // Verify the ticker exists by trying to get its data
    const stockResult = await stockCacheService.getStockData(normalizedTicker);
    if (!stockResult.success) {
      return res.status(404).json({
        success: false,
        error: `Stock ${normalizedTicker} not found or unavailable`,
        ticker: normalizedTicker,
        uid: uid,
        timestamp: new Date().toISOString()
      });
    }

    // Add to favorites
    const favoriteData = {
      addedAt: Date.now(),
      ticker: normalizedTicker
    };

    await firebaseService.database
      .ref(`users/${uid}/favorites/${normalizedTicker}`)
      .set(favoriteData);

    console.log(`✅ Successfully added ${normalizedTicker} to favorites for user ${uid}`);
    res.status(201).json({
      success: true,
      message: `${normalizedTicker} added to favorites`,
      data: {
        ticker: normalizedTicker,
        addedAt: favoriteData.addedAt,
        stockData: stockResult.data
      },
      uid: uid,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error(`❌ Error adding favorite for user ${req.params.uid}:`, error.message);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message,
      uid: req.params.uid,
      timestamp: new Date().toISOString()
    });
  }
});

/**
 * DELETE /api/users/:uid/favorites/:ticker - Remove a stock from user's favorites
 */
router.delete('/:uid/favorites/:ticker', validateUserId, async (req, res) => {
  try {
    const uid = req.params.uid;
    const ticker = req.params.ticker.toUpperCase();

    console.log(`👤 DELETE /api/users/${uid}/favorites/${ticker} - Removing from favorites`);

    if (!firebaseService.database) {
      return res.status(503).json({
        success: false,
        error: 'Firebase database not available',
        timestamp: new Date().toISOString()
      });
    }

    // Check if ticker exists in favorites
    const snapshot = await firebaseService.database
      .ref(`users/${uid}/favorites/${ticker}`)
      .once('value');

    if (!snapshot.exists()) {
      return res.status(404).json({
        success: false,
        error: `${ticker} is not in favorites`,
        ticker: ticker,
        uid: uid,
        timestamp: new Date().toISOString()
      });
    }

    // Remove from favorites
    await firebaseService.database
      .ref(`users/${uid}/favorites/${ticker}`)
      .remove();

    console.log(`✅ Successfully removed ${ticker} from favorites for user ${uid}`);
    res.json({
      success: true,
      message: `${ticker} removed from favorites`,
      ticker: ticker,
      uid: uid,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error(`❌ Error removing favorite for user ${req.params.uid}:`, error.message);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message,
      uid: req.params.uid,
      ticker: req.params.ticker,
      timestamp: new Date().toISOString()
    });
  }
});

/**
 * GET /api/users/:uid/favorites/count - Get count of user's favorites
 */
router.get('/:uid/favorites/count', validateUserId, async (req, res) => {
  try {
    const uid = req.params.uid;
    console.log(`👤 GET /api/users/${uid}/favorites/count - Getting favorites count`);

    if (!firebaseService.database) {
      return res.status(503).json({
        success: false,
        error: 'Firebase database not available',
        timestamp: new Date().toISOString()
      });
    }

    const snapshot = await firebaseService.database
      .ref(`users/${uid}/favorites`)
      .once('value');
    
    const favoritesData = snapshot.val() || {};
    const count = Object.keys(favoritesData).length;

    console.log(`✅ User ${uid} has ${count} favorites`);
    res.json({
      success: true,
      count: count,
      uid: uid,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error(`❌ Error getting favorites count for user ${req.params.uid}:`, error.message);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message,
      uid: req.params.uid,
      timestamp: new Date().toISOString()
    });
  }
});

module.exports = router; 