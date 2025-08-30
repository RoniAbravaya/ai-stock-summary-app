/**
 * News API Routes
 * Handles news-related endpoints
 */

const express = require('express');
const router = express.Router();
const newsCacheService = require('../services/newsCacheService');
const yahooFinanceService = require('../services/yahooFinanceService');
const mockData = require('../services/mockData');
const schedulerService = require('../services/schedulerService');

// GET /api/news - Get general news (trending stocks news)
router.get('/', async (req, res) => {
  try {
    console.log('📰 GET /api/news - Fetching general news');
    
    // Check if mock data is enabled
    if (process.env.ENABLE_MOCK_DATA === 'true') {
      console.log('🎭 Mock data enabled, returning mock news');
      const mockNews = mockData.getAllNews();
      return res.json({
        success: true,
        data: mockNews,
        source: 'mock',
        timestamp: new Date().toISOString()
      });
    }
    
    // Get news for trending tickers
    const trendingTickers = ['AAPL', 'GOOGL', 'MSFT', 'TSLA', 'AMZN', 'NVDA', 'META', 'JPM'];

    // Freshness controls
    const forceFresh = (req.query.fresh || '').toString().toLowerCase() === 'true' || req.query.fresh === '1';
    const noCache = (req.query.nocache || '').toString().toLowerCase() === 'true' || req.query.nocache === '1';
    const maxAgeHours = Number.isFinite(parseFloat(req.query.maxAgeHours))
      ? Math.max(1, parseFloat(req.query.maxAgeHours))
      : 6; // default to 6 hours

    let result = await newsCacheService.getNewsForTickers(trendingTickers);

    // Determine stale or missing tickers
    const staleTickers = [];
    if (result && result.results) {
      for (const ticker of trendingTickers) {
        const r = result.results[ticker];
        const isMissing = !r || r.success === false || !Array.isArray(r.articles) || r.articles.length === 0;
        const isStale = r && typeof r.cacheAge === 'number' && r.cacheAge >= maxAgeHours;
        if (forceFresh || noCache || isMissing || isStale) {
          staleTickers.push(ticker);
        }
      }
    }

    // If needed, refresh stale/missing tickers
    let fallbackUsed = false;
    let stillStaleOrMissing = [];
    if (staleTickers.length > 0) {
      console.log(`♻️ Refreshing stale/missing tickers: ${staleTickers.join(', ')} (maxAgeHours=${maxAgeHours}, forceFresh=${forceFresh}, noCache=${noCache})`);
      await Promise.allSettled(staleTickers.map(t => schedulerService.refreshTickerNews(t)));
      // Re-read after refresh
      result = await newsCacheService.getNewsForTickers(trendingTickers);

      // Determine if anything is still stale or missing, then fall back to direct fetch + store
      for (const ticker of staleTickers) {
        const r = result.results ? result.results[ticker] : null;
        const missing = !r || r.success === false || !Array.isArray(r.articles) || r.articles.length === 0;
        const stale = r && typeof r.cacheAge === 'number' && r.cacheAge >= maxAgeHours;
        if (missing || stale) stillStaleOrMissing.push(ticker);
      }

      if (stillStaleOrMissing.length > 0) {
        console.log(`🆘 Scheduler refresh insufficient. Falling back to direct fetch for: ${stillStaleOrMissing.join(', ')}`);
        try {
          const fetchResults = await yahooFinanceService.fetchNewsForMultipleTickers(stillStaleOrMissing, 800);
          const toStore = fetchResults.filter(r => r && r.success && Array.isArray(r.data) && r.data.length > 0);
          await Promise.allSettled(toStore.map(r => newsCacheService.storeNewsForTicker(r.ticker, r.data)));
          fallbackUsed = true;
          // Re-read after fallback store
          result = await newsCacheService.getNewsForTickers(trendingTickers);
        } catch (fallbackErr) {
          console.error('❌ Direct fetch fallback failed:', fallbackErr.message);
        }
      }
    }
    
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

      // Helper to parse various date fields
      const parseDate = (a) => {
        const candidates = [a.published_date, a.publishedAt, a.pubDate, a.date, a.time, a.cached_at];
        for (const c of candidates) {
          if (c) {
            const d = new Date(c);
            if (!isNaN(d.getTime())) return d;
          }
        }
        return new Date(0);
      };

      // Sort by published date (most recent first)
      allArticles.sort((a, b) => parseDate(b) - parseDate(a));

      // Optionally filter out very old items (> 30 days) to avoid stale content
      const thirtyDaysMs = 30 * 24 * 60 * 60 * 1000;
      const nowMs = Date.now();
      const freshArticles = allArticles.filter(a => nowMs - parseDate(a).getTime() <= thirtyDaysMs);

      // Limit to top 20 articles
      const limitedArticles = (freshArticles.length > 0 ? freshArticles : allArticles).slice(0, 20);
      
      console.log(`✅ Successfully fetched ${limitedArticles.length} news articles`);
      res.json({
        success: true,
        data: limitedArticles,
        totalTickers: Object.keys(result.results || {}).length,
        totalArticles: allArticles.length,
        returnedArticles: limitedArticles.length,
        source: 'cache_and_api',
        refreshedTickers: staleTickers || [],
        fallbackUsed,
        stillStaleOrMissing,
        freshness: { maxAgeHours, forceFresh, noCache },
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
      const mockNews = mockData.getNewsByStock(ticker);
      return res.json({
        success: true,
        data: mockNews,
        ticker: ticker,
        source: 'mock',
        timestamp: new Date().toISOString()
      });
    }
    
    const forceFresh = (req.query.fresh || '').toString().toLowerCase() === 'true' || req.query.fresh === '1';
    const maxAgeHours = Number.isFinite(parseFloat(req.query.maxAgeHours))
      ? Math.max(1, parseFloat(req.query.maxAgeHours))
      : 6;

    let result = await newsCacheService.getNewsForTickers([ticker]);

    const r = result.results ? result.results[ticker] : null;
    const isMissing = !r || r.success === false || !Array.isArray(r.articles) || r.articles.length === 0;
    const isStale = r && typeof r.cacheAge === 'number' && r.cacheAge >= maxAgeHours;
    if (forceFresh || isMissing || isStale) {
      console.log(`♻️ Refreshing ${ticker} (maxAgeHours=${maxAgeHours}, forceFresh=${forceFresh})`);
      await schedulerService.refreshTickerNews(ticker);
      result = await newsCacheService.getNewsForTickers([ticker]);
    }
    
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
          freshness: { maxAgeHours, forceFresh },
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
 
// Additional endpoint to manually refresh all news (admin/op usage)
router.post('/refresh', async (req, res) => {
  try {
    console.log('🔄 POST /api/news/refresh - Manual refresh requested');
    const result = await schedulerService.refreshAllTickersNews();
    res.json({ success: true, result });
  } catch (err) {
    console.error('❌ Manual news refresh failed:', err.message);
    res.status(500).json({ success: false, error: err.message });
  }
});