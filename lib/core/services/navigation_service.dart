import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
  GlobalKey<NavigatorState>();

  static BuildContext? get context => navigatorKey.currentContext;
  static NavigatorState? get navigator => navigatorKey.currentState;

  // Push with page_transition
  static Future<T?>? push<T extends Object?>(
      Widget page, {
        PageTransitionType type = PageTransitionType.rightToLeft,
        Duration duration = const Duration(milliseconds: 300),
        Curve curve = Curves.easeInOut,
        Alignment? alignment,
        bool inheritTheme = false,
      }) {
    return navigator?.push<T>(
      PageTransition(
        type: type,
        child: page,
        duration: duration,
        reverseDuration: duration,
        curve: curve,
        alignment: alignment,
        inheritTheme: inheritTheme,
      ),
    );
  }

  // Push Replacement with page_transition
  static Future<T?>? pushReplacement<T extends Object?, TO extends Object?>(
      Widget page, {
        PageTransitionType type = PageTransitionType.rightToLeft,
        Duration duration = const Duration(milliseconds: 300),
        Curve curve = Curves.easeInOut,
        TO? result,
      }) {
    return navigator?.pushReplacement<T, TO>(
      PageTransition(
        type: type,
        child: page,
        duration: duration,
        reverseDuration: duration,
        curve: curve,
      ),
      result: result,
    );
  }

  // Push and Remove Until
  static Future<T?>? pushAndRemoveUntil<T extends Object?>(
      Widget page,
      bool Function(Route<dynamic>) predicate, {
        PageTransitionType type = PageTransitionType.rightToLeft,
        Duration duration = const Duration(milliseconds: 300),
      }) {
    return navigator?.pushAndRemoveUntil<T>(
      PageTransition(
        type: type,
        child: page,
        duration: duration,
        reverseDuration: duration,
      ),
      predicate,
    );
  }

  // Push named route
  static Future<T?>? toNamed<T extends Object?>(
      String routeName, {
        Object? arguments,
      }) {
    return navigator?.pushNamed<T>(routeName, arguments: arguments);
  }

  // POP
  static void back<T extends Object?>([T? result]) {
    if (navigator?.canPop() ?? false) {
      navigator?.pop<T>(result);
    }
  }

  // Push Replacement Named
  static Future<T?>? offNamed<T extends Object?, TO extends Object?>(
      String routeName, {
        Object? arguments,
        TO? result,
      }) {
    return navigator?.pushReplacementNamed<T, TO>(
      routeName,
      arguments: arguments,
      result: result,
    );
  }

  // Push and remove all
  static Future<T?>? offAllNamed<T extends Object?>(
      String routeName, {
        Object? arguments,
      }) {
    return navigator?.pushNamedAndRemoveUntil<T>(
      routeName,
          (route) => false,
      arguments: arguments,
    );
  }

  // Push and remove until
  static Future<T?>? offUntilNamed<T extends Object?>(
      String newRouteName,
      String untilRouteName, {
        Object? arguments,
      }) {
    return navigator?.pushNamedAndRemoveUntil<T>(
      newRouteName,
      ModalRoute.withName(untilRouteName),
      arguments: arguments,
    );
  }

  // Show snackbar
  static void showSnackbar(
      String message, {
        bool isError = false,
        Duration duration = const Duration(seconds: 3),
        SnackBarAction? action,
      }) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : null,
          behavior: SnackBarBehavior.floating,
          duration: duration,
          action: action,
        ),
      );
    }
  }

  // Show dialog
  static Future<T?> showAppDialog<T>({
    required Widget child,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: navigatorKey.currentContext!,
      barrierDismissible: barrierDismissible,
      builder: (context) => child,
    );
  }

  // Show bottom sheet
  static Future<T?> showAppBottomSheet<T>({
    required Widget child,
    bool isScrollControlled = true,
    bool isDismissible = true,
  }) {
    return showModalBottomSheet<T>(
      context: navigatorKey.currentContext!,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      backgroundColor: Colors.transparent,
      builder: (context) => child,
    );
  }

  static Future<bool> showConfirmDialog({
    required String title,
    required String message,
    String confirmText = 'Onayla',
    String cancelText = 'İptal',
    Color? confirmColor,
    Color? cancelColor,
    bool isDangerous = false,
  }) {
    final context = navigatorKey.currentContext;
    if (context == null) return Future.value(false);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          content: Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: cancelColor ?? colorScheme.onSurface,
              ),
              child: Text(cancelText),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: confirmColor ??
                    (isDangerous ? Colors.red : colorScheme.primary),
                foregroundColor: Colors.white,
              ),
              child: Text(confirmText),
            ),
          ],
        );
      },
    ).then((value) => value ?? false);
  }

  static Future<bool> showDeleteConfirmDialog({
    String title = 'Emin misiniz?',
    required String message,
    String confirmText = 'Evet, Sil',
    String cancelText = 'İptal',
  }) {
    return showConfirmDialog(
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      isDangerous: true,
    );
  }

  static Future<void> showAlertDialog({
    required String title,
    required String message,
    String buttonText = 'Tamam',
    Color? buttonColor,
  }) {
    final context = navigatorKey.currentContext;
    if (context == null) return Future.value();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          content: Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: buttonColor ?? colorScheme.primary,
              ),
              child: Text(buttonText),
            ),
          ],
        );
      },
    );
  }

  static Future<T?> showCustomDialog<T>({
    required Widget child,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: navigatorKey.currentContext!,
      barrierDismissible: barrierDismissible,
      builder: (context) => child,
    );
  }

  static void showLoadingDialog({String message = 'Yükleniyor...'}) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 24),
                  Expanded(child: Text(message)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static void hideLoadingDialog() {
    if (navigator?.canPop() ?? false) {
      navigator?.pop();
    }
  }
}
