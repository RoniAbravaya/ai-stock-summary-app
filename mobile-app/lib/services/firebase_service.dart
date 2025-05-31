import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Getters
  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;
  FirebaseMessaging get messaging => _messaging;
  FirebaseStorage get storage => _storage;
  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => _auth.currentUser != null;

  /// Initialize Firebase services
  Future<void> initialize() async {
    try {
      // Request notification permissions
      await _requestNotificationPermissions();

      // Get FCM token
      await _getFCMToken();

      print('✅ Firebase services initialized successfully');
    } catch (e) {
      print('❌ Error initializing Firebase services: $e');
    }
  }

  /// Request notification permissions
  Future<void> _requestNotificationPermissions() async {
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
  }

  /// Get and store FCM token
  Future<String?> _getFCMToken() async {
    try {
      String? token = await _messaging.getToken();
      if (token != null && currentUser != null) {
        // Store token in Firestore
        await _firestore.collection('fcmTokens').doc(currentUser!.uid).set({
          'token': token,
          'updatedAt': FieldValue.serverTimestamp(),
        });
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
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _updateUserDocument(result.user!);
      await _getFCMToken();

      return result;
    } catch (e) {
      print('❌ Error signing in with email: $e');
      rethrow;
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

      // Update user profile
      await result.user!.updateDisplayName(displayName);

      // Create user document
      await _createUserDocument(result.user!);
      await _getFCMToken();

      return result;
    } catch (e) {
      print('❌ Error registering with email: $e');
      rethrow;
    }
  }

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);

      await _updateUserDocument(result.user!);
      await _getFCMToken();

      return result;
    } catch (e) {
      print('❌ Error signing in with Google: $e');
      rethrow;
    }
  }

  /// Sign in with Facebook
  Future<UserCredential?> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status != LoginStatus.success) {
        throw Exception('Facebook login failed');
      }

      final OAuthCredential credential = FacebookAuthProvider.credential(
        result.accessToken!.token,
      );

      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      await _updateUserDocument(userCredential.user!);
      await _getFCMToken();

      return userCredential;
    } catch (e) {
      print('❌ Error signing in with Facebook: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await FacebookAuth.instance.logOut();
      await _auth.signOut();
      print('✅ User signed out successfully');
    } catch (e) {
      print('❌ Error signing out: $e');
      rethrow;
    }
  }

  /// Create user document in Firestore
  Future<void> _createUserDocument(User user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'role': 'user',
        'subscriptionType': 'free',
        'summariesUsed': 0,
        'summariesLimit': 10,
        'lastResetDate': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ User document created successfully');
    } catch (e) {
      print('❌ Error creating user document: $e');
      rethrow;
    }
  }

  /// Update user document in Firestore
  Future<void> _updateUserDocument(User user) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        await _createUserDocument(user);
      } else {
        await _firestore.collection('users').doc(user.uid).update({
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('❌ Error updating user document: $e');
      rethrow;
    }
  }

  /// Get user data from Firestore
  Future<DocumentSnapshot> getUserData() async {
    if (currentUser == null) throw Exception('No user signed in');

    return await _firestore.collection('users').doc(currentUser!.uid).get();
  }

  /// Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    if (currentUser == null) throw Exception('No user signed in');

    await _firestore.collection('users').doc(currentUser!.uid).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
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

    await _firestore
        .collection('favorites')
        .doc(currentUser!.uid)
        .collection('stocks')
        .doc(stockId)
        .set({'stockId': stockId, 'addedAt': FieldValue.serverTimestamp()});
  }

  /// Remove stock from favorites
  Future<void> removeFromFavorites(String stockId) async {
    if (currentUser == null) throw Exception('No user signed in');

    await _firestore
        .collection('favorites')
        .doc(currentUser!.uid)
        .collection('stocks')
        .doc(stockId)
        .delete();
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
    return await _firestore.collection('summaries').doc(stockId).get();
  }
}
