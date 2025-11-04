import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

/// Firebase Service for Flutter
/// Handles authentication, Firestore operations, and other Firebase services
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Firebase instances (lazy to avoid crashes in tests where Firebase isn't initialized)
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  FirebaseMessaging? _messaging;
  FirebaseStorage? _storage;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Connection status
  bool _isFirestoreAvailable = false;
  DateTime? _lastConnectionCheck;
  final bool _isAuthAvailable = true; // Added for Google Sign-In

  // Getters
  FirebaseAuth get auth {
    if (_auth != null) return _auth!;
    if (Firebase.apps.isEmpty) {
      throw Exception('Firebase not initialized. Call Firebase.initializeApp() first.');
    }
    _auth = FirebaseAuth.instance;
    return _auth!;
  }

  FirebaseFirestore get firestore {
    if (_firestore != null) return _firestore!;
    if (Firebase.apps.isEmpty) {
      throw Exception('Firebase not initialized. Call Firebase.initializeApp() first.');
    }
    _firestore = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'flutter-database',
    );
    return _firestore!;
  }

  FirebaseMessaging get messaging {
    if (_messaging != null) return _messaging!;
    if (Firebase.apps.isEmpty) {
      throw Exception('Firebase not initialized. Call Firebase.initializeApp() first.');
    }
    _messaging = FirebaseMessaging.instance;
    return _messaging!;
  }

  FirebaseStorage get storage {
    if (_storage != null) return _storage!;
    if (Firebase.apps.isEmpty) {
      throw Exception('Firebase not initialized. Call Firebase.initializeApp() first.');
    }
    _storage = FirebaseStorage.instance;
    return _storage!;
  }
  User? get currentUser => _auth?.currentUser;
  bool get isSignedIn => _auth?.currentUser != null;
  bool get isFirestoreAvailable => _isFirestoreAvailable;

  /// Initialize Firebase services
  Future<void> initialize() async {
    print('🔧 Initializing Firebase services...');

    // Test Firebase connection first
    await _checkFirestoreConnection();

    if (!_isFirestoreAvailable) {
      print('⚠️ Firestore not available, running in offline mode');
      return;
    }

    try {
      // Initialize FCM token handling according to Firebase documentation
      await _initializeFCM();

      // Check if FCM token refresh was requested for this user
      await _checkForFCMRefreshRequest();

      print('✅ Firebase services initialized successfully');
    } catch (e) {
      print('❌ Firebase initialization error: $e');
    }
  }

  /// Check if FCM token refresh was requested and handle it
  Future<void> _checkForFCMRefreshRequest() async {
    try {
      final user = _auth?.currentUser;
      if (user == null) return;

      final doc = await firestore.collection('users').doc(user.uid).get();
      final userData = doc.data();
      
      if (userData?['fcmTokenRefreshRequested'] == true) {
        print('🔄 FCM token refresh was requested for this user');
        
        // Force refresh the FCM token
        await forceFCMTokenUpdate();
        
        // Clear the refresh request flag
        await firestore.collection('users').doc(user.uid).set({
          'fcmTokenRefreshRequested': false,
          'fcmTokenRefreshProcessedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        print('✅ FCM token refresh request processed');
      }
    } catch (e) {
      print('⚠️ Error checking FCM refresh request: $e');
    }
  }

  /// Initialize Firebase Cloud Messaging according to documentation
  Future<void> _initializeFCM() async {
    try {
      if (Firebase.apps.isEmpty) {
        // In tests or pre-init environments, skip
        return;
      }
      print('🔧 Initializing Firebase Cloud Messaging...');

      // Request notification permissions
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print(
          '📱 Notification permission granted: ${settings.authorizationStatus}',
        );
      } else {
        print(
          '⚠️ Notification permission denied: ${settings.authorizationStatus}',
        );
      }

      // Get and store FCM registration token according to documentation
      await _getFCMTokenSafely();

      // Listen for token refresh as recommended in documentation
      FirebaseMessaging.instance.onTokenRefresh.listen(_onTokenRefresh);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      print('✅ FCM initialization complete');
    } catch (e) {
      print('❌ FCM initialization error: $e');
    }
  }

  /// Prompt Android 13+ POST_NOTIFICATIONS runtime permission if needed
  Future<void> ensureAndroidNotificationPermission() async {
    try {
      if (Firebase.apps.isEmpty) return; // Skip in tests where Firebase is not initialized
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.notDetermined ||
          settings.authorizationStatus == AuthorizationStatus.denied) {
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } catch (e) {
      print('⚠️ ensureAndroidNotificationPermission error: $e');
    }
  }

  /// Get FCM registration token safely (as per Firebase documentation)
  Future<void> _getFCMTokenSafely() async {
    try {
      // Get FCM registration token as specified in documentation
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        print('📱 FCM Registration Token: ${token.substring(0, 20)}...');

        // Store token in user document for push notifications
        await _storeFCMToken(token);
      } else {
        print('⚠️ Failed to get FCM registration token');
      }
    } catch (e) {
      print('❌ Error getting FCM token: $e');
    }
  }

  // Store pending FCM token if user is not authenticated yet
  String? _pendingFCMToken;

  /// Store FCM token in user document for admin notifications
  Future<void> _storeFCMToken(String token) async {
    try {
      final user = _auth?.currentUser;
      print('🔍 Storing FCM token - User: ${user?.uid}, Firestore: $_isFirestoreAvailable');
      
      if (user == null) {
        print('⚠️ User not authenticated yet, storing FCM token for later: ${token.substring(0, 20)}...');
        _pendingFCMToken = token;
        return;
      }
      
      if (!_isFirestoreAvailable) {
        print('❌ Cannot store FCM token: Firestore not available');
        return;
      }

      // Use set with merge to ensure the document exists
      await firestore.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      print('✅ FCM token stored in user document for ${user.email}');
      
      // Clear pending token since it's now stored
      _pendingFCMToken = null;
      
      // Verify the token was actually stored
      final doc = await firestore.collection('users').doc(user.uid).get();
      final storedToken = doc.data()?['fcmToken'];
      if (storedToken == token) {
        print('✅ FCM token storage verified');
      } else {
        print('⚠️ FCM token storage verification failed');
      }
      
    } catch (e) {
      print('❌ Error storing FCM token: $e');
      print('❌ Error details: ${e.toString()}');
    }
  }

  /// Store any pending FCM token after user authentication
  Future<void> _storePendingFCMToken() async {
    if (_pendingFCMToken != null) {
      print('🔄 Storing pending FCM token after authentication');
      final token = _pendingFCMToken!;
      _pendingFCMToken = null; // Clear it first to avoid recursion
      await _storeFCMToken(token);
    }
  }

  /// Handle token refresh (as recommended in Firebase documentation)
  Future<void> _onTokenRefresh(String token) async {
    print('🔄 FCM Token refreshed: ${token.substring(0, 20)}...');
    await _storeFCMToken(token);
  }

  /// Handle foreground messages (as per Firebase documentation)
  void _handleForegroundMessage(RemoteMessage message) {
    print('📨 Foreground message received: ${message.messageId}');
    print('   - Title: ${message.notification?.title}');
    print('   - Body: ${message.notification?.body}');

    // You can show in-app notifications here
    // For now, just log the message
  }

  /// Refresh FCM token for notification re-registration
  Future<void> refreshFCMToken() async {
    try {
      print('🔄 Starting FCM token refresh...');
      await FirebaseMessaging.instance.deleteToken();
      await Future.delayed(Duration(seconds: 1)); // Small delay to ensure deletion
      await _getFCMTokenSafely();
      print('✅ FCM token refreshed successfully');
    } catch (e) {
      print('❌ Error refreshing FCM token: $e');
    }
  }

  /// Force FCM token update (for debugging)
  Future<void> forceFCMTokenUpdate() async {
    try {
      print('🔧 Forcing FCM token update...');
      final token = await FirebaseMessaging.instance.getToken(
        vapidKey: null, // Force refresh
      );
      
      if (token != null) {
        print('📱 New FCM token obtained: ${token.substring(0, 20)}...');
        await _storeFCMToken(token);
      } else {
        print('❌ Failed to get new FCM token');
      }
    } catch (e) {
      print('❌ Error forcing FCM token update: $e');
    }
  }

  /// Check if current user has FCM token and refresh if missing
  Future<bool> ensureFCMTokenExists() async {
    try {
      final user = _auth?.currentUser;
      if (user == null || !_isFirestoreAvailable) {
        print('⚠️ Cannot check FCM token: User not authenticated or Firestore unavailable');
        return false;
      }

      print('🔍 Checking if user has FCM token...');
      
      // Check current token in Firestore
      final doc = await firestore.collection('users').doc(user.uid).get();
      final userData = doc.data();
      final currentToken = userData?['fcmToken'];

      if (currentToken == null || currentToken.toString().trim().isEmpty) {
        print('⚠️ User missing FCM token, attempting to refresh...');
        
        // Try to get a new token
        await _getFCMTokenSafely();
        
        // Verify the token was stored
        final updatedDoc = await firestore.collection('users').doc(user.uid).get();
        final updatedData = updatedDoc.data();
        final newToken = updatedData?['fcmToken'];
        
        if (newToken != null && newToken.toString().trim().isNotEmpty) {
          print('✅ FCM token successfully refreshed for user');
          return true;
        } else {
          print('❌ Failed to refresh FCM token for user');
          return false;
        }
      } else {
        print('✅ User already has FCM token');
        return true;
      }
    } catch (e) {
      print('❌ Error ensuring FCM token exists: $e');
      return false;
    }
  }

  /// Bulk refresh FCM token for users without tokens (admin function)
  Future<Map<String, dynamic>> refreshMissingFCMTokens() async {
    try {
      print('🔧 Starting bulk FCM token refresh...');
      
      if (!_isFirestoreAvailable) {
        throw Exception('Firestore not available');
      }

      final user = _auth?.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if current user is admin
      final userDoc = await firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      if (userData?['role'] != 'admin') {
        throw Exception('Insufficient permissions - admin role required');
      }

      int successCount = 0;
      int failureCount = 0;
      List<String> processedUsers = [];

      // Get all users without FCM tokens
      final usersWithoutTokensQuery = await firestore
          .collection('users')
          .get();

      for (final doc in usersWithoutTokensQuery.docs) {
        final userData = doc.data();
        final fcmToken = userData['fcmToken'];
        
        // Skip users who already have tokens
        if (fcmToken != null && fcmToken.toString().trim().isNotEmpty) {
          continue;
        }

        try {
          // For each user without a token, we can't directly generate their token
          // as that requires the user's device. Instead, we'll mark them for refresh
          await firestore.collection('users').doc(doc.id).set({
            'fcmTokenRefreshRequested': true,
            'fcmTokenRefreshRequestedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          
          processedUsers.add(userData['email'] ?? doc.id);
          successCount++;
          
        } catch (e) {
          print('❌ Failed to mark user ${doc.id} for FCM refresh: $e');
          failureCount++;
        }
      }

      final result = {
        'success': failureCount == 0,
        'successCount': successCount,
        'failureCount': failureCount,
        'processedUsers': processedUsers,
        'message': 'Marked $successCount users for FCM token refresh'
      };

      print('✅ Bulk FCM token refresh completed: $successCount success, $failureCount failures');
      return result;

    } catch (e) {
      print('❌ Error in bulk FCM token refresh: $e');
      return {
        'success': false,
        'error': e.toString(),
        'successCount': 0,
        'failureCount': 0,
        'processedUsers': [],
      };
    }
  }

  /// Check if Firestore is available and responsive
  Future<void> _checkFirestoreConnection() async {
    try {
      if (Firebase.apps.isEmpty) {
        _isFirestoreAvailable = false;
        print('⚠️ Firestore not available: Firebase not initialized');
        return;
      }
      // Only check connection every 30 seconds to avoid repeated checks
      if (_lastConnectionCheck != null &&
          DateTime.now().difference(_lastConnectionCheck!).inSeconds < 30) {
        return;
      }

      _lastConnectionCheck = DateTime.now();

      // Try to read from Firestore with timeout
      await firestore
          .collection('_health')
          .doc('check')
          .get()
          .timeout(const Duration(seconds: 3));

      _isFirestoreAvailable = true;
      print('✅ Firestore connection successful');
    } catch (e) {
      _isFirestoreAvailable = false;
      print('⚠️ Firestore not available: $e');
    }
  }

  /// Sign in with email and password
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      // Add better error handling for type casting issues
      UserCredential result = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Ensure we have a valid user before proceeding
      if (result.user == null) {
        throw Exception('Authentication failed - no user returned');
      }

      // Check Firestore connection before proceeding
      await _checkFirestoreConnection();

      if (_isFirestoreAvailable && result.user != null) {
        try {
          await _updateUserDocumentSafely(result.user!);
          
          // Store any pending FCM token first
          await _storePendingFCMToken();
          
          // Ensure FCM token exists and refresh if missing
          final hasToken = await ensureFCMTokenExists();
          if (!hasToken) {
            print('⚠️ FCM token refresh failed during sign-in');
          }
        } catch (firestoreError) {
          print('⚠️ Firestore operations failed: $firestoreError');
          // Don't fail the whole sign-in process for Firestore issues
        }
      }

      // Setup admin user after successful authentication (ensures admin status is correct)
      await _setupAdminUserAfterAuth();

      return result;
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      throw Exception(_getAuthErrorMessage(e.code));
    } catch (e) {
      print('❌ Error signing in with email: $e');
      // Handle type casting and other errors gracefully
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('type cast')) {
        // Check if authentication was actually successful
        if (_auth?.currentUser != null && _auth!.currentUser!.email == email) {
          print('✅ Sign-in actually successful despite type casting error');

          // Ensure user document is properly updated
          if (_isFirestoreAvailable) {
            try {
              await _updateUserDocumentSafely(_auth!.currentUser!);
              await _storePendingFCMToken();
            } catch (docError) {
              print(
                '⚠️ User document update failed after type cast error: $docError',
              );
            }
          }

          // Setup admin user after successful authentication
          await _setupAdminUserAfterAuth();

          return null; // Signal successful sign-in despite error
        } else {
          throw Exception(
            'Authentication service temporarily unavailable. Please try again.',
          );
        }
      }
      rethrow;
    }
  }

  /// Get user-friendly error messages
  String _getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'invalid-credential':
        return 'Invalid email or password. Please check your credentials.';
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  /// Register with email and password
  Future<UserCredential?> registerWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      print('🔄 Starting email registration for: $email');

      UserCredential result = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('✅ Email registration successful for: ${result.user?.email}');

      // Ensure we have a valid user before proceeding
      if (result.user == null) {
        throw Exception('Registration failed - no user returned');
      }

      // Update user profile with better error handling
      try {
        await result.user!.updateDisplayName(displayName);
        print('✅ Display name updated successfully');
      } catch (profileError) {
        print('⚠️ Failed to update display name: $profileError');
        // Continue with registration even if display name update fails
      }

      // Check Firestore connection before proceeding
      await _checkFirestoreConnection();

      if (_isFirestoreAvailable && result.user != null) {
        try {
          // Create user document with retry mechanism
          await _createUserDocumentWithRetry(result.user!);
          await _getFCMTokenSafely();
          print('✅ User document created successfully');
        } catch (firestoreError) {
          print('⚠️ Firestore operations failed: $firestoreError');
          // Don't fail the whole registration process for Firestore issues
        }
      }

      // Setup admin user after successful authentication (no longer depends on UserDataService)
      await _setupAdminUserAfterAuth();

      return result;
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      throw Exception(_getAuthErrorMessage(e.code));
    } catch (e) {
      print('❌ Error registering with email: $e');

      // Handle type casting and other errors gracefully
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('type cast') ||
          e.toString().contains('List<Object?>')) {
        print(
          '⚠️ Type casting issue detected - checking if registration was successful...',
        );

        // The registration might have been successful despite the error
        if (_auth?.currentUser != null && _auth!.currentUser!.email == email) {
          print(
            '✅ Registration actually successful despite type casting error',
          );

          // Ensure user document is created even with type casting error
          if (_isFirestoreAvailable) {
            try {
              await _createUserDocumentWithRetry(_auth!.currentUser!);
            } catch (docError) {
              print(
                '⚠️ User document creation failed after type cast error: $docError',
              );
            }
          }

          // Setup admin user after successful authentication
          await _setupAdminUserAfterAuth();

          // Return success even though there was a type casting error
          return null; // Signal successful registration despite error
        } else {
          throw Exception(
            'Registration failed due to authentication service error. Please try again.',
          );
        }
      }
      rethrow;
    }
  }

  /// Create user document with retry mechanism
  Future<void> _createUserDocumentWithRetry(User user) async {
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        print('📝 Creating user document (attempt $attempt)...');
        await _createUserDocumentSafely(user);
        print('✅ User document created successfully on attempt $attempt');
        return;
      } catch (e) {
        print('❌ User document creation attempt $attempt failed: $e');
        if (attempt == 3) {
          print('❌ All user document creation attempts failed');
          rethrow;
        }
        await Future.delayed(Duration(seconds: attempt)); // Progressive delay
      }
    }
  }

  /// Central function to handle OAuth sign-in with automatic account linking
  /// Handles the "account-exists-with-different-credential" error by:
  /// 1. Detecting the error when a user tries to sign in with a provider for an email that's already registered
  /// 2. Signing in with the existing provider for that email
  /// 3. Linking the new provider credential to the existing account
  Future<UserCredential> _signInOrLink(
    Future<UserCredential> Function() signInAttempt,
    String providerName,
  ) async {
    print('🔵 _signInOrLink called for provider: $providerName');
    
    try {
      print('🔵 Step 1: Attempting normal sign-in with $providerName...');
      // 1) Normal sign-in (no collision)
      final result = await signInAttempt();
      print('✅ Normal sign-in successful - no account conflict detected');
      return result;
    } on FirebaseAuthException catch (e) {
      print('🔴 FirebaseAuthException caught!');
      print('   Error code: ${e.code}');
      print('   Error message: ${e.message}');
      print('   Error plugin: ${e.plugin}');
      
      // 2) Email is already on a different provider
      if (e.code == 'account-exists-with-different-credential') {
        print('');
        print('🔗 ===== ACCOUNT LINKING FLOW STARTED =====');
        print('📧 Account conflict detected: Email already exists with different provider');
        print('🎯 Attempting automatic account linking...');
        print('');
        
        final pendingCred = e.credential;
        final email = e.email;

        print('🔍 Extracted from error:');
        print('   Pending credential exists: ${pendingCred != null}');
        if (pendingCred != null) {
          print('   Pending credential provider: ${pendingCred.providerId}');
          print('   Pending credential sign-in method: ${pendingCred.signInMethod}');
        }
        print('   Email from error: ${email ?? "NOT PROVIDED"}');
        print('');

        if (pendingCred == null) {
          print('❌ CRITICAL: Pending credential is NULL - cannot proceed with linking');
          print('   This is unusual - Firebase should provide the credential in the error');
          rethrow;
        }
        
        if (email == null) {
          print('❌ CRITICAL: Email is NULL - cannot proceed with linking');
          print('   This is unusual - Firebase should provide the email in the error');
          rethrow;
        }

        // --- IMPORTANT ---
        // fetchSignInMethodsForEmail may be disabled by Email Enumeration Protection.
        // If this throws, we'll try all common providers automatically.
        List<String> methods = [];
        bool enumProtectionEnabled = false;
        
        try {
          print('🔄 Step 2: Fetching existing sign-in methods for email: $email');
          methods = await _auth!.fetchSignInMethodsForEmail(email);
          print('✅ fetchSignInMethodsForEmail succeeded!');
          print('📋 Existing sign-in methods: ${methods.isEmpty ? "NONE" : methods.join(", ")}');
          print('');
        } catch (fetchError) {
          print('⚠️ fetchSignInMethodsForEmail FAILED!');
          print('   Error type: ${fetchError.runtimeType}');
          print('   Error: $fetchError');
          print('   Reason: Email Enumeration Protection is likely ENABLED in Firebase Console');
          print('   📍 Firebase Console → Authentication → Settings → Email Enumeration Protection');
          print('');
          print('🔄 Fallback: Will try common providers automatically...');
          enumProtectionEnabled = true;
          
          // Try to determine provider from Firestore user data as fallback
          try {
            print('🔍 Attempting to find user in Firestore by email...');
            final usersQuery = await firestore
                .collection('users')
                .where('email', isEqualTo: email.toLowerCase())
                .limit(1)
                .get();
            
            if (usersQuery.docs.isNotEmpty) {
              final userData = usersQuery.docs.first.data();
              print('✅ Found user in Firestore!');
              print('   User data: ${userData.keys.join(", ")}');
              
              // Check if we can determine the provider from user data
              // This is a fallback - might not always work
              if (userData.containsKey('photoURL') && userData['photoURL'] != null) {
                final photoUrl = userData['photoURL'].toString();
                if (photoUrl.contains('googleusercontent.com')) {
                  methods.add('google.com');
                  print('   📊 Detected Google sign-in from photoURL');
                } else if (photoUrl.contains('facebook.com') || photoUrl.contains('fbcdn.net')) {
                  methods.add('facebook.com');
                  print('   📊 Detected Facebook sign-in from photoURL');
                }
              }
            } else {
              print('⚠️ User not found in Firestore');
            }
          } catch (firestoreError) {
            print('⚠️ Firestore fallback failed: $firestoreError');
          }
          print('');
        }

        // If we still have no methods, try all common providers
        if (methods.isEmpty && enumProtectionEnabled) {
          print('⚠️ No sign-in methods detected - will try all common providers');
          print('   Strategy: Try Google → Facebook → Twitter in sequence');
          methods = ['google.com', 'facebook.com', 'twitter.com'];
          print('');
        }

        if (methods.isEmpty) {
          print('❌ CRITICAL: No sign-in methods available');
          print('   Cannot proceed with automatic linking');
          print('');
          throw Exception(
            'This email is already registered but we cannot determine your sign-in method.\n'
            'Please contact support or try signing in with your existing account first.',
          );
        }

        print('🔄 Step 3: Signing in with existing provider...');
        print('   Will try methods in order: ${methods.join(" → ")}');
        print('');
        
        // 2a) Sign in with the existing provider
        UserCredential? existing;
        String? successfulMethod;
        
        for (String method in methods) {
          try {
            print('🔑 Attempting sign-in with: $method');
            
            if (method == 'google.com') {
              print('   📱 Launching Google sign-in flow...');
              existing = await _signInWithGoogleCredential();
              successfulMethod = 'Google';
            } else if (method == 'facebook.com') {
              print('   📱 Launching Facebook sign-in flow...');
              existing = await _signInWithFacebookCredential();
              successfulMethod = 'Facebook';
            } else if (method == 'twitter.com') {
              print('   📱 Launching Twitter sign-in flow...');
              existing = await _signInWithTwitterCredential();
              successfulMethod = 'Twitter';
            } else if (method == 'password') {
              print('   🔑 Existing provider is Email/Password');
              print('   ❌ Cannot auto-link with password provider - requires user input');
              throw Exception(
                'This email is registered with Email/Password.\n'
                'Please sign in with your email and password first,\n'
                'then link $providerName from Settings.',
              );
            } else {
              print('   ⚠️ Unknown method: $method - skipping');
              continue;
            }
            
            print('✅ Sign-in with $successfulMethod successful!');
            print('   User: ${existing?.user?.email}');
            print('   UID: ${existing?.user?.uid}');
            break; // Success - exit loop
            
          } catch (signInError) {
            print('❌ Sign-in with $method failed: $signInError');
            
            // If user cancelled, stop trying
            if (signInError.toString().toLowerCase().contains('cancel')) {
              print('👤 User cancelled the sign-in - stopping automatic linking');
              throw Exception('Sign-in cancelled. Account linking was not completed.');
            }
            
            // If this was the last method, throw error
            if (method == methods.last) {
              print('❌ All sign-in methods exhausted - automatic linking failed');
              throw Exception(
                'Could not sign in with your existing account to link $providerName.\n'
                'Please sign in with your existing method manually first.',
              );
            }
            
            // Otherwise, try next method
            print('   🔄 Trying next method...');
            continue;
          }
        }
        
        if (existing == null) {
          print('❌ CRITICAL: Sign-in succeeded but UserCredential is null');
          throw Exception('Authentication failed unexpectedly');
        }
        
        print('');
        print('✅ Step 3 Complete: Successfully authenticated with existing provider ($successfulMethod)');
        print('');

        // 3) Link the new credential to the existing account
        try {
          print('🔄 Step 4: Linking $providerName credential to existing account...');
          print('   Existing user: ${existing.user?.email}');
          print('   Existing UID: ${existing.user?.uid}');
          print('   New credential provider: ${pendingCred.providerId}');
          print('');
          
          await existing.user!.linkWithCredential(pendingCred);
          
          print('');
          print('✅✅✅ SUCCESS! Credential linking completed!');
          print('🎉 $providerName is now linked to your account!');
          print('🎉 You can now sign in with either $successfulMethod OR $providerName');
          print('');
          
          // Update user document after linking
          if (_isFirestoreAvailable && existing.user != null) {
            try {
              print('🔄 Updating user document in Firestore...');
              await _updateUserDocumentSafely(existing.user!);
              print('✅ Firestore update complete');
            } catch (firestoreError) {
              print('⚠️ Firestore update failed after linking: $firestoreError');
              print('   (This is non-critical - linking was still successful)');
            }
          }
          
          print('');
          print('🔗 ===== ACCOUNT LINKING COMPLETED SUCCESSFULLY =====');
          print('');
          
          // 4) Done: future logins via either provider work
          return existing;
        } catch (linkError) {
          print('');
          print('❌ Step 4 FAILED: Credential linking error!');
          print('   Error type: ${linkError.runtimeType}');
          print('   Error: $linkError');
          print('');
          
          // Linking failed, but user is still signed in with existing provider
          print('⚠️ Linking failed, but you are signed in with your existing account');
          print('   User can try linking again from Settings');
          print('');
          
          // Return the existing credential since user is authenticated
          return existing;
        }
      }
      
      // Other FirebaseAuth errors
      print('🔴 Different FirebaseAuth error (not account-exists): ${e.code}');
      rethrow;
    } catch (e) {
      print('🔴 Non-FirebaseAuth exception caught in _signInOrLink!');
      print('   Error type: ${e.runtimeType}');
      print('   Error: $e');
      rethrow;
    }
  }

  /// Internal method to get Google credential and sign in
  Future<UserCredential> _signInWithGoogleCredential() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    
    if (googleUser == null) {
      throw Exception('Google Sign-In was cancelled');
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await auth.signInWithCredential(credential);
  }

  /// Internal method to get Facebook credential and sign in
  Future<UserCredential> _signInWithFacebookCredential() async {
    final LoginResult result = await FacebookAuth.instance.login(
      permissions: ['email', 'public_profile'],
    );
    
    if (result.status != LoginStatus.success) {
      throw Exception('Facebook Sign-In failed: ${result.message}');
    }

    final AccessToken? accessToken = result.accessToken;
    if (accessToken == null) {
      throw Exception('Failed to get Facebook access token');
    }

    final OAuthCredential credential = FacebookAuthProvider.credential(
      accessToken.token,
    );

    return await auth.signInWithCredential(credential);
  }

  /// Internal method to get Twitter credential and sign in
  Future<UserCredential> _signInWithTwitterCredential() async {
    final twitterProvider = TwitterAuthProvider();
    twitterProvider.setCustomParameters({'lang': 'en'});
    
    return await _auth!.signInWithProvider(twitterProvider);
  }

  /// Sign in with Google - with automatic account linking
  Future<UserCredential> signInWithGoogle() async {
    try {
      print('🔄 Starting Google Sign-In...');

      // Use the centralized sign-in or link function
      final userCredential = await _signInOrLink(() async {
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

        if (googleUser == null) {
          throw Exception('Google Sign-In was cancelled');
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        return await auth.signInWithCredential(credential);
      }, 'Google');

      print('✅ Google Sign-In successful for: ${userCredential.user?.email}');

      // Check Firestore connection and update/create user document
      await _checkFirestoreConnection();

      if (_isFirestoreAvailable && userCredential.user != null) {
        try {
          await _updateUserDocumentSafely(userCredential.user!);
          
          // Store any pending FCM token first
          await _storePendingFCMToken();
          
          // Ensure FCM token exists and refresh if missing
          final hasToken = await ensureFCMTokenExists();
          if (!hasToken) {
            print('⚠️ FCM token refresh failed during Google sign-in');
          }
        } catch (firestoreError) {
          print('⚠️ Firestore operations failed: $firestoreError');
        }
      }

      // Setup admin user after successful authentication
      await _setupAdminUserAfterAuth();

      return userCredential;
    } catch (e) {
      print('❌ Error signing in with Google: $e');

      // Check if this is the known type casting error
      if (e.toString().contains('List<Object?>') &&
          e.toString().contains('PigeonUserDetails')) {
        print(
          '! Type casting issue detected - this is a known Firebase plugin bug',
        );

        // The authentication was actually successful, just the return type casting failed
        if (_auth?.currentUser != null) {
          print('✅ Authentication still successful despite type casting error');

          // Ensure user document is properly created/updated
          if (_isFirestoreAvailable) {
            try {
              await _updateUserDocumentSafely(_auth!.currentUser!);
              
              // Store any pending FCM token
              await _storePendingFCMToken();
              
              // Ensure FCM token exists
              final hasToken = await ensureFCMTokenExists();
              if (!hasToken) {
                print('⚠️ FCM token refresh failed after type cast error recovery');
              }
            } catch (docError) {
              print(
                '⚠️ User document update failed after type cast error: $docError',
              );
            }
          }

          // Setup admin user after successful authentication
          await _setupAdminUserAfterAuth();

          // Return success even though there was a type casting error
          return Future.value(auth.currentUser as UserCredential);
        }
      }

      rethrow;
    }
  }

  /// Sign in with Facebook - with automatic account linking
  Future<UserCredential> signInWithFacebook() async {
    try {
      print('📘 ===== FACEBOOK LOGIN STARTED =====');
      print('🔄 Step 1: Initializing Facebook Sign-In...');
      print('🔍 Auth instance available: ${_auth != null}');
      print('🔍 Current user before sign-in: ${_auth?.currentUser?.email ?? "null"}');

      // Use the centralized sign-in or link function
      final userCredential = await _signInOrLink(() async {
        // Trigger the Facebook sign-in flow
        print('🔄 Step 2: Requesting Facebook permissions...');
        print('📋 Permissions: [email, public_profile]');
        
        final LoginResult result = await FacebookAuth.instance.login(
          permissions: ['email', 'public_profile'],
        );

        print('✅ Facebook login completed with status: ${result.status}');
        
        // Check if login was successful
        if (result.status != LoginStatus.success) {
          print('❌ Facebook login not successful');
          if (result.status == LoginStatus.cancelled) {
            print('👤 User cancelled Facebook login');
            throw Exception('Facebook Sign-In was cancelled');
          }
          print('❌ Facebook error message: ${result.message}');
          throw Exception('Facebook Sign-In failed: ${result.message}');
        }

        // Get the access token
        print('🔄 Step 3: Retrieving Facebook access token...');
        final AccessToken? accessToken = result.accessToken;
        if (accessToken == null) {
          print('❌ Failed to get access token from Facebook');
          throw Exception('Failed to get Facebook access token');
        }
        print('✅ Access token received');
        print('🔑 Token: ${accessToken.token.substring(0, 20)}...');
        print('👤 User ID: ${accessToken.userId}');

        // Create a credential from the access token
        print('🔄 Step 4: Creating Firebase credential from Facebook token...');
        final OAuthCredential credential = FacebookAuthProvider.credential(
          accessToken.token,
        );
        print('✅ Firebase credential created');

        // Sign in to Firebase with the Facebook credential
        print('🔄 Step 5: Signing in to Firebase with Facebook credential...');
        return await auth.signInWithCredential(credential);
      }, 'Facebook');
      
      print('🎉 Step 6: Firebase sign-in completed!');
      print('✅ Facebook Sign-In successful!');
      print('👤 User UID: ${userCredential.user?.uid}');
      print('📧 User Email: ${userCredential.user?.email ?? "No email"}');
      print('📛 Display Name: ${userCredential.user?.displayName ?? "No name"}');
      print('🔗 Provider: ${userCredential.credential?.providerId ?? "Unknown"}');

      // Check Firestore connection and update/create user document
      await _checkFirestoreConnection();

      if (_isFirestoreAvailable && userCredential.user != null) {
        try {
          await _updateUserDocumentSafely(userCredential.user!);
          
          // Store any pending FCM token first
          await _storePendingFCMToken();
          
          // Ensure FCM token exists and refresh if missing
          final hasToken = await ensureFCMTokenExists();
          if (!hasToken) {
            print('⚠️ FCM token refresh failed during Facebook sign-in');
          }
        } catch (firestoreError) {
          print('⚠️ Firestore operations failed: $firestoreError');
        }
      }

      // Setup admin user after successful authentication
      await _setupAdminUserAfterAuth();

      print('📘 ===== FACEBOOK LOGIN COMPLETED SUCCESSFULLY =====');
      return userCredential;
    } catch (e, stackTrace) {
      print('📘 ===== FACEBOOK LOGIN ERROR =====');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Error message: $e');
      print('📍 Error details: ${e.toString()}');
      
      // Log specific Firebase Auth errors
      if (e is FirebaseAuthException) {
        print('🔥 FirebaseAuthException detected:');
        print('   - Code: ${e.code}');
        print('   - Message: ${e.message}');
        print('   - Plugin: ${e.plugin}');
        print('   - StackTrace: ${e.stackTrace}');
      }
      
      // Check if user cancelled
      if (e.toString().toLowerCase().contains('cancel') || 
          e.toString().toLowerCase().contains('abort')) {
        print('👤 User cancelled the Facebook login');
      }
      
      // Log stack trace for debugging
      print('📚 Stack trace:');
      print(stackTrace.toString().split('\n').take(10).join('\n'));

      // Check if this is a known type casting error similar to Google Sign-In
      if (e.toString().contains('List<Object?>') &&
          e.toString().contains('PigeonUserDetails')) {
        print(
          '⚠️ Type casting issue detected - this is a known Firebase plugin bug',
        );

        // The authentication was actually successful, just the return type casting failed
        if (_auth?.currentUser != null) {
          print('✅ Authentication still successful despite type casting error');
          print('👤 Authenticated user: ${_auth!.currentUser!.email}');

          // Ensure user document is properly created/updated
          if (_isFirestoreAvailable) {
            try {
              await _updateUserDocumentSafely(_auth!.currentUser!);
              
              // Store any pending FCM token
              await _storePendingFCMToken();
              
              // Ensure FCM token exists
              final hasToken = await ensureFCMTokenExists();
              if (!hasToken) {
                print('⚠️ FCM token refresh failed after type cast error recovery');
              }
            } catch (docError) {
              print(
                '⚠️ User document update failed after type cast error: $docError',
              );
            }
          }

          // Setup admin user after successful authentication
          await _setupAdminUserAfterAuth();

          // Return success even though there was a type casting error
          return Future.value(auth.currentUser as UserCredential);
        }
      }

      print('🔄 Checking if user is actually signed in despite error...');
      print('🔍 Current user after error: ${_auth?.currentUser?.email ?? "null"}');
      print('🔍 Is user signed in: ${_auth?.currentUser != null}');
      print('📘 ===== RETHROWING ERROR =====');
      
      rethrow;
    }
  }

  /// Sign in with Twitter - with automatic account linking
  /// Note: This requires Firebase Console configuration with your Twitter API credentials
  /// Configuration needed:
  /// 1. Go to Firebase Console > Authentication > Sign-in method
  /// 2. Enable Twitter provider
  /// 3. Add your Twitter API Key and API Secret
  /// 4. Add callback URL to Twitter Developer Portal
  Future<UserCredential> signInWithTwitter() async {
    try {
      print('🐦 ===== TWITTER LOGIN STARTED =====');
      print('🔄 Step 1: Initializing Twitter Sign-In...');
      print('🔍 Auth instance available: ${_auth != null}');
      print('🔍 Current user before sign-in: ${_auth?.currentUser?.email ?? "null"}');
      
      // Use the centralized sign-in or link function
      final userCredential = await _signInOrLink(() async {
        // Create Twitter provider with custom parameters
        print('🔄 Step 2: Creating TwitterAuthProvider...');
        final twitterProvider = TwitterAuthProvider();
        print('✅ TwitterAuthProvider created successfully');
        
        // Add custom parameters if needed (e.g., language)
        print('🔄 Step 3: Setting custom parameters...');
        twitterProvider.setCustomParameters({
          'lang': 'en',
        });
        print('✅ Custom parameters set');
        
        // Use signInWithProvider for both Web and Mobile
        // Firebase handles platform-specific implementation internally
        print('🔄 Step 4: Calling signInWithProvider...');
        print('🌐 This will open a browser/Chrome Custom Tab for Twitter login');
        
        return await _auth!.signInWithProvider(twitterProvider);
      }, 'Twitter');
      
      print('🎉 Step 5: signInWithProvider returned successfully!');
      print('✅ Twitter Sign-In successful!');
      print('👤 User UID: ${userCredential.user?.uid}');
      print('📧 User Email: ${userCredential.user?.email ?? "No email"}');
      print('📛 Display Name: ${userCredential.user?.displayName ?? "No name"}');
      print('🔑 Provider ID: ${userCredential.credential?.providerId ?? "Unknown"}');
      print('🔗 Sign-in method: ${userCredential.credential?.signInMethod ?? "Unknown"}');

      // Check Firestore connection and update/create user document
      await _checkFirestoreConnection();

      if (_isFirestoreAvailable && userCredential.user != null) {
        try {
          await _updateUserDocumentSafely(userCredential.user!);
          
          // Store any pending FCM token first
          await _storePendingFCMToken();
          
          // Ensure FCM token exists and refresh if missing
          final hasToken = await ensureFCMTokenExists();
          if (!hasToken) {
            print('⚠️ FCM token refresh failed during Twitter sign-in');
          }
        } catch (firestoreError) {
          print('⚠️ Firestore operations failed: $firestoreError');
        }
      }

      // Setup admin user after successful authentication
      await _setupAdminUserAfterAuth();

      print('🐦 ===== TWITTER LOGIN COMPLETED SUCCESSFULLY =====');
      return userCredential;
    } catch (e, stackTrace) {
      print('🐦 ===== TWITTER LOGIN ERROR =====');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Error message: $e');
      print('📍 Error details: ${e.toString()}');
      
      // Log specific Firebase Auth errors
      if (e is FirebaseAuthException) {
        print('🔥 FirebaseAuthException detected:');
        print('   - Code: ${e.code}');
        print('   - Message: ${e.message}');
        print('   - Plugin: ${e.plugin}');
        print('   - StackTrace: ${e.stackTrace}');
      }
      
      // Check if user cancelled
      if (e.toString().toLowerCase().contains('cancel') || 
          e.toString().toLowerCase().contains('abort')) {
        print('👤 User cancelled the Twitter login');
      }
      
      // Check for network issues
      if (e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('connection')) {
        print('🌐 Network/connection issue detected');
      }
      
      // Log stack trace for debugging
      print('📚 Stack trace:');
      print(stackTrace.toString().split('\n').take(10).join('\n'));

      // Check if this is a known type casting error similar to Google Sign-In
      if (e.toString().contains('List<Object?>') &&
          e.toString().contains('PigeonUserDetails')) {
        print(
          '⚠️ Type casting issue detected - this is a known Firebase plugin bug',
        );

        // The authentication was actually successful, just the return type casting failed
        if (_auth?.currentUser != null) {
          print('✅ Authentication still successful despite type casting error');
          print('👤 Authenticated user: ${_auth!.currentUser!.email}');

          // Ensure user document is properly created/updated
          if (_isFirestoreAvailable) {
            try {
              await _updateUserDocumentSafely(_auth!.currentUser!);
              
              // Store any pending FCM token
              await _storePendingFCMToken();
              
              // Ensure FCM token exists
              final hasToken = await ensureFCMTokenExists();
              if (!hasToken) {
                print('⚠️ FCM token refresh failed after type cast error recovery');
              }
            } catch (docError) {
              print(
                '⚠️ User document update failed after type cast error: $docError',
              );
            }
          }

          // Setup admin user after successful authentication
          await _setupAdminUserAfterAuth();

          // Return success even though there was a type casting error
          return Future.value(auth.currentUser as UserCredential);
        }
      }

      print('🔄 Checking if user is actually signed in despite error...');
      print('🔍 Current user after error: ${_auth?.currentUser?.email ?? "null"}');
      print('🔍 Is user signed in: ${_auth?.currentUser != null}');
      print('🐦 ===== RETHROWING ERROR =====');
      
      rethrow;
    }
  }

  /// Setup admin user after authentication
  Future<void> _setupAdminUserAfterAuth() async {
    try {
      print('🔧 Setting up admin user after authentication...');

      // Handle admin setup directly without UserDataService dependency
      final currentUser = _auth?.currentUser;
      if (currentUser != null && _isFirestoreAvailable) {
        try {
          // Check if user document exists and create/update if needed
          DocumentSnapshot userDoc = await firestore
              .collection('users')
              .doc(currentUser.uid)
              .get()
              .timeout(const Duration(seconds: 5));

          if (!userDoc.exists) {
            // Document doesn't exist, create it with proper admin setup
            await _createUserDocumentSafely(currentUser);
          } else {
            // Document exists, but verify admin status for erolrony91@gmail.com
            final userData = userDoc.data() as Map<String, dynamic>?;
            if (currentUser.email?.toLowerCase() == 'erolrony91@gmail.com' &&
                userData?['role'] != 'admin') {
              print('🔧 Promoting erolrony91@gmail.com to admin...');
              await firestore
                  .collection('users')
                  .doc(currentUser.uid)
                  .update({
                    'role': 'admin',
                    'subscriptionType': 'admin',
                    'summariesLimit': 1000,
                    'updatedAt': FieldValue.serverTimestamp(),
                  })
                  .timeout(const Duration(seconds: 5));
              print('✅ Admin role updated for erolrony91@gmail.com');
            }
          }
        } catch (e) {
          print('⚠️ Admin setup error: $e');
        }
      }

      print('✅ Admin user setup completed after authentication');
    } catch (e) {
      print('⚠️ Admin user setup failed: $e');
    }
  }

  /// Safely update user document with better error handling
  Future<void> _updateUserDocumentSafely(User user) async {
    if (!_isFirestoreAvailable) {
      print('⚠️ Skipping user document update - Firestore unavailable');
      return;
    }

    try {
      // Use a timeout and retry mechanism
      DocumentSnapshot? userDoc;

      for (int attempt = 0; attempt < 2; attempt++) {
        try {
          userDoc = await firestore
              .collection('users')
              .doc(user.uid)
              .get()
              .timeout(const Duration(seconds: 3));
          break; // Success, exit retry loop
        } catch (e) {
          print('⚠️ Firestore attempt ${attempt + 1} failed: $e');
          if (attempt == 1) rethrow; // Last attempt, throw error
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      if (userDoc == null) {
        throw Exception('Could not retrieve user document');
      }

      if (!userDoc.exists) {
        await _createUserDocumentSafely(user);
      } else {
        await firestore
            .collection('users')
            .doc(user.uid)
            .update({
              'email': user.email,
              'displayName': user.displayName,
              'photoURL': user.photoURL,
              'updatedAt': FieldValue.serverTimestamp(),
            })
            .timeout(const Duration(seconds: 3));
      }
    } catch (e) {
      print('❌ Error in safe user document update: $e');
      // Mark Firestore as unavailable to prevent further attempts
      _isFirestoreAvailable = false;
      rethrow;
    }
  }

  /// Safely create user document
  Future<void> _createUserDocumentSafely(User user) async {
    try {
      print('📝 Creating user document for: ${user.email}');

      // Check if this is the first user (admin) with better error handling
      bool isFirstUser = false;
      try {
        QuerySnapshot users = await firestore
            .collection('users')
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 5));
        isFirstUser = users.docs.isEmpty;
        print(
          '📊 First user check: $isFirstUser (${users.docs.length} existing users)',
        );
      } catch (e) {
        print('⚠️ Could not check for first user: $e');
        isFirstUser = false; // Default to regular user
      }

      // Check if this is the admin email
      bool isAdminEmail = user.email?.toLowerCase() == 'erolrony91@gmail.com';
      String userRole = (isFirstUser || isAdminEmail) ? 'admin' : 'user';
      int summariesLimit = (isFirstUser || isAdminEmail) ? 1000 : 10;
      String subscriptionType =
          (isFirstUser || isAdminEmail) ? 'admin' : 'free';

      print(
        '👤 User role determined: $userRole (firstUser: $isFirstUser, adminEmail: $isAdminEmail)',
      );

      // Normalize email for consistent search
      final normalizedEmail = user.email?.toLowerCase() ?? '';

      final userData = {
        'email': normalizedEmail,
        'displayName': user.displayName ?? user.email?.split('@')[0] ?? 'User',
        'photoURL': user.photoURL,
        'role': userRole,
        'subscriptionType': subscriptionType,
        'summariesUsed': 0,
        'summariesLimit': summariesLimit,
        'lastResetDate': FieldValue.serverTimestamp(),
        'registrationDate': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      print(
        '📝 User data to save: ${userData.toString().replaceAll(RegExp(r'FieldValue.*'), 'FieldValue')}',
      );

      await firestore
          .collection('users')
          .doc(user.uid)
          .set(userData)
          .timeout(const Duration(seconds: 10));

      print(
        '✅ User document created successfully - Role: $userRole, Email: $normalizedEmail',
      );

      if (isFirstUser || isAdminEmail) {
        print('🔥 Admin user created - Admin privileges granted');
      }
    } catch (e) {
      print('❌ Error creating user document safely: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await FacebookAuth.instance.logOut();
      await auth.signOut();
      print('✅ User signed out successfully');
    } catch (e) {
      print('❌ Error signing out: $e');
      rethrow;
    }
  }

  /// Create user document in Firestore with timeout and error handling
  Future<void> _createUserDocument(User user) async {
    if (!_isFirestoreAvailable) {
      print('⚠️ Skipping user document creation - Firestore unavailable');
      return;
    }

    try {
      // Check if this is the first user (admin)
      bool isFirstUser = await _isFirstUser();
      String userRole = isFirstUser ? 'admin' : 'user';

      await firestore
          .collection('users')
          .doc(user.uid)
          .set({
            'email': user.email,
            'displayName': user.displayName,
            'photoURL': user.photoURL,
            'role': userRole,
            'subscriptionType': 'free',
            'summariesUsed': 0,
            'summariesLimit': isFirstUser ? 100 : 10,
            'lastResetDate': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          })
          .timeout(const Duration(seconds: 10));

      print('✅ User document created successfully - Role: $userRole');

      if (isFirstUser) {
        print('🔥 First user registered - Admin privileges granted');
      }
    } catch (e) {
      print('❌ Error creating user document: $e');
      // Don't rethrow - user can still use the app without Firestore
    }
  }

  /// Check if this is the first user in the system
  Future<bool> _isFirstUser() async {
    try {
      QuerySnapshot users = await firestore
          .collection('users')
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 5));
      return users.docs.isEmpty;
    } catch (e) {
      print('❌ Error checking first user: $e');
      return false;
    }
  }

  /// Update user document in Firestore
  Future<void> _updateUserDocument(User user) async {
    if (!_isFirestoreAvailable) {
      print('⚠️ Skipping user document update - Firestore unavailable');
      return;
    }

    try {
      DocumentSnapshot userDoc = await firestore
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 5));

      if (!userDoc.exists) {
        await _createUserDocument(user);
      } else {
        await firestore
            .collection('users')
            .doc(user.uid)
            .update({
              'email': user.email,
              'displayName': user.displayName,
              'photoURL': user.photoURL,
              'updatedAt': FieldValue.serverTimestamp(),
            })
            .timeout(const Duration(seconds: 5));
      }
    } catch (e) {
      print('❌ Error updating user document: $e');
      // Don't rethrow - user can still use the app without Firestore
    }
  }

  /// Get user data from Firestore with timeout and fallback
  Future<DocumentSnapshot?> getUserData() async {
    if (currentUser == null) throw Exception('No user signed in');

    if (!_isFirestoreAvailable) {
      print('⚠️ Firestore unavailable - returning null');
      return null;
    }

    try {
      return await firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get()
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      print('❌ Error getting user data: $e');
      _isFirestoreAvailable = false;
      return null;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    if (currentUser == null) throw Exception('No user signed in');

    if (!_isFirestoreAvailable) {
      throw Exception('Firestore unavailable');
    }

    await firestore
        .collection('users')
        .doc(currentUser!.uid)
        .update({...data, 'updatedAt': FieldValue.serverTimestamp()})
        .timeout(const Duration(seconds: 5));
  }

  /// Check if user is admin
  Future<bool> isUserAdmin() async {
    try {
      if (currentUser == null) return false;

      // Prefer checking the user document role which aligns with Firestore rules
      final doc = await firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get()
          .timeout(const Duration(seconds: 3));

      final data = doc.data() as Map<String, dynamic>?;
      if (data != null && (data['role'] as String?)?.toLowerCase() == 'admin') {
        return true;
      }

      // Fallback to token custom claims if available
      try {
        final tokenResult = await currentUser!.getIdTokenResult();
        if (tokenResult.claims?['admin'] == true) return true;
      } catch (_) {}

      // Last resort: specific email is treated as admin
      if ((currentUser!.email ?? '').toLowerCase() == 'erolrony91@gmail.com') {
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Add stock to favorites
  Future<void> addToFavorites(String stockId) async {
    if (currentUser == null) throw Exception('No user signed in');

    if (!_isFirestoreAvailable) {
      throw Exception('Firestore unavailable');
    }

    await firestore
        .collection('favorites')
        .doc(currentUser!.uid)
        .collection('stocks')
        .doc(stockId)
        .set({'stockId': stockId, 'addedAt': FieldValue.serverTimestamp()})
        .timeout(const Duration(seconds: 5));
  }

  /// Remove stock from favorites
  Future<void> removeFromFavorites(String stockId) async {
    if (currentUser == null) throw Exception('No user signed in');

    if (!_isFirestoreAvailable) {
      throw Exception('Firestore unavailable');
    }

    await firestore
        .collection('favorites')
        .doc(currentUser!.uid)
        .collection('stocks')
        .doc(stockId)
        .delete()
        .timeout(const Duration(seconds: 5));
  }

  /// Get user's favorite stocks
  Stream<QuerySnapshot> getFavoriteStocks() {
    if (currentUser == null) throw Exception('No user signed in');

    return firestore
        .collection('favorites')
        .doc(currentUser!.uid)
        .collection('stocks')
        .orderBy('addedAt', descending: true)
        .snapshots();
  }

  /// Get stocks collection
  Stream<QuerySnapshot> getStocks() {
    return firestore.collection('stocks').orderBy('symbol').snapshots();
  }

  /// Get news collection
  Stream<QuerySnapshot> getNews() {
    return firestore
        .collection('news')
        .orderBy('publishedAt', descending: true)
        .limit(50)
        .snapshots();
  }

  /// Get AI summary for a stock
  Future<DocumentSnapshot> getStockSummary(String stockId) async {
    return await firestore
        .collection('summaries')
        .doc(stockId)
        .get()
        .timeout(const Duration(seconds: 5));
  }

  /// Admin Functions

  /// Get all users (admin only) - improved with better error handling
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    if (!isFirestoreAvailable) {
      throw Exception('Firestore not available');
    }

    try {
      print('🔍 Admin: Fetching all users...');
      final querySnapshot = await firestore.collection('users').get();
      print('🔍 Admin: Found ${querySnapshot.docs.length} users in database');

      final users =
          querySnapshot.docs.map((doc) {
            final data = doc.data();
            data['uid'] = doc.id;
            print(
              '📋 User found: ${data['email']} - Role: ${data['role']} - UID: ${doc.id}',
            );
            return data;
          }).toList();

      return users;
    } catch (e) {
      print('❌ Error fetching all users: $e');
      throw Exception('Failed to fetch users: $e');
    }
  }

  /// Search users by email (admin only) - improved with better search
  Future<List<Map<String, dynamic>>> searchUsersByEmail(String email) async {
    if (!isFirestoreAvailable) {
      throw Exception('Firestore not available');
    }

    try {
      print('🔍 Admin: Searching for users with email containing: "$email"');

      // If email is empty, return all users
      if (email.trim().isEmpty) {
        return await getAllUsers();
      }

      // Try exact match first
      final exactQuery =
          await firestore
              .collection('users')
              .where('email', isEqualTo: email.toLowerCase())
              .get();

      print('🔍 Admin: Exact match found ${exactQuery.docs.length} users');

      // If no exact match, try prefix search
      List<QueryDocumentSnapshot> allDocs = exactQuery.docs.toList();

      if (exactQuery.docs.isEmpty) {
        final prefixQuery =
            await firestore
                .collection('users')
                .where('email', isGreaterThanOrEqualTo: email.toLowerCase())
                .where(
                  'email',
                  isLessThanOrEqualTo: '${email.toLowerCase()}\uf8ff',
                )
                .limit(20)
                .get();

        print('🔍 Admin: Prefix search found ${prefixQuery.docs.length} users');
        allDocs = prefixQuery.docs.toList();
      }

      // If still no results, get all users and filter manually
      if (allDocs.isEmpty) {
        print(
          '🔍 Admin: No prefix matches, getting all users for manual filtering',
        );
        final allUsers = await firestore.collection('users').get();
        allDocs =
            allUsers.docs.where((doc) {
              final userData = doc.data();
              final userEmail =
                  userData['email']?.toString().toLowerCase() ?? '';
              return userEmail.contains(email.toLowerCase());
            }).toList();

        print('🔍 Admin: Manual filtering found ${allDocs.length} users');
      }

      final results =
          allDocs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['uid'] = doc.id;
            print(
              '📋 Search result: ${data['email']} - Role: ${data['role']} - UID: ${doc.id}',
            );
            return data;
          }).toList();

      return results;
    } catch (e) {
      print('❌ Error searching users: $e');
      throw Exception('Failed to search users: $e');
    }
  }

  /// Grant admin role to a user by email
  Future<void> grantAdminRole(String email) async {
    try {
      print('🔧 Admin: Granting admin role to $email...');

      if (!_isFirestoreAvailable) {
        throw Exception('Firestore is not available');
      }

      // Find the user by email
      QuerySnapshot userQuery =
          await firestore
              .collection('users')
              .where('email', isEqualTo: email.toLowerCase().trim())
              .limit(1)
              .get();

      if (userQuery.docs.isEmpty) {
        throw Exception('User not found with email: $email');
      }

      DocumentSnapshot userDoc = userQuery.docs.first;

      // Update user role to admin
      await userDoc.reference.update({
        'role': 'admin',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Admin: Successfully granted admin role to $email');
    } catch (e) {
      print('❌ Admin: Error granting admin role to $email: $e');
      rethrow;
    }
  }

  /// Revoke admin role from a user by email (demote to regular user)
  Future<void> revokeAdminRole(String email) async {
    try {
      print('🔧 Admin: Revoking admin role from $email...');

      if (!_isFirestoreAvailable) {
        throw Exception('Firestore is not available');
      }

      // Prevent self-demotion
      if (_auth?.currentUser?.email?.toLowerCase() == email.toLowerCase()) {
        throw Exception('You cannot revoke your own admin privileges');
      }

      // Find the user by email
      QuerySnapshot userQuery =
          await firestore
              .collection('users')
              .where('email', isEqualTo: email.toLowerCase().trim())
              .limit(1)
              .get();

      if (userQuery.docs.isEmpty) {
        throw Exception('User not found with email: $email');
      }

      DocumentSnapshot userDoc = userQuery.docs.first;

      // Update user role to regular user
      await userDoc.reference.update({
        'role': 'user',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Admin: Successfully revoked admin role from $email');
    } catch (e) {
      print('❌ Admin: Error revoking admin role from $email: $e');
      rethrow;
    }
  }

  /// Send push notification to all users (admin only)
  Future<void> sendNotificationToAllUsers(String title, String message) async {
    try {
      // Store notification in Firebase for the Cloud Function to process
      await firestore.collection('admin_notifications').add({
        'title': title,
        'message': message,
        'type': 'all_users',
        'sentBy': currentUser?.email,
        'sentAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      print('✅ Notification queued for all users');
    } catch (e) {
      print('❌ Error sending notification: $e');
      throw Exception('Failed to send notification: $e');
    }
  }

  /// Send push notification to specific user (admin only)
  Future<void> sendNotificationToUser(
    String userEmail,
    String title,
    String message,
  ) async {
    try {
      // Store notification in Firebase for the Cloud Function to process
      await firestore.collection('admin_notifications').add({
        'title': title,
        'message': message,
        'type': 'specific_user',
        'targetEmail': userEmail,
        'sentBy': currentUser?.email,
        'sentAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      print('✅ Notification queued for $userEmail');
    } catch (e) {
      print('❌ Error sending notification: $e');
      throw Exception('Failed to send notification: $e');
    }
  }

  /// Send push notification to user type (admin only)
  Future<void> sendNotificationToUserType(
    String userType,
    String title,
    String message,
  ) async {
    try {
      // Store notification in Firebase for the Cloud Function to process
      await firestore.collection('admin_notifications').add({
        'title': title,
        'message': message,
        'type': 'user_type',
        'userType': userType,
        'sentBy': currentUser?.email,
        'sentAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      print('✅ Notification queued for $userType users');
    } catch (e) {
      print('❌ Error sending notification: $e');
      throw Exception('Failed to send notification: $e');
    }
  }

  /// Add notification to user's notification history
  Future<void> addNotificationToHistory({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      await firestore
          .collection('user_notifications')
          .doc(userId)
          .collection('notifications')
          .add({
            'title': title,
            'body': body,
            'type': type,
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
            'data': data ?? {},
          });

      print('✅ Notification added to user history: $userId');
    } catch (e) {
      print('❌ Error adding notification to history: $e');
    }
  }

  /// Get system statistics (admin only)
  Future<Map<String, dynamic>> getSystemStats() async {
    if (!isFirestoreAvailable) {
      return {
        'totalUsers': 'Offline',
        'activeSubscriptions': 'Offline',
        'summariesGenerated': 'Offline',
        'systemStatus': 'Offline Mode',
      };
    }

    try {
      // Get total users count
      final usersSnapshot = await firestore.collection('users').count().get();
      final totalUsers = usersSnapshot.count ?? 0;

      // Get premium users count
      final premiumSnapshot =
          await firestore
              .collection('users')
              .where('subscriptionType', isEqualTo: 'premium')
              .count()
              .get();
      final premiumUsers = premiumSnapshot.count ?? 0;

      // Get total summaries generated (sum of all users' summariesUsed)
      final usersData = await firestore.collection('users').get();
      int totalSummaries = 0;
      for (final doc in usersData.docs) {
        final data = doc.data();
        totalSummaries += (data['summariesUsed'] as int? ?? 0);
      }

      return {
        'totalUsers': totalUsers,
        'activeSubscriptions': premiumUsers,
        'summariesGenerated': totalSummaries,
        'systemStatus': 'Online',
      };
    } catch (e) {
      print('❌ Error fetching system stats: $e');
      return {
        'totalUsers': 'Error',
        'activeSubscriptions': 'Error',
        'summariesGenerated': 'Error',
        'systemStatus': 'Error',
      };
    }
  }
}
