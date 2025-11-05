/**
 * Stock Profile Cache Service
 * Handles Firestore-based caching for stock company profiles
 * Caches data for 24 hours and provides scheduled refresh
 */

const firebaseService = require('./firebaseService');
const yahooFinanceService = require('./yahooFinanceService');

class StockProfileCacheService {
  constructor() {
    this.cacheExpiryMs = 24 * 60 * 60 * 1000; // 24 hours
    this.collectionName = 'stockProfiles';
  }

  /**
   * Get Firestore collection reference
   */
  get collection() {
    return firebaseService.firestore.collection(this.collectionName);
  }

  /**
   * Check if cached profile is still valid (within 24 hours)
   * @param {number} cachedAt - Timestamp when profile was cached
   * @returns {boolean}
   */
  isCacheValid(cachedAt) {
    if (!cachedAt) return false;
    const age = Date.now() - cachedAt;
    return age < this.cacheExpiryMs;
  }

  /**
   * Get stock profile with Firestore caching
   * @param {string} ticker - Stock ticker symbol
   * @returns {Promise<Object>} Profile data with metadata
   */
  async getProfile(ticker) {
    const upperTicker = ticker.toUpperCase();
    
    try {
      // 1. Try to get from Firestore cache first
      console.log(`🔍 Checking Firestore cache for ${upperTicker} profile`);
      const docRef = this.collection.doc(upperTicker);
      const doc = await docRef.get();

      if (doc.exists) {
        const cachedData = doc.data();
        
        if (this.isCacheValid(cachedData.cachedAt)) {
          console.log(`✅ Using cached profile for ${upperTicker} (age: ${Math.round((Date.now() - cachedData.cachedAt) / 1000 / 60)}m)`);
          return {
            success: true,
            data: cachedData.profile,
            source: 'firestore_cache',
            ticker: upperTicker,
            cachedAt: cachedData.cachedAt
          };
        } else {
          console.log(`⏰ Cache expired for ${upperTicker}, fetching fresh data`);
        }
      } else {
        console.log(`📭 No cache found for ${upperTicker}, fetching from API`);
      }

      // 2. Fetch fresh data from API
      const apiResult = await yahooFinanceService.getCompanyProfile(upperTicker);

      if (!apiResult.success) {
        // If API fails and we have stale cache, return it
        if (doc.exists) {
          const staleData = doc.data();
          console.log(`⚠️ API failed, using stale cache for ${upperTicker}`);
          return {
            success: true,
            data: staleData.profile,
            source: 'stale_firestore_cache',
            ticker: upperTicker,
            warning: 'Using expired cache due to API failure'
          };
        }

        return {
          success: false,
          error: apiResult.error || 'Failed to fetch profile',
          ticker: upperTicker
        };
      }

      // 3. Cache the fresh data in Firestore
      const cacheData = {
        ticker: upperTicker,
        profile: apiResult.data,
        cachedAt: Date.now(),
        source: apiResult.source,
        updatedAt: firebaseService.FieldValue.serverTimestamp()
      };

      await docRef.set(cacheData, { merge: true });
      console.log(`💾 Cached profile for ${upperTicker} in Firestore`);

      return {
        success: true,
        data: apiResult.data,
        source: apiResult.source,
        ticker: upperTicker,
        cachedAt: cacheData.cachedAt
      };

    } catch (error) {
      console.error(`❌ Error in getProfile for ${upperTicker}:`, error.message);
      
      // Try to return any cached data as last resort
      try {
        const docRef = this.collection.doc(upperTicker);
        const doc = await docRef.get();
        if (doc.exists) {
          const emergencyData = doc.data();
          console.log(`🚨 Error fallback: using any cached data for ${upperTicker}`);
          return {
            success: true,
            data: emergencyData.profile,
            source: 'emergency_cache',
            ticker: upperTicker,
            warning: 'Using cached data due to error'
          };
        }
      } catch (cacheError) {
        console.error(`❌ Cache fallback also failed:`, cacheError.message);
      }

      return {
        success: false,
        error: error.message,
        ticker: upperTicker
      };
    }
  }

  /**
   * Refresh profile data for a specific ticker (force refresh)
   * @param {string} ticker - Stock ticker symbol
   * @returns {Promise<Object>}
   */
  async refreshProfile(ticker) {
    const upperTicker = ticker.toUpperCase();
    console.log(`🔄 Force refreshing profile for ${upperTicker}`);

    const apiResult = await yahooFinanceService.getCompanyProfile(upperTicker);

    if (apiResult.success) {
      const cacheData = {
        ticker: upperTicker,
        profile: apiResult.data,
        cachedAt: Date.now(),
        source: apiResult.source,
        updatedAt: firebaseService.FieldValue.serverTimestamp()
      };

      await this.collection.doc(upperTicker).set(cacheData, { merge: true });
      console.log(`✅ Refreshed and cached profile for ${upperTicker}`);

      return {
        success: true,
        data: apiResult.data,
        source: 'refreshed',
        ticker: upperTicker
      };
    }

    return apiResult;
  }

  /**
   * Batch refresh profiles for multiple tickers
   * Used by scheduler to refresh popular stocks
   * @param {Array<string>} tickers - Array of ticker symbols
   * @returns {Promise<Object>} Summary of refresh operation
   */
  async batchRefreshProfiles(tickers) {
    console.log(`🔄 Batch refreshing ${tickers.length} stock profiles`);
    
    const results = {
      total: tickers.length,
      successful: 0,
      failed: 0,
      errors: []
    };

    for (const ticker of tickers) {
      try {
        const result = await this.refreshProfile(ticker);
        if (result.success) {
          results.successful++;
        } else {
          results.failed++;
          results.errors.push({ ticker, error: result.error });
        }
        
        // Small delay to avoid rate limiting
        await new Promise(resolve => setTimeout(resolve, 100));
      } catch (error) {
        results.failed++;
        results.errors.push({ ticker, error: error.message });
      }
    }

    console.log(`✅ Batch refresh complete:`, results);
    return results;
  }

  /**
   * Get all cached profiles (for admin/debugging)
   * @returns {Promise<Array>} Array of cached profiles
   */
  async getAllCachedProfiles() {
    try {
      const snapshot = await this.collection.get();
      return snapshot.docs.map(doc => ({
        ticker: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      console.error('❌ Error getting all cached profiles:', error.message);
      return [];
    }
  }

  /**
   * Delete expired cache entries
   * @returns {Promise<number>} Number of deleted entries
   */
  async cleanExpiredCache() {
    try {
      const snapshot = await this.collection.get();
      const expiredDocs = [];
      const cutoffTime = Date.now() - (30 * 24 * 60 * 60 * 1000); // 30 days

      snapshot.forEach(doc => {
        const data = doc.data();
        if (data.cachedAt && data.cachedAt < cutoffTime) {
          expiredDocs.push(doc.id);
        }
      });

      // Delete expired docs in batches
      const batch = firebaseService.firestore.batch();
      expiredDocs.forEach(ticker => {
        batch.delete(this.collection.doc(ticker));
      });

      await batch.commit();
      console.log(`🗑️ Cleaned ${expiredDocs.length} expired profile cache entries`);
      
      return expiredDocs.length;
    } catch (error) {
      console.error('❌ Error cleaning expired cache:', error.message);
      return 0;
    }
  }
}

module.exports = new StockProfileCacheService();

