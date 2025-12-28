/// Subscription Service
/// Handles in-app purchases, ad rewards, and subscription management
/// Updated for App Store Guideline 2.1 compliance - IAP products must be complete and validated
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../models/subscription_model.dart';
import './supabase_service.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final SupabaseService _supabase = SupabaseService();
  final InAppPurchase _iap = InAppPurchase.instance;

  // Premium subscription product IDs
  // IMPORTANT: These must match exactly with product IDs configured in App Store Connect
  // Before App Store submission, verify these IDs exist in App Store Connect
  static const String premiumMonthlyId = 'premium_monthly_subscription';
  static const String premiumYearlyId = 'premium_yearly_subscription';

  // Track available products after validation
  Map<String, ProductDetails> _availableProducts = {};
  bool _productsValidated = false;
  String? _productValidationError;

  // Test Ad Unit IDs (Google's official test IDs - safe for development)
  static const String _testRewardedAdUnitIdAndroid = 'ca-app-pub-3940256099942544/5224354917';
  static const String _testRewardedAdUnitIdIOS = 'ca-app-pub-3940256099942544/1712485313';
  
  // Production Ad Unit IDs (replace with actual IDs before release)
  // TODO: Replace with production AdMob IDs before App Store submission
  static const String _prodRewardedAdUnitIdAndroid = 'ca-app-pub-your-publisher-id/your-unit-id';
  static const String _prodRewardedAdUnitIdIOS = 'ca-app-pub-your-publisher-id/your-unit-id';

  // Get appropriate ad unit ID based on environment
  static String get rewardedAdUnitId {
    // Use test IDs in debug mode, production IDs in release
    if (kDebugMode) {
      return Platform.isAndroid ? _testRewardedAdUnitIdAndroid : _testRewardedAdUnitIdIOS;
    }
    return Platform.isAndroid ? _prodRewardedAdUnitIdAndroid : _prodRewardedAdUnitIdIOS;
  }

  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoaded = false;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // Initialize services
  Future<void> initialize() async {
    try {
      // Initialize Google Mobile Ads
      await MobileAds.instance.initialize();

      // Initialize In-App Purchase
      final bool available = await _iap.isAvailable();
      if (!available) {
        debugPrint('In-App Purchase not available');
        _productValidationError = 'In-App Purchase not available on this device';
        return;
      }

      // Validate and load product details (Guideline 2.1 compliance)
      await _validateProducts();

      // Listen to purchase updates
      final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
      _subscription = purchaseUpdated.listen((purchaseDetailsList) {
        _handlePurchaseUpdate(purchaseDetailsList);
      }, onDone: () {
        _subscription?.cancel();
      }, onError: (error) {
        debugPrint('Purchase stream error: $error');
      });

      // Load rewarded ad
      _loadRewardedAd();
    } catch (e) {
      debugPrint('SubscriptionService initialization error: $e');
    }
  }

  /// Validates that all IAP products are properly configured in App Store Connect
  /// Required for App Store Guideline 2.1 - products must be complete and reviewable
  Future<void> _validateProducts() async {
    try {
      final Set<String> productIds = {premiumMonthlyId, premiumYearlyId};
      final ProductDetailsResponse response = await _iap.queryProductDetails(productIds);

      // Check for missing products
      if (response.notFoundIDs.isNotEmpty) {
        _productValidationError = 'Products not found in store: ${response.notFoundIDs.join(", ")}';
        debugPrint('IAP WARNING: $_productValidationError');
        debugPrint('Please ensure these product IDs are configured in App Store Connect:');
        for (final id in response.notFoundIDs) {
          debugPrint('  - $id');
        }
      }

      // Store available products for later use
      for (final product in response.productDetails) {
        _availableProducts[product.id] = product;
        debugPrint('IAP Product loaded: ${product.id} - ${product.title} (${product.price})');
      }

      _productsValidated = true;
      
      if (response.error != null) {
        _productValidationError = 'Error loading products: ${response.error!.message}';
        debugPrint('IAP Error: $_productValidationError');
      }
    } catch (e) {
      _productValidationError = 'Failed to validate products: $e';
      debugPrint('IAP Validation Error: $_productValidationError');
    }
  }

  /// Check if products are available for purchase
  bool get areProductsAvailable => _productsValidated && _availableProducts.isNotEmpty;

  /// Get product validation error if any
  String? get productValidationError => _productValidationError;

  /// Get available product details
  ProductDetails? getProductDetails(String productId) => _availableProducts[productId];

  // Get current user subscription
  Future<SubscriptionModel?> getUserSubscription() async {
    try {
      final user = _supabase.client.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase.client
          .from('user_subscriptions')
          .select()
          .eq('user_id', user.id)
          .single();

      return SubscriptionModel.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
      return null;
    }
  }

  // Check if user can generate summary
  Future<bool> canGenerateSummary() async {
    try {
      final subscription = await getUserSubscription();
      if (subscription == null) return false;

      return subscription.canGenerateSummary;
    } catch (e) {
      debugPrint('Error checking summary generation: $e');
      return false;
    }
  }

  // Get remaining summaries
  Future<int> getRemainingSummaries() async {
    try {
      final subscription = await getUserSubscription();
      return subscription?.remainingSummaries ?? 0;
    } catch (e) {
      debugPrint('Error getting remaining summaries: $e');
      return 0;
    }
  }

  // Load rewarded ad
  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdLoaded = true;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
              _isRewardedAdLoaded = false;
              _loadRewardedAd(); // Load next ad
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _rewardedAd = null;
              _isRewardedAdLoaded = false;
              debugPrint('Rewarded ad failed to show: $error');
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isRewardedAdLoaded = false;
          debugPrint('Rewarded ad failed to load: $error');
          // Retry loading after delay
          Future.delayed(const Duration(seconds: 30), () {
            _loadRewardedAd();
          });
        },
      ),
    );
  }

  // Show rewarded ad and earn summary credit
  Future<bool> showRewardedAd() async {
    if (!_isRewardedAdLoaded || _rewardedAd == null) {
      return false;
    }

    bool adCompleted = false;

    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) async {
        // User earned reward - grant summary credit
        await _grantAdReward(reward.amount.toInt());
        adCompleted = true;
      },
    );

    return adCompleted;
  }

  // Grant ad reward and update usage
  Future<void> _grantAdReward(int rewardAmount) async {
    try {
      final user = _supabase.client.auth.currentUser;
      if (user == null) return;

      // Record ad interaction
      await _supabase.client.from('ad_interactions').insert({
        'user_id': user.id,
        'ad_type': 'rewarded_video',
        'ad_unit_id': rewardedAdUnitId,
        'reward_earned': true,
        'reward_amount': rewardAmount,
        'session_id': DateTime.now().millisecondsSinceEpoch.toString(),
      });

      // Increase monthly limit by reward amount
      await _supabase.client.from('user_subscriptions').update({
        'monthly_summary_limit':
            'monthly_summary_limit + $rewardAmount'.toString(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', user.id);
    } catch (e) {
      debugPrint('Error granting ad reward: $e');
    }
  }

  /// Purchase premium subscription
  /// Uses pre-validated products for App Store Guideline 2.1 compliance
  Future<PurchaseResult> purchasePremium({required bool isYearly}) async {
    try {
      final String productId = isYearly ? premiumYearlyId : premiumMonthlyId;

      // Check if products were validated during initialization
      if (!_productsValidated) {
        await _validateProducts();
      }

      // Use cached product details if available
      ProductDetails? productDetails = _availableProducts[productId];
      
      if (productDetails == null) {
        // Fallback: try to fetch product details directly
        final ProductDetailsResponse response =
            await _iap.queryProductDetails({productId});

        if (response.notFoundIDs.isNotEmpty) {
          debugPrint('Product not found: $productId');
          return PurchaseResult(
            success: false,
            error: 'Subscription product not available. Please try again later.',
            errorCode: PurchaseErrorCode.productNotFound,
          );
        }

        if (response.productDetails.isEmpty) {
          return PurchaseResult(
            success: false,
            error: 'Unable to load subscription details.',
            errorCode: PurchaseErrorCode.productNotFound,
          );
        }

        productDetails = response.productDetails.first;
        _availableProducts[productId] = productDetails;
      }

      final purchaseParam = PurchaseParam(productDetails: productDetails);
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      return PurchaseResult(success: true);
    } catch (e) {
      debugPrint('Purchase error: $e');
      return PurchaseResult(
        success: false,
        error: 'Purchase failed. Please try again.',
        errorCode: PurchaseErrorCode.unknown,
      );
    }
  }

  // Handle purchase updates
  void _handlePurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        _processPurchase(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        debugPrint('Purchase error: ${purchaseDetails.error}');
      }

      if (purchaseDetails.pendingCompletePurchase) {
        _iap.completePurchase(purchaseDetails);
      }
    }
  }

  // Process successful purchase
  Future<void> _processPurchase(PurchaseDetails purchaseDetails) async {
    try {
      final user = _supabase.client.auth.currentUser;
      if (user == null) return;

      final bool isYearly = purchaseDetails.productID == premiumYearlyId;
      final DateTime endDate = isYearly
          ? DateTime.now().add(const Duration(days: 365))
          : DateTime.now().add(const Duration(days: 30));

      // Update subscription to premium
      await _supabase.client.from('user_subscriptions').update({
        'tier': 'premium',
        'status': 'active',
        'monthly_summary_limit': 100,
        'subscription_end_date': endDate.toIso8601String(),
        'auto_renew': true,
        'purchase_receipt':
            purchaseDetails.verificationData.serverVerificationData,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', user.id);
    } catch (e) {
      debugPrint('Error processing purchase: $e');
    }
  }

  // Restore purchases
  Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('Restore purchases error: $e');
    }
  }

  // Get subscription usage stats
  Future<Map<String, dynamic>> getUsageStats() async {
    try {
      final user = _supabase.client.auth.currentUser;
      if (user == null) return {};

      final subscription = await getUserSubscription();
      if (subscription == null) return {};

      // Get this month's usage
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month);

      final usageResponse = await _supabase.client
          .from('ai_summary_usage')
          .select()
          .eq('user_id', user.id)
          .gte('usage_month', currentMonth.toIso8601String())
          .count();

      // Get ad interactions this month
      final adResponse = await _supabase.client
          .from('ad_interactions')
          .select()
          .eq('user_id', user.id)
          .eq('reward_earned', true)
          .gte('interaction_date', currentMonth.toIso8601String())
          .count();

      return {
        'total_usage': subscription.currentMonthUsage,
        'usage_limit': subscription.monthlySummaryLimit,
        'remaining': subscription.remainingSummaries,
        'ads_watched': adResponse.count ?? 0,
        'usage_percentage': subscription.usagePercentage,
        'days_until_reset': subscription.daysUntilReset,
        'is_premium': subscription.isPremium,
      };
    } catch (e) {
      debugPrint('Error getting usage stats: $e');
      return {};
    }
  }

  // Check if user can watch ad today
  Future<bool> canWatchAdToday() async {
    try {
      final user = _supabase.client.auth.currentUser;
      if (user == null) return false;

      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      final response = await _supabase.client
          .from('ad_interactions')
          .select()
          .eq('user_id', user.id)
          .eq('ad_type', 'rewarded_video')
          .eq('reward_earned', true)
          .gte('interaction_date', todayStart.toIso8601String())
          .count();

      // Allow one ad per day
      return (response.count ?? 0) == 0;
    } catch (e) {
      debugPrint('Error checking ad availability: $e');
      return false;
    }
  }

  // Cleanup
  void dispose() {
    _rewardedAd?.dispose();
    _subscription?.cancel();
  }
}

/// Result of a purchase attempt
class PurchaseResult {
  final bool success;
  final String? error;
  final PurchaseErrorCode? errorCode;

  PurchaseResult({
    required this.success,
    this.error,
    this.errorCode,
  });
}

/// Error codes for purchase failures
enum PurchaseErrorCode {
  productNotFound,
  purchaseCancelled,
  paymentFailed,
  networkError,
  unknown,
}
