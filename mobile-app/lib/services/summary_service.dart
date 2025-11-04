/// SummaryService
/// Provides helper methods to retrieve or generate AI stock summaries.
/// Prefers cached Firestore summaries and falls back to generating new ones
/// when permitted.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_service.dart';
import 'stock_service.dart';

class SummaryService {
  SummaryService._internal();

  static final SummaryService _instance = SummaryService._internal();
  factory SummaryService() => _instance;

  final FirebaseService _firebaseService = FirebaseService();
  final StockService _stockService = StockService();

  /// Fetches the latest cached summary for the ticker from Firestore.
  /// Returns `null` when no summary is available or Firestore is offline.
  Future<String?> getCachedSummary(String ticker) async {
    if (!_firebaseService.isFirestoreAvailable) {
      return null;
    }

    try {
      final doc = await _firebaseService.firestore
          .collection('summaries')
          .doc(ticker.toUpperCase())
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data();
      final content = data?['content']?.toString().trim();
      if (content == null || content.isEmpty) {
        return null;
      }

      return content;
    } on FirebaseException catch (error) {
      // Propagate Firebase-specific errors for upstream handling if needed.
      throw Exception('Failed to read summary: ${error.message}');
    } catch (_) {
      return null;
    }
  }

  /// Generates a fresh summary via the API using the authenticated user token.
  /// Returns the generated summary text.
  Future<String> generateSummary(String ticker, {String language = 'en'}) async {
    final user = _firebaseService.currentUser;
    if (user == null) {
      throw Exception('Please sign in to generate AI summaries.');
    }

    final idToken = await user.getIdToken();
    final summary = await _stockService.generateAISummary(
      ticker,
      language: language,
      idToken: idToken,
    );

    if (summary.trim().isEmpty) {
      throw Exception('Summary generation returned no content.');
    }

    return summary.trim();
  }

  /// Ensures a summary is available by checking the cache first and optionally
  /// generating a new one when not present.
  Future<String?> ensureSummary(
    String ticker, {
    bool generateIfMissing = true,
    String language = 'en',
  }) async {
    final cached = await getCachedSummary(ticker);
    if (cached != null) {
      return cached;
    }

    if (!generateIfMissing) {
      return null;
    }

    return await generateSummary(ticker, language: language);
  }
}
