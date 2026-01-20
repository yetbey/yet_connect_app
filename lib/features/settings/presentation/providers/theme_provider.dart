import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yet_x_app/core/services/storage_service.dart';

@immutable
class ThemeState {
  final String selectedScheme;
  final ThemeMode themeMode;

  const ThemeState({required this.selectedScheme, required this.themeMode});

  ThemeState copyWith({String? selectedScheme, ThemeMode? themeMode}) {
    return ThemeState(
      selectedScheme: selectedScheme ?? this.selectedScheme,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ThemeState &&
        other.selectedScheme == selectedScheme &&
        other.themeMode == themeMode;
  }

  @override
  int get hashCode => Object.hash(selectedScheme, themeMode);
}

class ThemeNotifier extends Notifier<ThemeState> {
  late final StorageService _storage;
  static const _colorSchemeKey = 'settings_colorScheme';
  static const _themeModeKey = 'settings_themeMode';
  static const _defaultScheme = 'Mavi';
  static const _defaultThemeMode = ThemeMode.dark;

  static const Map<String, FlexScheme> colorSchemes = {
    'Mavi': FlexScheme.blue,
    'Indigo': FlexScheme.indigo,
    'Hippie Blue': FlexScheme.hippieBlue,
    'Aqua Blue': FlexScheme.aquaBlue,
    'Yeşil': FlexScheme.green,
    'Kırmızı': FlexScheme.red,
    'Mor': FlexScheme.deepPurple,
    'Pembe': FlexScheme.sakura,
    'Turuncu': FlexScheme.orangeM3,
    'Amber': FlexScheme.amber,
    'Kahverengi': FlexScheme.espresso,
    'Gri': FlexScheme.greyLaw,
  };

  @override
  ThemeState build() {
    _storage = ref.read(storageServiceProvider);
    _loadSavedTheme();
    return const ThemeState(
      selectedScheme: _defaultScheme,
      themeMode: _defaultThemeMode,
    );
  }

  Future<void> _loadSavedTheme() async {
    final String? scheme = await _storage.read<String>(_colorSchemeKey);
    final String? modeStr = await _storage.read(_themeModeKey);

    ThemeMode mode = _defaultThemeMode;
    if (modeStr != null) {
      mode = ThemeMode.values.firstWhere(
        (e) => e.toString() == modeStr,
        orElse: () => _defaultThemeMode,
      );
    }

    if (scheme != null && colorSchemes.containsKey(scheme)) {
      state = ThemeState(selectedScheme: scheme, themeMode: mode);
    } else if (modeStr != null) {
      state = state.copyWith(themeMode: mode);
    }
  }

  Future<void> changeColorScheme(String schemeName) async {
    if (!colorSchemes.containsKey(schemeName)) {
      throw ArgumentError('Invalid color scheme: $schemeName');
    }

    await _storage.write(_colorSchemeKey, schemeName);
    state = state.copyWith(selectedScheme: schemeName);
  }

  Future<void> changeThemeMode(ThemeMode mode) async {
    await _storage.write(_themeModeKey, mode.toString());
    state = state.copyWith(themeMode: mode);
  }

  Future<void> resetTheme() async {
    await _storage.write(_colorSchemeKey, _defaultScheme);
    await _storage.write(_themeModeKey, _defaultThemeMode.toString());
    state = const ThemeState(
      selectedScheme: _defaultScheme,
      themeMode: _defaultThemeMode,
    );
  }

  ThemeData get lightThemeData {
    final scheme = colorSchemes[state.selectedScheme] ?? FlexScheme.blue;
    return _getLightTheme(scheme);
  }

  ThemeData get darkThemeData {
    final scheme = colorSchemes[state.selectedScheme] ?? FlexScheme.blue;
    return _getDarkTheme(scheme);
  }

  ThemeMode get themeMode => state.themeMode;

  List<String> get availableSchemes => colorSchemes.keys.toList();

  bool isCurrentScheme(String schemeName) => state.selectedScheme == schemeName;

