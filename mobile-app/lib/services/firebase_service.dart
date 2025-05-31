import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
// import 'package:flutter_facebook_auth/flutter_facebook_auth.dart'; // Removed

/// Firebase Service for Flutter
/// Handles authentication, Firestore operations, and other Firebase services
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Connection status
  bool _isFirestoreAvailable = false;
  DateTime? _lastConnectionCheck;
  bool _isAuthAvailable = true; // Added for Google Sign-In

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
    try {
      // Configure Firestore settings for better performance
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      // Check Firestore connection
      await _checkFirestoreConnection();

      // Request notification permissions
      await _requestNotificationPermissions();

      // Get FCM token
      await _getFCMToken();

      print('✅ Firebase services initialized successfully');
    } catch (e) {
      print('❌ Error initializing Firebase services: $e');
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

  /// Request notification permissions
  Future<void> _requestNotificationPermissions() async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print(
        '📱 Notification permission granted: ${settings.authorizationStatus}',
      );
    } catch (e) {
      print('⚠️ Notification permission error: $e');
    }
  }

  /// Get and store FCM token
  Future<String?> _getFCMToken() async {
    try {
      String? token = await _messaging.getToken();
      if (token != null && currentUser != null && _isFirestoreAvailable) {
        // Store token in Firestore with timeout
        await _firestore
            .collection('fcmTokens')
            .doc(currentUser!.uid)
            .set({'token': token, 'updatedAt': FieldValue.serverTimestamp()})
            .timeout(const Duration(seconds: 5));
      }
      return token;
    } catch (e) {
      print('❌ Error getting FCM token: $e');
      return null;
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
          await _updateUserDocument(result.user!);
          await _getFCMToken();
        } catch (firestoreError) {
          print('⚠️ Firestore operations failed: $firestoreError');
          // Don't fail the whole sign-in process for Firestore issues
        }
      }

      return result;
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      throw Exception(_getAuthErrorMessage(e.code));
    } catch (e) {
      print('❌ Error signing in with email: $e');
      // Handle type casting and other errors gracefully
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('type cast')) {
        throw Exception(
          'Authentication service temporarily unavailable. Please try again.',
        );
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
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Ensure we have a valid user before proceeding
      if (result.user == null) {
        throw Exception('Registration failed - no user returned');
      }

      // Update user profile with better error handling
      try {
        await result.user!.updateDisplayName(displayName);
      } catch (profileError) {
        print('⚠️ Failed to update display name: $profileError');
        // Continue with registration even if display name update fails
      }

      // Check Firestore connection before proceeding
      await _checkFirestoreConnection();

      if (_isFirestoreAvailable && result.user != null) {
        try {
          // Create user document
          await _createUserDocument(result.user!);
          await _getFCMToken();
        } catch (firestoreError) {
          print('⚠️ Firestore operations failed: $firestoreError');
          // Don't fail the whole registration process for Firestore issues
        }
      }

      return result;
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      throw Exception(_getAuthErrorMessage(e.code));
    } catch (e) {
      print('❌ Error registering with email: $e');
      // Handle type casting and other errors gracefully
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('type cast')) {
        throw Exception(
          'Registration service temporarily unavailable. Please try again.',
        );
      }
      rethrow;
    }
  }

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Check if Firebase Auth is available
      if (!_isAuthAvailable) {
        throw Exception('Firebase Auth not available');
      }

      print('🔄 Starting Google Sign-In...');

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('❌ Google Sign-In cancelled by user');
        return null; // User cancelled the sign-in
      }

      print('✅ Google Sign-In successful for: ${googleUser.email}');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('Failed to get Google authentication tokens');
      }

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      UserCredential result = await _auth.signInWithCredential(credential);

      if (result.user == null) {
        throw Exception('Failed to sign in with Firebase');
      }

      print('🎉 Firebase sign-in successful');

      // Check Firestore connection before proceeding
      await _checkFirestoreConnection();

      // Only attempt Firestore operations if available and avoid type casting issues
      if (_isFirestoreAvailable && result.user != null) {
        try {
          // Use Future.delayed to avoid immediate type casting issues
          await Future.delayed(const Duration(milliseconds: 100));
          await _updateUserDocumentSafely(result.user!);
          await _getFCMTokenSafely();
        } catch (firestoreError) {
          print(
            '⚠️ Firestore operations failed (continuing in offline mode): $firestoreError',
          );
          // Continue without throwing - user can still use the app
        }
      } else {
        print('⚠️ Firestore unavailable - operating in offline mode');
      }

      return result;
    } catch (e) {
      print('❌ Error signing in with Google: $e');

      // Handle specific type casting errors without breaking the auth flow
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('type cast') ||
          e.toString().contains('List<Object?>')) {
        print(
          '⚠️ Type casting issue detected - this is a known Firebase plugin bug',
        );

        // Still try to return a valid credential if auth was successful
        if (_auth.currentUser != null) {
          print('✅ Authentication still successful despite type casting error');
          return null; // Signal success but avoid the problematic operations
        }
      }

      return null;
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
      // Check if this is the first user (admin)
      bool isFirstUser = false;
      try {
        QuerySnapshot users = await _firestore
            .collection('users')
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 3));
        isFirstUser = users.docs.isEmpty;
      } catch (e) {
        print('⚠️ Could not check for first user: $e');
        isFirstUser = false; // Default to regular user
      }

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
          .timeout(const Duration(seconds: 5));

      print('✅ User document created successfully - Role: $userRole');

      if (isFirstUser) {
        print('🔥 First user registered - Admin privileges granted');
      }
    } catch (e) {
      print('❌ Error creating user document safely: $e');
      rethrow;
    }
  }

  /// Safely get FCM token
  Future<String?> _getFCMTokenSafely() async {
    try {
      String? token = await _messaging.getToken();
      if (token != null && currentUser != null && _isFirestoreAvailable) {
        // Store token in Firestore with timeout
        await _firestore
            .collection('fcmTokens')
            .doc(currentUser!.uid)
            .set({'token': token, 'updatedAt': FieldValue.serverTimestamp()})
            .timeout(const Duration(seconds: 3));
      }
      return token;
    } catch (e) {
      print('❌ Error getting FCM token safely: $e');
      return null;
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
      IdTokenResult tokenResult = await currentUser!.getIdTokenResult();
      return tokenResult.claims?['admin'] == true;
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
}
