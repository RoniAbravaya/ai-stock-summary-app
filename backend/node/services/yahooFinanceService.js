/**
 * Yahoo Finance API Service
 * Handles fetching news data from Yahoo Finance API
 */

const axios = require('axios');

class YahooFinanceService {
  constructor() {
    this.baseURL = 'https://yahoo-finance15.p.rapidapi.com';
    this.apiKey = process.env.RAPIDAPI_KEY;
    
    // In development, warn about missing API key but don't crash
    if (!this.apiKey && process.env.NODE_ENV !== 'production') {
      console.warn('⚠️ Warning: RAPIDAPI_KEY environment variable is not set.');
      console.warn('⚠️ Yahoo Finance API functionality will be limited.');
      this.isConfigured = false;
    } else if (!this.apiKey && process.env.NODE_ENV === 'production') {
      throw new Error('RAPIDAPI_KEY environment variable is not set in production environment.');
    } else {
      this.isConfigured = true;
      this.headers = {
        'x-rapidapi-host': 'yahoo-finance15.p.rapidapi.com',
        'x-rapidapi-key': this.apiKey
      };
    }
  }

  /**
   * Fetch news for a specific ticker
   * @param {string} ticker - Stock ticker symbol (e.g., 'AAPL')
   * @returns {Promise<Object>} News data from Yahoo Finance
   */
  async fetchNewsForTicker(ticker) {
    // Return mock data if API is not configured (development only)
    if (!this.isConfigured && process.env.NODE_ENV !== 'production') {
      console.log(`ℹ️ Using mock data for ${ticker} (API not configured)`);
      return {
        success: true,
        data: [
          {
            title: 'Mock News Article',
            text: 'This is a mock news article for development.',
            source: 'Mock Source',
            url: 'https://example.com',
            publishedAt: new Date().toISOString()
          }
        ],
        meta: { total: 1 },
        ticker: ticker,
        fetchedAt: new Date().toISOString()
      };
    }

    try {
      console.log(`🔍 Fetching news for ticker: ${ticker}`);
      
      const response = await axios.get(`${this.baseURL}/api/v2/markets/news`, {
        params: {
          tickers: ticker,
          type: 'ALL'
        },
        headers: this.headers,
        timeout: 30000 // 30 second timeout
      });

      if (response.data && response.data.body) {
        console.log(`✅ Successfully fetched ${response.data.body.length} news articles for ${ticker}`);
        return {
          success: true,
          data: response.data.body,
          meta: response.data.meta,
          ticker: ticker,
          fetchedAt: new Date().toISOString()
        };
      } else {
        console.warn(`⚠️ No news data found for ticker: ${ticker}`);
        return {
          success: false,
          error: 'No news data found',
          ticker: ticker,
          fetchedAt: new Date().toISOString()
        };
      }
    } catch (error) {
      console.error(`❌ Error fetching news for ${ticker}:`, error.message);
      
      // Handle rate limiting
      if (error.response && error.response.status === 429) {
        return {
          success: false,
          error: 'Rate limit exceeded',
          ticker: ticker,
          retryAfter: error.response.headers['retry-after'] || 60
        };
      }

      // Handle other API errors
      if (error.response) {
        return {
          success: false,
          error: `API Error: ${error.response.status} - ${error.response.statusText}`,
          ticker: ticker
        };
      }

      // Handle network errors
      return {
        success: false,
        error: `Network Error: ${error.message}`,
        ticker: ticker
      };
    }
  }

  /**
   * Fetch news for multiple tickers with delay between requests
   * @param {Array<string>} tickers - Array of ticker symbols
   * @param {number} delayMs - Delay between requests in milliseconds (default: 1000)
   * @returns {Promise<Array<Object>>} Array of news data results
   */
  async fetchNewsForMultipleTickers(tickers, delayMs = 1000) {
    if (!this.isConfigured && process.env.NODE_ENV !== 'production') {
      console.log('ℹ️ Using mock data for multiple tickers (API not configured)');
      return tickers.map(ticker => ({
        success: true,
        data: [
          {
            title: `Mock News for ${ticker}`,
            text: 'This is a mock news article for development.',
            source: 'Mock Source',
            url: 'https://example.com',
            publishedAt: new Date().toISOString()
          }
        ],
        meta: { total: 1 },
        ticker: ticker,
        fetchedAt: new Date().toISOString()
      }));
    }

    console.log(`🔄 Starting batch fetch for ${tickers.length} tickers`);
    const results = [];
    
    for (let i = 0; i < tickers.length; i++) {
      const ticker = tickers[i];
      
      try {
        const result = await this.fetchNewsForTicker(ticker);
        results.push(result);
        
        // Add delay between requests to avoid rate limiting (except for last request)
        if (i < tickers.length - 1) {
          console.log(`⏳ Waiting ${delayMs}ms before next request...`);
          await this.delay(delayMs);
        }
      } catch (error) {
        console.error(`❌ Failed to fetch news for ${ticker}:`, error.message);
        results.push({
          success: false,
          error: error.message,
          ticker: ticker
        });
      }
    }
    
    console.log(`✅ Batch fetch completed. ${results.filter(r => r.success).length}/${results.length} successful`);
    return results;
  }

  /**
   * Helper method to add delay between API calls
   * @param {number} ms - Milliseconds to delay
   * @returns {Promise<void>}
   */
  delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  /**
   * Check if the RapidAPI integration is configured correctly
   * @returns {boolean} True if API key is set
   */
  isApiConfigured() {
    return this.isConfigured;
  }

  /**
   * Test API connection
   * @returns {Promise<boolean>} True if API is accessible
   */
  async testConnection() {
    if (!this.isConfigured && process.env.NODE_ENV !== 'production') {
      console.log('ℹ️ Skipping API test (API not configured)');
      return true;
    }

    try {
      console.log('🔍 Testing Yahoo Finance API connection...');
      const result = await this.fetchNewsForTicker('AAPL');
      
      if (result.success) {
        console.log('✅ Yahoo Finance API connection successful');
        return true;
      } else {
        console.warn('⚠️ Yahoo Finance API connection failed:', result.error);
        return false;
      }
    } catch (error) {
      console.error('❌ Yahoo Finance API connection test failed:', error.message);
      return false;
    }
  }
}

// Export singleton instance
module.exports = new YahooFinanceService();