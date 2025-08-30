/**
 * Summary API Routes
 * Handles AI summary-related endpoints
 */

const express = require('express');
const router = express.Router();
const mockData = require('../services/mockData');
const stockCacheService = require('../services/stockCacheService');
const newsCacheService = require('../services/newsCacheService');
const schedulerService = require('../services/schedulerService');
const OpenAI = require('openai');

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

    // Require OpenAI key
    if (!process.env.OPENAI_API_KEY) {
      return res.status(501).json({
        success: false,
        error: 'OPENAI_API_KEY is not configured',
        message: 'Set OPENAI_API_KEY in environment to enable AI summaries',
        stockId,
        timestamp: new Date().toISOString()
      });
    }

    // 1) Gather stock data (quote + chart) from cache
    const ticker = stockId.toUpperCase();
    const stockResult = await stockCacheService.getStockData(ticker);
    if (!stockResult.success || !stockResult.data) {
      return res.status(404).json({
        success: false,
        error: `No stock data available for ${ticker}`,
        ticker,
        timestamp: new Date().toISOString()
      });
    }
    const stock = stockResult.data;

    // Prepare compact chart stats
    const points = Array.isArray(stock.chart?.dataPoints) ? stock.chart.dataPoints : [];
    const lastClose = points.length ? points[points.length - 1].close : stock.quote?.regularMarketPrice;
    let minClose = lastClose, maxClose = lastClose;
    for (const p of points) {
      if (typeof p.close === 'number') {
        if (minClose === undefined || p.close < minClose) minClose = p.close;
        if (maxClose === undefined || p.close > maxClose) maxClose = p.close;
      }
    }

    const recentSpan = Math.min(points.length, 30);
    const startIdx = recentSpan > 0 ? points.length - recentSpan : 0;
    const spanPoints = points.slice(startIdx);
    const spanStart = spanPoints.length ? spanPoints[0].close : lastClose;
    const spanChange = (lastClose && spanStart) ? ((lastClose - spanStart) / spanStart) * 100 : 0;

    // 2) Gather latest news for ticker (refresh if stale/missing)
    const newsResult0 = await newsCacheService.getNewsForTickers([ticker]);
    let tickerNews = newsResult0?.results?.[ticker];
    const isMissing = !tickerNews || !tickerNews.success || !Array.isArray(tickerNews.articles) || tickerNews.articles.length === 0;
    const isStale = tickerNews && typeof tickerNews.cacheAge === 'number' && tickerNews.cacheAge >= 24;
    if (isMissing || isStale) {
      try {
        await schedulerService.refreshTickerNews(ticker);
        const newsResult1 = await newsCacheService.getNewsForTickers([ticker]);
        tickerNews = newsResult1?.results?.[ticker];
      } catch (_) {}
    }

    const articles = (tickerNews && tickerNews.success && Array.isArray(tickerNews.articles))
      ? tickerNews.articles.slice(0, 5)
      : [];

    // Build prompt
    const priceDesc = {
      symbol: ticker,
      name: stock.name,
      lastPrice: lastClose,
      dayChange: stock.quote?.regularMarketChange,
      dayChangePercent: stock.quote?.regularMarketChangePercent,
      spanDays: recentSpan,
      spanChangePercent: Number.isFinite(spanChange) ? Number(spanChange.toFixed(2)) : null,
      rangeMin: minClose,
      rangeMax: maxClose,
      currency: stock.quote?.currency || 'USD',
    };

    const newsDesc = articles.map(a => ({
      title: a.title || a.text || a.summary,
      source: a.source,
      time: a.publishedAt || a.published_date || a.time || a.date,
      url: a.url,
    }));

    const systemPrompt = `You are a concise equity research assistant. Use the provided recent price action and latest news headlines to write a short, plain‑English summary and a balanced near‑term outlook. Avoid hype, keep it specific to the ticker.`;

    const userPrompt = {
      role: 'user',
      content: [
        { type: 'text', text: `Ticker: ${ticker}\nName: ${stock.name || ''}\n` },
        { type: 'text', text: `Price data (recent): ${JSON.stringify(priceDesc)}\n` },
        { type: 'text', text: `News (latest up to 5): ${JSON.stringify(newsDesc)}\n` },
        { type: 'text', text: `Write 2 sections:\n1) Summary (2-4 sentences)\n2) Near-term outlook (bulleted, 2-3 bullets)\nKeep under 120 words total. If data is thin, say so.` }
      ]
    };

    const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
    const model = process.env.OPENAI_MODEL || 'gpt-4o-mini';

    const completion = await client.chat.completions.create({
      model,
      temperature: 0.4,
      messages: [
        { role: 'system', content: systemPrompt },
        userPrompt,
      ],
    });

    const content = completion.choices?.[0]?.message?.content?.trim() || '';

    return res.json({
      success: true,
      data: {
        content,
        ticker,
        model,
        inputs: { priceDesc, newsCount: newsDesc.length },
      },
      stockId: ticker,
      source: 'openai',
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