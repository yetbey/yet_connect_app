// ============================================================================
// LOGIN PAGE
// ============================================================================
// This page allows users to sign in to the application.
// It performs email and password validation and manages error handling.
//
// Features:
// - Email and password validation
// - Password visibility toggle
// - Loading state handling
// - Email verification handling
// - Forgot password action
// - Navigation to register page
// ============================================================================

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yet_x_app/core/services/navigation_service.dart';
import 'package:yet_x_app/generated/locale_keys.g.dart';
import 'package:yet_x_app/shared/widgets/custom_auth_button.dart';
import 'package:yet_x_app/shared/widgets/custom_text_form_field.dart';
import 'package:yet_x_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:yet_x_app/config/routes/app_routes.dart';
import '../../../../core/utils/utils.dart';

/// Login page - User authentication screen
///
/// This widget allows users to log in using their email and password.
/// It integrates with Riverpod state management via [ConsumerStatefulWidget].
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  // ============================================================================
  // STATE & CONTROLLERS
  // ============================================================================

  /// Global key used to validate the form.
  final _formKey = GlobalKey<FormState>();

  /// Controller for the email input field.
  final _emailController = TextEditingController();

  /// Controller for the password input field.
  final _passwordController = TextEditingController();

  /// Notifier that manages the password visibility state.
  final ValueNotifier<bool> _isPasswordVisible = ValueNotifier<bool>(false);

  // ============================================================================
  // LIFECYCLE METHODS
  // ============================================================================

  /// Disposes controllers and notifiers to free up resources.
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _isPasswordVisible.dispose();
    super.dispose();
  }

  // ============================================================================
  // AUTHENTICATION LOGIC
  // ============================================================================

  /// Handles the login process.
  ///
  /// Steps:
  /// 1. Validates the form.
  /// 2. Trims and reads email & password values.
  /// 3. Calls the sign-in method on the auth provider.
  /// 4. Navigates to home on success.
  /// 5. Redirects to email verification screen if email is not verified.
  /// 6. Shows a friendly error message for other failures.
  Future<void> _handleLogin() async {
    // If form is not valid, abort early.
    if (!_formKey.currentState!.validate()) return;

    // Read and trim email value.
    final email = _emailController.text.trim();

    try {
      // Get auth notifier from the provider.
      final authNotifier = ref.read(authProvider.notifier);

      // Perform sign-in.
      await authNotifier.signIn(
        email: email,
        password: _passwordController.text.trim(),
      );

      // If successfully logged in and widget is still mounted, navigate to home.
      if (mounted && ref.read(authProvider).isLoggedIn) {
        NavigationService.toNamed(AppRoutes.home);
      }
    } catch (e) {
      // Handle custom email-not-verified error.
      if (e.toString().contains('Auth.EmailNotVerified')) {
        if (mounted) {
          // Inform user that email is not verified.
          Utils.showSnackBar(
            text: LocaleKeys.errors_email_not_verified_new_code.tr(),
            isError: false,
          );

          // Navigate to email verification page with email as argument.
          NavigationService.toNamed(
            AppRoutes.emailVerification,
            arguments: {'email': email},
          );
        }
      }
      // Other errors are handled by the auth provider.
    }
  }

  // ============================================================================
  // EMAIL VALIDATOR
  // ============================================================================

  /// Validates the email input.
  ///
  /// Checks:
  /// - Non-empty value.
  /// - Contains "@".
  /// - Matches a basic email pattern.
  ///
  /// Returns an error message string if invalid, otherwise `null`.
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return LocaleKeys.validation_email_required.tr();
    }

    if (!value.contains('@')) {
      return LocaleKeys.validation_invalid_email.tr();
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return LocaleKeys.validation_invalid_email.tr();
    }

    return null;
  }

  // ============================================================================
  // PASSWORD VALIDATOR
  // ============================================================================

  /// Validates the password input.
  ///
  /// Checks:
  /// - Non-empty value.
  /// - Minimum length of 6 characters.
  ///
  /// Returns an error message string if invalid, otherwise `null`.
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return LocaleKeys.validation_password_required.tr();
    }

    if (value.length < 6) {
      return LocaleKeys.validation_password_min_length.tr();
    }

    return null;
  }

  // ============================================================================
  // UI BUILDERS
  // ============================================================================

  /// Builds the back navigation button.
  Widget _buildBackButton(ThemeData theme) {
    return IconButton(
      onPressed: () => NavigationService.back(),
      icon: Icon(
        Icons.arrow_back_ios_new_rounded,
        color: theme.iconTheme.color,
      ),
      tooltip: 'Back',
    );
  }

  /// Builds the page header (title and subtitle).
  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main title.
          Text(
            LocaleKeys.auth_welcome_title.tr(),
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          // Subtitle showing the app name.
          Text(
            LocaleKeys.common_app_name.tr(),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the email input field.
  Widget _buildEmailField() {
    return CustomTextFormField(
      hintText: LocaleKeys.auth_email.tr(),
      obscureText: false,
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textCapitalization: TextCapitalization.none,
      validator: _validateEmail,
      prefixIcon: const Icon(
        Icons.email_outlined,
        color: Colors.white54,
      ),
    );
  }

  /// Builds the password input field with visibility toggle.
  Widget _buildPasswordField() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isPasswordVisible,
      builder: (context, isVisible, child) {
        return CustomTextFormField(
          hintText: LocaleKeys.auth_password.tr(),
          obscureText: !isVisible,
          controller: _passwordController,
          validator: _validatePassword,
          prefixIcon: const Icon(
            Icons.lock_outline_rounded,
            color: Colors.white54,
          ),
          suffixIcon: IconButton(
            onPressed: () {
              _isPasswordVisible.value = !isVisible;
            },
            icon: Icon(
              isVisible
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
              color: Colors.white54,
            ),
            tooltip: isVisible ? LocaleKeys.auth_hide_password.tr() : LocaleKeys.auth_show_password.tr(),
          ),
        );
      },
    );
  }

  /// Builds the "Forgot password" button.
  Widget _buildForgotPasswordButton(ThemeData theme) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () => NavigationService.toNamed(AppRoutes.forgotPassword),
        child: Text(
          LocaleKeys.auth_forgot_password.tr(),
          style: TextStyle(
            color: theme.primaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  /// Builds the register navigation link.
  Widget _buildRegisterLink(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          LocaleKeys.auth_dont_have_account.tr(),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white70,
          ),
        ),
        TextButton(
          onPressed: () => NavigationService.toNamed(AppRoutes.register),
          child: Text(
            LocaleKeys.auth_register.tr(),
            style: TextStyle(
              color: theme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleSignInButton(ThemeData theme) {
    final authState = ref.watch(authProvider);

    return OutlinedButton.icon(
      onPressed: authState.isLoading
          ? null
          : () => ref.read(authProvider.notifier).signInWithGoogle(),
      icon: const FaIcon(FontAwesomeIcons.google, size: 20, color: Colors.white),
      label: Text(
        'Google ile Giriş Yap',
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.white54, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 16),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Builds divider with "veya" text
  Widget _buildDivider(ThemeData theme) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Colors.white38)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'veya',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
        ),
        const Expanded(child: Divider(color: Colors.white38)),
      ],
    );
  }

  // ============================================================================
  // MAIN BUILD METHOD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    // Listen to auth state.
    final authState = ref.watch(authProvider);

    // Get current theme.
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button.
                _buildBackButton(theme),
                const SizedBox(height: 20),

                // Header section.
                _buildHeader(theme),
                const SizedBox(height: 40),

                // Form section.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      _buildEmailField(),
                      const SizedBox(height: 16),
                      _buildPasswordField(),
                      const SizedBox(height: 32),

                      // Login button.
                      CustomAuthButton(
                        label: LocaleKeys.auth_login.tr(),
                        isLoading: authState.isLoading,
                        onTap: _handleLogin,
                      ),
                      const SizedBox(height: 16),

                      // Forgot password link.
                      _buildForgotPasswordButton(theme),
                      const SizedBox(height: 24),

                      // Divider
                      _buildDivider(theme),
                      const SizedBox(height: 24),

                      // Google Sign-In button
                      _buildGoogleSignInButton(theme),
                      const SizedBox(height: 24),

                      // Register link.
                      _buildRegisterLink(theme),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
