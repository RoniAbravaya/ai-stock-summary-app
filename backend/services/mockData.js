/**
 * Mock Data Service
 * Generates realistic mock data for testing the AI Stock Summary app
 */

const mockStocks = [
  {
    id: 'AAPL',
    symbol: 'AAPL',
    name: 'Apple Inc.',
    price: 193.45,
    change: 2.34,
    changePercent: 1.22,
    volume: 45234567,
    marketCap: 3000000000000,
    pe: 28.5,
    sector: 'Technology',
    isFavorite: true,
    logo: 'https://logo.clearbit.com/apple.com'
  },
  {
    id: 'GOOGL',
    symbol: 'GOOGL',
    name: 'Alphabet Inc.',
    price: 2754.32,
    change: -12.45,
    changePercent: -0.45,
    volume: 1234567,
    marketCap: 1800000000000,
    pe: 23.4,
    sector: 'Technology',
    isFavorite: false,
    logo: 'https://logo.clearbit.com/google.com'
  },
  {
    id: 'MSFT',
    symbol: 'MSFT',
    name: 'Microsoft Corporation',
    price: 415.23,
    change: 5.67,
    changePercent: 1.38,
    volume: 23456789,
    marketCap: 3100000000000,
    pe: 31.2,
    sector: 'Technology',
    isFavorite: true,
    logo: 'https://logo.clearbit.com/microsoft.com'
  },
  {
    id: 'TSLA',
    symbol: 'TSLA',
    name: 'Tesla, Inc.',
    price: 234.56,
    change: 15.43,
    changePercent: 7.03,
    volume: 98765432,
    marketCap: 750000000000,
    pe: 45.7,
    sector: 'Automotive',
    isFavorite: true,
    logo: 'https://logo.clearbit.com/tesla.com'
  },
  {
    id: 'AMZN',
    symbol: 'AMZN',
    name: 'Amazon.com, Inc.',
    price: 3456.78,
    change: -23.45,
    changePercent: -0.67,
    volume: 3456789,
    marketCap: 1750000000000,
    pe: 52.3,
    sector: 'Consumer Discretionary',
    isFavorite: false,
    logo: 'https://logo.clearbit.com/amazon.com'
  }
];

const mockNews = [
  {
    id: '1',
    title: 'Apple Reports Strong Q4 Earnings Despite Market Challenges',
    summary: 'Apple Inc. exceeded expectations with robust iPhone sales and services revenue growth.',
    content: 'Apple Inc. today announced financial results for its fiscal 2024 fourth quarter...',
    source: 'Reuters',
    publishedAt: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(), // 2 hours ago
    url: 'https://example.com/news/apple-earnings',
    imageUrl: 'https://via.placeholder.com/400x200/007ACC/FFFFFF?text=Apple+News',
    relatedStocks: ['AAPL']
  },
  {
    id: '2',
    title: 'Tesla Announces New Gigafactory in Southeast Asia',
    summary: 'The electric vehicle manufacturer plans to expand production capacity with a new facility.',
    content: 'Tesla Inc. has announced plans to build a new Gigafactory in Southeast Asia...',
    source: 'Bloomberg',
    publishedAt: new Date(Date.now() - 4 * 60 * 60 * 1000).toISOString(), // 4 hours ago
    url: 'https://example.com/news/tesla-gigafactory',
    imageUrl: 'https://via.placeholder.com/400x200/CC0000/FFFFFF?text=Tesla+News',
    relatedStocks: ['TSLA']
  },
  {
    id: '3',
    title: 'Microsoft Azure Cloud Revenue Surges 30% Year-over-Year',
    summary: 'Cloud computing division continues to drive growth for the tech giant.',
    content: 'Microsoft Corporation reported impressive growth in its Azure cloud platform...',
    source: 'TechCrunch',
    publishedAt: new Date(Date.now() - 6 * 60 * 60 * 1000).toISOString(), // 6 hours ago
    url: 'https://example.com/news/microsoft-azure',
    imageUrl: 'https://via.placeholder.com/400x200/0078D4/FFFFFF?text=Microsoft+News',
    relatedStocks: ['MSFT']
  },
  {
    id: '4',
    title: 'Federal Reserve Signals Potential Interest Rate Adjustments',
    summary: 'Markets react to Fed Chairman\'s comments on monetary policy outlook.',
    content: 'The Federal Reserve Chairman indicated potential adjustments to interest rates...',
    source: 'Wall Street Journal',
    publishedAt: new Date(Date.now() - 8 * 60 * 60 * 1000).toISOString(), // 8 hours ago
    url: 'https://example.com/news/fed-rates',
    imageUrl: 'https://via.placeholder.com/400x200/008000/FFFFFF?text=Fed+News',
    relatedStocks: ['AAPL', 'GOOGL', 'MSFT', 'TSLA', 'AMZN']
  }
];

