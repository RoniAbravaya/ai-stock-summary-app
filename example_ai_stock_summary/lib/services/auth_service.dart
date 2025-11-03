import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:twitter_login/twitter_login.dart';
import '../services/supabase_service.dart';
import '../models/user_profile_model.dart';

class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();

  AuthService._();

  final client = SupabaseService.instance.client;

  // Get current user
  User? get currentUser => client.auth.currentUser;

  // Check if user is signed in
  bool get isSignedIn => currentUser != null;

  // Get current user profile
  Future<UserProfileModel?> getCurrentUserProfile() async {
    if (!isSignedIn) return null;

    try {
      final response = await client
          .from('user_profiles')
          .select('*')
          .eq('id', currentUser!.id)
          .single();

      return UserProfileModel.fromJson(response);
    } catch (error) {
      throw Exception('Failed to fetch user profile: $error');
    }
  }

  // Sign up with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
    String? role,
  }) async {
    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName ?? email.split('@')[0],
          'role': role ?? 'member',
        },
      );
      return response;
    } catch (error) {
      throw Exception('Sign-up failed: $error');
    }
  }

  // Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (error) {
      throw Exception('Sign-in failed: $error');
    }
  }

  // Sign in with Google OAuth
  Future<bool> signInWithGoogle() async {
    try {
      return await client.auth.signInWithOAuth(OAuthProvider.google);
    } catch (error) {
      throw Exception('Google sign-in failed: $error');
    }
  }

  // Sign in with Facebook OAuth
  Future<AuthResponse> signInWithFacebook() async {
    try {
      // Trigger the Facebook sign-in flow
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      // Check if login was successful
      if (result.status != LoginStatus.success) {
        if (result.status == LoginStatus.cancelled) {
          throw Exception('Facebook Sign-In was cancelled');
        }
        throw Exception('Facebook Sign-In failed: ${result.message}');
      }

      // Get the access token
      final AccessToken? accessToken = result.accessToken;
      if (accessToken == null) {
        throw Exception('Failed to get Facebook access token');
      }

      // Sign in to Supabase with the Facebook access token
      final response = await client.auth.signInWithIdToken(
        provider: OAuthProvider.facebook,
        idToken: accessToken.token,
      );

      return response;
    } catch (error) {
      throw Exception('Facebook sign-in failed: $error');
    }
  }

  // Sign in with Twitter OAuth
  Future<AuthResponse> signInWithTwitter() async {
    try {
      // Initialize Twitter login
      final twitterLogin = TwitterLogin(
        apiKey: 'fbDFUxyJ1RaHGed9fQrHfJx3h',
        apiSecretKey: 'kP3jjgqIoxAFObHMqDL2ekN0qP5AzrUFqc5VcnEnyXFXCNfBg3',
        redirectURI: 'aistock://',
      );

      // Trigger the Twitter sign-in flow
      final authResult = await twitterLogin.login();

      // Check if login was successful
      if (authResult.status != TwitterLoginStatus.loggedIn) {
        if (authResult.status == TwitterLoginStatus.cancelledByUser) {
          throw Exception('Twitter Sign-In was cancelled');
        }
        throw Exception('Twitter Sign-In failed: ${authResult.errorMessage}');
      }

      // Get the auth token and secret
      final authToken = authResult.authToken;
      final authTokenSecret = authResult.authTokenSecret;
      
      if (authToken == null || authTokenSecret == null) {
        throw Exception('Failed to get Twitter auth tokens');
      }

      // Sign in to Supabase with Twitter tokens
      // Note: Supabase might require different approach for Twitter OAuth
      // Using the access token as ID token for demonstration
      final response = await client.auth.signInWithIdToken(
        provider: OAuthProvider.twitter,
        idToken: authToken,
        accessToken: authTokenSecret,
      );

      return response;
    } catch (error) {
      throw Exception('Twitter sign-in failed: $error');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await FacebookAuth.instance.logOut();
      await client.auth.signOut();
    } catch (error) {
      throw Exception('Sign-out failed: $error');
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? fullName,
    String? avatarUrl,
  }) async {
    if (!isSignedIn) throw Exception('User not signed in');

    try {
      final updateData = <String, dynamic>{};

      if (fullName != null) updateData['full_name'] = fullName;
      if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;

      updateData['updated_at'] = DateTime.now().toIso8601String();

      await client
          .from('user_profiles')
          .update(updateData)
          .eq('id', currentUser!.id);
    } catch (error) {
      throw Exception('Failed to update profile: $error');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await client.auth.resetPasswordForEmail(email);
    } catch (error) {
      throw Exception('Password reset failed: $error');
    }
  }

  // Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      await client.auth.updateUser(UserAttributes(password: newPassword));
    } catch (error) {
      throw Exception('Password update failed: $error');
    }
  }

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  // Check if user has admin role
  Future<bool> isAdmin() async {
    final profile = await getCurrentUserProfile();
    return profile?.role == 'admin';
  }

  // Check if user has manager role or above
  Future<bool> isManagerOrAbove() async {
    final profile = await getCurrentUserProfile();
    return profile?.role == 'admin' || profile?.role == 'manager';
  }

  // Delete account
  Future<void> deleteAccount() async {
    if (!isSignedIn) throw Exception('User not signed in');

    try {
      // First delete user profile (will cascade to related data)
      await client.from('user_profiles').delete().eq('id', currentUser!.id);

      // Then sign out
      await signOut();
    } catch (error) {
      throw Exception('Account deletion failed: $error');
    }
  }
}
