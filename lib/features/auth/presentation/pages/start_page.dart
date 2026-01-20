// ============================================================================
// START PAGE
// ============================================================================
// This is the initial landing page for unauthenticated users.
// It displays the app branding and provides navigation to login or register.
//
// Features:
// - Full-screen background image with gradient overlay
// - App name/logo display
// - Login button navigation
// - Register button navigation
// - Responsive layout
// - High-quality image rendering
// ============================================================================

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:yet_x_app/core/constants/app_constants.dart';
import 'package:yet_x_app/config/routes/app_routes.dart';
import 'package:yet_x_app/core/services/navigation_service.dart';
import 'package:yet_x_app/generated/locale_keys.g.dart';
import 'package:yet_x_app/shared/widgets/custom_auth_button.dart';

/// Start page - Initial landing screen for unauthenticated users
///
/// This widget serves as the welcome/splash screen that presents users
/// with options to either log in to an existing account or create a new one.
/// It features a full-screen background image with overlay for better readability.
class StartPage extends StatelessWidget {
  const StartPage({super.key});

  // ============================================================================
  // UI BUILDERS
  // ============================================================================

  /// Builds the background image layer.
  ///
  /// Uses the app's main logo as a full-screen background with high quality
  /// rendering and cover fit mode to ensure proper display on all screen sizes.
  Widget _buildBackgroundImage(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: Image.asset(
        AppConstants.mainLogo,
        filterQuality: FilterQuality.high,
        fit: BoxFit.cover,
      ),
    );
  }

  /// Builds the gradient overlay layer.
  ///
  /// Adds a dark gradient from top to bottom to improve text readability
  /// and create visual depth. The gradient becomes more opaque towards the bottom
  /// where the content is located.
  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha:  0.3),
            Colors.black.withValues(alpha:  0.7),
          ],
        ),
      ),
    );
  }

  /// Builds the app name/title.
  ///
  /// Displays the app name in large, bold text with letter spacing
  /// for a modern, premium look.
  Widget _buildAppName() {
    return Text(
      LocaleKeys.common_app_name.tr(),
      style: const TextStyle(
        fontSize: 42,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  /// Builds the login button.
  ///
  /// When pressed, navigates the user to the login page.
  Widget _buildLoginButton() {
    return CustomAuthButton(
      label: LocaleKeys.auth_login.tr(),
      isLoading: false,
      onTap: () {
        NavigationService.toNamed(AppRoutes.login);
      },
    );
  }

  /// Builds the register button.
  ///
  /// When pressed, navigates the user to the registration page.
  Widget _buildRegisterButton() {
    return CustomAuthButton(
      label: LocaleKeys.auth_register.tr(),
      isLoading: false,
      onTap: () {
        NavigationService.toNamed(AppRoutes.register);
      },
    );
  }

  /// Builds the content section with app name and action buttons.
  ///
  /// Positioned at the bottom of the screen for better visual hierarchy
  /// and thumb reachability on mobile devices.
  Widget _buildContent() {
    return Positioned(
      bottom: 60,
      left: 20,
      right: 20,
      child: Column(
        children: [
          // App name/title.
          _buildAppName(),
          const SizedBox(height: 50),

          // Login button.
          _buildLoginButton(),
          const SizedBox(height: 16),

          // Register button.
          _buildRegisterButton(),
        ],
      ),
    );
  }

  // ============================================================================
  // MAIN BUILD METHOD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Layer 1: Background image.
          _buildBackgroundImage(context),

          // Layer 2: Gradient overlay for better readability.
          _buildGradientOverlay(),

          // Layer 3: Content (app name and buttons).
          _buildContent(),
        ],
      ),
    );
  }
}
