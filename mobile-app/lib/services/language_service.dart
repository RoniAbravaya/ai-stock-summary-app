import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

/// Language Service for multi-language support
/// Handles static UI translations and language preferences
class LanguageService {
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();

  static const String _languageKey = 'selected_language';
  static const String _translationsKey = 'cached_translations';

  SharedPreferences? _prefs;
  Map<String, Map<String, String>> _translations = {};
  String _currentLanguage = 'en';

  /// Supported languages
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'es': 'Español',
    'fr': 'Français',
    'de': 'Deutsch',
  };

  String get currentLanguage => _currentLanguage;
  List<String> get availableLanguages => supportedLanguages.keys.toList();
  String getCurrentLanguageName() =>
      supportedLanguages[_currentLanguage] ?? 'English';

  /// Initialize the service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    // Load saved language preference
    _currentLanguage = _prefs!.getString(_languageKey) ?? 'en';

    // Load cached translations
    await _loadCachedTranslations();

    // Load default English translations if not cached
    if (_translations.isEmpty) {
      await _loadDefaultTranslations();
    }
  }

  /// Get translation for a key
  String translate(String key, {String? fallback}) {
    final translation =
        _translations[_currentLanguage]?[key] ??
        _translations['en']?[key] ??
        fallback ??
        key;
    return translation;
  }

  /// Get translation with parameters
  String translateWithParams(
    String key,
    Map<String, String> params, {
    String? fallback,
  }) {
    String translation = translate(key, fallback: fallback);

    params.forEach((paramKey, paramValue) {
      translation = translation.replaceAll('{$paramKey}', paramValue);
    });

    return translation;
  }

  /// Change language
  Future<void> changeLanguage(String languageCode) async {
    if (!supportedLanguages.containsKey(languageCode)) {
      throw ArgumentError('Unsupported language: $languageCode');
    }

    _currentLanguage = languageCode;

    // Save preference
    await _prefs!.setString(_languageKey, languageCode);

    // Load translations for new language if not cached
    if (!_translations.containsKey(languageCode)) {
      await _loadTranslationsForLanguage(languageCode);
    }
  }

  /// Load default translations (English)
  Future<void> _loadDefaultTranslations() async {
    _translations['en'] = {
      // App Name
      'app_name': 'AI Stock Summary',
      'app_tagline': 'AI-Powered Stock Summaries',

      // Navigation
      'nav_dashboard': 'Dashboard',
      'nav_favorites': 'Favorites',
      'nav_news': 'News',
      'nav_profile': 'Profile',
      'nav_admin': 'Admin',

      // Authentication
      'auth_welcome_back': 'Welcome Back',
      'auth_create_account': 'Create Account',
      'auth_sign_in': 'Sign In',
      'auth_sign_up': 'Sign Up',
      'auth_sign_out': 'Sign Out',
      'auth_email': 'Email',
      'auth_password': 'Password',
      'auth_confirm_password': 'Confirm Password',
      'auth_full_name': 'Full Name',
      'auth_sign_in_google': 'Sign in with Google',
      'auth_forgot_password': 'Forgot Password?',
      'auth_no_account': 'Don\'t have an account? Sign Up',
      'auth_have_account': 'Already have an account? Sign In',

      // Profile
      'profile_title': 'Profile',
      'profile_usage_stats': 'Usage Statistics',
      'profile_subscription_type': 'Subscription Type',
      'profile_summaries_used': 'AI Summaries Used',
      'profile_monthly_usage': 'Monthly Summary Usage',
      'profile_free': 'Free',
      'profile_premium': 'Premium',
      'profile_admin': 'Admin',
      'profile_user': 'User',

      // Usage
      'usage_remaining': '{count} summaries remaining this month',
      'usage_remaining_singular': '1 summary remaining this month',
      'usage_no_remaining': 'No summaries remaining this month',
      'usage_resets_in': 'Resets in {days} days',
      'usage_resets_today': 'Resets today',
      'usage_resets_tomorrow': 'Resets tomorrow',

      // Premium
      'premium_upgrade': 'Upgrade to Premium',
      'premium_unlock': 'Unlock unlimited AI summaries and premium features',
      'premium_features':
          '• 100 AI summaries per month\n• Priority support\n• Advanced analytics\n• No ads',
      'premium_price': 'Upgrade Now - \$9.99/month',
      'premium_coming_soon': 'Premium subscription coming soon...',

      // Rewards
      'rewards_title': 'Get More Summaries',
      'rewards_watch_ad': 'Watch Rewarded Ad',
      'rewards_get_summary': 'Get +1 summary instantly',
      'rewards_watch': 'Watch',

      // Settings
      'settings_notifications': 'Notifications',
      'settings_notifications_desc': 'Manage push notifications',
      'settings_language': 'Language',
      'settings_language_desc': 'Change app language',
      'settings_help': 'Help & Support',
      'settings_help_desc': 'Get help and contact support',
      'settings_privacy': 'Privacy Policy',
      'settings_privacy_desc': 'View our privacy policy',
      'settings_sign_out_desc': 'Sign out of your account',
      'settings_demo_sign_out': 'Return to login',

      // Admin
      'admin_title': 'Admin Panel',
      'admin_send_notification': 'Send Push Notification',
      'admin_manage_users': 'Manage Users',
      'admin_system_stats': 'System Statistics',

      // Common
      'save': 'Save',
      'cancel': 'Cancel',
      'ok': 'OK',
      'yes': 'Yes',
      'no': 'No',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'retry': 'Retry',
      'close': 'Close',
      'edit': 'Edit',
      'delete': 'Delete',
      'add': 'Add',
      'remove': 'Remove',
      'update': 'Update',
      'create': 'Create',
      'search': 'Search',
      'filter': 'Filter',
      'sort': 'Sort',
      'refresh': 'Refresh',
      'back': 'Back',
      'next': 'Next',
      'previous': 'Previous',
      'done': 'Done',

      // Errors
      'error_network': 'Network error. Please check your connection.',
      'error_unknown': 'An unknown error occurred.',
      'error_auth_failed': 'Authentication failed.',
      'error_quota_exceeded':
          'Summary quota exceeded. Please upgrade or watch an ad.',

      // Success messages
      'success_profile_updated': 'Profile updated successfully',
      'success_language_changed': 'Language changed successfully',
      'success_signed_out': 'Signed out successfully',
    };

    await _saveTranslations();
  }

  /// Load translations for specific language
  Future<void> _loadTranslationsForLanguage(String languageCode) async {
    if (languageCode == 'en') {
      await _loadDefaultTranslations();
      return;
    }

    // For other languages, we'll use the same keys but different values
    // In a real app, these would come from translation files or APIs
    Map<String, String> translations = {};

    switch (languageCode) {
      case 'es':
        translations = await _getSpanishTranslations();
        break;
      case 'fr':
        translations = await _getFrenchTranslations();
        break;
      case 'de':
        translations = await _getGermanTranslations();
        break;
    }

    _translations[languageCode] = translations;
    await _saveTranslations();
  }

  /// Spanish translations
  Future<Map<String, String>> _getSpanishTranslations() async {
    return {
      'app_name': 'Resumen de Acciones IA',
      'app_tagline': 'Resúmenes de Acciones con IA',
      'nav_dashboard': 'Panel',
      'nav_favorites': 'Favoritos',
      'nav_news': 'Noticias',
      'nav_profile': 'Perfil',
      'nav_admin': 'Admin',
      'auth_welcome_back': 'Bienvenido de Nuevo',
      'auth_create_account': 'Crear Cuenta',
      'auth_sign_in': 'Iniciar Sesión',
      'auth_sign_up': 'Registrarse',
      'auth_sign_out': 'Cerrar Sesión',
      'auth_email': 'Correo',
      'auth_password': 'Contraseña',
      'auth_confirm_password': 'Confirmar Contraseña',
      'auth_full_name': 'Nombre Completo',
      'auth_sign_in_google': 'Iniciar sesión con Google',
      'profile_title': 'Perfil',
      'profile_usage_stats': 'Estadísticas de Uso',
      'profile_subscription_type': 'Tipo de Suscripción',
      'profile_summaries_used': 'Resúmenes IA Usados',
      'profile_monthly_usage': 'Uso Mensual de Resúmenes',
      'profile_free': 'Gratis',
      'profile_premium': 'Premium',
      'profile_admin': 'Admin',
      'profile_user': 'Usuario',
      'usage_remaining': '{count} resúmenes restantes este mes',
      'usage_remaining_singular': '1 resumen restante este mes',
      'usage_no_remaining': 'No quedan resúmenes este mes',
      'usage_resets_in': 'Se reinicia en {days} días',
      'usage_resets_today': 'Se reinicia hoy',
      'usage_resets_tomorrow': 'Se reinicia mañana',
      'premium_upgrade': 'Actualizar a Premium',
      'premium_unlock':
          'Desbloquea resúmenes IA ilimitados y funciones premium',
      'premium_features':
          '• 100 resúmenes IA por mes\n• Soporte prioritario\n• Análisis avanzado\n• Sin anuncios',
      'premium_price': 'Actualizar Ahora - \$9.99/mes',
      'settings_language': 'Idioma',
      'settings_language_desc': 'Cambiar idioma de la aplicación',
      'save': 'Guardar',
      'cancel': 'Cancelar',
      'loading': 'Cargando...',
      'error': 'Error',
      'success': 'Éxito',
    };
  }

  /// French translations
  Future<Map<String, String>> _getFrenchTranslations() async {
    return {
      'app_name': 'Résumé d\'Actions IA',
      'app_tagline': 'Résumés d\'Actions Alimentés par IA',
      'nav_dashboard': 'Tableau de Bord',
      'nav_favorites': 'Favoris',
      'nav_news': 'Actualités',
      'nav_profile': 'Profil',
      'nav_admin': 'Admin',
      'auth_welcome_back': 'Bon Retour',
      'auth_create_account': 'Créer un Compte',
      'auth_sign_in': 'Se Connecter',
      'auth_sign_up': 'S\'inscrire',
      'auth_sign_out': 'Se Déconnecter',
      'auth_email': 'Email',
      'auth_password': 'Mot de Passe',
      'auth_confirm_password': 'Confirmer le Mot de Passe',
      'auth_full_name': 'Nom Complet',
      'auth_sign_in_google': 'Se connecter avec Google',
      'profile_title': 'Profil',
      'profile_usage_stats': 'Statistiques d\'Utilisation',
      'profile_subscription_type': 'Type d\'Abonnement',
      'profile_summaries_used': 'Résumés IA Utilisés',
      'profile_monthly_usage': 'Utilisation Mensuelle des Résumés',
      'profile_free': 'Gratuit',
      'profile_premium': 'Premium',
      'profile_admin': 'Admin',
      'profile_user': 'Utilisateur',
      'usage_remaining': '{count} résumés restants ce mois',
      'usage_remaining_singular': '1 résumé restant ce mois',
      'usage_no_remaining': 'Aucun résumé restant ce mois',
      'usage_resets_in': 'Se remet à zéro dans {days} jours',
      'usage_resets_today': 'Se remet à zéro aujourd\'hui',
      'usage_resets_tomorrow': 'Se remet à zéro demain',
      'premium_upgrade': 'Passer à Premium',
      'premium_unlock':
          'Débloquez des résumés IA illimités et des fonctionnalités premium',
      'premium_features':
          '• 100 résumés IA par mois\n• Support prioritaire\n• Analyses avancées\n• Sans publicité',
      'premium_price': 'Mettre à Niveau Maintenant - 9,99\$/mois',
      'settings_language': 'Langue',
      'settings_language_desc': 'Changer la langue de l\'application',
      'save': 'Enregistrer',
      'cancel': 'Annuler',
      'loading': 'Chargement...',
      'error': 'Erreur',
      'success': 'Succès',
    };
  }

  /// German translations
  Future<Map<String, String>> _getGermanTranslations() async {
    return {
      'app_name': 'KI-Aktien-Zusammenfassung',
      'app_tagline': 'KI-gestützte Aktien-Zusammenfassungen',
      'nav_dashboard': 'Dashboard',
      'nav_favorites': 'Favoriten',
      'nav_news': 'Nachrichten',
      'nav_profile': 'Profil',
      'nav_admin': 'Admin',
      'auth_welcome_back': 'Willkommen zurück',
      'auth_create_account': 'Konto erstellen',
      'auth_sign_in': 'Anmelden',
      'auth_sign_up': 'Registrieren',
      'auth_sign_out': 'Abmelden',
      'auth_email': 'E-Mail',
      'auth_password': 'Passwort',
      'auth_confirm_password': 'Passwort bestätigen',
      'auth_full_name': 'Vollständiger Name',
      'auth_sign_in_google': 'Mit Google anmelden',
      'profile_title': 'Profil',
      'profile_usage_stats': 'Nutzungsstatistiken',
      'profile_subscription_type': 'Abonnement-Typ',
      'profile_summaries_used': 'KI-Zusammenfassungen verwendet',
      'profile_monthly_usage': 'Monatliche Zusammenfassungsnutzung',
      'profile_free': 'Kostenlos',
      'profile_premium': 'Premium',
      'profile_admin': 'Admin',
      'profile_user': 'Benutzer',
      'usage_remaining': '{count} Zusammenfassungen verbleibend diesen Monat',
      'usage_remaining_singular': '1 Zusammenfassung verbleibend diesen Monat',
      'usage_no_remaining': 'Keine Zusammenfassungen verbleibend diesen Monat',
      'usage_resets_in': 'Setzt sich in {days} Tagen zurück',
      'usage_resets_today': 'Setzt sich heute zurück',
      'usage_resets_tomorrow': 'Setzt sich morgen zurück',
      'premium_upgrade': 'Auf Premium upgraden',
      'premium_unlock':
          'Schalten Sie unbegrenzte KI-Zusammenfassungen und Premium-Funktionen frei',
      'premium_features':
          '• 100 KI-Zusammenfassungen pro Monat\n• Prioritäts-Support\n• Erweiterte Analysen\n• Keine Werbung',
      'premium_price': 'Jetzt upgraden - 9,99\$/Monat',
      'settings_language': 'Sprache',
      'settings_language_desc': 'App-Sprache ändern',
      'save': 'Speichern',
      'cancel': 'Abbrechen',
      'loading': 'Lädt...',
      'error': 'Fehler',
      'success': 'Erfolg',
    };
  }

  /// Load cached translations
  Future<void> _loadCachedTranslations() async {
    final cached = _prefs!.getString(_translationsKey);
    if (cached != null) {
      try {
        final Map<String, dynamic> decoded = json.decode(cached);
        _translations = decoded.map(
          (key, value) => MapEntry(key, Map<String, String>.from(value)),
        );
      } catch (e) {
        print('❌ Error loading cached translations: $e');
        _translations = {};
      }
    }
  }

  /// Save translations to cache
  Future<void> _saveTranslations() async {
    try {
      final encoded = json.encode(_translations);
      await _prefs!.setString(_translationsKey, encoded);
    } catch (e) {
      print('❌ Error saving translations: $e');
    }
  }
}
