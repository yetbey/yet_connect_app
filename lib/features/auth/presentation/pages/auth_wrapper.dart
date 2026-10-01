import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yet_x_app/core/utils/logger_service.dart';
import 'package:yet_x_app/features/auth/data/auth_repository.dart';
import 'package:yet_x_app/features/auth/presentation/pages/start_page.dart';
import 'package:yet_x_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:yet_x_app/features/dashboard/presentation/pages/navigation_page.dart';
import 'package:yet_x_app/features/profile/presentation/providers/user_provider.dart';
import 'package:yet_x_app/generated/locale_keys.g.dart';

/// Kimlik doğrulama kapısı.
///
/// - Giriş yoksa: StartPage
/// - Giriş var, profil yüklüyse: NavigationPage
/// - Giriş var, profil yoksa: profili yükler. Yüklenemezse hesabın silinip
///   silinmediğine bakar. Silinmişse çıkış yaptırır, ağ sorunuysa
///   "Tekrar dene" ekranı gösterir (kullanıcıyı atmaz).
class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  bool _checking = false;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _validateSession());
  }

  Future<void> _validateSession() async {
    if (_checking) return;

    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn || ref.read(userProvider).currentUser != null) return;

    _checking = true;
    if (mounted) setState(() => _loadFailed = false);

    try {
      LogService.i('AuthWrapper: profil yükleniyor...');
      await ref.read(userProvider.notifier).fetchMyProfile();
    } catch (e) {
      LogService.e('AuthWrapper: profil yüklenemedi', e);
    }

    if (!mounted) {
      _checking = false;
      return;
    }

    // Profil geldiyse bitti.
    if (ref.read(userProvider).currentUser != null) {
      _checking = false;
      return;
    }

    // Gelmediyse sebebini ayır: silinmiş hesap mı, bağlantı sorunu mu?
    final status = await ref.read(authRepositoryProvider).checkAccountStatus();

    if (!mounted) {
      _checking = false;
      return;
    }

    if (status == AccountStatus.deleted) {
      LogService.e('AuthWrapper: hesap silinmiş, çıkış yapılıyor.', status);
      _checking = false;
      await ref.read(authProvider.notifier).signOut();
      return;
    }

    setState(() => _loadFailed = true);
    _checking = false;
  }

  Widget _buildLoading({bool withText = false}) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            if (withText) ...[
              const SizedBox(height: 16),
              Text(
                LocaleKeys.auth_validating_profile.tr(),
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRetry() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 56, color: Colors.white54),
              const SizedBox(height: 16),
              Text(
                LocaleKeys.auth_profile_load_failed.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _validateSession,
                child: Text(LocaleKeys.common_retry.tr()),
              ),
              TextButton(
                onPressed: () => ref.read(authProvider.notifier).signOut(),
                child: Text(LocaleKeys.auth_logout.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Giriş yapılınca (veya oturum geri gelince) profili doğrula.
    ref.listen<AuthState>(authProvider, (prev, next) {
      final justLoggedIn = next.isLoggedIn && !(prev?.isLoggedIn ?? false);
      if (justLoggedIn) _validateSession();
      if (!next.isLoggedIn && _loadFailed) setState(() => _loadFailed = false);
    });

    final authState = ref.watch(authProvider);
    final userState = ref.watch(userProvider);

    if (authState.isLoading) return _buildLoading();

    if (authState.isLoggedIn) {
      if (userState.currentUser == null) {
        return _loadFailed ? _buildRetry() : _buildLoading(withText: true);
      }
      return const NavigationPage();
    }

    return const StartPage();
  }
}