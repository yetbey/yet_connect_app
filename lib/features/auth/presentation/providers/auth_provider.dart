import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yet_x_app/config/routes/app_routes.dart';
import 'package:yet_x_app/core/services/navigation_service.dart';
import 'package:yet_x_app/features/chat/presentation/providers/chat_provider.dart';
import 'package:yet_x_app/features/profile/presentation/providers/user_provider.dart';
import 'package:yet_x_app/features/auth/data/auth_repository.dart';
import 'package:yet_x_app/core/utils/error_handler.dart';
import 'package:yet_x_app/core/utils/utils.dart';
import 'package:yet_x_app/generated/locale_keys.g.dart';
import 'package:yet_x_app/core/utils/analytics_helper.dart';

/// ---> Verified and Approved <--- \\\

final supabaseAuthStateProvider = StreamProvider((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final sessionProvider = Provider((ref) {
  final authState = ref.watch(supabaseAuthStateProvider);
  return authState.value?.session;
});

class AuthState {
  final bool isLoading;
  final bool isLoggedIn;

  AuthState({this.isLoading = false, this.isLoggedIn = false});

  AuthState copyWith({bool? isLoading, bool? isLoggedIn}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _authRepository = ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    final session = Supabase.instance.client.auth.currentSession;
    return AuthState(isLoading: false, isLoggedIn: session != null);
  }

  void setLoggedIn(bool value) {
    state = state.copyWith(isLoggedIn: value);
  }

  /// Sign up
  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required String userName,
    required String phoneNumber,
    File? imageFile,
  }) async {
    state = state.copyWith(isLoading: true);

    ErrorHandler.log(LocaleKeys.infos_user_began_registration.tr(), data: {
      'email': email,
      'username': userName,
    });

    try {
      final res = await _authRepository.signUp(
        email: email,
        password: password,
        fullName: fullName,
        userName: userName,
        phoneNumber: phoneNumber,
      );

      final user = res.user;
      if (user != null) {
        await ErrorHandler.setUserContext(user.id, email: user.email);
        await AnalyticsHelper.setUserId(user.id);

        if (res.session == null) {
          ErrorHandler.log('Registration successful - email verification required');
          Utils.showSnackBar(
            text: LocaleKeys.auth_verify_email.tr(),
            isError: false,
          );
        } else {
          if (imageFile != null) {
            ErrorHandler.log('Uploading profile image');
            await _authRepository.uploadProfileImage(user.id, imageFile);
          }

          ErrorHandler.log('Registration completed successfully');
          await AnalyticsHelper.logSignUp('email');
          state = state.copyWith(isLoggedIn: true);
        }
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'User Registration',
        severity: ErrorSeverity.medium,
        userAction: LocaleKeys.auth_try_create_account.tr(),
        metadata: {
          'email': email,
          'username': userName,
          'has_image': imageFile != null,
        },
      );

      final errorMessage = ErrorHandler.getErrorMessage(e);
      Utils.showSnackBar(text: errorMessage, isError: true);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Sign in
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true);

    ErrorHandler.log('User attempting login', data: {'email': email});

    try {
      final res = await _authRepository.signIn(
        email: email,
        password: password,
      );

      final user = res.user;
      if (user != null) {
        await ErrorHandler.setUserContext(user.id, email: user.email);
        await AnalyticsHelper.setUserId(user.id);

        ErrorHandler.log('Login successful');
        await AnalyticsHelper.logLogin('email');

        state = state.copyWith(isLoggedIn: true);
        ref.read(userProvider.notifier).fetchMyProfile();
        // ref.read(chatListProvider.notifier).fetchChats();
      }
    } catch (e, stackTrace) {
      final errorString = e.toString();

      if (errorString.contains('Email not confirmed')) {

        try {
          await _authRepository.resendOtp(email);
          Utils.showSnackBar(
              text: LocaleKeys.errors_email_not_verified_new_code.tr(),
              isError: false
          );
        } catch (resendError) {
          ErrorHandler.log('Auto-resend failed: $resendError');
        }

        state = state.copyWith(isLoading: false);

        throw 'Auth.EmailNotVerified';
      }

      if (errorString.contains('Auth.EmailNotVerified')) {
        state = state.copyWith(isLoading: false);
        rethrow;
      }

      ErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'User Login',
        severity: ErrorSeverity.medium,
        userAction: LocaleKeys.auth_try_to_sign_in.tr(),
        metadata: {'email': email},
      );

      final errorMessage = ErrorHandler.getErrorMessage(e);
      Utils.showSnackBar(text: errorMessage, isError: true);
    } finally {
      if (state.isLoading) state = state.copyWith(isLoading: false);
    }
  }

  /// Google Sign-In
  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true);
    ErrorHandler.log('User attempting Google sign-in');

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: '1009522679920-e0stf8l6qmbg79ldhro7jun1fee5bgqs.apps.googleusercontent.com', // Web Client ID
        scopes: [
          'email',
          'profile',
        ],
      );

      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        state = state.copyWith(isLoading: false);
        return; // Kullanıcı iptal etti
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw 'Google authentication failed';
      }

      final res = await _authRepository.signInWithGoogle(
        idToken: idToken,
        accessToken: accessToken,
      );

      final user = res.user;
      if (user != null) {
        await ErrorHandler.setUserContext(user.id, email: user.email);
        await AnalyticsHelper.setUserId(user.id);
        ErrorHandler.log('Google sign-in successful');
        await AnalyticsHelper.logLogin('google');

        state = state.copyWith(isLoggedIn: true);
        ref.read(userProvider.notifier).fetchMyProfile();
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'Google Sign-In',
        severity: ErrorSeverity.medium,
        userAction: 'Try Google sign-in again',
      );
      final errorMessage = ErrorHandler.getErrorMessage(e);
      Utils.showSnackBar(text: errorMessage, isError: true);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }


  /// Sign out
  Future<void> signOut() async {
    ErrorHandler.log('User logging out');

    try {
      await _authRepository.signOut();

      ref.read(userProvider.notifier).clearUserData();
      ref.read(chatListProvider.notifier).clearChats();

      await ErrorHandler.clearUserContext();
      await AnalyticsHelper.clearUserId();
      await AnalyticsHelper.logLogout();

      state = state.copyWith(isLoggedIn: false);

      ErrorHandler.log('Logout successful');
      Utils.showSnackBar(text: LocaleKeys.auth_logout.tr(), isError: false);
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: LocaleKeys.auth_logged_out,
        severity: ErrorSeverity.high,
        userAction: LocaleKeys.auth_try_log_out.tr(),
      );

      final errorMessage = ErrorHandler.getErrorMessage(e);
      Utils.showSnackBar(text: errorMessage, isError: true);
    }
  }

  /// Delete Account
  Future<void> deleteAccount() async {
    state = state.copyWith(isLoading: true);

    try {
      await _authRepository.deleteAccount();
      ref.read(userProvider.notifier).clearUserData();
      state = state.copyWith(isLoggedIn: false);
      NavigationService.offAllNamed(AppRoutes.start);
      Utils.showSnackBar(
          text: LocaleKeys.infos_account_permanently_deleted.tr(),
          isError: false
      );
    } catch (e) {
      final errorMessage = ErrorHandler.getErrorMessage(e);
      Utils.showSnackBar(text: errorMessage, isError: true);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// OTP Verification
  Future<bool> verifyEmailOtp({
    required String email,
    required String token,
}) async {
    state = state.copyWith(isLoading: true);
    ErrorHandler.log('Verify Otp for Email', data: {'email': email});

    try {
      final res = await _authRepository.verifyOTP(email: email, token: token, type: OtpType.signup);

      final user = res.user;
      if (user != null) {
        await ErrorHandler.setUserContext(user.id, email: user.email);
        await AnalyticsHelper.setUserId(user.id);
        
        ref.read(userProvider.notifier).fetchMyProfile();

        ErrorHandler.log('OTP verification successful');
        state = state.copyWith(isLoading: false, isLoggedIn: true);
        return true; // success
      }
      return false; // fail
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace: stackTrace, context: 'Otp Verification ');
      final errorMessage = ErrorHandler.getErrorMessage(e);
      Utils.showSnackBar(text: errorMessage, isError: true);
      state = state.copyWith(isLoading: false);
      return false; // fail
    }
  }

  /// Resend verification code
  Future<void> resendVerificationCode(String email) async {
    try {
      await _authRepository.resendOtp(email);
      Utils.showSnackBar(text: LocaleKeys.infos_otp_sent_to_email.tr(), isError: false);
    } catch (e) {
      final errorMessage = ErrorHandler.getErrorMessage(e);
      Utils.showSnackBar(text: errorMessage, isError: true);
    }
  }
}

/// Auth provider
final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
