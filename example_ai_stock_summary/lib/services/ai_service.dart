import '../services/supabase_service.dart';
import '../services/openai_service.dart';
import '../models/ai_summary_model.dart';
import '../models/market_insight_model.dart';
import '../models/stock_model.dart';

class AiService {
  static AiService? _instance;
  static AiService get instance => _instance ??= AiService._();

  AiService._();

  final client = SupabaseService.instance.client;
  final _openAI = OpenAIService();

  /// Generate real-time AI summary using OpenAI for a specific stock
  Future<AiSummaryModel> generateAiSummaryWithOpenAI({
    required String stockId,
    String? userId,
    bool saveToDatabase = true,
  }) async {
    try {
      // First, get stock details
      final stockResponse =
          await client.from('stocks').select('*').eq('id', stockId).single();

      final stock = StockModel.fromJson(stockResponse);

      // Generate analysis using OpenAI
      final analysis = await _openAI.generateStockAnalysis(
        stockSymbol: stock.symbol,
        companyName: stock.name,
        sector: stock.sector,
        industry: stock.industry,
        currentPrice: stock.currentPrice,
        marketCap: stock.marketCap,
      );

      // Create AI summary record
      final summaryData = {
        'stock_id': stockId,
        'title': analysis.title,
        'summary': analysis.summary,
        'sentiment': analysis.sentiment,
        'confidence_score': analysis.confidenceScore,
        'key_points': analysis.keyPoints,
        'generated_at': DateTime.now().toIso8601String(),
        'is_active': true,
      };

      if (saveToDatabase) {
        final response =
            await client.from('ai_summaries').insert(summaryData).select('''
              *,
              stocks!inner(symbol, name, exchange, sector, industry)
            ''').single();

        return AiSummaryModel.fromJson(response);
      } else {
        // Create temporary model without saving to database
        return AiSummaryModel.fromJson({
          ...summaryData,
          'id': 'temp-${DateTime.now().millisecondsSinceEpoch}',
          'stocks': {
            'symbol': stock.symbol,
            'name': stock.name,
            'exchange': stock.exchange,
            'sector': stock.sector,
            'industry': stock.industry,
          }
        });
      }
    } catch (error) {
      throw Exception('Failed to generate AI summary with OpenAI: $error');
    }
  }

  /// Stream real-time AI summary generation
  Stream<String> streamAiSummaryGeneration({
    required String stockId,
  }) async* {
    try {
      // Get stock details
      final stockResponse =
          await client.from('stocks').select('*').eq('id', stockId).single();

      final stock = StockModel.fromJson(stockResponse);

      // Stream analysis from OpenAI
      await for (final chunk in _openAI.streamStockAnalysis(
        stockSymbol: stock.symbol,
        companyName: stock.name,
        sector: stock.sector,
        industry: stock.industry,
        currentPrice: stock.currentPrice,
        marketCap: stock.marketCap,
      )) {
        yield chunk;
      }
    } catch (error) {
      throw Exception('Failed to stream AI summary generation: $error');
    }
  }

  /// Generate market insights using OpenAI
  Future<void> generateMarketInsightsWithOpenAI({
    required String insightType,
    required List<String> stockSymbols,
  }) async {
    try {
      final insight = await _openAI.generateMarketInsight(
        insightType: insightType,
        stockSymbols: stockSymbols,
      );

      await client.from('market_insights').insert({
        'title': insight.title,
        'description': insight.description,
        'insight_type': insight.insightType,
        'stock_symbols': insight.stockSymbols,
        'color_hex': _getInsightColor(insight.insightType),
        'icon_name': _getInsightIcon(insight.insightType),
        'is_active': true,
      });
    } catch (error) {
      throw Exception('Failed to generate market insights with OpenAI: $error');
    }
  }

