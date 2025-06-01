import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_service.dart';

/// User Data Service for offline-first user data management
/// Handles caching, usage tracking, and sync with Firebase
class UserDataService {
  static final UserDataService _instance = UserDataService._internal();
  factory UserDataService() => _instance;
  UserDataService._internal();

  static const String _userDataKey = 'user_data';
  static const String _usageDataKey = 'usage_data';
  static const String _adminUsersKey = 'admin_users';
  static const String _lastSyncKey = 'last_sync';

  SharedPreferences? _prefs;
  bool _isSettingUpAdmin = false; // Flag to prevent multiple concurrent setups

  /// Initialize the service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _ensureAdminUser();
  }

  /// Ensure erolrony91@gmail.com has admin permissions
  Future<void> _ensureAdminUser() async {
    const adminEmail = 'erolrony91@gmail.com';

    try {
      final currentUser = FirebaseService().currentUser;
      print('🔍 Checking admin user setup...');
      print('👤 Current user: ${currentUser?.email ?? 'No user'}');
      print('🎯 Target admin email: $adminEmail');

      if (currentUser?.email == adminEmail) {
        print(
          '✅ Current user matches admin email - setting up admin permissions',
        );

        // Update local cache first
        await _updateLocalUserRole('admin');
        print('✅ Local admin role updated');

        // Update usage data with admin limits
        final usageData = await getUsageData();
        usageData['summariesLimit'] = 1000; // Give admin high limit
        await _saveUsageData(usageData);
        print('✅ Admin usage limits set locally');

        // Try to update Firebase if online
        try {
          if (FirebaseService().isFirestoreAvailable) {
            await FirebaseService().firestore
                .collection('users')
                .doc(currentUser!.uid)
                .set({
                  'email': currentUser?.email,
                  'displayName': currentUser?.displayName,
                  'photoURL': currentUser?.photoURL,
                  'role': 'admin',
                  'summariesLimit': 1000,
                  'subscriptionType': 'admin',
                  'createdAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));
            print(
              '✅ Admin permissions updated in Firebase for ${currentUser?.email ?? 'Unknown'}',
            );
          } else {
            print(
              '⚠️ Firebase not available - admin permissions set locally only',
            );
          }
        } catch (e) {
          print('⚠️ Could not update admin permissions in Firebase: $e');
          print('✅ Admin permissions still active locally');
        }
      } else {
        print('ℹ️ Current user is not the designated admin user');
      }
    } catch (e) {
      print('❌ Error in _ensureAdminUser: $e');
    }
  }

  /// Get user data (with conversion from stored format)
  Future<Map<String, dynamic>> getUserData() async {
    await _ensureInitialized();

    try {
      final jsonString = _prefs!.getString(_userDataKey);
      if (jsonString != null) {
        final rawData = json.decode(jsonString) as Map<String, dynamic>;
        // Convert stored data back to proper types
        return _convertStoredData(rawData);
      }
    } catch (e) {
      print('❌ Error loading user data: $e');
    }

    // Return default user data if none exists
    final currentUser = FirebaseService().currentUser;
    return {
      'uid': currentUser?.uid ?? '',
      'email': currentUser?.email ?? 'user@example.com',
      'displayName': currentUser?.displayName ?? 'User',
      'photoURL': currentUser?.photoURL,
      'role': 'user',
      'subscriptionType': 'free',
      'language': 'en',
      'registrationDate': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Get usage statistics (offline-first)
  Future<Map<String, dynamic>> getUsageData() async {
    await _ensureInitialized();

    final cachedData = _prefs!.getString(_usageDataKey);
    Map<String, dynamic> usageData = {};

    if (cachedData != null) {
      usageData = json.decode(cachedData);
    }

    // Check if monthly reset is needed
    await _checkAndHandleMonthlyReset(usageData);

    return _ensureDefaultUsageData(usageData);
  }

  /// Track AI summary usage
  Future<bool> trackSummaryUsage() async {
    final usageData = await getUsageData();
    final currentUsed = usageData['summariesUsed'] as int;
    final limit = usageData['summariesLimit'] as int;

    if (currentUsed >= limit) {
      return false; // Quota exceeded
    }

    // Update usage
    usageData['summariesUsed'] = currentUsed + 1;
    usageData['lastUsedAt'] = DateTime.now().toIso8601String();

    // Save locally
    await _saveUsageData(usageData);

    // Sync to Firebase if online
    await _syncUsageToFirebase(usageData);

    return true;
  }

  /// Check remaining summaries
  Future<int> getRemainingSum() async {
    final usageData = await getUsageData();
    final used = usageData['summariesUsed'] as int;
    final limit = usageData['summariesLimit'] as int;
    return limit - used;
  }

  /// Get days until next reset
  Future<int> getDaysUntilReset() async {
    final usageData = await getUsageData();
    final registrationDate = DateTime.parse(usageData['registrationDate']);
    final now = DateTime.now();

    // Calculate next reset date (30 days from registration, then every 30 days)
    DateTime nextReset = registrationDate.add(const Duration(days: 30));
    while (nextReset.isBefore(now)) {
      nextReset = nextReset.add(const Duration(days: 30));
    }

    return nextReset.difference(now).inDays;
  }

  /// Check if user is admin
  Future<bool> isAdmin() async {
    try {
      final userData = await getUserData();
      final usageData = await getUsageData();
      final currentUser = FirebaseService().currentUser;

      print('🔍 Checking admin status...');
      print('👤 User email: ${currentUser?.email}');

      // Check admin status from multiple sources
      final roleFromUserData = userData['role'] as String?;
      final roleFromUsageData = usageData['role'] as String?;
      final emailIsAdmin = currentUser?.email == 'erolrony91@gmail.com';

      print('🔐 Role from userData: $roleFromUserData');
      print('🔐 Role from usageData: $roleFromUsageData');
      print('📧 Email matches admin: $emailIsAdmin');

      // Admin if ANY of these conditions are true:
      // 1. Role in user data is admin
      // 2. Role in usage data is admin
      // 3. Email matches admin email (fallback)
      final isAdmin =
          roleFromUserData == 'admin' ||
          roleFromUsageData == 'admin' ||
          emailIsAdmin;

      print('✅ Final admin result: $isAdmin');

      // If email matches admin but role isn't set, fix it
      if (emailIsAdmin && !isAdmin) {
        print('🔧 Fixing admin role for admin email...');
        await _updateLocalUserRole('admin');
        final updatedUsageData = await getUsageData();
        updatedUsageData['role'] = 'admin';
        await _saveUsageData(updatedUsageData);
        return true;
      }

      return isAdmin;
    } catch (e) {
      print('❌ Error checking admin status: $e');

      // Fallback: check if email matches admin email
      final currentUser = FirebaseService().currentUser;
      if (currentUser?.email == 'erolrony91@gmail.com') {
        print('🔧 Fallback: email matches admin, returning true');
        return true;
      }

      return false;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    final userData = await getUserData();
    userData.addAll(updates);
    userData['updatedAt'] = DateTime.now().toIso8601String();

    // Save locally
    await _saveUserData(userData);

    // Sync to Firebase if online
    await _syncUserDataToFirebase(userData);
  }

  /// Sync with Firebase when coming online
  Future<void> syncWithFirebase() async {
    if (!FirebaseService().isFirestoreAvailable) return;

    try {
      await _syncUserDataFromFirebase();
      await _syncUsageFromFirebase();

      final lastSync = DateTime.now().toIso8601String();
      await _prefs!.setString(_lastSyncKey, lastSync);

      print('✅ Successfully synced with Firebase');
    } catch (e) {
      print('❌ Error syncing with Firebase: $e');
    }
  }

  /// Ensure admin user setup after authentication (called after sign-in)
  Future<void> ensureAdminUserAfterAuth() async {
    const adminEmail = 'erolrony91@gmail.com';

    // Prevent multiple concurrent admin setups
    if (_isSettingUpAdmin) {
      print('⚠️ Admin setup already in progress, skipping...');
      return;
    }

    try {
      _isSettingUpAdmin = true;
      final currentUser = FirebaseService().currentUser;
      print('🔍 Post-auth admin setup for: ${currentUser?.email ?? 'No user'}');

      if (currentUser?.email == adminEmail) {
        print('✅ Admin user detected - setting up admin permissions');

        // First, clear all cached data to ensure fresh start
        print('🧹 Starting cache clear...');
        await _clearAllCachedData().timeout(const Duration(seconds: 3));
        print('✅ Cleared all cached data for fresh admin setup');

        // Force update local cache with admin role
        print('🔧 Updating local user role...');
        await _updateLocalUserRole('admin').timeout(const Duration(seconds: 2));
        print('✅ Local admin role updated');

        // Update usage data with admin limits
        print('📊 Updating usage data...');
        final usageData = await getUsageData().timeout(
          const Duration(seconds: 3),
        );
        usageData['summariesLimit'] = 1000; // Give admin high limit
        usageData['role'] = 'admin'; // Store role in usage data too
        usageData['subscriptionType'] = 'admin'; // Set subscription type
        await _saveUsageData(usageData).timeout(const Duration(seconds: 2));
        print('✅ Admin usage limits set locally');

        // Also update user data
        print('👤 Updating user data...');
        final userData = await getUserData().timeout(
          const Duration(seconds: 3),
        );
        userData['role'] = 'admin';
        userData['subscriptionType'] = 'admin';
        await _saveUserData(userData).timeout(const Duration(seconds: 2));
        print('✅ Admin user data updated locally');

        // Try to update Firebase if online (with timeout) - make this non-blocking
        print('🔥 Attempting Firebase update...');
        _updateFirebaseAsync(currentUser!); // Fire and forget

        // Verify the setup worked
        print('🔍 Starting admin verification...');
        await _verifyAdminSetup().timeout(const Duration(seconds: 3));

        print(
          '🎉 Admin setup complete for ${currentUser?.email ?? 'Unknown user'}',
        );
      } else {
        print('ℹ️ Current user is not the designated admin user');
      }
    } catch (e) {
      print('❌ Error in ensureAdminUserAfterAuth: $e');

      // Fallback: ensure basic admin setup even if something fails
      final currentUser = FirebaseService().currentUser;
      if (currentUser?.email == adminEmail) {
        print('🔧 Fallback: Setting basic admin permissions...');
        try {
          await _updateLocalUserRole(
            'admin',
          ).timeout(const Duration(seconds: 1));
          print('✅ Fallback admin setup completed');
        } catch (fallbackError) {
          print('❌ Fallback admin setup failed: $fallbackError');
        }
      }
    } finally {
      _isSettingUpAdmin = false;
    }
  }

  /// Update Firebase asynchronously without blocking
  void _updateFirebaseAsync(User currentUser) async {
    try {
      if (FirebaseService().isFirestoreAvailable) {
        await FirebaseService().firestore
            .collection('users')
            .doc(currentUser.uid)
            .set({
              'email': currentUser.email,
              'displayName': currentUser.displayName,
              'photoURL': currentUser.photoURL,
              'role': 'admin',
              'summariesLimit': 1000,
              'subscriptionType': 'admin',
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true))
            .timeout(const Duration(seconds: 10));
        print(
          '✅ Admin permissions updated in Firebase for ${currentUser.email ?? 'Unknown'}',
        );
      } else {
        print('⚠️ Firebase not available - admin permissions set locally only');
      }
    } catch (e) {
      print('⚠️ Could not update admin permissions in Firebase: $e');
      print('✅ Admin permissions still active locally');
    }
  }

  /// Clear all cached data
  Future<void> _clearAllCachedData() async {
    await _ensureInitialized();
    await _prefs!.remove(_userDataKey);
    await _prefs!.remove(_usageDataKey);
    await _prefs!.remove(_adminUsersKey);
    await _prefs!.remove(_lastSyncKey);
  }

  /// Verify admin setup worked correctly
  Future<void> _verifyAdminSetup() async {
    try {
      final userData = await getUserData();
      final usageData = await getUsageData();
      final adminCheck = await isAdmin();

      print('🔍 Admin setup verification:');
      print('   📝 User role: ${userData['role']}');
      print('   📊 Usage role: ${usageData['role']}');
      print('   📈 Usage limit: ${usageData['summariesLimit']}');
      print('   🔐 Is admin check: $adminCheck');

      if (adminCheck &&
          userData['role'] == 'admin' &&
          usageData['role'] == 'admin') {
        print('✅ Admin setup verification PASSED');
      } else {
        print('❌ Admin setup verification FAILED');
      }
    } catch (e) {
      print('❌ Error verifying admin setup: $e');
    }
  }

  /// Private helper methods

  Future<void> _ensureInitialized() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Map<String, dynamic> _ensureDefaultUserData(Map<String, dynamic> userData) {
    final currentUser = FirebaseService().currentUser;

    return {
      'uid': currentUser?.uid ?? '',
      'email': currentUser?.email ?? userData['email'] ?? '',
      'displayName':
          currentUser?.displayName ?? userData['displayName'] ?? 'User',
      'photoURL': currentUser?.photoURL ?? userData['photoURL'],
      'role': userData['role'] ?? 'user',
      'subscriptionType': userData['subscriptionType'] ?? 'free',
      'language': userData['language'] ?? 'en',
      'registrationDate':
          userData['registrationDate'] ?? DateTime.now().toIso8601String(),
      'updatedAt': userData['updatedAt'] ?? DateTime.now().toIso8601String(),
      ...userData,
    };
  }

  Map<String, dynamic> _ensureDefaultUsageData(Map<String, dynamic> usageData) {
    final defaultLimit = usageData['role'] == 'admin' ? 1000 : 10;

    return {
      'summariesUsed': usageData['summariesUsed'] ?? 0,
      'summariesLimit': usageData['summariesLimit'] ?? defaultLimit,
      'lastResetDate':
          usageData['lastResetDate'] ?? DateTime.now().toIso8601String(),
      'registrationDate':
          usageData['registrationDate'] ?? DateTime.now().toIso8601String(),
      'monthlyUsageHistory': usageData['monthlyUsageHistory'] ?? [],
      ...usageData,
    };
  }

  Future<void> _checkAndHandleMonthlyReset(
    Map<String, dynamic> usageData,
  ) async {
    final registrationDate = DateTime.parse(
      usageData['registrationDate'] ?? DateTime.now().toIso8601String(),
    );
    final lastResetDate = DateTime.parse(
      usageData['lastResetDate'] ?? DateTime.now().toIso8601String(),
    );
    final now = DateTime.now();

    // Calculate if 30 days have passed since last reset
    final daysSinceReset = now.difference(lastResetDate).inDays;

    if (daysSinceReset >= 30) {
      // Reset usage
      final previousUsage = usageData['summariesUsed'] ?? 0;
      usageData['summariesUsed'] = 0;
      usageData['lastResetDate'] = now.toIso8601String();

      // Add to history
      List<dynamic> history = usageData['monthlyUsageHistory'] ?? [];
      history.add({
        'month': '${now.year}-${now.month.toString().padLeft(2, '0')}',
        'usage': previousUsage,
        'resetDate': now.toIso8601String(),
      });

      // Keep only last 12 months
      if (history.length > 12) {
        history = history.sublist(history.length - 12);
      }
      usageData['monthlyUsageHistory'] = history;

      await _saveUsageData(usageData);
      print('🔄 Monthly usage reset completed');
    }
  }

  /// Save user data to local storage (with conversion)
  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    await _ensureInitialized();
    try {
      // Convert data before storing
      final convertedData = _convertFirebaseData(userData);
      await _prefs!.setString(_userDataKey, json.encode(convertedData));
      print('💾 User data saved locally');
    } catch (e) {
      print('❌ Error saving user data: $e');
    }
  }

  Future<void> _saveUsageData(Map<String, dynamic> usageData) async {
    await _ensureInitialized();
    await _prefs!.setString(_usageDataKey, json.encode(usageData));
  }

  Future<void> _updateLocalUserRole(String role) async {
    final userData = await getUserData();
    userData['role'] = role;
    await _saveUserData(userData);
  }

  /// Helper method to convert Firebase data for local storage
  Map<String, dynamic> _convertFirebaseData(Map<String, dynamic> data) {
    final converted = <String, dynamic>{};

    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value is FieldValue) {
        // Skip FieldValue objects as they can't be stored locally
        continue;
      } else if (value is Timestamp) {
        // Convert Timestamp to ISO string
        converted[key] = value.toDate().toIso8601String();
      } else if (value is DateTime) {
        // Convert DateTime to ISO string
        converted[key] = value.toIso8601String();
      } else {
        // Keep other values as-is
        converted[key] = value;
      }
    }

    return converted;
  }

  /// Helper method to convert stored data back to proper types
  Map<String, dynamic> _convertStoredData(Map<String, dynamic> data) {
    final converted = <String, dynamic>{};

    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value is String &&
          (key.contains('Date') ||
              key.contains('At') ||
              key == 'registrationDate' ||
              key == 'updatedAt' ||
              key == 'createdAt' ||
              key == 'lastResetDate')) {
        // Try to convert ISO string back to DateTime
        try {
          converted[key] = DateTime.parse(value);
        } catch (e) {
          converted[key] = value; // Keep as string if parsing fails
        }
      } else {
        converted[key] = value;
      }
    }

    return converted;
  }

  /// Sync user data from Firebase (if online)
  Future<void> _syncUserDataFromFirebase() async {
    try {
      final currentUser = FirebaseService().currentUser;
      if (currentUser == null || !FirebaseService().isFirestoreAvailable) {
        print(
          '⚠️ Skipping Firebase sync - user not authenticated or Firestore unavailable',
        );
        return;
      }

      print('🔄 Syncing user data from Firebase...');

      final userDoc =
          await FirebaseService().firestore
              .collection('users')
              .doc(currentUser.uid)
              .get();

      if (userDoc.exists) {
        final firebaseData = userDoc.data() as Map<String, dynamic>;
        print('📥 Retrieved user data from Firebase');

        // Convert Firebase data for local storage
        final convertedData = _convertFirebaseData(firebaseData);

        await _updateLocalUserData(convertedData);
        print('✅ User data synced and cached locally');
      } else {
        print('📝 No user document found in Firebase');
      }
    } catch (e) {
      print('❌ Error syncing user data from Firebase: $e');
      // Don't throw - allow offline operation
    }
  }

  Future<void> _syncUserDataToFirebase(Map<String, dynamic> userData) async {
    if (!FirebaseService().isFirestoreAvailable) return;

    try {
      final currentUser = FirebaseService().currentUser;
      if (currentUser == null) return;

      // Remove local-only fields
      final firebaseData = Map<String, dynamic>.from(userData);
      firebaseData.remove('uid');
      firebaseData['updatedAt'] = FieldValue.serverTimestamp();

      await FirebaseService().firestore
          .collection('users')
          .doc(currentUser.uid)
          .set(firebaseData, SetOptions(merge: true))
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      print('❌ Error syncing user data to Firebase: $e');
    }
  }

  Future<void> _syncUsageFromFirebase() async {
    if (!FirebaseService().isFirestoreAvailable) return;

    try {
      final currentUser = FirebaseService().currentUser;
      if (currentUser == null) return;

      final doc = await FirebaseService().firestore
          .collection('users')
          .doc(currentUser.uid)
          .get()
          .timeout(const Duration(seconds: 5));

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final usageData = {
          'summariesUsed': data['summariesUsed'] ?? 0,
          'summariesLimit': data['summariesLimit'] ?? 10,
          'lastResetDate':
              data['lastResetDate']?.toDate()?.toIso8601String() ??
              DateTime.now().toIso8601String(),
          'registrationDate':
              data['createdAt']?.toDate()?.toIso8601String() ??
              DateTime.now().toIso8601String(),
          'monthlyUsageHistory': data['monthlyUsageHistory'] ?? [],
        };

        await _saveUsageData(usageData);
      }
    } catch (e) {
      print('❌ Error syncing usage data from Firebase: $e');
    }
  }

  Future<void> _syncUsageToFirebase(Map<String, dynamic> usageData) async {
    if (!FirebaseService().isFirestoreAvailable) return;

    try {
      final currentUser = FirebaseService().currentUser;
      if (currentUser == null) return;

      await FirebaseService().firestore
          .collection('users')
          .doc(currentUser.uid)
          .update({
            'summariesUsed': usageData['summariesUsed'],
            'summariesLimit': usageData['summariesLimit'],
            'lastResetDate': FieldValue.serverTimestamp(),
            'monthlyUsageHistory': usageData['monthlyUsageHistory'],
            'updatedAt': FieldValue.serverTimestamp(),
          })
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      print('❌ Error syncing usage data to Firebase: $e');
    }
  }

  /// Update local user data with converted data
  Future<void> _updateLocalUserData(Map<String, dynamic> data) async {
    final currentUser = FirebaseService().currentUser;

    // Merge with current data, preserving local changes
    final currentData = await getUserData();
    final mergedData = {
      ...currentData,
      ...data,
      'uid': currentUser?.uid,
      'email': currentUser?.email,
      'displayName': currentUser?.displayName,
      'photoURL': currentUser?.photoURL,
    };

    await _saveUserData(mergedData);
  }
}
