// ============================================================================
// EMAIL VERIFICATION PAGE
// ============================================================================
// This page handles email verification using an 8-digit OTP code.
// It provides a user-friendly PIN input interface with auto-submit on completion.
//
// Features:
// - 8-digit PIN input with Pinput widget
// - Auto-verification when all digits are entered
// - Resend code functionality with countdown timer
// - Email parameter handling via constructor or route arguments
// - Loading state management
// - Navigation to home on successful verification
// ============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:pinput/pinput.dart';
import 'package:yet_x_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:yet_x_app/config/routes/app_routes.dart';
import 'package:yet_x_app/core/services/navigation_service.dart';
import 'package:yet_x_app/generated/locale_keys.g.dart';

/// Email Verification page - OTP code verification screen
///
/// This widget displays an 8-digit PIN input field for email verification.
/// The email address can be passed either through the constructor or via
/// route arguments. It includes a countdown timer for resend functionality.
class EmailVerificationPage extends ConsumerStatefulWidget {
  /// Optional email address passed through constructor.
  final String? email;

  const EmailVerificationPage({super.key, this.email});

  @override
  ConsumerState<EmailVerificationPage> createState() =>
      _EmailVerificationPageState();
}

class _EmailVerificationPageState extends ConsumerState<EmailVerificationPage> {
  // ============================================================================
  // STATE & CONTROLLERS
  // ============================================================================

  /// Controller for the PIN input field.
  final TextEditingController _pinController = TextEditingController();

  /// Focus node for the PIN input field.
  final FocusNode _pinFocusNode = FocusNode();

  /// Flag indicating if the user can resend the verification code.
  bool _canResend = false;

  /// Countdown timer in seconds before resend is available.
  int _timerSeconds = 60;

  /// Timer instance for countdown.
  Timer? _timer;

  /// Email address for verification (from constructor or route args).
  late String _email;

  // ============================================================================
  // LIFECYCLE METHODS
  // ============================================================================

  /// Initialize state and start countdown timer.
  @override
  void initState() {
    super.initState();

    // Retrieve email from constructor parameter.
    final argsEmail = widget.email;
    _email = argsEmail ?? '';

    // Start the resend countdown timer.
    _startTimer();
  }

  /// Handle route arguments if email wasn't provided via constructor.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // If email is empty, try to get it from route arguments.
    if (_email.isEmpty) {
      final args = ModalRoute.of(context)?.settings.arguments;

      // Handle both String and Map argument types.
      if (args is String) {
        _email = args;
      } else if (args is Map && args['email'] != null) {
        _email = args['email'] as String;
      }
    }
  }

  /// Dispose controllers, focus nodes, and timers.
  @override
  void dispose() {
    _timer?.cancel();
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  // ============================================================================
  // TIMER LOGIC
  // ============================================================================

  /// Starts a 60-second countdown timer before allowing code resend.
  ///
  /// This prevents spam and ensures users wait before requesting a new code.
  void _startTimer() {
    setState(() {
      _canResend = false;
      _timerSeconds = 60;
    });

    // Create periodic timer that ticks every second.
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        setState(() => _timerSeconds--);
      } else {
        // Timer completed - allow resend.
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  // ============================================================================
  // VERIFICATION LOGIC
  // ============================================================================

  /// Verifies the entered OTP code.
  ///
  /// This method:
  /// 1. Validates that exactly 8 digits are entered
  /// 2. Calls the auth provider to verify the OTP
  /// 3. Navigates to home screen on success
  Future<void> _verify() async {
    final code = _pinController.text.trim();

    // Ensure exactly 8 digits are entered.
    if (code.length != 8) return;

    // Call auth provider to verify OTP.
    final success = await ref.read(authProvider.notifier).verifyEmailOtp(
      email: _email,
      token: code,
    );

    // Navigate to home on successful verification.
    if (success && mounted) {
      NavigationService.offAllNamed(AppRoutes.home);
    }
  }

  /// Resends the verification code to the user's email.
  ///
  /// This method:
  /// 1. Calls the auth provider to resend the code
  /// 2. Restarts the countdown timer
  Future<void> _resendCode() async {
    await ref.read(authProvider.notifier).resendVerificationCode(_email);
    _startTimer();
  }

  // ============================================================================
  // UI BUILDERS
  // ============================================================================

  /// Builds the header with icon and instructions.
  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        // Lock icon for visual representation.
        const Icon(
          Icons.mark_email_unread_outlined,
          size: 80,
          color: Colors.grey,
        ),
        const SizedBox(height: 24),

        // Title.
        Text(
          LocaleKeys.auth_check_email.tr(),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // Instruction text with email address.
        Text(
          '${LocaleKeys.auth_enter_eight_digit_code.tr()}$_email',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  /// Builds the PIN input field using Pinput package.
  Widget _buildPinInput(ThemeData theme, bool isLoading) {
    // Default theme for PIN boxes.
    final defaultPinTheme = PinTheme(
      width: 40,
      height: 50,
      textStyle: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.transparent),
      ),
    );

    // Theme for focused PIN box.
    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: theme.colorScheme.primary, width: 2),
      ),
    );

    // Theme for submitted PIN box.
    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: theme.colorScheme.primaryContainer,
        border: Border.all(color: theme.colorScheme.primary),
      ),
    );

    return Pinput(
      controller: _pinController,
      focusNode: _pinFocusNode,
      length: 8,
      defaultPinTheme: defaultPinTheme,
      focusedPinTheme: focusedPinTheme,
      submittedPinTheme: submittedPinTheme,
      onCompleted: (pin) => _verify(),
      enabled: !isLoading,
      pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
      separatorBuilder: (index) => const SizedBox(width: 6),
      autofocus: true,
    );
  }

  /// Builds the verify button.
  Widget _buildVerifyButton(bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton(
        onPressed: isLoading ? null : _verify,
        child: isLoading
            ? const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : const Text('Verify'),
      ),
    );
  }

  /// Builds the resend code section with timer.
  Widget _buildResendSection(ThemeData theme, bool isLoading) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _canResend
              ? LocaleKeys.auth_did_not_receive_code.tr()
              : '${LocaleKeys.auth_resend_available_in.tr()} $_timerSeconds s',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey,
          ),
        ),
        if (_canResend) ...[
          const SizedBox(width: 8),
          TextButton(
            onPressed: isLoading ? null : _resendCode,
            child: Text(LocaleKeys.auth_resend_email.tr()),
          ),
        ],
      ],
    );
  }

  // ============================================================================
  // MAIN BUILD METHOD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    // Watch auth state for loading status.
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.auth_verify_email.tr()),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                // Ensure minimum height to center content vertically.
                minHeight: constraints.maxHeight - 50,
              ),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Header section.
                    _buildHeader(theme),
                    const SizedBox(height: 32),

                    // PIN input field.
                    _buildPinInput(theme, authState.isLoading),
                    const SizedBox(height: 40),

                    // Verify button.
                    _buildVerifyButton(authState.isLoading),
                    const SizedBox(height: 24),

                    // Resend code section.
                    _buildResendSection(theme, authState.isLoading),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
