import 'package:supabase_flutter/supabase_flutter.dart';
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

  // Sign out
  Future<void> signOut() async {
    try {
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
