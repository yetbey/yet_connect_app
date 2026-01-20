import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yet_x_app/config/routes/app_routes.dart';
import 'package:yet_x_app/core/services/navigation_service.dart';
import 'package:yet_x_app/core/utils/error_handler.dart';
import 'package:yet_x_app/core/utils/utils.dart';
import 'package:yet_x_app/core/utils/validators.dart';
import 'package:yet_x_app/features/auth/data/auth_repository.dart';
import 'package:yet_x_app/shared/widgets/custom_auth_button.dart';
import 'package:yet_x_app/shared/widgets/custom_text_form_field.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final authRepo = ref.read(authRepositoryProvider);

      await authRepo.sendPasswordResetOTP(email);

      ErrorHandler.log('Password reset OTP sent', data: {'email': email});

      if (mounted) {
        Utils.showSnackBar(
          text: 'Doğrulama kodu email adresinize gönderildi',
          isError: false,
        );

        // OTP girme sayfasına yönlendir
        NavigationService.toNamed(AppRoutes.verifyResetOtp, arguments: {'email': email});
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        stackTrace: stackTrace,
        context: 'Send Password Reset OTP',
        severity: ErrorSeverity.medium,
      );

      if (mounted) {
        Utils.showSnackBar(
          text: ErrorHandler.getErrorMessage(e),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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
                // Back Button
                IconButton(
                  onPressed: () => NavigationService.back(),
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: theme.iconTheme.color,
                  ),
                ),
                const SizedBox(height: 20),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Şifremi Unuttum',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Email adresinize doğrulama kodu göndereceğiz.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Email Field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      CustomTextFormField(
                        hintText: 'Email',
                        obscureText: false,
                        controller: _emailController,
                        validator: Validators.email,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 32),

                      // Send Code Button
                      CustomAuthButton(
                        label: 'Kod Gönder',
                        isLoading: _isLoading,
                        onTap: _handleSendOTP,
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