  String get themeModeText {
    switch (state.themeMode) {
      case ThemeMode.light:
        return 'Açık';
      case ThemeMode.dark:
        return 'Kapalı';
      case ThemeMode.system:
        return 'Sistem';
    }
  }

  // Lİght Theme
  static ThemeData _getLightTheme(FlexScheme scheme) {
    return FlexThemeData.light(
      scheme: scheme,
      textTheme: _buildTextTheme(),
      surfaceMode: FlexSurfaceMode.highScaffoldLevelSurface,
      blendLevel: 7,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 10,
        useM2StyleDividerInM3: true,
        alignedDropdown: true,
        useInputDecoratorThemeInDialogs: true,
        interactionEffects: true,
        tintedDisabledControls: true,
        blendOnColors: false,
        cardElevation: 1,
        elevatedButtonElevation: 1,
        inputDecoratorIsFilled: true,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        inputDecoratorUnfocusedBorderIsColored: false,
        appBarBackgroundSchemeColor: SchemeColor.surface,
        navigationBarSelectedLabelSchemeColor: SchemeColor.primary,
        navigationBarIndicatorSchemeColor: SchemeColor.primaryContainer,
        navigationBarOpacity: 1.0,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      swapLegacyOnMaterial3: true,
    );
  }

  // Dark Theme
  static ThemeData _getDarkTheme(FlexScheme scheme) {
    return FlexThemeData.dark(
      scheme: scheme,
      textTheme: _buildTextTheme(),
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 13,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 20,
        useM2StyleDividerInM3: true,
        alignedDropdown: true,
        useInputDecoratorThemeInDialogs: true,
        interactionEffects: true,
        tintedDisabledControls: true,
        blendOnColors: true,
        cardElevation: 2,
        elevatedButtonElevation: 2,
        inputDecoratorIsFilled: true,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        inputDecoratorUnfocusedBorderIsColored: false,
        appBarBackgroundSchemeColor: SchemeColor.surface,
        navigationBarSelectedLabelSchemeColor: SchemeColor.primary,
        navigationBarIndicatorSchemeColor: SchemeColor.primaryContainer,
        navigationBarOpacity: 1.0,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      swapLegacyOnMaterial3: true,
    );
  }

  static TextTheme _buildTextTheme() {
    return GoogleFonts.ubuntuCondensedTextTheme().copyWith(
      titleSmall: GoogleFonts.ubuntuCondensed(fontWeight: FontWeight.bold),
      titleMedium: GoogleFonts.ubuntuCondensed(fontWeight: FontWeight.bold),
      titleLarge: GoogleFonts.ubuntuCondensed(fontWeight: FontWeight.bold),
      headlineSmall: GoogleFonts.ubuntuCondensed(fontWeight: FontWeight.w600),
      headlineMedium: GoogleFonts.ubuntuCondensed(fontWeight: FontWeight.w600),
      headlineLarge: GoogleFonts.ubuntuCondensed(fontWeight: FontWeight.w700),
      bodySmall: GoogleFonts.ubuntuCondensed(fontWeight: FontWeight.normal),
      bodyMedium: GoogleFonts.ubuntuCondensed(fontWeight: FontWeight.normal),
      bodyLarge: GoogleFonts.ubuntuCondensed(fontWeight: FontWeight.w500),
      labelSmall: GoogleFonts.ubuntuCondensed(fontWeight: FontWeight.w500),
      labelMedium: GoogleFonts.ubuntuCondensed(fontWeight: FontWeight.w600),
      labelLarge: GoogleFonts.ubuntuCondensed(fontWeight: FontWeight.bold),
    );
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeState>(() {
  return ThemeNotifier();
});

final lightThemeDataProvider = Provider<ThemeData>((ref) {
  return ref.watch(themeProvider.notifier).lightThemeData;
});

final darkThemeDataProvider = Provider<ThemeData>((ref) {
  return ref.watch(themeProvider.notifier).darkThemeData;
});

final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(themeProvider.notifier).themeMode;
});

final availableSchemesProvider = Provider<List<String>>((ref) {
  return ref.watch(themeProvider.notifier).availableSchemes;
});
