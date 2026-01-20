// ============================================================================
// VERIFY RESET OTP PAGE
// ============================================================================
// This page handles password reset via OTP verification.
// Users enter the 8-digit code sent to their email and set a new password.
//
// Features:
// - 8-digit OTP code input with validation
// - New password input with visibility toggle
// - Password confirmation with matching validation
// - Resend code functionality with loading state
// - Two-step process: verify OTP then update password
// - Comprehensive error handling
// - Navigation to login on success
// ============================================================================

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yet_x_app/config/routes/app_routes.dart';
import 'package:yet_x_app/core/services/navigation_service.dart';
import 'package:yet_x_app/core/utils/error_handler.dart';
import 'package:yet_x_app/core/utils/utils.dart';
import 'package:yet_x_app/core/utils/validators.dart';
import 'package:yet_x_app/features/auth/data/auth_repository.dart';
import 'package:yet_x_app/generated/locale_keys.g.dart';
import 'package:yet_x_app/shared/widgets/custom_auth_button.dart';
import 'package:yet_x_app/shared/widgets/custom_text_form_field.dart';

/// Verify Reset OTP page - OTP verification and password reset screen
///
/// This widget combines OTP verification with password reset functionality.
/// It requires the user's email address and displays a form to:
/// 1. Enter the 8-digit OTP code
/// 2. Set a new password
/// 3. Confirm the new password
class VerifyResetOtpPage extends ConsumerStatefulWidget {
  /// Email address where the OTP was sent.
  final String email;

  const VerifyResetOtpPage({super.key, required this.email});

  @override
  ConsumerState<VerifyResetOtpPage> createState() =>
      _VerifyResetOtpPageState();
}

class _VerifyResetOtpPageState extends ConsumerState<VerifyResetOtpPage> {
  // ============================================================================
  // STATE & CONTROLLERS
  // ============================================================================

  /// Global key used to validate the form.
  final _formKey = GlobalKey<FormState>();

  /// Controller for the OTP code input field.
  final _otpController = TextEditingController();

  /// Controller for the new password input field.
  final _newPasswordController = TextEditingController();

  /// Controller for the confirm password input field.
  final _confirmPasswordController = TextEditingController();

  /// Notifier that manages the new password visibility state.
  final ValueNotifier<bool> _isPasswordVisible = ValueNotifier<bool>(false);

  /// Notifier that manages the confirm password visibility state.
  final ValueNotifier<bool> _isConfirmPasswordVisible =
  ValueNotifier<bool>(false);

  /// Loading state for password reset operation.
  bool _isLoading = false;

  /// Loading state for resend code operation.
  bool _isResending = false;

  // ============================================================================
  // LIFECYCLE METHODS
  // ============================================================================

  /// Disposes controllers and notifiers to free up resources.
  @override
  void dispose() {
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _isPasswordVisible.dispose();
    _isConfirmPasswordVisible.dispose();
    super.dispose();
  }

  // ============================================================================
  // VALIDATORS
  // ============================================================================

  /// Validates the OTP code field.
  ///
  /// Checks:
  /// - Non-empty value
  /// - Exactly 8 digits
  ///
  /// Returns an error message string if invalid, otherwise `null`.
  String? _validateOtp(String? value) {
    if (value == null || value.isEmpty) {
      return 'Code is required';
    }

    if (value.length != 8) {
      return 'Code must be 8 digits';
    }

    return null;
  }

