/**
 * Stocks API Routes
 * Handles stock-related endpoints
 */

const express = require('express');
const router = express.Router();
const yahooFinanceService = require('../services/yahooFinanceService');
const newsCacheService = require('../services/newsCacheService');
const stockCacheService = require('../services/stockCacheService');
const stockProfileCacheService = require('../services/stockProfileCacheService');
const mockData = require('../services/mockData');

// GET /api/stocks/main - Get main 20 stocks with quotes and charts
router.get('/main', async (req, res) => {
  try {
    console.log('📊 GET /api/stocks/main - Fetching main 20 stocks with charts');
    
    // Check if mock data is enabled
    if (process.env.ENABLE_MOCK_DATA === 'true') {
      console.log('🎭 Mock data enabled, returning mock main stocks');
      const mockStocks = stockCacheService.getMainStocks().map(ticker => ({
        symbol: ticker,
        name: yahooFinanceService.getStockName(ticker),
        logo: yahooFinanceService.getCompanyLogo(ticker),
        quote: yahooFinanceService.getMockQuote(ticker),
        chart: yahooFinanceService.getMockChartData(ticker, '1d', '1mo'),
        lastUpdated: Date.now()
      }));
      
      return res.json({
        success: true,
        data: mockStocks,
        totalStocks: mockStocks.length,
        source: 'mock',
        timestamp: new Date().toISOString()
      });
    }
    
    // Get main stocks data from cache service
    const results = await stockCacheService.getMainStocksData();
    const successfulResults = results.filter(result => result.success);
    
    console.log('✅ Successfully returned main stocks', {
      successCount: successfulResults.length,
      total: results.length
    });
    res.json({
      success: true,
      data: successfulResults.map(result => result.data),
      totalStocks: successfulResults.length,
      cached: successfulResults.filter(r => r.source === 'cache').length,
      fresh: successfulResults.filter(r => r.source === 'api').length,
      stale: successfulResults.filter(r => r.source === 'stale_cache').length,
      source: 'stock_cache_service',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('❌ Error in GET /api/stocks/main', { error });
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// GET /api/stocks/:ticker/chart - Get chart data for a specific stock
router.get('/:ticker/chart', async (req, res) => {
  try {
    const ticker = req.params.ticker.toUpperCase();
    const interval = req.query.interval || '1d';
    const range = req.query.range || '1mo';
    
    console.log('📈 GET /api/stocks/chart - Fetching chart data', {
      ticker,
      interval,
      range
    });
    
    // Check if mock data is enabled
    if (process.env.ENABLE_MOCK_DATA === 'true') {
      console.log('🎭 Mock data enabled, returning mock chart data');
      const mockChart = yahooFinanceService.getMockChartData(ticker, interval, range);
      return res.json({
        success: true,
        data: mockChart,
        ticker: ticker,
        interval: interval,
        range: range,
        source: 'mock',
        timestamp: new Date().toISOString()
      });
    }
    
    // Get chart data from Yahoo Finance
    const result = await yahooFinanceService.getChartData(ticker, interval, range);
    
    if (result.success) {
      console.log('✅ Successfully returned chart data', { ticker });
      res.json({
        success: true,
        data: result.data,
        ticker: ticker,
        interval: interval,
        range: range,
        source: 'yahoo_finance',
        timestamp: new Date().toISOString()
      });
    } else {
      console.warn('⚠️ Failed to get chart data', {
        ticker,
        error: result.error
      });
      res.status(404).json({
        success: false,
        error: result.error,
        ticker: ticker,
        interval: interval,
        range: range,
        timestamp: new Date().toISOString()
      });
    }
  } catch (error) {
    console.error('❌ Error in GET /api/stocks/chart', {
      ticker: req.params.ticker,
      error
    });
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message,
      ticker: req.params.ticker,
      timestamp: new Date().toISOString()
    });
  }
});

// GET /api/stocks/search - Enhanced search stocks
router.get('/search', async (req, res) => {
  try {
    const query = req.query.q;
    console.log('🔍 GET /api/stocks/search - Enhanced stock search', { query });
    
    if (!query) {
      return res.status(400).json({
        success: false,
        error: 'Query parameter "q" is required',
        timestamp: new Date().toISOString()
      });
    }
    
    // Check if mock data is enabled
    if (process.env.ENABLE_MOCK_DATA === 'true') {
      console.log('🎭 Mock data enabled, using mock search');
      const mockResults = yahooFinanceService.getMockSearchResults(query);
      return res.json({
        success: true,
        data: mockResults,
        query: query,
        totalResults: mockResults.length,
        source: 'mock',
        timestamp: new Date().toISOString()
      });
    }
    
    // Use stock cache service for search
    const result = await stockCacheService.searchStocks(query);
    
    if (result.success) {
      console.log('✅ Found search results', {
        query,
        count: result.data.length
      });
      res.json({
        success: true,
        data: result.data,
        query: query,
        totalResults: result.data.length,
        source: 'yahoo_finance_search',
        timestamp: new Date().toISOString()
      });
    } else {
      console.warn('⚠️ Search failed', {
        query,
        error: result.error
      });
      res.status(500).json({
        success: false,
        error: result.error,
        query: query,
        timestamp: new Date().toISOString()
      });
    }
  } catch (error) {
    console.error('❌ Error in GET /api/stocks/search', {
      query: req.query.q,
      error
    });
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message,
      query: req.query.q,
      timestamp: new Date().toISOString()
    });
  }
});

// GET /api/stocks/trending - Get trending stocks
router.get('/trending', async (req, res) => {
  try {
    console.log('📈 GET /api/stocks/trending - Fetching trending stocks');
    
    // Check if mock data is enabled
    if (process.env.ENABLE_MOCK_DATA === 'true') {
      console.log('🎭 Mock data enabled, returning mock trending stocks');
      const mockStocks = mockData.getTrendingStocks();
      return res.json({
        success: true,
        data: mockStocks,
        source: 'mock',
        timestamp: new Date().toISOString()
      });
    }
    
    // Use first 8 main stocks as trending
    const mainStocks = stockCacheService.getMainStocks();
    const trendingTickers = mainStocks.slice(0, 8);
    
    const trendingStocks = trendingTickers.map((ticker, index) => ({
      symbol: ticker,
      name: yahooFinanceService.getStockName(ticker),
      type: 'stock',
      trending: true,
      rank: index + 1
    }));
    
    console.log('✅ Successfully returned trending stocks', {
      count: trendingStocks.length
    });
    res.json({
      success: true,
      data: trendingStocks,
      totalTrending: trendingStocks.length,
      source: 'main_stocks_subset',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('❌ Error in GET /api/stocks/trending', { error });
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// GET /api/stocks - Get available stocks
router.get('/', async (req, res) => {
  try {
    console.log('📈 GET /api/stocks - Fetching available stocks');
    
    // Check if mock data is enabled
    if (process.env.ENABLE_MOCK_DATA === 'true') {
      console.log('🎭 Mock data enabled, returning mock stocks');
      const mockStocks = mockData.getAllStocks();
      return res.json({
        success: true,
        data: mockStocks,
        source: 'mock',
        timestamp: new Date().toISOString()
      });
    }
    
    // Get main stocks list
    const mainStocks = stockCacheService.getMainStocks();
    const stocks = mainStocks.map(ticker => ({
      symbol: ticker,
      name: yahooFinanceService.getStockName(ticker),
      type: 'stock',
      supported: true,
      isMainStock: true
    }));
    
    console.log('✅ Successfully returned available stocks', {
      count: stocks.length
    });
    res.json({
      success: true,
      data: stocks,
      totalStocks: stocks.length,
      source: 'main_stocks_list',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('❌ Error in GET /api/stocks', { error });
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// GET /api/stocks/:ticker/profile - Get company profile data with Firestore caching
router.get('/:ticker/profile', async (req, res) => {
  try {
    const ticker = req.params.ticker.toUpperCase();
    console.log('🏢 GET /api/stocks/profile - Fetching company profile', { ticker });

    // Use Firestore cache service for 24-hour caching
    const result = await stockProfileCacheService.getProfile(ticker);

    if (result.success) {
      return res.json({
        success: true,
        data: result.data,
        ticker: ticker,
        source: result.source,
        cachedAt: result.cachedAt,
        warning: result.warning,
        timestamp: new Date().toISOString()
      });
    }

    console.warn('⚠️ Failed to get profile for ticker', {
      ticker,
      error: result.error
    });
    return res.status(404).json({
      success: false,
      error: result.error || 'Profile not found',
      ticker: ticker,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('❌ Error in GET /api/stocks/profile', {
      ticker: req.params.ticker,
      error
    });
    return res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message,
      ticker: req.params.ticker,
      timestamp: new Date().toISOString()
    });
  }
});

// GET /api/stocks/:ticker - Get complete stock data (quote + chart)
// This MUST be last to avoid catching specific routes like /main, /search, /trending
router.get('/:ticker', async (req, res) => {
  try {
    const ticker = req.params.ticker.toUpperCase();
    console.log('📊 GET /api/stocks - Fetching complete stock data', { ticker });
    
    // Check if mock data is enabled
    if (process.env.ENABLE_MOCK_DATA === 'true') {
      console.log('🎭 Mock data enabled, returning mock stock data');
      const mockStock = {
        symbol: ticker,
        name: yahooFinanceService.getStockName(ticker),
        logo: yahooFinanceService.getCompanyLogo(ticker),
        quote: yahooFinanceService.getMockQuote(ticker),
        chart: yahooFinanceService.getMockChartData(ticker, '1d', '1mo'),
        lastUpdated: Date.now()
      };
      
      return res.json({
        success: true,
        data: mockStock,
        ticker: ticker,
        source: 'mock',
        timestamp: new Date().toISOString()
      });
    }
    
    // Get stock data from cache service
    const result = await stockCacheService.getStockData(ticker);
    
    if (result.success) {
      console.log('✅ Successfully returned complete data', { ticker });
      res.json({
        success: true,
        data: result.data,
        ticker: ticker,
        source: result.source,
        warning: result.warning,
        timestamp: new Date().toISOString()
      });
    } else {
      console.warn('⚠️ Failed to get stock data', {
        ticker,
        error: result.error
      });
      res.status(404).json({
        success: false,
        error: result.error,
        ticker: ticker,
        timestamp: new Date().toISOString()
      });
    }
  } catch (error) {
    console.error('❌ Error in GET /api/stocks', {
      ticker: req.params.ticker,
      error
    });
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message,
      ticker: req.params.ticker,
      timestamp: new Date().toISOString()
    });
  }
});

// Helper function to get stock names
function getStockName(ticker) {
  return yahooFinanceService.getStockName(ticker);
}

module.exports = router; 