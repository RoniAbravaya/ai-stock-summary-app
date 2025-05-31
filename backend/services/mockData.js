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
    id: 'AAPL',
    stockSymbol: 'AAPL',
    summary: {
      en: 'Apple Inc. is showing strong performance with recent iPhone sales exceeding expectations. The company\'s services segment continues to grow, providing recurring revenue. However, concerns about supply chain disruptions in Asia may impact Q1 2024. Overall sentiment: BULLISH. Key factors: strong brand loyalty, expanding services ecosystem, and robust cash flow generation.',
      es: 'Apple Inc. muestra un rendimiento sólido con las ventas recientes de iPhone superando las expectativas. El segmento de servicios de la empresa continúa creciendo, proporcionando ingresos recurrentes. Sin embargo, las preocupaciones sobre las interrupciones de la cadena de suministro en Asia pueden afectar el Q1 2024.',
      fr: 'Apple Inc. affiche de solides performances avec les ventes récentes d\'iPhone dépassant les attentes. Le segment des services de l\'entreprise continue de croître, fournissant des revenus récurrents.'
    },
    sentiment: 'BULLISH',
    confidence: 85,
    keyPoints: [
      'Strong iPhone 15 sales momentum',
      'Services revenue growing at 15% YoY',
      'Supply chain resilience improving',
      'Strong cash position for acquisitions'
    ],
    riskFactors: [
      'China market regulatory uncertainties',
      'Competition in smartphone market',
      'Currency exchange rate impacts'
    ],
    priceTarget: 210.00,
    analystRating: 'BUY',
    lastUpdated: new Date().toISOString(),
    language: 'en'
  },
  'TSLA': {
    id: 'TSLA',
    stockSymbol: 'TSLA',
    summary: {
      en: 'Tesla continues to lead the EV market with strong delivery numbers and expanding manufacturing capacity. The Cybertruck launch is generating significant interest. Energy storage and solar business showing promising growth. However, increased competition and potential margin pressure remain concerns. Overall sentiment: BULLISH with caution on valuation.',
      es: 'Tesla continúa liderando el mercado de vehículos eléctricos con sólidos números de entrega y capacidad de fabricación en expansión. El lanzamiento de Cybertruck está generando un interés significativo.',
      fr: 'Tesla continue de dominer le marché des véhicules électriques avec de solides chiffres de livraison et une capacité de fabrication en expansion.'
    },
    sentiment: 'BULLISH',
    confidence: 78,
    keyPoints: [
      'Record quarterly deliveries',
      'Cybertruck production ramping up',
      'Energy business growth acceleration',
      'Full Self-Driving progress'
    ],
    riskFactors: [
      'Increased EV competition',
      'Regulatory challenges',
      'Production scaling risks'
    ],
    priceTarget: 280.00,
    analystRating: 'HOLD',
    lastUpdated: new Date().toISOString(),
    language: 'en'
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

module.exports = {
  getMockStocks,
  getMockNews,
  getMockSummary,
  getMockUsers,
  getMockUser,
  mockStocks,
  mockNews,
  mockSummaries,
  mockUsers
}; 