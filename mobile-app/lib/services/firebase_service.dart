import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
// import 'user_data_service.dart'; // Removed
// import 'package:flutter_facebook_auth/flutter_facebook_auth.dart'; // Removed

/// Firebase Service for Flutter
/// Handles authentication, Firestore operations, and other Firebase services
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'flutter-database',
  );
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Connection status
  bool _isFirestoreAvailable = false;
  DateTime? _lastConnectionCheck;
  final bool _isAuthAvailable = true; // Added for Google Sign-In

  // Getters
  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;
  FirebaseMessaging get messaging => _messaging;
  FirebaseStorage get storage => _storage;
  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => _auth.currentUser != null;
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

      print('✅ Firebase services initialized successfully');
    } catch (e) {
      print('❌ Firebase initialization error: $e');
    }
  }

  /// Initialize Firebase Cloud Messaging according to documentation
  Future<void> _initializeFCM() async {
    try {
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

  /// Store FCM token in user document for admin notifications
  Future<void> _storeFCMToken(String token) async {
    try {
      final user = _auth.currentUser;
      if (user != null && _isFirestoreAvailable) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        print('✅ FCM token stored in user document');
      }
    } catch (e) {
      print('❌ Error storing FCM token: $e');
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
      await FirebaseMessaging.instance.deleteToken();
      await _getFCMTokenSafely();
      print('✅ FCM token refreshed successfully');
    } catch (e) {
      print('❌ Error refreshing FCM token: $e');
    }
  }

  /// Check if Firestore is available and responsive
  Future<void> _checkFirestoreConnection() async {
    try {
      // Only check connection every 30 seconds to avoid repeated checks
      if (_lastConnectionCheck != null &&
          DateTime.now().difference(_lastConnectionCheck!).inSeconds < 30) {
        return;
      }

      _lastConnectionCheck = DateTime.now();

      // Try to read from Firestore with timeout
      await _firestore
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
      UserCredential result = await _auth.signInWithEmailAndPassword(
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
          await _getFCMTokenSafely();
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
        if (_auth.currentUser != null && _auth.currentUser!.email == email) {
          print('✅ Sign-in actually successful despite type casting error');

          // Ensure user document is properly updated
          if (_isFirestoreAvailable) {
            try {
              await _updateUserDocumentSafely(_auth.currentUser!);
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

      UserCredential result = await _auth.createUserWithEmailAndPassword(
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
        if (_auth.currentUser != null && _auth.currentUser!.email == email) {
          print(
            '✅ Registration actually successful despite type casting error',
          );

          // Ensure user document is created even with type casting error
          if (_isFirestoreAvailable) {
            try {
              await _createUserDocumentWithRetry(_auth.currentUser!);
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

  /// Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      print('🔄 Starting Google Sign-In...');

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

      final userCredential = await _auth.signInWithCredential(credential);
      print('✅ Google Sign-In successful for: ${userCredential.user?.email}');

      // Check Firestore connection and update/create user document
      await _checkFirestoreConnection();

      if (_isFirestoreAvailable && userCredential.user != null) {
        try {
          await _updateUserDocumentSafely(userCredential.user!);
          await _getFCMTokenSafely();
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
        if (_auth.currentUser != null) {
          print('✅ Authentication still successful despite type casting error');

          // Ensure user document is properly created/updated
          if (_isFirestoreAvailable) {
            try {
              await _updateUserDocumentSafely(_auth.currentUser!);
            } catch (docError) {
              print(
                '⚠️ User document update failed after type cast error: $docError',
              );
            }
          }

          // Setup admin user after successful authentication
          await _setupAdminUserAfterAuth();

          // Return success even though there was a type casting error
          return Future.value(_auth.currentUser as UserCredential);
        }
      }

      rethrow;
    }
  }

  /// Setup admin user after authentication
  Future<void> _setupAdminUserAfterAuth() async {
    try {
      print('🔧 Setting up admin user after authentication...');

      // Handle admin setup directly without UserDataService dependency
      final currentUser = _auth.currentUser;
      if (currentUser != null && _isFirestoreAvailable) {
        try {
          // Check if user document exists and create/update if needed
          DocumentSnapshot userDoc = await _firestore
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
              await _firestore
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
          userDoc = await _firestore
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
        await _firestore
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
        QuerySnapshot users = await _firestore
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

      await _firestore
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
      await _auth.signOut();
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

      await _firestore
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
      QuerySnapshot users = await _firestore
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
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 5));

      if (!userDoc.exists) {
        await _createUserDocument(user);
      } else {
        await _firestore
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
      return await _firestore
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

    await _firestore
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
      final doc = await _firestore
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

    await _firestore
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

    await _firestore
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

    return _firestore
        .collection('favorites')
        .doc(currentUser!.uid)
        .collection('stocks')
        .orderBy('addedAt', descending: true)
        .snapshots();
  }

  /// Get stocks collection
  Stream<QuerySnapshot> getStocks() {
    return _firestore.collection('stocks').orderBy('symbol').snapshots();
  }

  /// Get news collection
  Stream<QuerySnapshot> getNews() {
    return _firestore
        .collection('news')
        .orderBy('publishedAt', descending: true)
        .limit(50)
        .snapshots();
  }

  /// Get AI summary for a stock
  Future<DocumentSnapshot> getStockSummary(String stockId) async {
    return await _firestore
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
          await _firestore
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
      if (_auth.currentUser?.email?.toLowerCase() == email.toLowerCase()) {
        throw Exception('You cannot revoke your own admin privileges');
      }

      // Find the user by email
      QuerySnapshot userQuery =
          await _firestore
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
