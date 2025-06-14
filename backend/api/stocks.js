/**
 * Stocks API Routes
 * Handles stock-related endpoints
 */

const express = require('express');
const router = express.Router();
const yahooFinanceService = require('../services/yahooFinanceService');
const newsCacheService = require('../services/newsCacheService');
const mockData = require('../services/mockData');

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
    
    // Get supported tickers from news cache service
    const supportedTickers = newsCacheService.getSupportedTickers();
    
    // Get basic stock data for supported tickers
    const stocks = supportedTickers.map(ticker => ({
      symbol: ticker,
      name: getStockName(ticker),
      type: 'stock',
      supported: true
    }));
    
    console.log(`✅ Successfully returned ${stocks.length} available stocks`);
    res.json({
      success: true,
      data: stocks,
      totalStocks: stocks.length,
      source: 'supported_tickers',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('❌ Error in GET /api/stocks:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message,
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
    
    // Define trending stocks (can be made dynamic later)
    const trendingTickers = ['AAPL', 'GOOGL', 'MSFT', 'TSLA', 'AMZN', 'NVDA', 'META', 'JPM'];
    
    const trendingStocks = trendingTickers.map(ticker => ({
      symbol: ticker,
      name: getStockName(ticker),
      type: 'stock',
      trending: true,
      rank: trendingTickers.indexOf(ticker) + 1
    }));
    
    console.log(`✅ Successfully returned ${trendingStocks.length} trending stocks`);
    res.json({
      success: true,
      data: trendingStocks,
      totalTrending: trendingStocks.length,
      source: 'curated_list',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('❌ Error in GET /api/stocks/trending:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// GET /api/stocks/search - Search stocks
router.get('/search', async (req, res) => {
  try {
    const query = req.query.q;
    console.log(`📈 GET /api/stocks/search?q=${query} - Searching stocks`);
    
    if (!query) {
      return res.status(400).json({
        success: false,
        error: 'Query parameter "q" is required',
        timestamp: new Date().toISOString()
      });
    }
    
    // Check if mock data is enabled
    if (process.env.ENABLE_MOCK_DATA === 'true') {
      console.log('🎭 Mock data enabled, searching mock stocks');
      const mockStocks = mockData.getAllStocks().filter(stock => 
        stock.symbol.toLowerCase().includes(query.toLowerCase()) ||
        stock.name.toLowerCase().includes(query.toLowerCase())
      );
      return res.json({
        success: true,
        data: mockStocks,
        query: query,
        source: 'mock',
        timestamp: new Date().toISOString()
      });
    }
    
    // Simple search in supported tickers
    const supportedTickers = newsCacheService.getSupportedTickers();
    const matchingStocks = supportedTickers
      .filter(ticker => 
        ticker.toLowerCase().includes(query.toLowerCase()) ||
        getStockName(ticker).toLowerCase().includes(query.toLowerCase())
      )
      .map(ticker => ({
        symbol: ticker,
        name: getStockName(ticker),
        type: 'stock',
        matchType: ticker.toLowerCase().includes(query.toLowerCase()) ? 'symbol' : 'name'
      }));
    
    console.log(`✅ Found ${matchingStocks.length} stocks matching "${query}"`);
    res.json({
      success: true,
      data: matchingStocks,
      query: query,
      totalMatches: matchingStocks.length,
      source: 'supported_tickers_search',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error(`❌ Error in GET /api/stocks/search:`, error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message,
      query: req.query.q,
      timestamp: new Date().toISOString()
    });
  }
});

// GET /api/stocks/:id - Get specific stock details
router.get('/:id', async (req, res) => {
  try {
    const ticker = req.params.id.toUpperCase();
    console.log(`📈 GET /api/stocks/${ticker} - Fetching stock details`);
    
    // Check if mock data is enabled
    if (process.env.ENABLE_MOCK_DATA === 'true') {
      console.log('🎭 Mock data enabled, returning mock stock details');
      const mockStock = mockData.getStockById(ticker);
      if (mockStock) {
        return res.json({
          success: true,
          data: mockStock,
          ticker: ticker,
          source: 'mock',
          timestamp: new Date().toISOString()
        });
      } else {
        return res.status(404).json({
          success: false,
          error: `Stock ${ticker} not found in mock data`,
          ticker: ticker,
          timestamp: new Date().toISOString()
        });
      }
    }
    
    // Check if ticker is supported
    const supportedTickers = newsCacheService.getSupportedTickers();
    if (!supportedTickers.includes(ticker)) {
      return res.status(404).json({
        success: false,
        error: `Stock ${ticker} is not supported`,
        ticker: ticker,
        supportedTickers: supportedTickers,
        timestamp: new Date().toISOString()
      });
    }
    
    // Return basic stock information
    const stockDetails = {
      symbol: ticker,
      name: getStockName(ticker),
      type: 'stock',
      supported: true,
      hasNews: true
    };
    
    console.log(`✅ Successfully returned details for ${ticker}`);
    res.json({
      success: true,
      data: stockDetails,
      ticker: ticker,
      source: 'basic_info',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error(`❌ Error in GET /api/stocks/${req.params.id}:`, error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message,
      ticker: req.params.id,
      timestamp: new Date().toISOString()
    });
  }
});

// Helper function to get stock names
function getStockName(ticker) {
  const stockNames = {
    'AAPL': 'Apple Inc.',
    'GOOGL': 'Alphabet Inc.',
    'MSFT': 'Microsoft Corporation',
    'TSLA': 'Tesla, Inc.',
    'AMZN': 'Amazon.com, Inc.',
    'NVDA': 'NVIDIA Corporation',
    'META': 'Meta Platforms, Inc.',
    'JPM': 'JPMorgan Chase & Co.',
    'BAC': 'Bank of America Corporation',
    'ABBV': 'AbbVie Inc.',
    'NVO': 'Novo Nordisk A/S',
    'KO': 'The Coca-Cola Company',
    'PLTR': 'Palantir Technologies Inc.',
    'SMFG': 'Sumitomo Mitsui Financial Group',
    'ASML': 'ASML Holding N.V.',
    'BABA': 'Alibaba Group Holding Limited',
    'PM': 'Philip Morris International Inc.',
    'TMUS': 'T-Mobile US, Inc.',
    'UNH': 'UnitedHealth Group Incorporated',
    'GE': 'General Electric Company',
    'V': 'Visa Inc.',
    'WMT': 'Walmart Inc.',
    'JNJ': 'Johnson & Johnson',
    'XOM': 'Exxon Mobil Corporation',
    'PG': 'The Procter & Gamble Company'
  };
  
  return stockNames[ticker] || `${ticker} Stock`;
}

module.exports = router; 