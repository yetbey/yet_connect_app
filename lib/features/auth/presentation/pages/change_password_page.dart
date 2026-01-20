// ============================================================================
// CHANGE PASSWORD PAGE
// ============================================================================
// This page allows authenticated users to change their password.
// It validates the current password before allowing the update.
//
// Features:
// - Current password verification
// - New password validation
// - Password confirmation matching
// - Password visibility toggles for all fields
// - Loading state management
// - Comprehensive error handling
// - Success feedback with navigation
// ============================================================================

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yet_x_app/core/services/navigation_service.dart';
import 'package:yet_x_app/core/utils/error_handler.dart';
import 'package:yet_x_app/core/utils/utils.dart';
import 'package:yet_x_app/core/utils/validators.dart';
import 'package:yet_x_app/generated/locale_keys.g.dart';
import 'package:yet_x_app/shared/widgets/custom_auth_button.dart';
import 'package:yet_x_app/shared/widgets/custom_text_form_field.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Change Password page - Allows users to update their password
///
/// This widget provides a secure password change flow that:
/// 1. Verifies the user's current password
/// 2. Validates the new password format
/// 3. Confirms the new password matches
/// 4. Updates the password in Supabase
class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() =>
      _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  // ============================================================================
  // STATE & CONTROLLERS
  // ============================================================================

  /// Global key used to validate the form.
  final _formKey = GlobalKey<FormState>();

  /// Controller for the current password input field.
  final _currentPasswordController = TextEditingController();

  /// Controller for the new password input field.
  final _newPasswordController = TextEditingController();

  /// Controller for the confirm password input field.
  final _confirmPasswordController = TextEditingController();

  /// Notifier that manages the current password visibility state.
  final ValueNotifier<bool> _isCurrentPasswordVisible =
  ValueNotifier<bool>(false);

  /// Notifier that manages the new password visibility state.
  final ValueNotifier<bool> _isNewPasswordVisible = ValueNotifier<bool>(false);

  /// Notifier that manages the confirm password visibility state.
  final ValueNotifier<bool> _isConfirmPasswordVisible =
  ValueNotifier<bool>(false);

  /// Loading state for password change operation.
  bool _isLoading = false;

  // ============================================================================
  // LIFECYCLE METHODS
  // ============================================================================

  /// Disposes controllers and notifiers to free up resources.
  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _isCurrentPasswordVisible.dispose();
    _isNewPasswordVisible.dispose();
    _isConfirmPasswordVisible.dispose();
    super.dispose();
  }

  // ============================================================================
  // VALIDATORS
  // ============================================================================

  /// Validates the current password field.
  ///
  /// Checks:
  /// - Non-empty value
  ///
  /// Returns an error message string if invalid, otherwise `null`.
  String? _validateCurrentPassword(String? value) {
    if (value == null || value.isEmpty) {
      return LocaleKeys.auth_enter_current_password.tr();
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
      return LocaleKeys.auth_confirm_new_password.tr();
    }

    if (value != _newPasswordController.text) {
      return LocaleKeys.auth_passwords_not_match.tr();
    }

    return null;
  }

  // ============================================================================
  // PASSWORD CHANGE LOGIC
  // ============================================================================

  /// Handles the password change process.
  ///
  /// Flow:
  /// 1. Validates all form fields
  /// 2. Retrieves current user email
  /// 3. Verifies current password by attempting sign in
  /// 4. Updates to new password via Supabase
  /// 5. Shows success message and navigates back
  /// 6. Handles and displays any errors
  Future<void> _handleChangePassword() async {
    // If form is not valid, abort early.
    if (!_formKey.currentState!.validate()) return;

    // Set loading state.
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final email = supabase.auth.currentUser?.email;

      // Ensure user is authenticated.
      if (email == null) {
        throw 'User information not found';
      }

      // Step 1: Verify current password by attempting sign in.
      // This is a security measure to ensure the user knows their current password.
      try {
        await supabase.auth.signInWithPassword(
          email: email,
          password: _currentPasswordController.text.trim(),
        );
      } catch (e) {
        throw LocaleKeys.auth_current_password_incorrect.tr();
      }

      // Step 2: Update to new password.
      await supabase.auth.updateUser(
        UserAttributes(
          password: _newPasswordController.text.trim(),
        ),
      );

      // Log success.
      ErrorHandler.log('Password changed successfully');

      // Show success message and navigate back.
      if (mounted) {
        Utils.showSnackBar(
          text: LocaleKeys.auth_password_changed_success.tr(),
          isError: false,
        );
        NavigationService.back();
      }
    } catch (e, stackTrace) {
      // Log error with context.
      ErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'Change Password',
        severity: ErrorSeverity.medium,
      );

      // Determine appropriate error message.
      final errorMessage = e.toString().contains('Current password is incorrect')
          ? 'Current password is incorrect'
          : ErrorHandler.getErrorMessage(e);

      // Show error message to user.
      if (mounted) {
        Utils.showSnackBar(text: errorMessage, isError: true);
      }
    } finally {
      // Reset loading state.
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ============================================================================
  // UI BUILDERS
  // ============================================================================

  /// Builds the current password input field.
  Widget _buildCurrentPasswordField() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isCurrentPasswordVisible,
      builder: (context, isVisible, child) {
        return CustomTextFormField(
          hintText: LocaleKeys.auth_current_password.tr(),
          obscureText: !isVisible,
          controller: _currentPasswordController,
          validator: _validateCurrentPassword,
          prefixIcon: const Icon(
            Icons.lock_outline_rounded,
            color: Colors.white54,
          ),
          suffixIcon: IconButton(
            onPressed: () {
              _isCurrentPasswordVisible.value = !isVisible;
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

  /// Builds the new password input field.
  Widget _buildNewPasswordField() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isNewPasswordVisible,
      builder: (context, isVisible, child) {
        return CustomTextFormField(
          hintText: LocaleKeys.auth_new_password.tr(),
          obscureText: !isVisible,
          controller: _newPasswordController,
          validator: Validators.password,
          prefixIcon: const Icon(
            Icons.lock_reset_rounded,
            color: Colors.white54,
          ),
          suffixIcon: IconButton(
            onPressed: () {
              _isNewPasswordVisible.value = !isVisible;
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
            tooltip: isVisible ? LocaleKeys.auth_hide_password.tr() : LocaleKeys.auth_show_password.tr(),
          ),
        );
      },
    );
  }

  /// Builds a helpful info card with password requirements.
  Widget _buildPasswordRequirementsCard() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Colors.blue.shade300,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                LocaleKeys.auth_password_requirements.tr(),
                style: TextStyle(
                  color: Colors.blue.shade300,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildRequirementItem(LocaleKeys.auth_at_least_characters_long.tr()),
          _buildRequirementItem(LocaleKeys.auth_recommended_letters_mix.tr()),
        ],
      ),
    );
  }

  /// Builds a single requirement item for the info card.
  Widget _buildRequirementItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 16,
            color: Colors.white54,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
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
      appBar: AppBar(
        title:  Text(LocaleKeys.auth_change_password.tr()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Password requirements info card.
                _buildPasswordRequirementsCard(),

                // Current password field.
                _buildCurrentPasswordField(),
                const SizedBox(height: 16),

                // New password field.
                _buildNewPasswordField(),
                const SizedBox(height: 16),

                // Confirm password field.
                _buildConfirmPasswordField(),
                const SizedBox(height: 32),

                // Change password button.
                CustomAuthButton(
                  label: LocaleKeys.auth_change_password.tr(),
                  isLoading: _isLoading,
                  onTap: _handleChangePassword,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
