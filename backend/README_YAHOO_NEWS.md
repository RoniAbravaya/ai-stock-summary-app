# Yahoo Finance News Caching System

This document describes the Yahoo Finance news caching system implemented in the AI Stock Summary backend.

## Overview

The system automatically fetches and caches news articles from Yahoo Finance API for 25 major stock tickers. It stores the data in Firebase Realtime Database and refreshes it every 24 hours at 9:00 PM UTC.

## Architecture

### Services

1. **YahooFinanceService** (`services/yahooFinanceService.js`)
   - Handles API calls to Yahoo Finance
   - Implements rate limiting and error handling
   - Supports batch fetching with delays

2. **NewsCacheService** (`services/newsCacheService.js`)
   - Manages Firebase Realtime Database operations
   - Creates separate collections for each ticker (`news_aapl`, `news_googl`, etc.)
   - Provides cache statistics and status checking

3. **SchedulerService** (`services/schedulerService.js`)
   - Handles cron job scheduling
   - Runs daily refresh at 9:00 PM UTC
   - Supports manual refresh triggers

## Supported Tickers

The system currently supports 25 major stock tickers:

```
BAC, ABBV, NVO, KO, PLTR, SMFG, ASML, BABA, PM, TMUS,
UNH, GE, AAPL, GOOGL, MSFT, TSLA, AMZN, NVDA, META,
JPM, V, WMT, JNJ, XOM, PG
```

## API Endpoints

### Public Endpoints

#### Get News for Multiple Tickers
```
GET /api/yahoo-news?tickers=AAPL,GOOGL,TSLA
```

**Response:**
```json
{
  "success": true,
  "results": {
    "AAPL": {
      "success": true,
      "ticker": "AAPL",
      "lastUpdated": "2024-01-15T21:00:00.000Z",
      "totalArticles": 25,
      "articles": [...],
      "cacheAge": 2.5
    }
  },
  "requestedTickers": ["AAPL", "GOOGL", "TSLA"],
  "retrievedAt": "2024-01-16T09:30:00.000Z"
}
```

#### Get Cache Statistics
```
GET /api/yahoo-news/stats
```

**Response:**
```json
{
  "success": true,
  "stats": {
    "totalTickers": 25,
    "cachedTickers": 23,
    "freshTickers": 20,
    "staleTickers": 3,
    "totalArticles": 1250,
    "tickers": {...}
  },
  "generatedAt": "2024-01-16T09:30:00.000Z"
}
```

#### Get Supported Tickers
```
GET /api/yahoo-news/tickers
```

**Response:**
```json
{
  "success": true,
  "tickers": ["BAC", "ABBV", "NVO", ...],
  "total": 25
}
```

### Admin Endpoints (Require Authentication + Admin Role)

#### Manual Refresh Single Ticker
```
POST /api/admin/refresh-news/AAPL
Authorization: Bearer <firebase-token>
```

#### Manual Refresh All Tickers
```
POST /api/admin/refresh-news/all
Authorization: Bearer <firebase-token>
```

#### Get Scheduler Status
```
GET /api/admin/scheduler/status
Authorization: Bearer <firebase-token>
```

## Database Structure

### Firebase Realtime Database Collections

Each ticker has its own collection: `news_{ticker_lowercase}`

**Example: `news_aapl`**
```json
{
  "ticker": "AAPL",
  "lastUpdated": "2024-01-15T21:00:00.000Z",
  "totalArticles": 25,
  "articles": {
    "article_0_timestamp": {
      "url": "https://example.com/article",
      "img": "https://example.com/image.jpg",
      "title": "Apple Reports Strong Earnings",
      "text": "Apple Inc. announced...",
      "source": "Reuters",
      "type": "Article",
      "tickers": ["$AAPL"],
      "time": "Jan 15, 2024, 2:30 PM EST",
      "ago": "2 hours ago",
      "cached_at": "2024-01-15T21:00:00.000Z",
      "ticker": "AAPL"
    }
  }
}
```

## Configuration

### Environment Variables

Required in `.env` file:

```bash
# Yahoo Finance API (via RapidAPI)
RAPIDAPI_KEY=your-rapidapi-key-here

# Firebase Configuration
FIREBASE_PROJECT_ID=your-firebase-project-id
FIREBASE_DATABASE_URL=https://your-project-id-default-rtdb.firebaseio.com/
# ... other Firebase vars
```

### Scheduler Configuration

- **Schedule**: Daily at 9:00 PM UTC
- **Cron Expression**: `0 21 * * *`
- **Timezone**: UTC
- **Delay between API calls**: 2 seconds (to avoid rate limiting)

## Rate Limiting & Error Handling

### API Rate Limiting
- 2-second delay between Yahoo Finance API calls
- Automatic retry logic for rate limit errors
- Graceful degradation on API failures

### Error Handling
- Individual ticker failures don't stop the batch process
- Comprehensive error logging
- Fallback to cached data on API errors

## Monitoring & Statistics

### Cache Statistics
- Total tickers supported
- Currently cached tickers
- Fresh vs stale cache status
- Total articles cached
- Per-ticker cache age

### Scheduler Statistics
- Total runs
- Successful runs
- Failed runs
- Last run result
- Next scheduled run time

## Installation & Setup

1. **Install dependencies:**
   ```bash
   npm install
   ```

2. **Configure environment variables:**
   ```bash
   cp env.example .env
   # Edit .env with your API keys
   ```

3. **Start the server:**
   ```bash
   npm start
   ```

4. **Verify setup:**
   ```bash
   curl http://localhost:3000/health
   ```

## Testing

### Test API Connection
```bash
# Check if Yahoo Finance API is working
curl "http://localhost:3000/api/yahoo-news/tickers"
```

### Test News Retrieval
```bash
# Get cached news for specific tickers
curl "http://localhost:3000/api/yahoo-news?tickers=AAPL,GOOGL"
```

### Test Manual Refresh (Admin)
```bash
# Refresh single ticker (requires admin token)
curl -X POST "http://localhost:3000/api/admin/refresh-news/AAPL" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```

## Troubleshooting

### Common Issues

1. **API Key Issues**
   - Ensure `RAPIDAPI_KEY` is set in environment variables
   - Verify API key is valid and has access to Yahoo Finance endpoints

2. **Firebase Connection**
   - Check Firebase configuration variables
   - Ensure Realtime Database is enabled in Firebase console

3. **Rate Limiting**
   - Yahoo Finance API has rate limits
   - Increase delay between calls if needed
   - Monitor API usage in RapidAPI dashboard

4. **Cache Issues**
   - Check cache statistics endpoint for details
   - Clear cache manually if needed
   - Verify Firebase Realtime Database permissions

### Logs to Monitor

- `🔍 Fetching news for ticker: {ticker}`
- `✅ Successfully cached {count} articles for {ticker}`
- `🕘 Daily news refresh triggered at 9:00 PM UTC`
- `❌ Error fetching news for {ticker}: {error}`

## Performance Considerations

- **Memory Usage**: Each ticker stores ~25-50 articles (~1-2MB per ticker)
- **API Calls**: 25 calls per day (one per ticker)
- **Database Reads**: Optimized with single queries per ticker
- **Cache Strategy**: 24-hour TTL with automatic refresh

## Future Enhancements

1. **Dynamic Ticker Support**: Allow adding/removing tickers without code changes
2. **Multiple Refresh Schedules**: Different refresh intervals for different tickers
3. **Article Deduplication**: Remove duplicate articles across tickers
4. **Content Analysis**: Extract sentiment, keywords, and topics
5. **Real-time Updates**: WebSocket support for real-time news updates