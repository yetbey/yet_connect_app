// ============================================================================
// AUTH WRAPPER
// ============================================================================
// This widget acts as the authentication gate for the application.
// It determines which screen to show based on authentication state and
// handles zombie session detection.
//
// Features:
// - Authentication state monitoring
// - User profile validation
// - Zombie session detection and cleanup
// - Loading state handling
// - Automatic navigation based on auth state
//
// Flow:
// 1. Check if auth state is loading -> show loading indicator
// 2. Check if user is logged in -> validate profile
// 3. If profile is null but logged in -> fetch profile or sign out
// 4. If not logged in -> show start page
// ============================================================================

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yet_x_app/features/auth/presentation/pages/start_page.dart';
import 'package:yet_x_app/features/dashboard/presentation/pages/navigation_page.dart';
import 'package:yet_x_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:yet_x_app/features/profile/presentation/providers/user_provider.dart';
import 'package:yet_x_app/core/utils/logger_service.dart';
import 'package:yet_x_app/generated/locale_keys.g.dart';

/// Authentication wrapper - Main entry point for auth flow
///
/// This widget monitors authentication state and determines which screen
/// to display. It also handles edge cases like deleted user accounts
/// (zombie sessions) by validating the user profile on startup.
class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  // ============================================================================
  // LIFECYCLE METHODS
  // ============================================================================

  /// Initialize state and trigger user session validation.
  @override
  void initState() {
    super.initState();
    // Start session check when widget is first created.
    _checkUserSession();
  }

  // ============================================================================
  // SESSION VALIDATION LOGIC
  // ============================================================================

  /// Validates the current user session.
  ///
  /// This method performs zombie session detection by:
  /// 1. Checking if user is logged in but profile is not loaded
  /// 2. Attempting to fetch user profile from backend
  /// 3. If profile doesn't exist (deleted account), signing out user
  /// 4. Preventing access to app with invalid session
  ///
  /// A zombie session occurs when a user's auth token exists but their
  /// account has been deleted from the database.
  Future<void> _checkUserSession() async {
    // Wait for the current build cycle to complete before reading providers.
    // This prevents "Cannot read provider during build" errors.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Read current auth and user states.
      final authState = ref.read(authProvider);
      final userState = ref.read(userProvider);

      // Check for zombie session: logged in but no user profile in memory.
      if (authState.isLoggedIn && userState.currentUser == null) {
        try {
          LogService.i('AuthWrapper: Validating user profile...');

          // Attempt to fetch user profile from backend.
          await ref.read(userProvider.notifier).fetchMyProfile();

          // Verify that profile was successfully loaded.
          final user = ref.read(userProvider).currentUser;

          if (user == null) {
            // Profile doesn't exist in database - account was deleted.
            throw Exception('User not found in database (deleted account)');
          }
        } catch (e) {
          // Handle zombie session: force sign out.
          LogService.e('AuthWrapper: Zombie session detected. Signing out.', e);

          // Clear local auth session since user no longer exists.
          await ref.read(authProvider.notifier).signOut();
        }
      }
    });
  }

  // ============================================================================
  // UI BUILDERS
  // ============================================================================

  /// Builds a loading screen for authentication state.
  Widget _buildAuthLoadingScreen() {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// Builds a loading screen for profile validation.
  Widget _buildProfileLoadingScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              LocaleKeys.auth_validating_profile.tr(),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // MAIN BUILD METHOD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    // Watch auth and user states for reactive updates.
    final authState = ref.watch(authProvider);
    final userState = ref.watch(userProvider);

    // State 1: Authentication state is loading.
    // Show loading indicator while determining auth status.
    if (authState.isLoading) {
      return _buildAuthLoadingScreen();
    }

    // State 2: User is authenticated.
    if (authState.isLoggedIn) {
      // State 2a: Profile is not loaded yet.
      // This is critical - we must validate the profile before
      // allowing access to the app. The _checkUserSession method
      // will either load the profile or sign out if it doesn't exist.
      if (userState.currentUser == null) {
        return _buildProfileLoadingScreen();
      }

      // State 2b: Profile is loaded successfully.
      // User is authenticated and profile exists - show main app.
      return const NavigationPage();
    }

    // State 3: User is not authenticated.
    // Show start/welcome page with login/register options.
    return const StartPage();
  }
}
