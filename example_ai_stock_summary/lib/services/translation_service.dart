import 'package:dio/dio.dart';

import '../core/app_export.dart';
import '../models/ai_summary_model.dart';
import '../models/subscription_model.dart';
import './supabase_service.dart';

class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  final SupabaseService _supabase = SupabaseService();
  final Dio _dio = Dio();

  // Supported languages
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'it': 'Italian',
    'pt': 'Portuguese',
    'zh': 'Chinese',
    'ja': 'Japanese',
    'ko': 'Korean',
    'ru': 'Russian',
    'ar': 'Arabic',
    'hi': 'Hindi',
  };

  // Get translated summary or create if doesn't exist
  Future<SummaryTranslationModel?> getTranslatedSummary(
      String summaryId, String languageCode) async {
    try {
      // First check if translation exists
      final response = await _supabase.client
          .from('ai_summary_translations')
          .select()
          .eq('original_summary_id', summaryId)
          .eq('language_code', languageCode)
          .maybeSingle();

      if (response != null) {
        return SummaryTranslationModel.fromJson(response);
      }

      // If not exists and not English, create translation
      if (languageCode != 'en') {
        return await _createTranslation(summaryId, languageCode);
      }

      return null;
    } catch (e) {
      print('Error getting translated summary: $e');
      return null;
    }
  }

  // Create new translation using AI
  Future<SummaryTranslationModel?> _createTranslation(
      String summaryId, String languageCode) async {
    try {
      // Get original summary
      final summaryResponse = await _supabase.client
          .from('ai_summaries')
          .select()
          .eq('id', summaryId)
          .single();

      final originalSummary = AISummaryModel.fromJson(summaryResponse);

      // Translate using OpenAI
      final translatedContent =
          await _translateWithOpenAI(originalSummary, languageCode);

      if (translatedContent != null) {
        // Save translation to database
        final translationData = {
          'original_summary_id': summaryId,
          'language_code': languageCode,
          'translated_title': translatedContent['title'],
          'translated_summary': translatedContent['summary'],
          'translated_key_points': translatedContent['keyPoints'],
          'translation_service': 'openai',
          'translation_quality_score': translatedContent['qualityScore'],
        };

        final response = await _supabase.client
            .from('ai_summary_translations')
            .insert(translationData)
            .select()
            .single();

        return SummaryTranslationModel.fromJson(response);
      }

      return null;
    } catch (e) {
      print('Error creating translation: $e');
      return null;
    }
  }

  // Translate content using OpenAI
  Future<Map<String, dynamic>?> _translateWithOpenAI(
      AISummaryModel summary, String languageCode) async {
    try {
      final languageName = supportedLanguages[languageCode] ?? 'English';

      // Create translation prompt
      final prompt = '''
Translate the following stock analysis to $languageName. Maintain the professional financial tone and accuracy of all data:

Title: ${summary.title}
Summary: ${summary.summary}
Key Points: ${summary.keyPoints?.join(', ') ?? ''}

Please respond in the following JSON format:
{
  "title": "translated title",
  "summary": "translated summary",
  "keyPoints": ["translated key point 1", "translated key point 2"],
  "qualityScore": 0.95
}
''';

      // Call OpenAI API (using Edge Function)
      final supabaseUrl = const String.fromEnvironment('SUPABASE_URL');
      final anonKey = const String.fromEnvironment('SUPABASE_ANON_KEY');

      _dio.options.headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $anonKey',
      };

      final response = await _dio.post(
        '$supabaseUrl/functions/v1/translate-summary',
        data: {
          'prompt': prompt,
          'language_code': languageCode,
          'original_summary_id': summary.id,
        },
      );

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data);
      }

      return null;
    } catch (e) {
      print('Error translating with OpenAI: $e');
      return null;
    }
  }

  // Get all available translations for a summary
  Future<List<SummaryTranslationModel>> getAllTranslations(
      String summaryId) async {
    try {
      final response = await _supabase.client
          .from('ai_summary_translations')
          .select()
          .eq('original_summary_id', summaryId)
          .order('created_at');

      return response
          .map<SummaryTranslationModel>(
              (json) => SummaryTranslationModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting all translations: $e');
      return [];
    }
  }

  // Delete translation
  Future<bool> deleteTranslation(String translationId) async {
    try {
      await _supabase.client
          .from('ai_summary_translations')
          .delete()
          .eq('id', translationId);
      return true;
    } catch (e) {
      print('Error deleting translation: $e');
      return false;
    }
  }

  // Update translation quality score
  Future<void> updateQualityScore(String translationId, double score) async {
    try {
      await _supabase.client.from('ai_summary_translations').update({
        'translation_quality_score': score,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', translationId);
    } catch (e) {
      print('Error updating quality score: $e');
    }
  }

  // Get user's preferred language
  Future<String> getUserPreferredLanguage() async {
    try {
      final user = _supabase.client.auth.currentUser;
      if (user == null) return 'en';

      // Get from user metadata or device locale
      final userMetadata = user.userMetadata;
      return userMetadata?['preferred_language'] ?? 'en';
    } catch (e) {
      print('Error getting user language preference: $e');
      return 'en';
    }
  }

  // Set user's preferred language
  Future<void> setUserPreferredLanguage(String languageCode) async {
    try {
      await _supabase.client.auth.updateUser(
        UserAttributes(
          data: {'preferred_language': languageCode},
        ),
      );
    } catch (e) {
      print('Error setting user language preference: $e');
    }
  }
}