  /// Generate portfolio analysis using OpenAI
  Future<Map<String, dynamic>> generatePortfolioAnalysisWithOpenAI({
    required String userId,
  }) async {
    try {
      // Get user's portfolio holdings
      final holdingsResponse =
          await client.from('portfolio_holdings').select('''
            *,
            portfolios!inner(user_id),
            stocks!inner(symbol, name, current_price)
          ''').eq('portfolios.user_id', userId);

      if (holdingsResponse.isEmpty) {
        throw Exception('No portfolio holdings found for user');
      }

      // Prepare holdings data for analysis
      final holdings = <Map<String, dynamic>>[];
      double totalValue = 0;

      for (var holding in holdingsResponse) {
        final shares = holding['quantity'] ?? 0;
        final avgPrice = holding['average_price'] ?? 0.0;
        final currentPrice = holding['stocks']['current_price'] ?? avgPrice;
        final value = shares * currentPrice;
        totalValue += value;

        holdings.add({
          'symbol': holding['stocks']['symbol'],
          'shares': shares,
          'avgPrice': avgPrice,
          'currentPrice': currentPrice,
          'value': value,
        });
      }

      // Calculate percentages
      for (var holding in holdings) {
        holding['percentage'] = (holding['value'] / totalValue) * 100;
      }

      // Generate analysis using OpenAI
      final analysis = await _openAI.generatePortfolioAnalysis(
        holdings: holdings,
        totalValue: totalValue,
      );

      return {
        'summary': analysis.summary,
        'diversification': analysis.diversification,
        'performance': analysis.performance,
        'recommendations': analysis.recommendations,
        'riskAssessment': analysis.riskAssessment,
        'totalValue': totalValue,
        'holdings': holdings,
      };
    } catch (error) {
      throw Exception(
          'Failed to generate portfolio analysis with OpenAI: $error');
    }
  }

  /// Regenerate AI summary with OpenAI
  Future<AiSummaryModel> regenerateAiSummaryWithOpenAI({
    required String stockId,
  }) async {
    try {
      // Mark existing summaries as inactive
      await client
          .from('ai_summaries')
          .update({'is_active': false}).eq('stock_id', stockId);

      // Generate new summary
      return await generateAiSummaryWithOpenAI(stockId: stockId);
    } catch (error) {
      throw Exception('Failed to regenerate AI summary with OpenAI: $error');
    }
  }

  String _getInsightColor(String insightType) {
    switch (insightType.toLowerCase()) {
      case 'price_movement':
        return '#10B981';
      case 'ai_analysis':
        return '#4A90E2';
      case 'market_trend':
        return '#F59E0B';
      case 'sector_analysis':
        return '#8B5CF6';
      default:
        return '#6B7280';
    }
  }

  String _getInsightIcon(String insightType) {
    switch (insightType.toLowerCase()) {
      case 'price_movement':
        return 'trending_up';
      case 'ai_analysis':
        return 'psychology';
      case 'market_trend':
        return 'timeline';
      case 'sector_analysis':
        return 'category';
      default:
        return 'insights';
    }
  }

  // Get AI summaries
  Future<List<AiSummaryModel>> getAiSummaries({
    String? stockId,
    int limit = 20,
  }) async {
    try {
      var query = client.from('ai_summaries').select('''
            *,
            stocks!inner(symbol, name, exchange)
          ''').eq('is_active', true);

      if (stockId != null) {
        query = query.eq('stock_id', stockId);
      }

      final response =
          await query.order('generated_at', ascending: false).limit(limit);

      return (response as List)
          .map((json) => AiSummaryModel.fromJson(json))
          .toList();
    } catch (error) {
      throw Exception('Failed to fetch AI summaries: $error');
    }
  }

