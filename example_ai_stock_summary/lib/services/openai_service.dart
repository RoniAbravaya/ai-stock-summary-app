import 'dart:convert';

import 'package:dio/dio.dart';


class OpenAIService {
  static final OpenAIService _instance = OpenAIService._internal();
  late final Dio _dio;
  static const String apiKey = String.fromEnvironment('OPENAI_API_KEY');

  // Factory constructor to return the singleton instance
  factory OpenAIService() {
    return _instance;
  }

  // Private constructor for singleton pattern
  OpenAIService._internal() {
    _initializeService();
  }

  void _initializeService() {
    // Load API key from environment variables
    if (apiKey.isEmpty) {
      throw Exception('OPENAI_API_KEY must be provided via --dart-define');
    }

    // Configure Dio with base URL and headers
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.openai.com/v1',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
      ),
    );
  }

  Dio get dio => _dio;

  /// Generates a stock analysis using OpenAI GPT models
  Future<StockAnalysis> generateStockAnalysis({
    required String stockSymbol,
    required String companyName,
    String? sector,
    String? industry,
    double? currentPrice,
    double? marketCap,
    String model = 'gpt-4o',
    Map<String, dynamic>? options,
  }) async {
    try {
      final prompt = _buildStockAnalysisPrompt(
        stockSymbol: stockSymbol,
        companyName: companyName,
        sector: sector,
        industry: industry,
        currentPrice: currentPrice,
        marketCap: marketCap,
      );

      final messages = [
        {
          'role': 'system',
          'content':
              'You are a professional financial analyst specializing in stock analysis. Provide comprehensive, accurate, and actionable investment insights.'
        },
        {
          'role': 'user',
          'content': prompt,
        }
      ];

      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': model,
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 1500,
          if (options != null) ...options,
        },
      );

      final content = response.data['choices'][0]['message']['content'];
      return _parseStockAnalysis(content);
    } on DioException catch (e) {
      throw OpenAIException(
        statusCode: e.response?.statusCode ?? 500,
        message: e.response?.data['error']?['message'] ??
            e.message ??
            'Unknown error',
      );
    }
  }

  /// Streams stock analysis generation in real-time
  Stream<String> streamStockAnalysis({
    required String stockSymbol,
    required String companyName,
    String? sector,
    String? industry,
    double? currentPrice,
    double? marketCap,
    String model = 'gpt-4o',
    Map<String, dynamic>? options,
  }) async* {
    try {
      final prompt = _buildStockAnalysisPrompt(
        stockSymbol: stockSymbol,
        companyName: companyName,
        sector: sector,
        industry: industry,
        currentPrice: currentPrice,
        marketCap: marketCap,
      );

      final messages = [
        {
          'role': 'system',
          'content':
              'You are a professional financial analyst specializing in stock analysis. Provide comprehensive, accurate, and actionable investment insights.'
        },
        {
          'role': 'user',
          'content': prompt,
        }
      ];

      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': model,
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 1500,
          'stream': true,
          if (options != null) ...options,
        },
        options: Options(responseType: ResponseType.stream),
      );

      final stream = response.data.stream;
      await for (var line
          in LineSplitter().bind(utf8.decoder.bind(stream.stream))) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6);
          if (data == '[DONE]') break;

          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            final delta = json['choices'][0]['delta'] as Map<String, dynamic>;
            final content = delta['content'] ?? '';
            final finishReason = json['choices'][0]['finish_reason'];

            if (content.isNotEmpty) {
              yield content;
            }

            // If finish reason is provided, this is the final chunk
            if (finishReason != null) break;
          } catch (e) {
            // Skip malformed JSON lines
            continue;
          }
        }
      }
    } on DioException catch (e) {
      throw OpenAIException(
        statusCode: e.response?.statusCode ?? 500,
        message: e.response?.data['error']?['message'] ??
            e.message ??
            'Unknown error',
      );
    }
  }

  /// Generates market insights using OpenAI
  Future<MarketInsight> generateMarketInsight({
    required String insightType,
    required List<String> stockSymbols,
    String model = 'gpt-4o',
    Map<String, dynamic>? options,
  }) async {
    try {
      final prompt = _buildMarketInsightPrompt(
        insightType: insightType,
        stockSymbols: stockSymbols,
      );

      final messages = [
        {
          'role': 'system',
          'content':
              'You are a market analyst providing timely market insights and trends analysis.'
        },
        {
          'role': 'user',
          'content': prompt,
        }
      ];

      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': model,
          'messages': messages,
          'temperature': 0.8,
          'max_tokens': 800,
          if (options != null) ...options,
        },
      );

      final content = response.data['choices'][0]['message']['content'];
      return _parseMarketInsight(content, insightType, stockSymbols);
    } on DioException catch (e) {
      throw OpenAIException(
        statusCode: e.response?.statusCode ?? 500,
        message: e.response?.data['error']?['message'] ??
            e.message ??
            'Unknown error',
      );
    }
  }

  /// Generate portfolio analysis using OpenAI
  Future<PortfolioAnalysis> generatePortfolioAnalysis({
    required List<Map<String, dynamic>> holdings,
    required double totalValue,
    String model = 'gpt-4o',
    Map<String, dynamic>? options,
  }) async {
    try {
      final prompt = _buildPortfolioAnalysisPrompt(
        holdings: holdings,
        totalValue: totalValue,
      );

      final messages = [
        {
          'role': 'system',
          'content':
              'You are a portfolio manager providing comprehensive portfolio analysis and recommendations.'
        },
        {
          'role': 'user',
          'content': prompt,
        }
      ];

      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': model,
          'messages': messages,
          'temperature': 0.6,
          'max_tokens': 1200,
          if (options != null) ...options,
        },
      );

      final content = response.data['choices'][0]['message']['content'];
      return _parsePortfolioAnalysis(content);
    } on DioException catch (e) {
      throw OpenAIException(
        statusCode: e.response?.statusCode ?? 500,
        message: e.response?.data['error']?['message'] ??
            e.message ??
            'Unknown error',
      );
    }
  }

  String _buildStockAnalysisPrompt({
    required String stockSymbol,
    required String companyName,
    String? sector,
    String? industry,
    double? currentPrice,
    double? marketCap,
  }) {
    final buffer = StringBuffer();
    buffer.writeln(
        'Provide a comprehensive stock analysis for $stockSymbol ($companyName).');

    if (sector != null) buffer.writeln('Sector: $sector');
    if (industry != null) buffer.writeln('Industry: $industry');
    if (currentPrice != null)
      buffer.writeln('Current Price: \$${currentPrice.toStringAsFixed(2)}');
    if (marketCap != null)
      buffer.writeln('Market Cap: \$${_formatLargeNumber(marketCap)}');

    buffer.writeln('''

Please structure your analysis as follows:

**TITLE:** [Create a compelling title for the analysis]

**EXECUTIVE SUMMARY:**
Provide a 3-4 sentence overview of the stock's current position and outlook.

**FINANCIAL HEALTH:**
• List 4-5 key financial strengths or concerns
• Focus on revenue, profitability, debt, and cash flow

**MARKET POSITION:**
• List 4-5 points about the company's competitive position
• Include market share, competitive advantages, and industry trends

**INVESTMENT OUTLOOK:**
• Recommendation: Buy/Hold/Sell
• Risk Level: Low/Medium/High
• Brief reasoning (2-3 sentences)

**KEY POINTS:**
• List 3-5 bullet points of the most important takeaways

**SENTIMENT:** bullish/bearish/neutral

Keep the analysis factual, balanced, and actionable for investors.''');

    return buffer.toString();
  }

  String _buildMarketInsightPrompt({
    required String insightType,
    required List<String> stockSymbols,
  }) {
    final buffer = StringBuffer();
    buffer.writeln(
        'Generate a market insight about $insightType for the following stocks: ${stockSymbols.join(', ')}.');

    buffer.writeln('''

Please provide:

**TITLE:** [Create a catchy title for this market insight]

**DESCRIPTION:**
Provide a 2-3 sentence description of the current market trend or insight related to these stocks and the specified insight type.

Keep it concise, timely, and relevant for active traders and investors.''');

    return buffer.toString();
  }

  String _buildPortfolioAnalysisPrompt({
    required List<Map<String, dynamic>> holdings,
    required double totalValue,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('Analyze the following investment portfolio:');
    buffer
        .writeln('Total Portfolio Value: \$${_formatLargeNumber(totalValue)}');
    buffer.writeln('\nHoldings:');

    for (var holding in holdings) {
      buffer.writeln(
          '• ${holding['symbol']}: ${holding['shares']} shares @ \$${holding['avgPrice']?.toStringAsFixed(2) ?? 'N/A'} (${holding['percentage']?.toStringAsFixed(1) ?? 'N/A'}%)');
    }

    buffer.writeln('''

Please provide:

**PORTFOLIO SUMMARY:**
Brief overview of the portfolio composition and overall health.

**DIVERSIFICATION ANALYSIS:**
Assess sector/geographic diversification and concentration risks.

**PERFORMANCE INSIGHTS:**
Key observations about current performance and positioning.

**RECOMMENDATIONS:**
3-4 specific actionable recommendations for portfolio optimization.

**RISK ASSESSMENT:**
Overall risk level and major risk factors to consider.''');

    return buffer.toString();
  }

  StockAnalysis _parseStockAnalysis(String content) {
    // Extract title
    final titleMatch = RegExp(r'\*\*TITLE:\*\*\s*(.+)', caseSensitive: false)
        .firstMatch(content);
    final title = titleMatch?.group(1)?.trim() ?? 'Stock Analysis';

    // Extract executive summary
    final summaryMatch = RegExp(
            r'\*\*EXECUTIVE SUMMARY:\*\*\s*((?:[^\*]|\*(?!\*))+)',
            caseSensitive: false)
        .firstMatch(content);
    final summary = summaryMatch?.group(1)?.trim() ?? '';

    // Extract financial health points
    final financialMatch = RegExp(
            r'\*\*FINANCIAL HEALTH:\*\*\s*((?:[^\*]|\*(?!\*))+)',
            caseSensitive: false)
        .firstMatch(content);
    final financialText = financialMatch?.group(1)?.trim() ?? '';
    final financialHealth = _extractBulletPoints(financialText);

    // Extract market position points
    final marketMatch = RegExp(
            r'\*\*MARKET POSITION:\*\*\s*((?:[^\*]|\*(?!\*))+)',
            caseSensitive: false)
        .firstMatch(content);
    final marketText = marketMatch?.group(1)?.trim() ?? '';
    final marketPosition = _extractBulletPoints(marketText);

    // Extract investment outlook
    final outlookMatch = RegExp(
            r'\*\*INVESTMENT OUTLOOK:\*\*\s*((?:[^\*]|\*(?!\*))+)',
            caseSensitive: false)
        .firstMatch(content);
    final outlookText = outlookMatch?.group(1)?.trim() ?? '';

    // Parse recommendation
    final recMatch =
        RegExp(r'Recommendation:\s*(Buy|Hold|Sell)', caseSensitive: false)
            .firstMatch(outlookText);
    final recommendation = recMatch?.group(1) ?? 'Hold';

    // Parse risk level
    final riskMatch =
        RegExp(r'Risk Level:\s*(Low|Medium|High)', caseSensitive: false)
            .firstMatch(outlookText);
    final riskLevel = riskMatch?.group(1) ?? 'Medium';

    // Extract key points
    final keyPointsMatch = RegExp(
            r'\*\*KEY POINTS:\*\*\s*((?:[^\*]|\*(?!\*))+)',
            caseSensitive: false)
        .firstMatch(content);
    final keyPointsText = keyPointsMatch?.group(1)?.trim() ?? '';
    final keyPoints = _extractBulletPoints(keyPointsText);

    // Extract sentiment
    final sentimentMatch =
        RegExp(r'\*\*SENTIMENT:\*\*\s*(\w+)', caseSensitive: false)
            .firstMatch(content);
    final sentiment = sentimentMatch?.group(1)?.toLowerCase() ?? 'neutral';

    return StockAnalysis(
      title: title,
      summary: summary,
      financialHealth: financialHealth,
      marketPosition: marketPosition,
      recommendation: recommendation,
      riskLevel: riskLevel,
      keyPoints: keyPoints,
      sentiment: sentiment,
      confidenceScore: 0.8, // Default confidence score
    );
  }

  MarketInsight _parseMarketInsight(
      String content, String insightType, List<String> stockSymbols) {
    // Extract title
    final titleMatch = RegExp(r'\*\*TITLE:\*\*\s*(.+)', caseSensitive: false)
        .firstMatch(content);
    final title = titleMatch?.group(1)?.trim() ?? 'Market Insight';

    // Extract description
    final descMatch = RegExp(r'\*\*DESCRIPTION:\*\*\s*((?:[^\*]|\*(?!\*))+)',
            caseSensitive: false)
        .firstMatch(content);
    final description = descMatch?.group(1)?.trim() ?? content;

    return MarketInsight(
      title: title,
      description: description,
      insightType: insightType,
      stockSymbols: stockSymbols,
    );
  }

  PortfolioAnalysis _parsePortfolioAnalysis(String content) {
    // Extract portfolio summary
    final summaryMatch = RegExp(
            r'\*\*PORTFOLIO SUMMARY:\*\*\s*((?:[^\*]|\*(?!\*))+)',
            caseSensitive: false)
        .firstMatch(content);
    final summary = summaryMatch?.group(1)?.trim() ?? '';

    // Extract diversification analysis
    final diversificationMatch = RegExp(
            r'\*\*DIVERSIFICATION ANALYSIS:\*\*\s*((?:[^\*]|\*(?!\*))+)',
            caseSensitive: false)
        .firstMatch(content);
    final diversification = diversificationMatch?.group(1)?.trim() ?? '';

    // Extract performance insights
    final performanceMatch = RegExp(
            r'\*\*PERFORMANCE INSIGHTS:\*\*\s*((?:[^\*]|\*(?!\*))+)',
            caseSensitive: false)
        .firstMatch(content);
    final performance = performanceMatch?.group(1)?.trim() ?? '';

    // Extract recommendations
    final recommendationsMatch = RegExp(
            r'\*\*RECOMMENDATIONS:\*\*\s*((?:[^\*]|\*(?!\*))+)',
            caseSensitive: false)
        .firstMatch(content);
    final recommendationsText = recommendationsMatch?.group(1)?.trim() ?? '';
    final recommendations = _extractBulletPoints(recommendationsText);

    // Extract risk assessment
    final riskMatch = RegExp(
            r'\*\*RISK ASSESSMENT:\*\*\s*((?:[^\*]|\*(?!\*))+)',
            caseSensitive: false)
        .firstMatch(content);
    final riskAssessment = riskMatch?.group(1)?.trim() ?? '';

    return PortfolioAnalysis(
      summary: summary,
      diversification: diversification,
      performance: performance,
      recommendations: recommendations,
      riskAssessment: riskAssessment,
    );
  }

  List<String> _extractBulletPoints(String text) {
    final points = <String>[];
    final lines = text.split('\n');

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('•') ||
          trimmed.startsWith('-') ||
          trimmed.startsWith('*')) {
        points.add(trimmed.substring(1).trim());
      }
    }

    return points;
  }

  String _formatLargeNumber(double number) {
    if (number >= 1e12) {
      return '${(number / 1e12).toStringAsFixed(2)}T';
    } else if (number >= 1e9) {
      return '${(number / 1e9).toStringAsFixed(2)}B';
    } else if (number >= 1e6) {
      return '${(number / 1e6).toStringAsFixed(2)}M';
    } else {
      return number.toStringAsFixed(0);
    }
  }
}

