// ============================================================================
// REGISTER PAGE
// ============================================================================
// This page allows new users to create an account.
// It performs comprehensive validation for all input fields including
// real-time username availability checking.
//
// Features:
// - Full name, email, username, password, and phone number validation
// - Real-time username availability check with debouncing
// - Password visibility toggle
// - Input formatters for proper data formatting
// - Loading state management
// - Navigation to email verification after successful registration
// ============================================================================

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:yet_x_app/core/services/navigation_service.dart';
import 'package:yet_x_app/core/utils/formatters.dart';
import 'package:yet_x_app/features/auth/data/auth_repository.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:yet_x_app/generated/locale_keys.g.dart';
import 'package:yet_x_app/shared/widgets/custom_auth_button.dart';
import 'package:yet_x_app/shared/widgets/custom_text_form_field.dart';
import 'package:yet_x_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:yet_x_app/core/utils/validators.dart';
import 'package:yet_x_app/config/routes/app_routes.dart';

/// Register page - New user account creation screen
///
/// This widget provides a comprehensive registration form with real-time
/// validation and username availability checking. It integrates with Riverpod
/// for state management.
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  // ============================================================================
  // STATE & CONTROLLERS
  // ============================================================================

  /// Global key used to validate the form.
  final _formKey = GlobalKey<FormState>();

  /// Controller for the email input field.
  final _emailController = TextEditingController();

  /// Controller for the password input field.
  final _passwordController = TextEditingController();

  /// Controller for the full name input field.
  final _fullNameController = TextEditingController();

  /// Controller for the phone number input field.
  final _phoneNumberController = TextEditingController();

  /// Controller for the username input field.
  final _userNameController = TextEditingController();

  /// Notifier that manages the password visibility state.
  final ValueNotifier<bool> _isPasswordVisible = ValueNotifier<bool>(false);

  /// Timer for debouncing username availability checks.
  Timer? _debounce;

  /// Flag indicating if the current username is already taken.
  bool _isUsernameTaken = false;

  /// Flag indicating if a username check is in progress.
  bool _isCheckingUsername = false;

  /// Global key for the username field to trigger validation programmatically.
  final GlobalKey<FormFieldState> _usernameKey = GlobalKey<FormFieldState>();

  // ============================================================================
  // LIFECYCLE METHODS
  // ============================================================================

  /// Disposes controllers, timers, and notifiers to free up resources.
  @override
  void dispose() {
    _debounce?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    _userNameController.dispose();
    _isPasswordVisible.dispose();
    super.dispose();
  }

  // ============================================================================
  // USERNAME AVAILABILITY LOGIC
  // ============================================================================

  /// Handles username input changes with debounced API calls.
  ///
  /// This method:
  /// 1. Cancels any pending debounce timer
  /// 2. Resets username taken flag
  /// 3. Shows loading indicator
  /// 4. Validates minimum length (3 characters)
  /// 5. Waits 500ms before making API call
  /// 6. Checks username availability via repository
  /// 7. Updates UI with results
  ///
  /// [value] The current username input value
  void _onUsernameChanged(String value) {
    // Cancel any active debounce timer.
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Reset flags and show loading indicator.
    setState(() {
      _isUsernameTaken = false;
      _isCheckingUsername = true;
    });

    // If username is too short, abort check.
    if (value.length < 3) {
      setState(() => _isCheckingUsername = false);
      return;
    }

    // Debounce API call to avoid excessive requests.
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final repo = ref.read(authRepositoryProvider);
      final isTaken = await repo.isUsernameTaken(value);

      // Check if widget is still mounted before updating state.
      if (!mounted) return;

      setState(() {
        _isUsernameTaken = isTaken;
        _isCheckingUsername = false;
      });

      // Trigger validation to show error message if username is taken.
      _usernameKey.currentState?.validate();
    });
  }

  // ============================================================================
  // VALIDATORS
  // ============================================================================

  /// Validates the username field.
  ///
  /// Checks:
  /// - Format validation (via Validators utility)
  /// - Availability (not already taken)
  ///
  /// Returns an error message string if invalid, otherwise `null`.
  String? _validateUsername(String? value) {
    // First check format validation.
    final formatError = Validators.username(value);
    if (formatError != null) return formatError;

    // Then check availability.
    if (_isUsernameTaken) {
      return LocaleKeys.auth_username_already_taken.tr();
    }

    return null;
  }

  // ============================================================================
  // REGISTRATION LOGIC
  // ============================================================================

  /// Handles the registration process.
  ///
  /// Steps:
  /// 1. Validates all form fields
  /// 2. Trims and reads all input values
  /// 3. Calls the register method on the auth provider
  /// 4. Navigates to email verification screen on success
  Future<void> _handleRegister() async {
    // If form is not valid, abort early.
    if (!_formKey.currentState!.validate()) return;

    // Store email for navigation after registration.
    final email = _emailController.text.trim();

    // Get auth notifier from the provider.
    final authNotifier = ref.read(authProvider.notifier);

    // Perform registration with all user data.
    await authNotifier.register(
      email: email,
      password: _passwordController.text.trim(),
      fullName: _fullNameController.text.trim(),
      userName: _userNameController.text.trim(),
      phoneNumber: _phoneNumberController.text.trim(),
    );

    // Navigate to email verification if registration was successful.
    if (mounted && !ref.read(authProvider).isLoading) {
      NavigationService.toNamed(
        AppRoutes.emailVerification,
        arguments: {'email': email},
      );
    }
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
      tooltip: LocaleKeys.common_back.tr(),
    );
  }

  /// Builds the page header title.
  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        LocaleKeys.auth_begin_register.tr(),
        style: theme.textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  /// Builds the full name input field.
  Widget _buildFullNameField() {
    return CustomTextFormField(
      hintText: LocaleKeys.auth_full_name.tr(),
      obscureText: false,
      controller: _fullNameController,
      validator: Validators.name,
      keyboardType: TextInputType.name,
      textCapitalization: TextCapitalization.words,
      textInputFormatter: [
        TitleCaseFormatter(),
        LengthLimitingTextInputFormatter(50),
      ],
      prefixIcon: const Icon(
        Icons.person_outline_rounded,
        color: Colors.white54,
      ),
    );
  }

  /// Builds the email input field.
  Widget _buildEmailField() {
    return CustomTextFormField(
      hintText: LocaleKeys.auth_email.tr(),
      obscureText: false,
      controller: _emailController,
      validator: Validators.email,
      keyboardType: TextInputType.emailAddress,
      textInputFormatter: [
        NoSpaceFormatter(),
        LowerCaseFormatter(),
      ],
      prefixIcon: const Icon(
        Icons.email_outlined,
        color: Colors.white54,
      ),
    );
  }

  /// Builds the username input field with real-time availability checking.
  Widget _buildUsernameField() {
    return CustomTextFormField(
      fieldKey: _usernameKey,
      hintText: LocaleKeys.auth_username.tr(),
      obscureText: false,
      controller: _userNameController,
      validator: _validateUsername,
      textInputFormatter: [
        NoSpaceFormatter(),
        LowerCaseFormatter(),
        FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9_]')),
        LengthLimitingTextInputFormatter(20),
      ],
      onChanged: _onUsernameChanged,
      prefixIcon: const Icon(
        Icons.alternate_email_rounded,
        color: Colors.white54,
      ),
      suffixIcon: _isCheckingUsername
          ? const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white54,
          ),
        ),
      )
          : null,
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
          validator: Validators.password,
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

  /// Builds the phone number input field.
  Widget _buildPhoneNumberField() {
    return CustomTextFormField(
      hintText: LocaleKeys.auth_phone_number.tr(),
      obscureText: false,
      controller: _phoneNumberController,
      keyboardType: TextInputType.phone,
      validator: Validators.phone,
      textInputFormatter: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(13),
      ],
      prefixIcon: const Icon(
        Icons.phone_outlined,
        color: Colors.white54,
      ),
    );
  }

  /// Builds the login navigation link.
  Widget _buildLoginLink(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          LocaleKeys.auth_already_have_account.tr(),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white70,
          ),
        ),
        TextButton(
          onPressed: () => NavigationService.back(),
          child: Text(
            LocaleKeys.auth_login.tr(),
            style: TextStyle(
              color: theme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the Google Sign-In button.
  Widget _buildGoogleSignInButton(ThemeData theme) {
    final authState = ref.watch(authProvider);

    return OutlinedButton.icon(
      onPressed: authState.isLoading
          ? null
          : () => ref.read(authProvider.notifier).signInWithGoogle(),
      icon: const FaIcon(FontAwesomeIcons.google, size: 20, color: Colors.white),
      label: Text(
        'Google ile Kayıt Ol',
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
                      // Full name field.
                      _buildFullNameField(),
                      const SizedBox(height: 16),

                      // Email field.
                      _buildEmailField(),
                      const SizedBox(height: 16),

                      // Username field.
                      _buildUsernameField(),
                      const SizedBox(height: 16),

                      // Password field.
                      _buildPasswordField(),
                      const SizedBox(height: 16),

                      // Phone number field.
                      _buildPhoneNumberField(),
                      const SizedBox(height: 32),

                      // Register button.
                      CustomAuthButton(
                        label: LocaleKeys.auth_register.tr(),
                        isLoading: authState.isLoading,
                        onTap: _handleRegister,
                      ),
                      const SizedBox(height: 24),

                      // Divider
                      _buildDivider(theme),
                      const SizedBox(height: 24),

                      // Google Sign-In button
                      _buildGoogleSignInButton(theme),
                      const SizedBox(height: 24),

                      // Login link.
                      _buildLoginLink(theme),
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