const mockSummaries = {
  'AAPL': {
    title: 'Apple Inc. (AAPL) - AI Analysis',
    summary: 'Apple continues to show strong fundamentals with robust iPhone sales and growing services revenue. The company\'s move into AI and machine learning presents significant opportunities for future growth. Recent price movements suggest bullish sentiment among investors.',
    sentiment: 'bullish',
    keyPoints: [
      'Strong iPhone sales in Q4',
      'Services revenue up 16% YoY',
      'AI integration driving innovation',
      'Strong balance sheet with $29B cash'
    ],
    riskFactors: [
      'Regulatory scrutiny in EU',
      'Supply chain challenges',
      'Market saturation concerns'
    ],
    recommendation: 'BUY',
    targetPrice: 210.00,
    confidenceScore: 0.87
  },
  'GOOGL': {
    title: 'Alphabet Inc. (GOOGL) - AI Analysis',
    summary: 'Google\'s dominance in search and growing cloud business position it well for future growth. AI investments through Gemini and Bard show promise, though competition from Microsoft and OpenAI intensifies.',
    sentiment: 'bullish',
    keyPoints: [
      'Search revenue remains strong',
      'Cloud growth accelerating',
      'AI investments showing results',
      'YouTube advertising recovery'
    ],
    riskFactors: [
      'Regulatory pressures',
      'AI competition intensifying',
      'Economic slowdown impact on ads'
    ],
    recommendation: 'HOLD',
    targetPrice: 2800.00,
    confidenceScore: 0.82
  }
};

const mockUsers = [
  {
    id: 'user1',
    email: 'john.doe@example.com',
    name: 'John Doe',
    role: 'user',
    subscriptionType: 'free',
    summariesUsed: 3,
    summariesLimit: 10,
    lastResetDate: new Date().toISOString(),
    favoriteStocks: ['AAPL', 'TSLA'],
    createdAt: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString() // 30 days ago
  },
  {
    id: 'admin1',
    email: 'admin@example.com',
    name: 'Admin User',
    role: 'admin',
    subscriptionType: 'premium',
    summariesUsed: 25,
    summariesLimit: 100,
    lastResetDate: new Date().toISOString(),
    favoriteStocks: ['AAPL', 'GOOGL', 'MSFT'],
    createdAt: new Date(Date.now() - 90 * 24 * 60 * 60 * 1000).toISOString() // 90 days ago
  }
];

// Helper functions
function getMockStocks() {
  return {
    success: true,
    data: mockStocks,
    totalCount: mockStocks.length,
    timestamp: new Date().toISOString()
  };
}

function getMockNews() {
  return {
    success: true,
    data: mockNews,
    totalCount: mockNews.length,
    timestamp: new Date().toISOString()
  };
}

function getMockSummary(stockId) {
  const summary = mockSummaries[stockId];
  if (!summary) {
    return {
      success: false,
      error: 'Summary not found for this stock',
      stockId: stockId
    };
  }

  return {
    success: true,
    data: summary,
    timestamp: new Date().toISOString()
  };
}

function getMockUsers() {
  return {
    success: true,
    data: mockUsers,
    totalCount: mockUsers.length,
    timestamp: new Date().toISOString()
  };
}

function getMockUser(userId) {
  const user = mockUsers.find(u => u.id === userId);
  if (!user) {
    return {
      success: false,
      error: 'User not found'
    };
  }

  return {
    success: true,
    data: user,
    timestamp: new Date().toISOString()
  };
}

// Additional methods
const getAllStocks = () => {
  return mockStocks;
};

const getTrendingStocks = () => {
  return mockStocks
    .filter(stock => Math.abs(stock.changePercent) > 2)
    .sort((a, b) => Math.abs(b.changePercent) - Math.abs(a.changePercent))
    .slice(0, 10);
};

const getStockById = (id) => {
  return mockStocks.find(stock => stock.id === id || stock.symbol === id);
};

const getAllNews = () => {
  return mockNews;
};

const getNewsByStock = (stockId) => {
  return mockNews.filter(news => 
    news.relatedStocks.includes(stockId) || 
    news.title.toLowerCase().includes(stockId.toLowerCase())
  );
};

const generateAISummary = (stockId) => {
  // Return existing summary or generate a new one
  if (mockSummaries[stockId]) {
    return {
      stockId,
      ...mockSummaries[stockId],
      generatedAt: new Date().toISOString(),
      language: 'en'
    };
  }

  // Generate a generic summary for unknown stocks
  const stock = getStockById(stockId);
  if (!stock) {
    throw new Error('Stock not found');
  }

  return {
    stockId,
    title: `${stock.name} (${stock.symbol}) - AI Analysis`,
    summary: `${stock.name} is currently trading at $${stock.price} with a ${stock.changePercent > 0 ? 'positive' : 'negative'} momentum of ${stock.changePercent}%. Based on current market conditions and technical analysis, the stock shows ${stock.changePercent > 2 ? 'strong bullish' : stock.changePercent < -2 ? 'bearish' : 'mixed'} signals.`,
    sentiment: stock.changePercent > 1 ? 'bullish' : stock.changePercent < -1 ? 'bearish' : 'neutral',
    keyPoints: [
      `Current price: $${stock.price}`,
      `Daily change: ${stock.changePercent}%`,
      `Market cap: $${(stock.marketCap / 1e9).toFixed(1)}B`,
      `P/E ratio: ${stock.pe}`
    ],
    riskFactors: [
      'Market volatility',
      'Economic uncertainty',
      'Sector-specific risks'
    ],
    recommendation: stock.changePercent > 2 ? 'BUY' : stock.changePercent < -2 ? 'SELL' : 'HOLD',
    targetPrice: stock.price * (1 + (stock.changePercent / 100) * 0.5),
    confidenceScore: 0.75,
    generatedAt: new Date().toISOString(),
    language: 'en'
  };
};

module.exports = {
  getAllStocks,
  getTrendingStocks,
  getStockById,
  getAllNews,
  getNewsByStock,
  generateAISummary,
  // Legacy methods for backward compatibility
  getMockStocks: getAllStocks,
  getMockNews: getAllNews,
  getMockSummary: generateAISummary,
  getMockUsers,
  getMockUser,
  mockStocks,
  mockNews,
  mockSummaries,
  mockUsers
}; 