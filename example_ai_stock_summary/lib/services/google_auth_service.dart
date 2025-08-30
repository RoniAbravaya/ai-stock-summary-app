import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';

class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  final SupabaseService _supabase = SupabaseService();
  late GoogleSignIn _googleSignIn;

  void initialize() {
    _googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
    );
  }

  // Sign in with Google
  Future<AuthResponse?> signInWithGoogle() async {
    try {
      // Sign in with Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in cancelled by user');
      }

      // Get Google auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('Failed to get Google auth tokens');
      }

      // Sign in to Supabase with Google credentials
      final AuthResponse response =
          await _supabase.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken!,
      );

      return response;
    } catch (e) {
      print('Google sign-in error: $e');
      rethrow;
    }
  }

  // Sign out from Google and Supabase
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _supabase.client.auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
      rethrow;
    }
  }

  // Check if user is signed in with Google
  Future<bool> isSignedIn() async {
    try {
      return await _googleSignIn.isSignedIn();
    } catch (e) {
      print('Check sign-in status error: $e');
      return false;
    }
  }

  // Get current Google user
  GoogleSignInAccount? getCurrentUser() {
    return _googleSignIn.currentUser;
  }

  // Disconnect Google account
  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
    } catch (e) {
      print('Disconnect Google account error: $e');
      rethrow;
    }
  }
}
