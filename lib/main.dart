import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:yet_x_app/core/services/database_service.dart';
import 'package:yet_x_app/core/services/navigation_service.dart';
import 'package:yet_x_app/features/settings/presentation/providers/theme_provider.dart';
import 'package:yet_x_app/config/routes/app_pages.dart';
import 'package:yet_x_app/config/routes/app_routes.dart';
import 'package:yet_x_app/core/services/storage_service.dart';
import 'package:yet_x_app/core/utils/logger_service.dart';
import 'package:yet_x_app/core/utils/utils.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:firebase_core/firebase_core.dart';
import 'core/services/fcm_service.dart';
import 'firebase_options.dart';

void main() async {
  await runZonedGuarded(
    () async {
      try {
        WidgetsFlutterBinding.ensureInitialized();

        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );

        _enableHighRefreshRate();
        _configureSystemUI();
        _configureImageCache();

        timeago.setLocaleMessages('tr', timeago.TrMessages());
        dotenv.load(fileName: '.env');

        final storageService = HiveStorageService();
        await storageService.init();

        final dbService = DatabaseService();
        await dbService.database; // İlk açılışı tetikler
        LogService.i('✅ Database başlatıldı');
        await dbService.cleanExpiredData();

        await Supabase.initialize(
          url: dotenv.env['SUPABASE_URL'] ?? '',
          publishableKey: dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ?? '',
          debug: false,
          authOptions: const FlutterAuthClientOptions(
            authFlowType: AuthFlowType.pkce,
          ),
        );

        await FCMService.instance.initialize();

        await EasyLocalization.ensureInitialized();

        FlutterError.onError = (FlutterErrorDetails details) {
          FlutterError.presentError(details);
          LogService.e('Flutter Error: ${details.exception}');
        };

        runApp(
          ProviderScope(
            overrides: [
              storageServiceProvider.overrideWithValue(storageService),
            ],
            child: EasyLocalization(
              supportedLocales: const [Locale('tr'), Locale('en')],
              path: 'assets/translations',
              fallbackLocale: const Locale('tr'),
              useOnlyLangCode: true,
              useFallbackTranslations: true,
              child: const YetXApp(),
            ),
          ),
        );
      } catch (e, stackTrace) {
        debugPrint('Uygulama başlatma hatası: $e');
        debugPrint('Stack trace: $stackTrace');
        runApp(const ErrorApp());
      }
    },
    (error, stack) {
      LogService.e('Zone Error: $error');
      debugPrint('Zone Stack: $stack');
    },
  );
}


void _enableHighRefreshRate() {
  SchedulerBinding.instance.addPostFrameCallback((_) {
    final display = ui.PlatformDispatcher.instance.displays.first;
    final refreshRate = display.refreshRate;

    if (kDebugMode) {
      debugPrint('🎯 Display Refresh Rate: ${refreshRate}Hz');
    }

    if (refreshRate >= 90) {
      if (kDebugMode) {
        debugPrint('✅ High refresh rate mode enabled!');
      }
    }
  });
}

void _configureSystemUI() {
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
}

void _configureImageCache() {
  PaintingBinding.instance.imageCache.maximumSize = 200;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 100 * 1024 * 1024;
}

class YetXApp extends ConsumerWidget {
  const YetXApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeNotifier = ref.watch(themeProvider.notifier);
    final themeState = ref.watch(themeProvider);
    ref.watch(themeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'YET Connect',
      scaffoldMessengerKey: Utils.messengerKey,

      navigatorKey: NavigationService.navigatorKey,

      // Dil Ayarları
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      // Theme Settings
      theme: themeNotifier.lightThemeData,
      darkTheme: themeNotifier.darkThemeData,
      themeMode: themeState.themeMode,

      // Scroll Behavior
      scrollBehavior: const CustomScrollBehavior(),

      // Routes
      initialRoute: AppRoutes.authWrapper,
      routes: AppPages.routes,
      onGenerateRoute: AppPages.onGenerateRoute,
      onUnknownRoute: AppPages.onUnknownRoute,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(
              minScaleFactor: 0.8,
              maxScaleFactor: 1.3,
            ),
          ),
          child: child!,
        );
      },
      navigatorObservers: [
        if (kDebugMode) CustomNavigatorObserver(),
      ],
    );
  }
}

class CustomScrollBehavior extends MaterialScrollBehavior {
  const CustomScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    switch (getPlatform(context)) {
      case TargetPlatform.android:
        return child;
      case TargetPlatform.iOS:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return Scrollbar(controller: details.controller, child: child);
    }
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class CustomNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (kDebugMode && route.settings.name != null) {
      LogService.i('🟢 Pushed: ${route.settings.name}');
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (kDebugMode && route.settings.name != null) {
      LogService.i('🔴 Popped: ${route.settings.name}');
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (kDebugMode) {
      LogService.i(
        '🟡 Replaced: ${oldRoute?.settings.name} → ${newRoute?.settings.name}',
      );
    }
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 80, color: Colors.red),
                const SizedBox(height: 24),
                const Text(
                  'Uygulama Başlatılırken Hata Oluştu!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Lütfen uygulamayı yeniden başlatın.\nSorun devam ederse uygulama güncellemesini kontrol edin.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => SystemNavigator.pop(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Uygulamayı Kapat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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
