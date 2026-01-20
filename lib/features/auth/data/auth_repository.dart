import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:yet_x_app/core/constants/supabase_tables.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:yet_x_app/core/services/database_service.dart';
import 'package:yet_x_app/core/utils/logger_service.dart';
import 'package:yet_x_app/generated/locale_keys.g.dart';

/// ---> Verified and Approved <--- \\\

class AuthRepository {
  final SupabaseClient _supabase;
  final DatabaseService _db;

  AuthRepository(this._supabase, this._db);

  /// Username token
  Future<bool> isUsernameTaken(String username) async {
    try {
      // Check if a the user exists in the Profiles table
      final data = await _supabase
          .from(profilesTable.tableName)
          .select(profilesTable.username)
          .eq(profilesTable.username, username)
          .maybeSingle();

      return data != null;
    } catch (e) {
      return false;
    }
  }

  /// Sign up
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String userName,
    required String phoneNumber,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        profilesTable.fullName: fullName,
        profilesTable.username: userName,
        profilesTable.phoneNumber: phoneNumber,
      },
    );
  }

  /// Sign in
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Google Sign-In
  Future<AuthResponse> signInWithGoogle({
    required String idToken,
    required String accessToken,
  }) async {
    try {
      // Google ile giriş yap
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      final user = response.user;

      // Kullanıcı başarıyla giriş yaptıysa ve profil kontrolü yap
      if (user != null) {
        // Profilde username var mı kontrol et
        final profile = await _supabase
            .from(profilesTable.tableName)
            .select('${profilesTable.username}')
            .eq(profilesTable.id, user.id)
            .maybeSingle();

        // Username yoksa oluştur
        if (profile == null || profile[profilesTable.username] == null) {
          String username = await _generateUniqueUsername(user);

          // Profili güncelle
          await _supabase
              .from(profilesTable.tableName)
              .update({
            profilesTable.username: username,
            profilesTable.fullName: user.userMetadata?['full_name'] ?? user.email?.split('@')[0],
          })
              .eq(profilesTable.id, user.id);

          LogService.i('Username created for Google user: $username');
        }
      }

      return response;
    } catch (e) {
      LogService.e('Google Sign-In Error', e);
      rethrow;
    }
  }

  /// Benzersiz username oluştur
  Future<String> _generateUniqueUsername(User user) async {
    // Email'den veya display name'den base username al
    String baseUsername = user.userMetadata?['name']?.toString().toLowerCase().replaceAll(' ', '_')
        ?? user.email?.split('@')[0]
        ?? 'user';

    // Türkçe karakterleri temizle
    baseUsername = baseUsername
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');

    String username = baseUsername;
    int counter = 1;

    // Username benzersiz olana kadar dene
    while (await isUsernameTaken(username)) {
      username = '${baseUsername}_$counter';
      counter++;
    }

    return username;
  }



  /// Sign out
  Future<void> signOut() async {
    try {
      await _db.clearAllData();
      LogService.i(LocaleKeys.infos_database_clear.tr());

      await _supabase.auth.signOut();
      LogService.i(LocaleKeys.infos_user_logged_out.tr());
    } catch (e) {
      LogService.e(LocaleKeys.errors_logout_error.tr(), e);
      rethrow;
    }
  }

  /// Upload Profile Picture
  Future<void> uploadProfileImage(String userId, File imageFile) async {
    final fileExt = imageFile.path.split('.').last;
    final fileName = '$userId/avatar.$fileExt';

    await _supabase.storage
        .from(uploadsStorage.tableName)
        .upload(
          fileName,
          imageFile,
          fileOptions: const FileOptions(upsert: true),
        );

    final imageUrl = _supabase.storage
        .from(uploadsStorage.tableName)
        .getPublicUrl(fileName);
    final finalUrl = '$imageUrl?t=${DateTime.now().millisecondsSinceEpoch}';

    await _supabase
        .from(profilesTable.tableName)
        .update({profilesTable.profileImageUrl: finalUrl})
        .eq(profilesTable.id, userId);
  }

  /// Reset Password
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  /// Otp verification
  Future<AuthResponse> verifyOTP({
    required String email,
    required String token,
    required OtpType type,
  }) async {
    return await _supabase.auth.verifyOTP(
      email: email,
      token: token,
      type: type,
    );
  }

  // Resend otp code
  Future<void> resendOtp(String email) async {
    if (email.trim().isEmpty) {
      throw LocaleKeys.errors_email_not_found_login_again.tr();
    }
    await _supabase.auth.resend(type: OtpType.signup, email: email);
  }

  /// Send password reset otp code
  Future<void> sendPasswordResetOTP(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
      );
      LogService.i(LocaleKeys.infos_password_reset_otp_sent.tr());
    } catch (e) {
      LogService.e(LocaleKeys.errors_password_reset_otp_send_fail.tr(), e);
      rethrow;
    }
  }

  // Verify password reset otp
  Future<AuthResponse> verifyPasswordResetOTP({
    required String email,
    required String token,
  }) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.recovery,
      );
      LogService.i(LocaleKeys.infos_password_reset_otp_verifies.tr());
      return response;
    } catch (e) {
      LogService.e(LocaleKeys.errors_password_reset_otp_send_fail.tr(), e);
      rethrow;
    }
  }

  /// Update Password
  Future<UserResponse> updatePassword(String newPassword) async {
    try {
      final response = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      LogService.i(LocaleKeys.infos_password_updated.tr());
      return response;
    } catch (e) {
      LogService.e(LocaleKeys.errors_password_update_fail.tr(), e);
      rethrow;
    }
  }

  ///Delete permanently account
  Future<void> deleteAccount() async {
    try {
      await _supabase.rpc(SupabaseRpc.deleteUserAccount);
      LogService.i(LocaleKeys.infos_account_permanently_deleted.tr());

      await _db.clearAllData();
    } catch (e) {
      LogService.e(LocaleKeys.errors_delete_account_fail.tr(), e);
      rethrow;
    }
  }
}

/// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    Supabase.instance.client,
    ref.read(databaseServiceProvider),
  );
});
