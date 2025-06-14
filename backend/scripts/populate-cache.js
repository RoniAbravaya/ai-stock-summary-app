/**
 * Cache Population Script
 * Manually populate the Firebase cache with news data for testing
 */

const dotenv = require('dotenv');
const path = require('path');

// Load environment variables
dotenv.config({ path: path.join(__dirname, '../config.env') });

const schedulerService = require('../services/schedulerService');
const newsCacheService = require('../services/newsCacheService');
const firebaseService = require('../services/firebaseService');

async function populateCache() {
  console.log('🚀 Starting cache population...');
  console.log(`📊 Firebase initialized: ${firebaseService.isInitialized}`);
  
  if (!firebaseService.isInitialized) {
    console.warn('⚠️ Firebase is not initialized. Using memory cache for testing.');
    console.log('📝 To use Firebase cache, configure these environment variables:');
    console.log('- FIREBASE_PROJECT_ID');
    console.log('- FIREBASE_DATABASE_URL');
    console.log('- FIREBASE_CLIENT_EMAIL');
    console.log('- FIREBASE_PRIVATE_KEY');
    console.log('\n🔄 Continuing with memory cache...\n');
  }

  try {
    // Get cache stats before population
    console.log('\n📊 Cache stats before population:');
    const statsBefore = await newsCacheService.getCacheStats();
    console.log(`Cached tickers: ${statsBefore.stats?.cachedTickers || 0}/${statsBefore.stats?.totalTickers || 0}`);
    console.log(`Total articles: ${statsBefore.stats?.totalArticles || 0}`);

    // Manually trigger news refresh for all tickers
    console.log('\n🔄 Triggering manual news refresh...');
    const refreshResult = await schedulerService.refreshAllTickersNews();
    
    console.log('\n✅ Cache population completed!');
    console.log(`Summary: ${refreshResult.summary}`);
    console.log(`Duration: ${refreshResult.durationSeconds} seconds`);
    console.log(`Successful tickers: ${refreshResult.successfulTickers}/${refreshResult.totalTickers}`);

    // Get cache stats after population
    console.log('\n📊 Cache stats after population:');
    const statsAfter = await newsCacheService.getCacheStats();
    console.log(`Cached tickers: ${statsAfter.stats?.cachedTickers || 0}/${statsAfter.stats?.totalTickers || 0}`);
    console.log(`Total articles: ${statsAfter.stats?.totalArticles || 0}`);

    // Show some sample data
    if (refreshResult.successfulTickers > 0) {
      console.log('\n📰 Sample cached data:');
      const sampleTickers = ['AAPL', 'GOOGL', 'MSFT'].slice(0, 2);
      const sampleData = await newsCacheService.getNewsForTickers(sampleTickers);
      
      for (const ticker of sampleTickers) {
        const tickerData = sampleData.results[ticker];
        if (tickerData && tickerData.success) {
          console.log(`${ticker}: ${tickerData.totalArticles} articles (last updated: ${tickerData.lastUpdated})`);
        }
      }
    }

    console.log('\n🎉 Cache population script completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error during cache population:', error.message);
    console.error(error);
    process.exit(1);
  }
}

// Run the script
populateCache(); 