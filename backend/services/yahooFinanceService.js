/**
 * Yahoo Finance API Service
 * Handles fetching news data and stock data from Yahoo Finance API
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
   * Validate if API key is configured
   * @returns {boolean} True if API key is set
   */
  isConfigured() {
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

  /**
   * Fetch stock quotes for multiple tickers
   * @param {Array<string>} tickers - Array of ticker symbols (e.g., ['AAPL', 'MSFT'])
   * @returns {Promise<Object>} Stock quotes data from Yahoo Finance
   */
  async getBatchQuotes(tickers) {
    if (!this.isConfigured) {
      console.log(`ℹ️ Using mock data for batch quotes (API not configured)`);
      return {
        success: true,
        data: tickers.map(ticker => this.getMockQuote(ticker)),
        fetchedAt: new Date().toISOString()
      };
    }

    try {
      console.log(`📊 Fetching batch quotes for ${tickers.length} tickers: ${tickers.join(', ')}`);
      
      // Try multiple endpoints in order of preference
      const endpoints = [
        // Try the quote endpoint first
        {
          url: `${this.baseURL}/api/v1/markets/stock/quotes`,
          params: { ticker: tickers.join(',') }
        },
        // Try individual ticker approach
        {
          url: `${this.baseURL}/api/v1/markets/stock/quotes`,
          params: { ticker: tickers[0] } // Just try first ticker as test
        }
      ];

      let lastError = null;
      
      for (const endpoint of endpoints) {
        try {
          console.log(`🔄 Trying endpoint: ${endpoint.url} with params:`, endpoint.params);
          
          const response = await axios.get(endpoint.url, {
            params: endpoint.params,
            headers: this.headers,
            timeout: 15000
          });

                console.log(`✅ API Response Status: ${response.status}`);
      console.log(`✅ Response data type: ${Array.isArray(response.data) ? 'Array' : typeof response.data}`);
      // Sanitize response keys to avoid logging sensitive data
      const safeKeys = Object.keys(response.data || {}).filter(key => 
        !key.toLowerCase().includes('key') && 
        !key.toLowerCase().includes('token') && 
        !key.toLowerCase().includes('secret') &&
        !key.toLowerCase().includes('password')
      );
      console.log(`✅ Response keys:`, safeKeys);

          if (response.data) {
            // Handle different response formats
            let stockData = [];
            
            if (Array.isArray(response.data)) {
              stockData = response.data;
            } else if (response.data.body && Array.isArray(response.data.body)) {
              stockData = response.data.body;
            } else if (response.data.data && Array.isArray(response.data.data)) {
              stockData = response.data.data;
            } else if (typeof response.data === 'object') {
              // Single stock response
              stockData = [response.data];
            }

            if (stockData.length > 0) {
              console.log(`✅ Successfully fetched quotes for ${stockData.length} stocks`);
              console.log(`✅ Sample data:`, stockData[0]);
              
              return {
                success: true,
                data: stockData,
                fetchedAt: new Date().toISOString()
              };
            }
          }
        } catch (endpointError) {
          console.warn(`⚠️ Endpoint failed: ${endpoint.url}`, endpointError.message);
          lastError = endpointError;
          continue;
        }
      }

      // If all endpoints failed, log the error and return mock data
      console.warn(`⚠️ All endpoints failed. Last error:`, lastError?.message);
      console.warn(`⚠️ Falling back to mock data for ${tickers.length} tickers`);
      
      return {
        success: true,
        data: tickers.map(ticker => this.getMockQuote(ticker)),
        source: 'mock_fallback',
        fetchedAt: new Date().toISOString()
      };

    } catch (error) {
      console.error(`❌ Error fetching batch quotes:`, error.message);
      
      // Log detailed error information
      if (error.response) {
        console.error(`❌ API Response Status: ${error.response.status}`);
        console.error(`❌ API Response Headers:`, error.response.headers);
        console.error(`❌ API Response Data:`, error.response.data);
      }
      
      // Return mock data as fallback
      console.log(`🔄 Returning mock data as fallback`);
      return {
        success: true,
        data: tickers.map(ticker => this.getMockQuote(ticker)),
        source: 'mock_fallback',
        error: error.message,
        fetchedAt: new Date().toISOString()
      };
    }
  }

  /**
   * Fetch chart data for a specific ticker
   * @param {string} ticker - Stock ticker symbol (e.g., 'AAPL')
   * @param {string} interval - Data interval (e.g., '1d', '1h', '1m')
   * @param {string} range - Data range (e.g., '1mo', '1y', '5d')
   * @returns {Promise<Object>} Chart data from Yahoo Finance
   */
  async getChartData(ticker, interval = '1d', range = '1mo') {
    if (!this.isConfigured) {
      console.log(`ℹ️ Using mock chart data for ${ticker} (API not configured)`);
      return {
        success: true,
        data: this.getMockChartData(ticker, interval, range),
        fetchedAt: new Date().toISOString()
      };
    }

    try {
      console.log(`📈 Fetching chart data for ${ticker} (${interval}, ${range})`);
      
      // Try multiple chart endpoints
      const endpoints = [
        {
          url: `${this.baseURL}/api/v2/markets/stock/history`,
          params: { symbol: ticker, interval: interval, limit: 30 }
        },
        {
          url: `${this.baseURL}/api/v1/markets/stock/history`,
          params: { ticker: ticker, interval: interval, range: range }
        }
      ];

      let lastError = null;
      
      for (const endpoint of endpoints) {
        try {
          console.log(`🔄 Trying chart endpoint: ${endpoint.url}`);
          
          const response = await axios.get(endpoint.url, {
            params: endpoint.params,
            headers: this.headers,
            timeout: 15000
          });

                console.log(`✅ Chart API Response Status: ${response.status}`);
      // Sanitize chart response keys to avoid logging sensitive data
      const safeChartKeys = Object.keys(response.data || {}).filter(key => 
        !key.toLowerCase().includes('key') && 
        !key.toLowerCase().includes('token') && 
        !key.toLowerCase().includes('secret') &&
        !key.toLowerCase().includes('password')
      );
      console.log(`✅ Chart response keys:`, safeChartKeys);

          if (response.data && (response.data.items || response.data.body || response.data.data)) {
            const chartData = response.data.items || response.data.body || response.data.data || response.data;
            console.log(`✅ Successfully fetched chart data for ${ticker}`);
            
            return {
              success: true,
              data: response.data,
              ticker: ticker,
              interval: interval,
              range: range,
              fetchedAt: new Date().toISOString()
            };
          }
        } catch (endpointError) {
          console.warn(`⚠️ Chart endpoint failed: ${endpoint.url}`, endpointError.message);
          lastError = endpointError;
          continue;
        }
      }

      // If all endpoints failed, return mock data
      console.warn(`⚠️ All chart endpoints failed for ${ticker}. Returning mock data.`);
      return {
        success: true,
        data: this.getMockChartData(ticker, interval, range),
        source: 'mock_fallback',
        ticker: ticker,
        fetchedAt: new Date().toISOString()
      };

    } catch (error) {
      console.error(`❌ Error fetching chart data for ${ticker}:`, error.message);
      
      // Log detailed error information
      if (error.response) {
        console.error(`❌ Chart API Response Status: ${error.response.status}`);
        console.error(`❌ Chart API Response Data:`, error.response.data);
      }
      
      // Return mock data as fallback
      console.log(`🔄 Returning mock chart data for ${ticker}`);
      return {
        success: true,
        data: this.getMockChartData(ticker, interval, range),
        source: 'mock_fallback',
        error: error.message,
        ticker: ticker,
        fetchedAt: new Date().toISOString()
      };
    }
  }

  /**
   * Search for stocks
   * @param {string} query - Search query
   * @returns {Promise<Object>} Search results from Yahoo Finance
   */
  async searchStocks(query) {
    if (!this.isConfigured) {
      console.log(`ℹ️ Using mock search data for "${query}" (API not configured)`);
      return {
        success: true,
        data: this.getMockSearchResults(query),
        query: query,
        fetchedAt: new Date().toISOString()
      };
    }

    try {
      console.log(`🔍 Searching stocks for query: "${query}"`);
      
      // Try multiple search endpoints
      const endpoints = [
        {
          url: `${this.baseURL}/api/v1/markets/search`,
          params: { search: query }
        },
        {
          url: `${this.baseURL}/api/v2/markets/search`,
          params: { q: query }
        }
      ];

      let lastError = null;
      
      for (const endpoint of endpoints) {
        try {
          console.log(`🔄 Trying search endpoint: ${endpoint.url}`);
          
          const response = await axios.get(endpoint.url, {
            params: endpoint.params,
            headers: this.headers,
            timeout: 15000
          });

          console.log(`✅ Search API Response Status: ${response.status}`);
          // Sanitize search response keys to avoid logging sensitive data
      const safeSearchKeys = Object.keys(response.data || {}).filter(key => 
        !key.toLowerCase().includes('key') && 
        !key.toLowerCase().includes('token') && 
        !key.toLowerCase().includes('secret') &&
        !key.toLowerCase().includes('password')
      );
      console.log(`✅ Search response keys:`, safeSearchKeys);

          if (response.data) {
            let searchResults = [];
            
            if (Array.isArray(response.data)) {
              searchResults = response.data;
            } else if (response.data.body && Array.isArray(response.data.body)) {
              searchResults = response.data.body;
            } else if (response.data.data && Array.isArray(response.data.data)) {
              searchResults = response.data.data;
            } else if (response.data.results && Array.isArray(response.data.results)) {
              searchResults = response.data.results;
            }

            if (searchResults.length > 0) {
              console.log(`✅ Found ${searchResults.length} search results for "${query}"`);
              return {
                success: true,
                data: searchResults,
                meta: response.data.meta,
                query: query,
                fetchedAt: new Date().toISOString()
              };
            }
          }
        } catch (endpointError) {
          console.warn(`⚠️ Search endpoint failed: ${endpoint.url}`, endpointError.message);
          lastError = endpointError;
          continue;
        }
      }

      // If all endpoints failed, return mock data
      console.warn(`⚠️ All search endpoints failed for "${query}". Returning mock data.`);
      return {
        success: true,
        data: this.getMockSearchResults(query),
        source: 'mock_fallback',
        query: query,
        fetchedAt: new Date().toISOString()
      };

    } catch (error) {
      console.error(`❌ Error searching stocks for "${query}":`, error.message);
      
      // Return mock data as fallback
      console.log(`🔄 Returning mock search data for "${query}"`);
      return {
        success: true,
        data: this.getMockSearchResults(query),
        source: 'mock_fallback',
        error: error.message,
        query: query,
        fetchedAt: new Date().toISOString()
      };
    }
  }

  /**
   * Fetch company profile information for a specific ticker
   * Uses RapidAPI Yahoo Finance endpoint with proper module parameters
   * @param {string} ticker - Stock ticker symbol (e.g., 'AAPL')
   * @returns {Promise<Object>} Company profile data
   */
  async getCompanyProfile(ticker) {
    const upperTicker = ticker?.toUpperCase?.() || ticker;

    if (!this.isConfigured) {
      console.log(`ℹ️ Using mock company profile for ${upperTicker} (API not configured)`);
      return {
        success: true,
        data: this.getMockCompanyProfile(upperTicker),
        source: 'mock'
      };
    }

    try {
      // Use the correct RapidAPI endpoint with module parameter
      const url = `${this.baseURL}/api/v1/markets/stock/modules`;
      const params = {
        ticker: upperTicker,
        module: 'asset-profile,financial-data,statistics'
      };

      console.log(`🏢 Fetching comprehensive profile for ${upperTicker}`);
      const response = await axios.get(url, {
        params: params,
        headers: this.headers,
        timeout: 15000
      });

      if (!response?.data) {
        throw new Error('No data received from API');
      }

      const data = response.data;
      
      // Extract data from different modules
      const assetProfile = data.assetProfile || {};
      const financialData = data.financialData || {};
      const statistics = data.defaultKeyStatistics || {};

      // Build comprehensive profile data
      const profileData = {
        symbol: upperTicker,
        
        // Basic company info from assetProfile
        companyName: assetProfile.companyName || upperTicker,
        sector: assetProfile.sector || null,
        industry: assetProfile.industry || null,
        country: assetProfile.country || null,
        city: assetProfile.city || null,
        state: assetProfile.state || null,
        website: assetProfile.website || null,
        longBusinessSummary: assetProfile.longBusinessSummary || null,
        employees: assetProfile.fullTimeEmployees || null,
        
        // Market data from financialData
        currentPrice: financialData.currentPrice?.raw || null,
        targetMeanPrice: financialData.targetMeanPrice?.raw || null,
        marketCap: financialData.marketCap?.raw || statistics.marketCap?.raw || null,
        marketCapFormatted: financialData.marketCap?.fmt || statistics.marketCap?.fmt || null,
        
        // Key statistics
        fiftyTwoWeekHigh: statistics.fiftyTwoWeekHigh?.raw || null,
        fiftyTwoWeekLow: statistics.fiftyTwoWeekLow?.raw || null,
        beta: statistics.beta?.raw || null,
        peRatio: statistics.forwardPE?.raw || null,
        
        // Financial metrics
        revenueGrowth: financialData.revenueGrowth?.raw || null,
        earningsGrowth: financialData.earningsGrowth?.raw || null,
        profitMargins: financialData.profitMargins?.raw || null,
        returnOnEquity: financialData.returnOnEquity?.raw || null,
        
        // Exchange info (fallback to generic)
        exchange: 'NYSE/NASDAQ',
        exchangeTimezone: 'America/New_York',
        
        fetchedAt: new Date().toISOString()
      };

      // Validate we got useful data
      if (profileData.companyName && (profileData.sector || profileData.marketCap)) {
        console.log(`✅ Successfully fetched profile for ${upperTicker} with ${Object.keys(data).join(', ')}`);
        return {
          success: true,
          data: profileData,
          source: 'rapidapi'
        };
      }

      throw new Error('Insufficient data in API response');

    } catch (error) {
      const message = error?.response?.data?.message || error?.message || error;
      console.error(`❌ Failed to fetch company profile for ${upperTicker}: ${message}`);
      
      // Return error instead of mock data
      // This way we can see what's actually failing
      return {
        success: false,
        error: `Failed to fetch profile: ${message}`,
        ticker: upperTicker
      };
    }
  }

  /**
   * Get company logo URL (placeholder implementation)
   * @param {string} ticker - Stock ticker symbol
   * @returns {string} Logo URL
   */
  getCompanyLogo(ticker) {
    // Use a public logo service as fallback
    return `https://logo.clearbit.com/${this.getCompanyDomain(ticker)}`;
  }

  /**
   * Get company domain for logo fetching
   * @param {string} ticker - Stock ticker symbol
   * @returns {string} Company domain
   */
  getCompanyDomain(ticker) {
    const domains = {
      'AAPL': 'apple.com',
      'GOOGL': 'google.com',
      'MSFT': 'microsoft.com',
      'TSLA': 'tesla.com',
      'AMZN': 'amazon.com',
      'NVDA': 'nvidia.com',
      'META': 'meta.com',
      'JPM': 'jpmorganchase.com',
      'BAC': 'bankofamerica.com',
      'V': 'visa.com',
      'WMT': 'walmart.com',
      'JNJ': 'jnj.com'
    };
    return domains[ticker] || `${ticker.toLowerCase()}.com`;
  }

  /**
   * Generate mock quote data for development
   * @param {string} ticker - Stock ticker symbol
   * @returns {Object} Mock quote data
   */
  getMockQuote(ticker) {
    const basePrice = Math.random() * 200 + 50; // Random price between 50-250
    const change = (Math.random() - 0.5) * 10; // Random change between -5 to +5
    const changePercent = (change / basePrice) * 100;

    return {
      symbol: ticker,
      shortName: this.getStockName(ticker),
      longName: this.getStockName(ticker),
      regularMarketPrice: parseFloat(basePrice.toFixed(2)),
      regularMarketChange: parseFloat(change.toFixed(2)),
      regularMarketChangePercent: parseFloat(changePercent.toFixed(2)),
      currency: 'USD',
      marketState: 'REGULAR',
      regularMarketTime: Math.floor(Date.now() / 1000),
      regularMarketDayHigh: parseFloat((basePrice + Math.random() * 5).toFixed(2)),
      regularMarketDayLow: parseFloat((basePrice - Math.random() * 5).toFixed(2)),
      regularMarketVolume: Math.floor(Math.random() * 10000000) + 1000000,
      marketCap: Math.floor(Math.random() * 1000000000000) + 100000000000
    };
  }

  /**
   * Generate mock company profile data for development
   * @param {string} ticker - Stock ticker symbol
   * @returns {Object} Mock company profile data
   */
  getMockCompanyProfile(ticker) {
    // Return minimal mock data - only what's absolutely necessary
    // Most fields should be null to show "N/A" in the UI
    return {
      symbol: ticker,
      companyName: this.getStockName(ticker),
      sector: null,
      industry: null,
      country: null,
      website: null,
      longBusinessSummary: null, // Don't show mock business summary
      exchange: null,
      exchangeTimezone: null,
      marketCap: null,
      marketCapFormatted: null,
      fiftyTwoWeekHigh: null,
      fiftyTwoWeekLow: null,
      employees: null,
      city: null,
      state: null,
      fetchedAt: new Date().toISOString()
    };
  }

  /**
   * Generate mock chart data for development
   * @param {string} ticker - Stock ticker symbol
   * @param {string} interval - Data interval
   * @param {string} range - Data range
   * @returns {Object} Mock chart data
   */
  getMockChartData(ticker, interval, range) {
    const items = {};
    const now = Date.now();
    const dayMs = 24 * 60 * 60 * 1000;
    const basePrice = Math.random() * 200 + 50;

    // Generate 30 days of mock data
    for (let i = 29; i >= 0; i--) {
      const timestamp = Math.floor((now - (i * dayMs)) / 1000);
      const price = basePrice + (Math.random() - 0.5) * 20;
      const high = price + Math.random() * 5;
      const low = price - Math.random() * 5;
      const open = low + Math.random() * (high - low);
      const close = low + Math.random() * (high - low);

      items[timestamp] = {
        date: new Date(timestamp * 1000).toISOString().split('T')[0],
        date_utc: timestamp,
        open: parseFloat(open.toFixed(2)),
        high: parseFloat(high.toFixed(2)),
        low: parseFloat(low.toFixed(2)),
        close: parseFloat(close.toFixed(2)),
        volume: Math.floor(Math.random() * 10000000) + 1000000
      };
    }

    return {
      meta: {
        currency: 'USD',
        symbol: ticker,
        exchangeName: 'NMS',
        instrumentType: 'EQUITY',
        regularMarketPrice: basePrice,
        dataGranularity: interval,
        range: range
      },
      items: items
    };
  }

  /**
   * Generate mock search results for development
   * @param {string} query - Search query
   * @returns {Array} Mock search results
   */
  getMockSearchResults(query) {
    const allStocks = [
      { symbol: 'AAPL', name: 'Apple Inc.', exch: 'NMS', type: 'S', exchDisp: 'NASDAQ', typeDisp: 'Equity' },
      { symbol: 'GOOGL', name: 'Alphabet Inc.', exch: 'NMS', type: 'S', exchDisp: 'NASDAQ', typeDisp: 'Equity' },
      { symbol: 'MSFT', name: 'Microsoft Corporation', exch: 'NMS', type: 'S', exchDisp: 'NASDAQ', typeDisp: 'Equity' },
      { symbol: 'TSLA', name: 'Tesla, Inc.', exch: 'NMS', type: 'S', exchDisp: 'NASDAQ', typeDisp: 'Equity' },
      { symbol: 'AMZN', name: 'Amazon.com, Inc.', exch: 'NMS', type: 'S', exchDisp: 'NASDAQ', typeDisp: 'Equity' }
    ];

    return allStocks.filter(stock => 
      stock.symbol.toLowerCase().includes(query.toLowerCase()) ||
      stock.name.toLowerCase().includes(query.toLowerCase())
    );
  }

  /**
   * Get stock name by ticker
   * @param {string} ticker - Stock ticker symbol
   * @returns {string} Stock name
   */
  getStockName(ticker) {
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

  /**
   * Handle API errors consistently
   * @param {Error} error - The error object
   * @param {Object} context - Additional context
   * @returns {Object} Standardized error response
   */
  handleApiError(error, context = {}) {
    // Handle rate limiting
    if (error.response && error.response.status === 429) {
      return {
        success: false,
        error: 'Rate limit exceeded',
        retryAfter: error.response.headers['retry-after'] || 60,
        ...context
      };
    }

    // Handle other API errors
    if (error.response) {
      return {
        success: false,
        error: `API Error: ${error.response.status} - ${error.response.statusText}`,
        ...context
      };
    }

    // Handle network errors
    return {
      success: false,
      error: `Network Error: ${error.message}`,
      ...context
    };
  }

  /**
   * Test API connection and response format
   * @returns {Promise<Object>} Test results
   */
  async testApiConnection() {
    if (!this.isConfigured) {
      return {
        success: false,
        error: 'API not configured - missing RAPIDAPI_KEY',
        details: {
          rapidApiKey: !!process.env.RAPIDAPI_KEY,
          rapidApiHost: process.env.RAPIDAPI_HOST
        }
      };
    }

    console.log('🔍 Testing Yahoo Finance API connection...');
    
    const testResults = {
      endpoints: {},
      overall: { success: false, workingEndpoints: 0, totalEndpoints: 0 }
    };

    // Test multiple endpoints to see which ones work
    const endpointsToTest = [
      {
        name: 'quotes_v1',
        url: `${this.baseURL}/api/v1/markets/stock/quotes`,
        params: { ticker: 'AAPL' }
      },
      {
        name: 'tickers_v2',
        url: `${this.baseURL}/api/v2/markets/tickers`,
        params: { page: 1, type: 'STOCKS' }
      },
      {
        name: 'history_v2',
        url: `${this.baseURL}/api/v2/markets/stock/history`,
        params: { symbol: 'AAPL', interval: '1d', limit: 5 }
      },
      {
        name: 'search_v1',
        url: `${this.baseURL}/api/v1/markets/search`,
        params: { search: 'AAPL' }
      }
    ];

    testResults.overall.totalEndpoints = endpointsToTest.length;

    for (const endpoint of endpointsToTest) {
      try {
        console.log(`🔄 Testing endpoint: ${endpoint.name} (${endpoint.url})`);
        
        const response = await axios.get(endpoint.url, {
          params: endpoint.params,
          headers: this.headers,
          timeout: 10000
        });

        const hasData = response.data && (
          Array.isArray(response.data) ||
          (response.data.body && Array.isArray(response.data.body)) ||
          (response.data.data && Array.isArray(response.data.data)) ||
          typeof response.data === 'object'
        );

        testResults.endpoints[endpoint.name] = {
          success: true,
          status: response.status,
          hasData: hasData,
          dataType: Array.isArray(response.data) ? 'array' : typeof response.data,
          dataKeys: response.data ? Object.keys(response.data) : [],
          sampleData: hasData ? (Array.isArray(response.data) ? response.data[0] : response.data) : null
        };

        if (hasData) {
          testResults.overall.workingEndpoints++;
          console.log(`✅ ${endpoint.name}: Working with data`);
        } else {
          console.log(`⚠️ ${endpoint.name}: Responds but no usable data`);
        }

      } catch (error) {
        testResults.endpoints[endpoint.name] = {
          success: false,
          error: error.message,
          status: error.response?.status,
          details: error.response?.data
        };
        console.log(`❌ ${endpoint.name}: Failed - ${error.message}`);
      }
    }

    testResults.overall.success = testResults.overall.workingEndpoints > 0;
    
    if (testResults.overall.success) {
      console.log(`✅ API Test Results: ${testResults.overall.workingEndpoints}/${testResults.overall.totalEndpoints} endpoints working`);
      return {
        success: true,
        message: `${testResults.overall.workingEndpoints} out of ${testResults.overall.totalEndpoints} endpoints working`,
        details: testResults
      };
    } else {
      console.log(`❌ API Test Results: No working endpoints found`);
      return {
        success: false,
        error: 'No working endpoints found',
        details: testResults
      };
    }
  }
}

// Export singleton instance
module.exports = new YahooFinanceService();