  // Get AI summary for specific stock
  Future<AiSummaryModel?> getStockAiSummary(String stockId) async {
    try {
      final response = await client
          .from('ai_summaries')
          .select('''
            *,
            stocks!inner(symbol, name, exchange, sector, industry)
          ''')
          .eq('stock_id', stockId)
          .eq('is_active', true)
          .order('generated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response != null ? AiSummaryModel.fromJson(response) : null;
    } catch (error) {
      throw Exception('Failed to fetch stock AI summary: $error');
    }
  }

  // Get recent AI summaries for dashboard
  Future<List<AiSummaryModel>> getRecentAiSummaries({int limit = 5}) async {
    try {
      final response = await client
          .from('ai_summaries')
          .select('''
            *,
            stocks!inner(symbol, name)
          ''')
          .eq('is_active', true)
          .order('generated_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => AiSummaryModel.fromJson(json))
          .toList();
    } catch (error) {
      throw Exception('Failed to fetch recent AI summaries: $error');
    }
  }

  // Create AI summary (admin only)
  Future<void> createAiSummary({
    required String stockId,
    required String title,
    required String summary,
    required String sentiment,
    double? confidenceScore,
    List<String>? keyPoints,
  }) async {
    try {
      await client.from('ai_summaries').insert({
        'stock_id': stockId,
        'title': title,
        'summary': summary,
        'sentiment': sentiment,
        'confidence_score': confidenceScore,
        'key_points': keyPoints,
        'generated_at': DateTime.now().toIso8601String(),
        'is_active': true,
      });
    } catch (error) {
      throw Exception('Failed to create AI summary: $error');
    }
  }

  // Update AI summary
  Future<void> updateAiSummary({
    required String summaryId,
    String? title,
    String? summary,
    String? sentiment,
    double? confidenceScore,
    List<String>? keyPoints,
    bool? isActive,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (title != null) updateData['title'] = title;
      if (summary != null) updateData['summary'] = summary;
      if (sentiment != null) updateData['sentiment'] = sentiment;
      if (confidenceScore != null)
        updateData['confidence_score'] = confidenceScore;
      if (keyPoints != null) updateData['key_points'] = keyPoints;
      if (isActive != null) updateData['is_active'] = isActive;

      await client.from('ai_summaries').update(updateData).eq('id', summaryId);
    } catch (error) {
      throw Exception('Failed to update AI summary: $error');
    }
  }

  // Market Insights Methods

  // Get market insights
  Future<List<MarketInsightModel>> getMarketInsights({int limit = 10}) async {
    try {
      final response = await client
          .from('market_insights')
          .select('*')
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => MarketInsightModel.fromJson(json))
          .toList();
    } catch (error) {
      throw Exception('Failed to fetch market insights: $error');
    }
  }

  // Create market insight
  Future<void> createMarketInsight({
    required String title,
    required String description,
    required String insightType,
    String? iconName,
    String? colorHex,
    List<String>? stockSymbols,
  }) async {
    try {
      await client.from('market_insights').insert({
        'title': title,
        'description': description,
        'insight_type': insightType,
        'icon_name': iconName,
        'color_hex': colorHex,
        'stock_symbols': stockSymbols,
        'is_active': true,
      });
    } catch (error) {
      throw Exception('Failed to create market insight: $error');
    }
  }

  // Update market insight
  Future<void> updateMarketInsight({
    required String insightId,
    String? title,
    String? description,
    String? insightType,
    String? iconName,
    String? colorHex,
    List<String>? stockSymbols,
    bool? isActive,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (insightType != null) updateData['insight_type'] = insightType;
      if (iconName != null) updateData['icon_name'] = iconName;
      if (colorHex != null) updateData['color_hex'] = colorHex;
      if (stockSymbols != null) updateData['stock_symbols'] = stockSymbols;
      if (isActive != null) updateData['is_active'] = isActive;

      updateData['updated_at'] = DateTime.now().toIso8601String();

      await client
          .from('market_insights')
          .update(updateData)
          .eq('id', insightId);
    } catch (error) {
      throw Exception('Failed to update market insight: $error');
    }
  }

  // Get AI summaries by sentiment
  Future<List<AiSummaryModel>> getAiSummariesBySentiment(
    String sentiment, {
    int limit = 10,
  }) async {
    try {
      final response = await client
          .from('ai_summaries')
          .select('''
            *,
            stocks!inner(symbol, name)
          ''')
          .eq('sentiment', sentiment)
          .eq('is_active', true)
          .order('generated_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => AiSummaryModel.fromJson(json))
          .toList();
    } catch (error) {
      throw Exception('Failed to fetch AI summaries by sentiment: $error');
    }
  }
}
