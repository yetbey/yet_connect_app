import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:yet_x_app/config/routes/app_routes.dart';
import 'package:yet_x_app/core/constants/app_constants.dart';
import 'package:yet_x_app/core/services/database_service.dart';
import 'package:yet_x_app/core/services/navigation_service.dart';
import 'package:yet_x_app/features/settings/presentation/widgets/material_tile.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:yet_x_app/features/settings/presentation/providers/theme_provider.dart';
import 'package:yet_x_app/features/profile/presentation/providers/user_provider.dart';
import 'package:yet_x_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yet_x_app/core/utils/utils.dart';
import 'package:yet_x_app/generated/locale_keys.g.dart';
import 'package:yet_x_app/shared/widgets/custom_dialog.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  String _appVersion = '...';
  Map<String, int>? _dbStats;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
    _loadDatabaseStats();
  }

  Future<void> _loadAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
    });
  }

  Future<void> _loadDatabaseStats() async {
    try {
      final db = DatabaseService();
      final stats = await db.getDatabaseStats();
      setState(() {
        _dbStats = stats;
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _launchPrivacyPolicy() async {
    final Uri url = Uri.parse(AppConstants.privacyPolicyLink);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        Utils.showSnackBar(
          text: LocaleKeys.settings_link_not_open.tr(),
          isError: true,
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await NavigationService.showCustomDialog<bool>(
      child: CustomConfirmDialog(
        title: LocaleKeys.common_are_you_sure.tr(),
        message: LocaleKeys.auth_logout_account_confitm.tr(),
        confirmText: LocaleKeys.auth_logout.tr(),
        cancelText: LocaleKeys.common_cancel.tr(),
      ),
    );

    if (confirmed == true && mounted) {
      final authNotifier = ref.read(authProvider.notifier);
      final userNotifier = ref.read(userProvider.notifier);

      await authNotifier.signOut();
      userNotifier.clearUserData();

      if (mounted) {
        NavigationService.toNamed(AppRoutes.start);
      }
    }
  }

  Future<void> _handleDeleteAccount() async {
    final confirmed = await NavigationService.showCustomDialog<bool>(
      child: CustomConfirmDialog(
        title: '⚠️ ${LocaleKeys.common_attention.tr()}',
        message: LocaleKeys.auth_delete_account_confirm.tr(),
        confirmText:
            '${LocaleKeys.common_yes.tr()}, ${LocaleKeys.common_delete.tr()}',
        cancelText: LocaleKeys.common_cancel.tr(),
        isDangerous: true,
      ),
    );

    if (confirmed == true && mounted) {
      final authNotifier = ref.read(authProvider.notifier);
      await authNotifier.deleteAccount();
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await NavigationService.showCustomDialog<bool>(
      child: CustomConfirmDialog(
        title: LocaleKeys.settings_clear_cache.tr(),
        message: LocaleKeys.settings_clear_cache_confirm.tr(),
        confirmText: LocaleKeys.common_clear.tr(),
        cancelText: LocaleKeys.common_cancel.tr(),
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final db = DatabaseService();
        await db.cleanExpiredData();
        await _loadDatabaseStats(); // İstatistikleri güncelle
        if (mounted) {
          Utils.showSnackBar(
            text: LocaleKeys.settings_cache_cleared.tr(),
            isError: false,
          );
        }
      } catch (e) {
        if (mounted) {
          Utils.showSnackBar(
            text: '${LocaleKeys.errors_default_error.tr()} $e',
            isError: true,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeNotifier = ref.read(themeProvider.notifier);
    final themeState = ref.watch(themeProvider);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) {
          FocusScope.of(context).unfocus();
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          scrolledUnderElevation: 0.0,
          title: Text(
            LocaleKeys.settings_title.tr(),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: theme.scaffoldBackgroundColor,
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hesap İşlemleri
              _buildSectionHeader(
                LocaleKeys.settings_account.tr(),
                IconsaxPlusBold.user,
                context,
              ),

              _buildCard(
                context,
                children: [
                  MaterialTile(
                    title: LocaleKeys.auth_change_password.tr(),
                    subtitle: LocaleKeys.auth_change_password_subtitle.tr(),
                    icon: IconsaxPlusBold.lock,
                    onTap: () => NavigationService.toNamed(AppRoutes.changePassword),
                  ),
                ],
              ),

              // Görünüm Bölümü
              _buildSectionHeader(
                LocaleKeys.settings_appearance.tr(),
                IconsaxPlusBold.color_swatch,
                context,
              ),
              _buildCard(
                context,
                children: [
                  _buildThemeModeTile(context, themeState, themeNotifier),
                  _buildColorSchemeTile(context, themeState, themeNotifier),
                ],
              ),

              // Depolama Bölümü
              _buildSectionHeader(
                LocaleKeys.settings_storage.tr(),
                IconsaxPlusBold.folder_2,
                context,
              ),
              _buildCard(
                context,
                children: [_buildStorageInfoTile(), _buildCacheTile()],
              ),

              // Tercihler Bölümü
              _buildSectionHeader(
                LocaleKeys.settings_preferences.tr(),
                IconsaxPlusBold.setting,
                context,
              ),
              _buildCard(context, children: [_buildLanguageTile()]),

              // Uygulama Bilgisi Bölümü
              _buildSectionHeader(
                LocaleKeys.settings_app_info.tr(),
                IconsaxPlusBold.information,
                context,
              ),
              _buildCard(
                context,
                children: [
                  MaterialTile(
                    title: LocaleKeys.settings_app_version.tr(),
                    subtitle: _appVersion,
                    icon: IconsaxPlusBold.code_circle,
                  ),
                  MaterialTile(
                    title: LocaleKeys.settings_privacy_policy.tr(),
                    subtitle: LocaleKeys.settings_terms_conditions.tr(),
                    icon: IconsaxPlusBold.shield_security,
                    showTrailing: true,
                    onTap: _launchPrivacyPolicy,
                  ),
                ],
              ),

              // Çıkış Yap Butonu
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _handleLogout,
                    icon: const Icon(IconsaxPlusBold.logout, size: 22),
                    label: Text(
                      LocaleKeys.auth_logout.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.surface,
                      foregroundColor: theme.colorScheme.onSurface,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: theme.colorScheme.outline.withAlpha(77),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Hesabı Sil Butonu
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 40),
                child: TextButton.icon(
                  onPressed: _handleDeleteAccount,
                  icon: const Icon(IconsaxPlusBold.trash, size: 20),
                  label: Text(
                    LocaleKeys.auth_delete_account.tr(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- YARDIMCI WIDGET'LAR ---

  Widget _buildCard(BuildContext context, {required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(26),
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon,
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeModeTile(
      BuildContext context,
      ThemeState state,
      ThemeNotifier notifier,
      ) {
    return ListTile(
      title: Text(LocaleKeys.settings_theme_mode.tr()),
      subtitle: Text(notifier.themeModeText),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          state.themeMode == ThemeMode.light
              ? IconsaxPlusBold.sun_1
              : state.themeMode == ThemeMode.dark
              ? IconsaxPlusBold.moon : IconsaxPlusBold.setting_2,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
          size: 24,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _showThemeModeBottomSheet(context, state, notifier),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _showThemeModeBottomSheet(
      BuildContext context,
      ThemeState state,
      ThemeNotifier notifier,
      ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  LocaleKeys.settings_select_theme_mode.tr(),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              _buildThemeModeOption(
                ThemeMode.light,
                'Açık Tema',
                IconsaxPlusBold.sun_1,
                state,
                notifier,
                context,
              ),
              _buildThemeModeOption(
                ThemeMode.dark,
                'Koyu Tema',
                IconsaxPlusBold.moon,
                state,
                notifier,
                context,
              ),
              _buildThemeModeOption(
                ThemeMode.system,
                'Sistem Ayarı',
                IconsaxPlusBold.setting_2,
                state,
                notifier,
                context,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeModeOption(
      ThemeMode mode,
      String label,
      IconData icon,
      ThemeState state,
      ThemeNotifier notifier,
      BuildContext context,
      ) {
    final isSelected = state.themeMode == mode;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer.withAlpha(77)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
            : null,
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
            size: 24,
          ),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
            : null,
        onTap: () {
          notifier.changeThemeMode(mode);
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildColorSchemeTile(
    BuildContext context,
    ThemeState state,
    ThemeNotifier notifier,
  ) {
    return ListTile(
      title: Text(LocaleKeys.settings_color_theme.tr()),
      subtitle: Text(state.selectedScheme),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          IconsaxPlusBold.color_swatch,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          size: 24,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _showColorSchemeBottomSheet(context, state, notifier),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildStorageInfoTile() {
    return ListTile(
      title: Text(LocaleKeys.settings_storage_usage.tr()),
      subtitle: _isLoadingStats
          ? Text(LocaleKeys.common_loading.tr())
          : Text(
              '${_dbStats?['users'] ?? 0} kullanıcı • ${_dbStats?['posts'] ?? 0} post • ${_dbStats?['messages'] ?? 0} mesaj',
            ),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          IconsaxPlusBold.chart,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildCacheTile() {
    return ListTile(
      title: Text(LocaleKeys.settings_clear_cache.tr()),
      subtitle: Text(LocaleKeys.settings_clear_cache_desc.tr()),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          IconsaxPlusBold.broom,
          color: Theme.of(context).colorScheme.onTertiaryContainer,
          size: 24,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: _clearCache,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildLanguageTile() {
    final currentLocale = context.locale;
    final languageName = currentLocale.languageCode == 'tr'
        ? LocaleKeys.settings_turkish.tr()
        : LocaleKeys.settings_english.tr();

    return ListTile(
      title: Text(LocaleKeys.settings_language.tr()),
      subtitle: Text(languageName),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          IconsaxPlusBold.language_square,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          size: 24,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _showLanguageDialog(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocaleKeys.settings_select_language.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(LocaleKeys.settings_turkish.tr()),
              leading: const Text('🇹🇷', style: TextStyle(fontSize: 24)),
              onTap: () {
                context.setLocale(const Locale('tr'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(LocaleKeys.settings_english.tr()),
              leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
              onTap: () {
                context.setLocale(const Locale('en'));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showColorSchemeBottomSheet(
    BuildContext context,
    ThemeState state,
    ThemeNotifier notifier,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Başlık
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  LocaleKeys.settings_select_color_theme.tr(),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              // Renk seçenekleri
              Expanded(
                child: ListView(
                  children: ThemeNotifier.colorSchemes.keys.map((schemeName) {
                    return _buildColorSchemeOption(
                      schemeName,
                      state,
                      notifier,
                      context,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildColorSchemeOption(
    String schemeName,
    ThemeState state,
    ThemeNotifier notifier,
    BuildContext context,
  ) {
    final isSelected = state.selectedScheme == schemeName;
    final scheme = ThemeNotifier.colorSchemes[schemeName]!;
    final colorScheme = FlexColorScheme.dark(scheme: scheme).toScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer.withAlpha(77)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
            : null,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primary,
          child: isSelected
              ? Icon(Icons.check, color: colorScheme.onPrimary, size: 24)
              : null,
        ),
        title: Text(
          schemeName,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ColorCircle(color: colorScheme.primary),
            const SizedBox(width: 4),
            _ColorCircle(color: colorScheme.secondary),
            const SizedBox(width: 4),
            _ColorCircle(color: colorScheme.tertiary),
          ],
        ),
        onTap: () {
          notifier.changeColorScheme(schemeName);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _ColorCircle extends StatelessWidget {
  final Color color;

  const _ColorCircle({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.withAlpha(77), width: 1.5),
      ),
    );
  }
}
