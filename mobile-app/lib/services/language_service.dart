import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool get isInitialized => _prefs != null && _translations.isNotEmpty;
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

    // Load translations for current language if not already loaded
    if (!_translations.containsKey(_currentLanguage)) {
      await _loadTranslationsForLanguage(_currentLanguage);
    }
  }

  /// Get translation for a key
  String translate(String key, {String? fallback}) {
    // Ensure translations are loaded
    if (_translations.isEmpty || !_translations.containsKey(_currentLanguage)) {
      // Return key as fallback if translations not loaded yet
      return fallback ?? key;
    }

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

  /// Clear cache and reload translations
  Future<void> clearCacheAndReload() async {
    _translations.clear();
    await _prefs!.remove(_translationsKey);
    await _loadTranslationsForLanguage(_currentLanguage);
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
      'auth_password_min_length': 'Password must be at least 6 characters',
      'auth_passwords_not_match': 'Passwords do not match',
      'auth_enter_email': 'Please enter your email',
      'auth_enter_valid_email': 'Please enter a valid email',
      'auth_enter_password': 'Please enter your password',
      'auth_enter_name': 'Please enter your full name',
      'auth_demo_mode': 'Running in demo mode - Firebase features disabled',
      'auth_continue_demo': 'Continue (Demo)',
      'auth_account_created': 'Account created successfully! Welcome!',
      'auth_demo_account_created': 'Demo account created!',

      // Dashboard
      'dashboard_title': 'Dashboard',
      'dashboard_trending_stocks': 'Trending Stocks',
      'dashboard_no_stocks': 'Unable to load stocks',
      'dashboard_added_favorites': 'Added to favorites!',
      'dashboard_error_adding': 'Error: {error}',

      // Favorites
      'favorites_title': 'My Favorites',
      'favorites_no_favorites': 'No favorites yet',
      'favorites_add_from_dashboard':
          'Add stocks from Dashboard to generate AI summaries',
      'favorites_generate_summary': 'Generate AI Summary',
      'favorites_ai_summary': 'AI Summary:',
      'favorites_no_summary': 'No summary generated yet',
      'favorites_removed': 'Removed from favorites',
      'favorites_summary_coming': 'AI Summary generation coming soon...',
      'favorites_share_label': 'Share summary',
      'favorites_share_generating': 'Generating latest summary...',
      'favorites_share_missing': 'No summary available to share yet.',
      'favorites_share_error': 'Unable to share summary: {error}',

      // Stock Details
      'stock_brief_title': 'Company Brief',
      'stock_brief_sector': 'Sector',
      'stock_brief_market_cap': 'Market cap',
      'stock_brief_range': '52-week range',
      'stock_brief_exchange': 'Exchange',
      'stock_brief_country': 'Country',
      'stock_brief_website': 'Website',
      'stock_brief_about': 'About',
      'stock_brief_not_available': 'N/A',
      'stock_brief_error': 'Unable to load company details.',

      // Support
      'support_title': 'Contact Support',
      'support_description': 'Let us know how we can help. Our team will respond to your message via email.',
      'support_subject_label': 'Subject',
      'support_subject_hint': 'Briefly describe your issue',
      'support_message_label': 'Message',
      'support_message_hint': 'Share details that will help us assist you faster...',
      'support_submit': 'Send message',
      'support_submit_success': 'Thanks! Your message has been sent.',
      'support_submit_error': 'Unable to send message: {error}',
      'support_field_required': 'This field is required.',

      // Admin Support
      'admin_support_error': 'Unable to load support messages.',
      'admin_support_empty': 'No support messages yet.',
      'admin_support_detail_title': 'Support Ticket',
      'admin_support_status_label': 'Ticket status',
      'admin_support_save': 'Update status',
      'admin_support_update_success': 'Status updated.',
      'admin_support_update_error': 'Unable to update status: {error}',
      'admin_support_status_open': 'Open',
      'admin_support_status_in_progress': 'In progress',
      'admin_support_status_closed': 'Closed',
      'admin_support_tab': 'Support',

      // News
      'news_title': 'Financial News',
      'news_no_news': 'No news available',
      'news_read_more': 'Read more',

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
      'profile_no_email': 'No email',
      'profile_unable_load': 'Unable to load profile',

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
      'premium_subscribe': 'Subscribe',
      'premium_features_include': 'Premium features include:',
      'premium_monthly_summaries': '• 100 AI summaries per month',
      'premium_priority_support': '• Priority support',
      'premium_advanced_analytics': '• Advanced analytics',
      'premium_ad_free': '• Ad-free experience',
      'premium_price_info': 'Price: \$9.99/month',

      // Rewards
      'rewards_title': 'Get More Summaries',
      'rewards_watch_ad': 'Watch Rewarded Ad',
      'rewards_get_summary': 'Get +1 summary instantly',
      'rewards_watch': 'Watch',
      'rewards_watch_video':
          'Watch a short video ad to get +1 summary instantly.',
      'rewards_coming_soon': 'Rewarded ads coming soon...',

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
      'settings_help_coming': 'Help & Support coming soon...',
      'settings_privacy_coming': 'Privacy Policy coming soon...',
      'settings_sign_out_confirm': 'Sign Out',
      'settings_sign_out_question':
          'Are you sure you want to sign out of your account?',
      'settings_return_login': 'Return to login screen?',

      // Notifications
      'notif_settings_title': 'Notification Settings',
      'notif_settings_desc':
          'Control when and how you receive notifications from the app',
      'notif_push_notifications': 'Push Notifications',
      'notif_receive_notifications': 'Receive notifications from the app',
      'notif_all_disabled': 'All notifications are disabled',
      'notif_history_title': 'Notification History',
      'notif_history_desc': 'View all notifications you\'ve received',
      'notif_history_stats': '{total} total • {unread} unread',
      'notif_about_title': 'About Notifications',
      'notif_about_content':
          'You may receive notifications about:\n• Important app updates\n• Stock market alerts\n• System announcements\n• New features and improvements',
      'notif_status_active': 'Notifications Active',
      'notif_status_active_desc':
          'You will receive push notifications when enabled',
      'notif_status_disabled': 'Notifications Disabled',
      'notif_status_disabled_desc': 'You won\'t receive any push notifications',
      'notif_enabled_success': 'Notifications enabled successfully',
      'notif_disabled_success': 'Notifications disabled successfully',
      'notif_error_updating': 'Error updating notification settings: {error}',
      'notif_no_title': 'No Title',
      'notif_new': 'NEW',
      'notif_mark_read': 'Mark as Read',
      'notif_empty_title': 'No Notifications Yet',
      'notif_empty_desc':
          'You\'ll see your notifications here when you receive them',
      'notif_check': 'Check for Notifications',
      'notif_type_admin': 'Admin',
      'notif_type_system': 'System',
      'notif_type_stock': 'Stock',
      'notif_type_news': 'News',
      'notif_type_general': 'General',
      'notif_time_unknown': 'Unknown',
      'notif_time_now': 'Just now',
      'notif_time_minutes': '{minutes}m ago',
      'notif_time_hours': '{hours}h ago',
      'notif_time_days': '{days}d ago',

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
      'or': 'OR',
      'watch_ad': 'Watch Ad',

      // Errors
      'error_network': 'Network error. Please check your connection.',
      'error_unknown': 'An unknown error occurred.',
      'error_auth_failed': 'Authentication failed.',
      'error_quota_exceeded':
          'Summary quota exceeded. Please upgrade or watch an ad.',
      'error_sign_out': 'Error signing out: {error}',

      // Success messages
      'success_profile_updated': 'Profile updated successfully',
      'success_language_changed': 'Language changed successfully',
      'success_signed_out': 'Signed out successfully',

      // Restart
      'restart_required': 'Restart Required',
      'restart_required_desc':
          'Please restart the app for the language change to take effect.',
      'restart_now': 'Restart Now',
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
      // App Name
      'app_name': 'Resumen de Acciones IA',
      'app_tagline': 'Resúmenes de Acciones con IA',

      // Navigation
      'nav_dashboard': 'Panel',
      'nav_favorites': 'Favoritos',
      'nav_news': 'Noticias',
      'nav_profile': 'Perfil',
      'nav_admin': 'Admin',

      // Authentication
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
      'auth_forgot_password': '¿Olvidaste tu contraseña?',
      'auth_no_account': '¿No tienes cuenta? Regístrate',
      'auth_have_account': '¿Ya tienes cuenta? Inicia Sesión',
      'auth_password_min_length':
          'La contraseña debe tener al menos 6 caracteres',
      'auth_passwords_not_match': 'Las contraseñas no coinciden',
      'auth_enter_email': 'Por favor ingresa tu correo',
      'auth_enter_valid_email': 'Por favor ingresa un correo válido',
      'auth_enter_password': 'Por favor ingresa tu contraseña',
      'auth_enter_name': 'Por favor ingresa tu nombre completo',
      'auth_demo_mode':
          'Ejecutando en modo demo - Funciones de Firebase deshabilitadas',
      'auth_continue_demo': 'Continuar (Demo)',
      'auth_account_created': '¡Cuenta creada exitosamente! ¡Bienvenido!',
      'auth_demo_account_created': '¡Cuenta demo creada!',

      // Dashboard
      'dashboard_title': 'Panel',
      'dashboard_trending_stocks': 'Acciones en Tendencia',
      'dashboard_no_stocks': 'No se pueden cargar las acciones',
      'dashboard_added_favorites': '¡Agregado a favoritos!',
      'dashboard_error_adding': 'Error: {error}',

      // Favorites
      'favorites_title': 'Mis Favoritos',
      'favorites_no_favorites': 'Sin favoritos aún',
      'favorites_add_from_dashboard':
          'Agrega acciones desde el Panel para generar resúmenes IA',
      'favorites_generate_summary': 'Generar Resumen IA',
      'favorites_ai_summary': 'Resumen IA:',
      'favorites_no_summary': 'No se ha generado resumen aún',
      'favorites_removed': 'Eliminado de favoritos',
        'favorites_summary_coming': 'Generación de resúmenes IA próximamente...',
        'favorites_share_label': 'Compartir resumen',
        'favorites_share_generating': 'Generando el último resumen...',
        'favorites_share_missing': 'No hay un resumen disponible para compartir.',
        'favorites_share_error': 'No se pudo compartir el resumen: {error}',

        // Stock Details
        'stock_brief_title': 'Resumen de la compañía',
        'stock_brief_sector': 'Sector',
        'stock_brief_market_cap': 'Capitalización bursátil',
        'stock_brief_range': 'Rango de 52 semanas',
        'stock_brief_exchange': 'Bolsa',
        'stock_brief_country': 'País',
        'stock_brief_website': 'Sitio web',
        'stock_brief_about': 'Acerca de',
        'stock_brief_not_available': 'N/D',
        'stock_brief_error': 'No se pudieron cargar los detalles de la compañía.',

        // Support
        'support_title': 'Contactar soporte',
        'support_description': 'Cuéntanos cómo podemos ayudarte. Nuestro equipo responderá por correo electrónico.',
        'support_subject_label': 'Asunto',
        'support_subject_hint': 'Describe brevemente tu problema',
        'support_message_label': 'Mensaje',
        'support_message_hint': 'Comparte detalles que nos ayuden a asistirte más rápido...',
        'support_submit': 'Enviar mensaje',
        'support_submit_success': '¡Gracias! Tu mensaje ha sido enviado.',
        'support_submit_error': 'No se pudo enviar el mensaje: {error}',
        'support_field_required': 'Este campo es obligatorio.',

        // Admin Support
        'admin_support_error': 'No se pueden cargar los mensajes de soporte.',
        'admin_support_empty': 'Aún no hay mensajes de soporte.',
        'admin_support_detail_title': 'Ticket de soporte',
        'admin_support_status_label': 'Estado del ticket',
        'admin_support_save': 'Actualizar estado',
        'admin_support_update_success': 'Estado actualizado.',
        'admin_support_update_error': 'No se pudo actualizar el estado: {error}',
        'admin_support_status_open': 'Abierto',
        'admin_support_status_in_progress': 'En progreso',
        'admin_support_status_closed': 'Cerrado',
        'admin_support_tab': 'Soporte',

      // News
      'news_title': 'Noticias Financieras',
      'news_no_news': 'No hay noticias disponibles',
      'news_read_more': 'Leer más',

      // Profile
      'profile_title': 'Perfil',
      'profile_usage_stats': 'Estadísticas de Uso',
      'profile_subscription_type': 'Tipo de Suscripción',
      'profile_summaries_used': 'Resúmenes IA Usados',
      'profile_monthly_usage': 'Uso Mensual de Resúmenes',
      'profile_free': 'Gratis',
      'profile_premium': 'Premium',
      'profile_admin': 'Admin',
      'profile_user': 'Usuario',
      'profile_no_email': 'Sin correo',
      'profile_unable_load': 'No se puede cargar el perfil',

      // Usage
      'usage_remaining': '{count} resúmenes restantes este mes',
      'usage_remaining_singular': '1 resumen restante este mes',
      'usage_no_remaining': 'No quedan resúmenes este mes',
      'usage_resets_in': 'Se reinicia en {days} días',
      'usage_resets_today': 'Se reinicia hoy',
      'usage_resets_tomorrow': 'Se reinicia mañana',

      // Premium
      'premium_upgrade': 'Actualizar a Premium',
      'premium_unlock':
          'Desbloquea resúmenes IA ilimitados y funciones premium',
      'premium_features':
          '• 100 resúmenes IA por mes\n• Soporte prioritario\n• Análisis avanzado\n• Sin anuncios',
      'premium_price': 'Actualizar Ahora - \$9.99/mes',
      'premium_coming_soon': 'Suscripción premium próximamente...',
      'premium_subscribe': 'Suscribirse',
      'premium_features_include': 'Las funciones premium incluyen:',
      'premium_monthly_summaries': '• 100 resúmenes IA por mes',
      'premium_priority_support': '• Soporte prioritario',
      'premium_advanced_analytics': '• Análisis avanzado',
      'premium_ad_free': '• Experiencia sin anuncios',
      'premium_price_info': 'Precio: \$9.99/mes',

      // Rewards
      'rewards_title': 'Obtener Más Resúmenes',
      'rewards_watch_ad': 'Ver Anuncio Recompensado',
      'rewards_get_summary': 'Obtén +1 resumen instantáneamente',
      'rewards_watch': 'Ver',
      'rewards_watch_video':
          'Ve un video corto para obtener +1 resumen instantáneamente.',
      'rewards_coming_soon': 'Anuncios recompensados próximamente...',

      // Settings
      'settings_notifications': 'Notificaciones',
      'settings_notifications_desc': 'Administrar notificaciones push',
      'settings_language': 'Idioma',
      'settings_language_desc': 'Cambiar idioma de la aplicación',
      'settings_help': 'Ayuda y Soporte',
      'settings_help_desc': 'Obtener ayuda y contactar soporte',
      'settings_privacy': 'Política de Privacidad',
      'settings_privacy_desc': 'Ver nuestra política de privacidad',
      'settings_sign_out_desc': 'Cerrar sesión de tu cuenta',
      'settings_demo_sign_out': 'Volver al inicio de sesión',
      'settings_help_coming': 'Ayuda y Soporte próximamente...',
      'settings_privacy_coming': 'Política de Privacidad próximamente...',
      'settings_sign_out_confirm': 'Cerrar Sesión',
      'settings_sign_out_question':
          '¿Estás seguro de que quieres cerrar sesión?',
      'settings_return_login': '¿Volver a la pantalla de inicio de sesión?',

      // Notifications
      'notif_settings_title': 'Configuración de Notificaciones',
      'notif_settings_desc':
          'Controla cuándo y cómo recibes notificaciones de la aplicación',
      'notif_push_notifications': 'Notificaciones Push',
      'notif_receive_notifications': 'Recibir notificaciones de la aplicación',
      'notif_all_disabled': 'Todas las notificaciones están deshabilitadas',
      'notif_history_title': 'Historial de Notificaciones',
      'notif_history_desc': 'Ver todas las notificaciones que has recibido',
      'notif_history_stats': '{total} total • {unread} sin leer',
      'notif_about_title': 'Acerca de las Notificaciones',
      'notif_about_content':
          'Puedes recibir notificaciones sobre:\n• Actualizaciones importantes de la app\n• Alertas del mercado de valores\n• Anuncios del sistema\n• Nuevas funciones y mejoras',
      'notif_status_active': 'Notificaciones Activas',
      'notif_status_active_desc':
          'Recibirás notificaciones push cuando estén habilitadas',
      'notif_status_disabled': 'Notificaciones Deshabilitadas',
      'notif_status_disabled_desc': 'No recibirás ninguna notificación push',
      'notif_enabled_success': 'Notificaciones habilitadas exitosamente',
      'notif_disabled_success': 'Notificaciones deshabilitadas exitosamente',
      'notif_error_updating':
          'Error al actualizar configuración de notificaciones: {error}',
      'notif_no_title': 'Sin Título',
      'notif_new': 'NUEVA',
      'notif_mark_read': 'Marcar como Leída',
      'notif_empty_title': 'Sin Notificaciones Aún',
      'notif_empty_desc': 'Verás tus notificaciones aquí cuando las recibas',
      'notif_check': 'Buscar Notificaciones',
      'notif_type_admin': 'Admin',
      'notif_type_system': 'Sistema',
      'notif_type_stock': 'Acciones',
      'notif_type_news': 'Noticias',
      'notif_type_general': 'General',
      'notif_time_unknown': 'Desconocido',
      'notif_time_now': 'Ahora mismo',
      'notif_time_minutes': 'hace {minutes}m',
      'notif_time_hours': 'hace {hours}h',
      'notif_time_days': 'hace {days}d',

      // Admin
      'admin_title': 'Panel de Admin',
      'admin_send_notification': 'Enviar Notificación Push',
      'admin_manage_users': 'Administrar Usuarios',
      'admin_system_stats': 'Estadísticas del Sistema',

      // Common
      'save': 'Guardar',
      'cancel': 'Cancelar',
      'ok': 'OK',
      'yes': 'Sí',
      'no': 'No',
      'loading': 'Cargando...',
      'error': 'Error',
      'success': 'Éxito',
      'retry': 'Reintentar',
      'close': 'Cerrar',
      'edit': 'Editar',
      'delete': 'Eliminar',
      'add': 'Agregar',
      'remove': 'Eliminar',
      'update': 'Actualizar',
      'create': 'Crear',
      'search': 'Buscar',
      'filter': 'Filtrar',
      'sort': 'Ordenar',
      'refresh': 'Actualizar',
      'back': 'Atrás',
      'next': 'Siguiente',
      'previous': 'Anterior',
      'done': 'Hecho',
      'or': 'O',
      'watch_ad': 'Ver Anuncio',

      // Errors
      'error_network': 'Error de red. Por favor verifica tu conexión.',
      'error_unknown': 'Ocurrió un error desconocido.',
      'error_auth_failed': 'Autenticación fallida.',
      'error_quota_exceeded':
          'Cuota de resúmenes excedida. Por favor actualiza o ve un anuncio.',
      'error_sign_out': 'Error al cerrar sesión: {error}',

      // Success messages
      'success_profile_updated': 'Perfil actualizado exitosamente',
      'success_language_changed': 'Idioma cambiado exitosamente',
      'success_signed_out': 'Sesión cerrada exitosamente',

      // Restart
      'restart_required': 'Reinicio Requerido',
      'restart_required_desc':
          'Por favor reinicia la aplicación para que el cambio de idioma tenga efecto.',
      'restart_now': 'Reiniciar Ahora',
    };
  }

  /// French translations
  Future<Map<String, String>> _getFrenchTranslations() async {
    // First ensure English translations are loaded
    if (!_translations.containsKey('en')) {
      await _loadDefaultTranslations();
    }

    return {
      // App Name
      'app_name': 'Résumé d\'Actions IA',
      'app_tagline': 'Résumés d\'Actions Alimentés par IA',

      // Navigation
      'nav_dashboard': 'Tableau de Bord',
      'nav_favorites': 'Favoris',
      'nav_news': 'Actualités',
      'nav_profile': 'Profil',
      'nav_admin': 'Admin',

      // Authentication
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
      'auth_forgot_password': 'Mot de passe oublié?',
      'auth_no_account': 'Pas de compte? S\'inscrire',
      'auth_have_account': 'Déjà un compte? Se Connecter',

      // Profile
      'profile_title': 'Profil',
      'profile_usage_stats': 'Statistiques d\'Utilisation',
      'profile_subscription_type': 'Type d\'Abonnement',
      'profile_summaries_used': 'Résumés IA Utilisés',
      'profile_monthly_usage': 'Utilisation Mensuelle des Résumés',
      'profile_free': 'Gratuit',
      'profile_premium': 'Premium',
      'profile_admin': 'Admin',
      'profile_user': 'Utilisateur',

      // Usage
      'usage_remaining': '{count} résumés restants ce mois',
      'usage_remaining_singular': '1 résumé restant ce mois',
      'usage_no_remaining': 'Aucun résumé restant ce mois',
      'usage_resets_in': 'Se remet à zéro dans {days} jours',
      'usage_resets_today': 'Se remet à zéro aujourd\'hui',
      'usage_resets_tomorrow': 'Se remet à zéro demain',

      // Premium
      'premium_upgrade': 'Passer à Premium',
      'premium_unlock':
          'Débloquez des résumés IA illimités et des fonctionnalités premium',
      'premium_features':
          '• 100 résumés IA par mois\n• Support prioritaire\n• Analyses avancées\n• Sans publicité',
      'premium_price': 'Mettre à Niveau Maintenant - 9,99\$/mois',

      // Settings
      'settings_language': 'Langue',
      'settings_language_desc': 'Changer la langue de l\'application',
      'settings_notifications': 'Notifications',
      'settings_notifications_desc': 'Gérer les notifications push',
      'settings_help': 'Aide et Support',
      'settings_help_desc': 'Obtenir de l\'aide et contacter le support',
      'settings_privacy': 'Politique de Confidentialité',
      'settings_privacy_desc': 'Voir notre politique de confidentialité',

      // Common
      'save': 'Enregistrer',
      'cancel': 'Annuler',
      'loading': 'Chargement...',
      'error': 'Erreur',
      'success': 'Succès',
      'yes': 'Oui',
      'no': 'Non',

      // Add all missing translations with French defaults
      'dashboard_title': 'Tableau de Bord',
      'dashboard_trending_stocks': 'Actions Tendances',
      'dashboard_no_stocks': 'Impossible de charger les actions',
      'dashboard_added_favorites': 'Ajouté aux favoris!',
      'dashboard_error_adding': 'Erreur: {error}',
        'favorites_title': 'Mes Favoris',
        'favorites_no_favorites': 'Pas encore de favoris',
        'favorites_add_from_dashboard':
            'Ajoutez des actions depuis le Tableau de Bord pour générer des résumés IA',
        'favorites_generate_summary': 'Générer un Résumé IA',
        'favorites_ai_summary': 'Résumé IA:',
        'favorites_no_summary': 'Aucun résumé généré',
        'favorites_removed': 'Retiré des favoris',
        'favorites_summary_coming':
            'Génération de résumés IA bientôt disponible...',
        'favorites_share_label': 'Partager le résumé',
        'favorites_share_generating': 'Génération du dernier résumé...',
        'favorites_share_missing': 'Aucun résumé disponible à partager.',
        'favorites_share_error': 'Impossible de partager le résumé : {error}',

        // Stock Details
        'stock_brief_title': 'Aperçu de l\'entreprise',
        'stock_brief_sector': 'Secteur',
        'stock_brief_market_cap': 'Capitalisation boursière',
        'stock_brief_range': 'Fourchette sur 52 semaines',
        'stock_brief_exchange': 'Bourse',
        'stock_brief_country': 'Pays',
        'stock_brief_website': 'Site web',
        'stock_brief_about': 'À propos',
        'stock_brief_not_available': 'N/D',
        'stock_brief_error': 'Impossible de charger les informations de l\'entreprise.',

        // Support
        'support_title': 'Contacter le support',
        'support_description': 'Dites-nous comment nous pouvons vous aider. Notre équipe vous répondra par e-mail.',
        'support_subject_label': 'Objet',
        'support_subject_hint': 'Décrivez brièvement votre problème',
        'support_message_label': 'Message',
        'support_message_hint': 'Fournissez des détails pour nous aider à vous assister plus rapidement...',
        'support_submit': 'Envoyer le message',
        'support_submit_success': 'Merci ! Votre message a été envoyé.',
        'support_submit_error': "Impossible d'envoyer le message : {error}",
        'support_field_required': 'Ce champ est obligatoire.',

        // Admin Support
        'admin_support_error': 'Impossible de charger les messages de support.',
        'admin_support_empty': 'Aucun message de support pour le moment.',
        'admin_support_detail_title': 'Ticket de support',
        'admin_support_status_label': 'Statut du ticket',
        'admin_support_save': 'Mettre à jour le statut',
        'admin_support_update_success': 'Statut mis à jour.',
        'admin_support_update_error': 'Impossible de mettre à jour le statut : {error}',
        'admin_support_status_open': 'Ouvert',
        'admin_support_status_in_progress': 'En cours',
        'admin_support_status_closed': 'Fermé',
      'news_title': 'Actualités Financières',
      'news_no_news': 'Aucune actualité disponible',
      'news_read_more': 'Lire plus',
      'profile_no_email': 'Pas d\'email',
      'profile_unable_load': 'Impossible de charger le profil',
      'premium_coming_soon': 'Abonnement premium bientôt disponible...',
      'premium_subscribe': 'S\'abonner',
      'premium_features_include': 'Les fonctionnalités premium incluent:',
      'premium_monthly_summaries': '• 100 résumés IA par mois',
      'premium_priority_support': '• Support prioritaire',
      'premium_advanced_analytics': '• Analyses avancées',
      'premium_ad_free': '• Expérience sans publicité',
      'premium_price_info': 'Prix: 9,99\$/mois',
      'rewards_title': 'Obtenir Plus de Résumés',
      'rewards_watch_ad': 'Regarder une Publicité Récompensée',
      'rewards_get_summary': 'Obtenez +1 résumé instantanément',
      'rewards_watch': 'Regarder',
      'rewards_watch_video':
          'Regardez une courte vidéo pour obtenir +1 résumé instantanément.',
      'rewards_coming_soon': 'Publicités récompensées bientôt disponibles...',
      'settings_sign_out_desc': 'Se déconnecter de votre compte',
      'settings_demo_sign_out': 'Retour à la connexion',
      'settings_help_coming': 'Aide et Support bientôt disponibles...',
      'settings_privacy_coming':
          'Politique de Confidentialité bientôt disponible...',
      'settings_sign_out_confirm': 'Se Déconnecter',
      'settings_sign_out_question':
          'Êtes-vous sûr de vouloir vous déconnecter?',
      'settings_return_login': 'Retourner à l\'écran de connexion?',

      // Notifications
      'notif_settings_title': 'Paramètres de Notification',
      'notif_settings_desc':
          'Contrôlez quand et comment vous recevez des notifications de l\'application',
      'notif_push_notifications': 'Notifications Push',
      'notif_receive_notifications':
          'Recevoir des notifications de l\'application',
      'notif_all_disabled': 'Toutes les notifications sont désactivées',
      'notif_history_title': 'Historique des Notifications',
      'notif_history_desc':
          'Voir toutes les notifications que vous avez reçues',
      'notif_history_stats': '{total} total • {unread} non lues',
      'notif_about_title': 'À Propos des Notifications',
      'notif_about_content':
          'Vous pouvez recevoir des notifications sur:\n• Mises à jour importantes de l\'app\n• Alertes boursières\n• Annonces système\n• Nouvelles fonctionnalités et améliorations',
      'notif_status_active': 'Notifications Actives',
      'notif_status_active_desc':
          'Vous recevrez des notifications push lorsqu\'elles sont activées',
      'notif_status_disabled': 'Notifications Désactivées',
      'notif_status_disabled_desc': 'Vous ne recevrez aucune notification push',
      'notif_enabled_success': 'Notifications activées avec succès',
      'notif_disabled_success': 'Notifications désactivées avec succès',
      'notif_error_updating':
          'Erreur lors de la mise à jour des paramètres de notification: {error}',
      'notif_no_title': 'Sans Titre',
      'notif_new': 'NOUVEAU',
      'notif_mark_read': 'Marquer comme Lu',
      'notif_empty_title': 'Aucune Notification',
      'notif_empty_desc':
          'Vous verrez vos notifications ici quand vous les recevrez',
      'notif_check': 'Vérifier les Notifications',
      'notif_type_admin': 'Admin',
      'notif_type_system': 'Système',
      'notif_type_stock': 'Actions',
      'notif_type_news': 'Actualités',
      'notif_type_general': 'Général',
      'notif_time_unknown': 'Inconnu',
      'notif_time_now': 'À l\'instant',
      'notif_time_minutes': 'il y a {minutes}m',
      'notif_time_hours': 'il y a {hours}h',
      'notif_time_days': 'il y a {days}j',

      'admin_title': 'Panneau Admin',
      'admin_send_notification': 'Envoyer une Notification Push',
      'admin_manage_users': 'Gérer les Utilisateurs',
      'admin_system_stats': 'Statistiques du Système',
      'ok': 'OK',
      'retry': 'Réessayer',
      'close': 'Fermer',
      'edit': 'Modifier',
      'delete': 'Supprimer',
      'add': 'Ajouter',
      'remove': 'Retirer',
      'update': 'Mettre à jour',
      'create': 'Créer',
      'search': 'Rechercher',
      'filter': 'Filtrer',
      'sort': 'Trier',
      'refresh': 'Actualiser',
      'back': 'Retour',
      'next': 'Suivant',
      'previous': 'Précédent',
      'done': 'Terminé',
      'or': 'OU',
      'watch_ad': 'Regarder la Pub',
      'error_network': 'Erreur réseau. Veuillez vérifier votre connexion.',
      'error_unknown': 'Une erreur inconnue s\'est produite.',
      'error_auth_failed': 'Échec de l\'authentification.',
      'error_quota_exceeded':
          'Quota de résumés dépassé. Veuillez mettre à niveau ou regarder une publicité.',
      'error_sign_out': 'Erreur lors de la déconnexion: {error}',
      'success_profile_updated': 'Profil mis à jour avec succès',
      'success_language_changed': 'Langue changée avec succès',
      'success_signed_out': 'Déconnexion réussie',

      // Restart
      'restart_required': 'Redémarrage Requis',
      'restart_required_desc':
          'Veuillez redémarrer l\'application pour que le changement de langue prenne effet.',
      'restart_now': 'Redémarrer Maintenant',
      'auth_password_min_length':
          'Le mot de passe doit contenir au moins 6 caractères',
      'auth_passwords_not_match': 'Les mots de passe ne correspondent pas',
      'auth_enter_email': 'Veuillez entrer votre email',
      'auth_enter_valid_email': 'Veuillez entrer un email valide',
      'auth_enter_password': 'Veuillez entrer votre mot de passe',
      'auth_enter_name': 'Veuillez entrer votre nom complet',
      'auth_demo_mode': 'Mode démo - Fonctionnalités Firebase désactivées',
      'auth_continue_demo': 'Continuer (Démo)',
      'auth_account_created': 'Compte créé avec succès! Bienvenue!',
      'auth_demo_account_created': 'Compte démo créé!',
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
      'yes': 'Ja',
      'no': 'Nein',

      // Add all missing translations with German defaults
      'dashboard_title': 'Dashboard',
      'dashboard_trending_stocks': 'Trending Aktien',
      'dashboard_no_stocks': 'Aktien können nicht geladen werden',
      'dashboard_added_favorites': 'Zu Favoriten hinzugefügt!',
      'dashboard_error_adding': 'Fehler: {error}',
      'favorites_title': 'Meine Favoriten',
      'favorites_no_favorites': 'Noch keine Favoriten',
      'favorites_add_from_dashboard':
          'Fügen Sie Aktien vom Dashboard hinzu, um KI-Zusammenfassungen zu generieren',
      'favorites_generate_summary': 'KI-Zusammenfassung generieren',
      'favorites_ai_summary': 'KI-Zusammenfassung:',
      'favorites_no_summary': 'Noch keine Zusammenfassung generiert',
      'favorites_removed': 'Aus Favoriten entfernt',
        'favorites_summary_coming': 'KI-Zusammenfassungen kommen bald...',
        'favorites_share_label': 'Zusammenfassung teilen',
        'favorites_share_generating': 'Aktuelle Zusammenfassung wird erstellt...',
        'favorites_share_missing': 'Keine Zusammenfassung zum Teilen verfügbar.',
        'favorites_share_error': 'Zusammenfassung konnte nicht geteilt werden: {error}',

        // Stock Details
        'stock_brief_title': 'Unternehmensüberblick',
        'stock_brief_sector': 'Sektor',
        'stock_brief_market_cap': 'Marktkapitalisierung',
        'stock_brief_range': '52-Wochen-Spanne',
        'stock_brief_exchange': 'Börse',
        'stock_brief_country': 'Land',
        'stock_brief_website': 'Webseite',
        'stock_brief_about': 'Überblick',
        'stock_brief_not_available': 'k.A.',

        // Support
        'support_title': 'Support kontaktieren',
        'support_description': 'Teilen Sie uns mit, wie wir helfen können. Unser Team antwortet per E-Mail.',
        'support_subject_label': 'Betreff',
        'support_subject_hint': 'Beschreiben Sie Ihr Anliegen kurz',
        'support_message_label': 'Nachricht',
        'support_message_hint': 'Geben Sie Details an, die uns schneller helfen...',
        'support_submit': 'Nachricht senden',
        'support_submit_success': 'Danke! Ihre Nachricht wurde gesendet.',
        'support_submit_error': 'Nachricht konnte nicht gesendet werden: {error}',
        'support_field_required': 'Dieses Feld ist erforderlich.',

        // Admin Support
        'admin_support_error': 'Support-Nachrichten konnten nicht geladen werden.',
        'admin_support_empty': 'Noch keine Support-Nachrichten.',
        'admin_support_detail_title': 'Support-Ticket',
        'admin_support_status_label': 'Ticketstatus',
        'admin_support_save': 'Status aktualisieren',
        'admin_support_update_success': 'Status aktualisiert.',
        'admin_support_update_error': 'Status konnte nicht aktualisiert werden: {error}',
        'admin_support_status_open': 'Offen',
        'admin_support_status_in_progress': 'In Bearbeitung',
        'admin_support_status_closed': 'Geschlossen',
        'stock_brief_error': 'Unternehmensdetails konnten nicht geladen werden.',
      'news_title': 'Finanznachrichten',
      'news_no_news': 'Keine Nachrichten verfügbar',
      'news_read_more': 'Mehr lesen',
      'profile_no_email': 'Keine E-Mail',
      'profile_unable_load': 'Profil kann nicht geladen werden',
      'premium_coming_soon': 'Premium-Abonnement kommt bald...',
      'premium_subscribe': 'Abonnieren',
      'premium_features_include': 'Premium-Funktionen beinhalten:',
      'premium_monthly_summaries': '• 100 KI-Zusammenfassungen pro Monat',
      'premium_priority_support': '• Prioritäts-Support',
      'premium_advanced_analytics': '• Erweiterte Analysen',
      'premium_ad_free': '• Werbefreie Erfahrung',
      'premium_price_info': 'Preis: 9,99\$/Monat',
      'rewards_title': 'Mehr Zusammenfassungen erhalten',
      'rewards_watch_ad': 'Belohnungswerbung ansehen',
      'rewards_get_summary': 'Erhalten Sie sofort +1 Zusammenfassung',
      'rewards_watch': 'Ansehen',
      'rewards_watch_video':
          'Sehen Sie ein kurzes Video, um sofort +1 Zusammenfassung zu erhalten.',
      'rewards_coming_soon': 'Belohnungswerbung kommt bald...',
      'settings_notifications': 'Benachrichtigungen',
      'settings_notifications_desc': 'Push-Benachrichtigungen verwalten',
      'settings_help': 'Hilfe & Support',
      'settings_help_desc': 'Hilfe erhalten und Support kontaktieren',
      'settings_privacy': 'Datenschutzrichtlinie',
      'settings_privacy_desc': 'Unsere Datenschutzrichtlinie ansehen',
      'settings_sign_out_desc': 'Von Ihrem Konto abmelden',
      'settings_demo_sign_out': 'Zurück zur Anmeldung',
      'settings_help_coming': 'Hilfe & Support kommt bald...',
      'settings_privacy_coming': 'Datenschutzrichtlinie kommt bald...',
      'settings_sign_out_confirm': 'Abmelden',
      'settings_sign_out_question':
          'Sind Sie sicher, dass Sie sich abmelden möchten?',
      'settings_return_login': 'Zurück zum Anmeldebildschirm?',
      'admin_title': 'Admin-Panel',
      'admin_send_notification': 'Push-Benachrichtigung senden',
      'admin_manage_users': 'Benutzer verwalten',
      'admin_system_stats': 'Systemstatistiken',
      'ok': 'OK',
      'retry': 'Wiederholen',
      'close': 'Schließen',
      'edit': 'Bearbeiten',
      'delete': 'Löschen',
      'add': 'Hinzufügen',
      'remove': 'Entfernen',
      'update': 'Aktualisieren',
      'create': 'Erstellen',
      'search': 'Suchen',
      'filter': 'Filtern',
      'sort': 'Sortieren',
      'refresh': 'Aktualisieren',
      'back': 'Zurück',
      'next': 'Weiter',
      'previous': 'Zurück',
      'done': 'Fertig',
      'or': 'ODER',
      'watch_ad': 'Werbung ansehen',
      'error_network': 'Netzwerkfehler. Bitte überprüfen Sie Ihre Verbindung.',
      'error_unknown': 'Ein unbekannter Fehler ist aufgetreten.',
      'error_auth_failed': 'Authentifizierung fehlgeschlagen.',
      'error_quota_exceeded':
          'Zusammenfassungsquote überschritten. Bitte upgraden oder Werbung ansehen.',
      'error_sign_out': 'Fehler beim Abmelden: {error}',
      'success_profile_updated': 'Profil erfolgreich aktualisiert',
      'success_language_changed': 'Sprache erfolgreich geändert',
      'success_signed_out': 'Erfolgreich abgemeldet',
      'auth_forgot_password': 'Passwort vergessen?',
      'auth_no_account': 'Kein Konto? Registrieren',
      'auth_have_account': 'Bereits ein Konto? Anmelden',
      'auth_password_min_length': 'Passwort muss mindestens 6 Zeichen haben',
      'auth_passwords_not_match': 'Passwörter stimmen nicht überein',
      'auth_enter_email': 'Bitte E-Mail eingeben',
      'auth_enter_valid_email': 'Bitte gültige E-Mail eingeben',
      'auth_enter_password': 'Bitte Passwort eingeben',
      'auth_enter_name': 'Bitte vollständigen Namen eingeben',
      'auth_demo_mode': 'Demo-Modus - Firebase-Funktionen deaktiviert',
      'auth_continue_demo': 'Weiter (Demo)',
      'auth_account_created': 'Konto erfolgreich erstellt! Willkommen!',
      'auth_demo_account_created': 'Demo-Konto erstellt!',

      // Notifications
      'notif_settings_title': 'Benachrichtigungseinstellungen',
      'notif_settings_desc':
          'Steuern Sie, wann und wie Sie Benachrichtigungen von der App erhalten',
      'notif_push_notifications': 'Push-Benachrichtigungen',
      'notif_receive_notifications': 'Benachrichtigungen von der App erhalten',
      'notif_all_disabled': 'Alle Benachrichtigungen sind deaktiviert',
      'notif_history_title': 'Benachrichtigungsverlauf',
      'notif_history_desc': 'Alle erhaltenen Benachrichtigungen anzeigen',
      'notif_history_stats': '{total} gesamt • {unread} ungelesen',
      'notif_about_title': 'Über Benachrichtigungen',
      'notif_about_content':
          'Sie können Benachrichtigungen erhalten über:\n• Wichtige App-Updates\n• Börsenalarme\n• Systemankündigungen\n• Neue Funktionen und Verbesserungen',
      'notif_status_active': 'Benachrichtigungen Aktiv',
      'notif_status_active_desc':
          'Sie erhalten Push-Benachrichtigungen, wenn aktiviert',
      'notif_status_disabled': 'Benachrichtigungen Deaktiviert',
      'notif_status_disabled_desc':
          'Sie erhalten keine Push-Benachrichtigungen',
      'notif_enabled_success': 'Benachrichtigungen erfolgreich aktiviert',
      'notif_disabled_success': 'Benachrichtigungen erfolgreich deaktiviert',
      'notif_error_updating':
          'Fehler beim Aktualisieren der Benachrichtigungseinstellungen: {error}',
      'notif_no_title': 'Kein Titel',
      'notif_new': 'NEU',
      'notif_mark_read': 'Als gelesen markieren',
      'notif_empty_title': 'Noch keine Benachrichtigungen',
      'notif_empty_desc':
          'Sie sehen Ihre Benachrichtigungen hier, wenn Sie sie erhalten',
      'notif_check': 'Nach Benachrichtigungen suchen',
      'notif_type_admin': 'Admin',
      'notif_type_system': 'System',
      'notif_type_stock': 'Aktien',
      'notif_type_news': 'Nachrichten',
      'notif_type_general': 'Allgemein',
      'notif_time_unknown': 'Unbekannt',
      'notif_time_now': 'Gerade eben',
      'notif_time_minutes': 'vor {minutes}m',
      'notif_time_hours': 'vor {hours}h',
      'notif_time_days': 'vor {days}T',

      // Restart
      'restart_required': 'Neustart Erforderlich',
      'restart_required_desc':
          'Bitte starten Sie die App neu, damit die Sprachänderung wirksam wird.',
      'restart_now': 'Jetzt Neustarten',
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