/// OpenAI-specific exception
class OpenAIException implements Exception {
  final int statusCode;
  final String message;

  OpenAIException({required this.statusCode, required this.message});

  @override
  String toString() => 'OpenAIException: $statusCode - $message';
}

/// Stock analysis result from OpenAI
class StockAnalysis {
  final String title;
  final String summary;
  final List<String> financialHealth;
  final List<String> marketPosition;
  final String recommendation;
  final String riskLevel;
  final List<String> keyPoints;
  final String sentiment;
  final double confidenceScore;

  StockAnalysis({
    required this.title,
    required this.summary,
    required this.financialHealth,
    required this.marketPosition,
    required this.recommendation,
    required this.riskLevel,
    required this.keyPoints,
    required this.sentiment,
    required this.confidenceScore,
  });
}

/// Market insight result from OpenAI
class MarketInsight {
  final String title;
  final String description;
  final String insightType;
  final List<String> stockSymbols;

  MarketInsight({
    required this.title,
    required this.description,
    required this.insightType,
    required this.stockSymbols,
  });
}

/// Portfolio analysis result from OpenAI
class PortfolioAnalysis {
  final String summary;
  final String diversification;
  final String performance;
  final List<String> recommendations;
  final String riskAssessment;

  PortfolioAnalysis({
    required this.summary,
    required this.diversification,
    required this.performance,
    required this.recommendations,
    required this.riskAssessment,
  });
}