  /// Validates the confirm password field.
  ///
  /// Checks:
  /// - Non-empty value
  /// - Matches the new password value
  ///
  /// Returns an error message string if invalid, otherwise `null`.
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return LocaleKeys.auth_confirm_current_password.tr();
    }

    if (value != _newPasswordController.text) {
      return LocaleKeys.auth_passwords_not_match.tr();
    }

    return null;
  }

  // ============================================================================
  // PASSWORD RESET LOGIC
  // ============================================================================

  /// Handles the OTP verification and password reset process.
  ///
  /// This is a two-step process:
  /// 1. Verify the OTP code and establish a session
  /// 2. Update the password using the authenticated session
  ///
  /// Flow:
  /// 1. Validates all form fields
  /// 2. Calls auth repository to verify OTP
  /// 3. Calls auth repository to update password
  /// 4. Shows success message
  /// 5. Navigates to login page
  /// 6. Handles and displays any errors
  Future<void> _handleVerifyAndReset() async {
    // If form is not valid, abort early.
    if (!_formKey.currentState!.validate()) return;

    // Set loading state.
    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);

      // Step 1: Verify OTP and establish authenticated session.
      await authRepo.verifyPasswordResetOTP(
        email: widget.email,
        token: _otpController.text.trim(),
      );

      // Step 2: Update password using the authenticated session.
      await authRepo.updatePassword(_newPasswordController.text.trim());

      // Log success.
      ErrorHandler.log('Password reset successful');

      // Show success message and navigate to login.
      if (mounted) {
        Utils.showSnackBar(
          text: LocaleKeys.auth_password_changed_success.tr(),
          isError: false,
        );

        // Navigate to login page, clearing navigation stack.
        NavigationService.offAllNamed(AppRoutes.login);
      }
    } catch (e, stackTrace) {
      // Log error with context.
      ErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: LocaleKeys.auth_verify_reset_otp.tr(),
        severity: ErrorSeverity.high,
      );

      // Show error message to user.
      if (mounted) {
        Utils.showSnackBar(
          text: ErrorHandler.getErrorMessage(e),
          isError: true,
        );
      }
    } finally {
      // Reset loading state.
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Resends the OTP code to the user's email.
  ///
  /// This allows users to request a new code if:
  /// - They didn't receive the original code
  /// - The code has expired
  /// - They accidentally deleted the email
  Future<void> _handleResendCode() async {
    setState(() => _isResending = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.sendPasswordResetOTP(widget.email);

      if (mounted) {
        Utils.showSnackBar(
          text: LocaleKeys.auth_new_code_sent_mail.tr(),
          isError: false,
        );
      }
    } catch (e) {
      if (mounted) {
        Utils.showSnackBar(
          text: ErrorHandler.getErrorMessage(e),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
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

  /// Builds the header section with title and instructions.
  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lock icon for visual representation.
          Icon(
            Icons.password_rounded,
            size: 64,
            color: theme.primaryColor,
          ),
          const SizedBox(height: 24),

          // Title.
          Text(
            LocaleKeys.auth_password_reset.tr(),
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),

          // Instruction text with email address.
          Text(
            '${LocaleKeys.auth_enter_eight_digit_code.tr()} ${widget.email} ${LocaleKeys.auth_set_new_password.tr()}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the OTP code input field.
  Widget _buildOtpField() {
    return CustomTextFormField(
      hintText: LocaleKeys.auth_enter_eight_digit_code.tr(),
      obscureText: false,
      controller: _otpController,
      keyboardType: TextInputType.number,
      textInputFormatter: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(8),
      ],
      validator: _validateOtp,
      prefixIcon: const Icon(
        Icons.pin_outlined,
        color: Colors.white54,
      ),
    );
  }

  /// Builds the resend code button.
  Widget _buildResendButton(ThemeData theme) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _isResending ? null : _handleResendCode,
        child: _isResending
            ? const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        )
            : Text(
          LocaleKeys.auth_resend_code.tr(),
          style: TextStyle(color: theme.primaryColor),
        ),
      ),
    );
  }

  /// Builds the new password input field.
  Widget _buildNewPasswordField() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isPasswordVisible,
      builder: (context, isVisible, child) {
        return CustomTextFormField(
          hintText: LocaleKeys.auth_new_password.tr(),
          obscureText: !isVisible,
          controller: _newPasswordController,
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
            tooltip: isVisible ? LocaleKeys.auth_hide_password.tr(): LocaleKeys.auth_show_password.tr(),
          ),
        );
      },
    );
  }

  /// Builds the confirm password input field.
  Widget _buildConfirmPasswordField() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isConfirmPasswordVisible,
      builder: (context, isVisible, child) {
        return CustomTextFormField(
          hintText: LocaleKeys.auth_confirm_new_password.tr(),
          obscureText: !isVisible,
          controller: _confirmPasswordController,
          validator: _validateConfirmPassword,
          prefixIcon: const Icon(
            Icons.lock_clock_rounded,
            color: Colors.white54,
          ),
          suffixIcon: IconButton(
            onPressed: () {
              _isConfirmPasswordVisible.value = !isVisible;
            },
            icon: Icon(
              isVisible
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
              color: Colors.white54,
            ),
            tooltip: isVisible ? LocaleKeys.auth_hide_password.tr(): LocaleKeys.auth_show_password.tr(),
          ),
        );
      },
    );
  }

  /// Builds a helpful info card with instructions.
  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:  0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha:  0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Colors.blue.shade300,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              LocaleKeys.auth_check_email_expired_ten_minutes.tr(),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // MAIN BUILD METHOD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
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

                // Form fields section.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      // Info card.
                      _buildInfoCard(),

                      // OTP code field.
                      _buildOtpField(),
                      const SizedBox(height: 8),

                      // Resend code button.
                      _buildResendButton(theme),
                      const SizedBox(height: 16),

                      // New password field.
                      _buildNewPasswordField(),
                      const SizedBox(height: 16),

                      // Confirm password field.
                      _buildConfirmPasswordField(),
                      const SizedBox(height: 32),

                      // Submit button.
                      CustomAuthButton(
                        label: LocaleKeys.auth_change_password.tr(),
                        isLoading: _isLoading,
                        onTap: _handleVerifyAndReset,
                      ),
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
