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
  bool _redesignEnabled = true;
  final StreamController<bool> _redesignStreamController =
      StreamController<bool>.broadcast();

  bool get isInitialized => _prefs != null;
  bool get redesignEnabled => _redesignEnabled;
  Stream<bool> get redesignStream => _redesignStreamController.stream;

  Future<void> initialize() async {
    if (_prefs != null) return;
    _prefs = await SharedPreferences.getInstance();
    // Force redesign ON and persist it
    _redesignEnabled = true;
    await _prefs!.setBool(_redesignKey, true);
    _redesignStreamController.add(true);
  }

  Future<void> setRedesignEnabled(bool enabled) async {
    if (_prefs == null) {
      await initialize();
    }
    // Ignore input and keep redesign ON
    _redesignEnabled = true;
    await _prefs!.setBool(_redesignKey, true);
    _redesignStreamController.add(true);
  }

  void dispose() {
    _redesignStreamController.close();
  }
}


