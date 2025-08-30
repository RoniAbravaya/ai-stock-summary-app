import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

/// FeatureFlagService manages experiment/feature toggles with persistence.
/// Currently supports a redesign toggle that gates the new UI theme.
class FeatureFlagService {
  static final FeatureFlagService _instance = FeatureFlagService._internal();
  factory FeatureFlagService() => _instance;
  FeatureFlagService._internal();

  static const String _redesignKey = 'feature_redesign_enabled';

  SharedPreferences? _prefs;
  bool _redesignEnabled = false;
  final StreamController<bool> _redesignStreamController =
      StreamController<bool>.broadcast();

  bool get isInitialized => _prefs != null;
  bool get redesignEnabled => _redesignEnabled;
  Stream<bool> get redesignStream => _redesignStreamController.stream;

  Future<void> initialize() async {
    if (_prefs != null) return;
    _prefs = await SharedPreferences.getInstance();
    _redesignEnabled = _prefs!.getBool(_redesignKey) ?? false;
  }

  Future<void> setRedesignEnabled(bool enabled) async {
    if (_prefs == null) {
      await initialize();
    }
    _redesignEnabled = enabled;
    await _prefs!.setBool(_redesignKey, enabled);
    _redesignStreamController.add(enabled);
  }

  void dispose() {
    _redesignStreamController.close();
  }
}


