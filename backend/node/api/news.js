/**
 * News API Routes
 * Handles news-related endpoints
 */

const express = require('express');
const router = express.Router();
const newsCacheService = require('../services/newsCacheService');
const yahooFinanceService = require('../services/yahooFinanceService');
const mockData = require('../services/mockData');

// GET /api/news - Get general news (trending stocks news)
router.get('/', async (req, res) => {
  try {
    console.log('📰 GET /api/news - Fetching general news');
    
    // Check if mock data is enabled
    if (process.env.ENABLE_MOCK_DATA === 'true') {
      console.log('🎭 Mock data enabled, returning mock news');
      const mockNews = mockData.getNewsData();
      return res.json({
        success: true,
        data: mockNews,
        source: 'mock',
        timestamp: new Date().toISOString()
      });
    }
    
    // Get news for trending tickers
    const trendingTickers = ['AAPL', 'GOOGL', 'MSFT', 'TSLA', 'AMZN', 'NVDA', 'META', 'JPM'];
    const result = await newsCacheService.getNewsForTickers(trendingTickers);
    
    if (result.success) {
      // Combine all articles from all tickers
      const allArticles = [];
      Object.values(result.results).forEach(tickerResult => {
        if (tickerResult.success && tickerResult.articles) {
          tickerResult.articles.forEach(article => {
            allArticles.push({
              ...article,
              ticker: tickerResult.ticker
            });
          });
        }
      });
      
      // Sort by published date (most recent first)
      allArticles.sort((a, b) => {
        const dateA = new Date(a.published_date || a.publishedAt || 0);
        const dateB = new Date(b.published_date || b.publishedAt || 0);
        return dateB - dateA;
      });
      
      // Limit to top 20 articles
      const limitedArticles = allArticles.slice(0, 20);
      
      console.log(`✅ Successfully fetched ${limitedArticles.length} news articles`);
      res.json({
        success: true,
        data: limitedArticles,
        totalTickers: trendingTickers.length,
        totalArticles: allArticles.length,
        returnedArticles: limitedArticles.length,
        source: 'cache_and_api',
        timestamp: new Date().toISOString()
      });
    } else {
      console.error('❌ Failed to fetch news:', result.error);
      res.status(500).json({
        success: false,
        error: 'Failed to fetch news data',
        details: result.error,
        timestamp: new Date().toISOString()
      });
    }
  } catch (error) {
    console.error('❌ Error in GET /api/news:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// GET /api/news/stock/:ticker - Get news for specific stock
router.get('/stock/:ticker', async (req, res) => {
  try {
    const ticker = req.params.ticker.toUpperCase();
    console.log(`📰 GET /api/news/stock/${ticker} - Fetching news for specific stock`);
    
    // Check if mock data is enabled
    if (process.env.ENABLE_MOCK_DATA === 'true') {
      console.log('🎭 Mock data enabled, returning mock news for ticker');
      const mockNews = mockData.getNewsData().filter(article => 
        article.title.toLowerCase().includes(ticker.toLowerCase()) ||
        article.summary.toLowerCase().includes(ticker.toLowerCase())
      );
      return res.json({
        success: true,
        data: mockNews,
        ticker: ticker,
        source: 'mock',
        timestamp: new Date().toISOString()
      });
    }
    
    const result = await newsCacheService.getNewsForTickers([ticker]);
    
    if (result.success && result.results[ticker]) {
      const tickerResult = result.results[ticker];
      
      if (tickerResult.success) {
        console.log(`✅ Successfully fetched ${tickerResult.articles.length} articles for ${ticker}`);
        res.json({
          success: true,
          data: tickerResult.articles,
          ticker: ticker,
          totalArticles: tickerResult.totalArticles,
          lastUpdated: tickerResult.lastUpdated,
          cacheAge: tickerResult.cacheAge,
          source: tickerResult.freshlyFetched ? 'fresh_api' : 'cache',
          timestamp: new Date().toISOString()
        });
      } else {
        console.error(`❌ Failed to fetch news for ${ticker}:`, tickerResult.error);
        res.status(404).json({
          success: false,
          error: `No news found for ${ticker}`,
          ticker: ticker,
          details: tickerResult.error,
          timestamp: new Date().toISOString()
        });
      }
    } else {
      console.error(`❌ Failed to fetch news for ${ticker}:`, result.error);
      res.status(500).json({
        success: false,
        error: 'Failed to fetch news data',
        ticker: ticker,
        details: result.error,
        timestamp: new Date().toISOString()
      });
    }
  } catch (error) {
    console.error(`❌ Error in GET /api/news/stock/${req.params.ticker}:`, error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message,
      ticker: req.params.ticker,
      timestamp: new Date().toISOString()
    });
  }
});

// GET /api/news/:id - Get specific news article (placeholder)
router.get('/:id', (req, res) => {
  res.status(501).json({
    success: false,
    error: 'Not implemented',
    message: 'Individual news article endpoint not yet implemented',
    id: req.params.id,
    timestamp: new Date().toISOString()
  });
});

module.exports = router; 