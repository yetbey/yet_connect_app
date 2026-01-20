// lib/core/utils/error_handler.dart

import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yet_x_app/core/utils/logger_service.dart';

/// Error severity levels
enum ErrorSeverity {
  low,      // Info, minor issues
  medium,   // Expected errors (validation, not found)
  high,     // Unexpected errors (network, database)
  critical, // App-breaking errors (crash)
}

/// Error types for categorization
enum ErrorType {
  network,
  database,
  authentication,
  storage,
  validation,
  permission,
  timeout,
  unknown,
}

/// Custom app error with full context
class AppError {
  final String message;
  final String? code;
  final ErrorSeverity severity;
  final ErrorType type;
  final StackTrace? stackTrace;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final String? userAction; // What user was doing

  AppError({
    required this.message,
    this.code,
    this.severity = ErrorSeverity.medium,
    this.type = ErrorType.unknown,
    this.stackTrace,
    this.metadata,
    this.userAction,
  }) : timestamp = DateTime.now();

  Map<String, dynamic> toJson() => {
    'message': message,
    'code': code,
    'severity': severity.name,
    'type': type.name,
    'timestamp': timestamp.toIso8601String(),
    'userAction': userAction,
    'metadata': metadata,
  };

  @override
  String toString() => 'AppError: $message (${severity.name})';
}

/// Main error handler
class ErrorHandler {
  static final _crashlytics = FirebaseCrashlytics.instance;
  static final _analytics = FirebaseAnalytics.instance;

  // Error log cache (last 100 errors)
  static final List<AppError> _errorLog = [];
  static const int _maxLogSize = 100;

  // User context
  static String? _currentUserId;
  static String? _currentUserEmail;

  /// Log error with full context
  static void logError(
      dynamic error, {
        StackTrace? stackTrace,
        String? context,
        ErrorSeverity severity = ErrorSeverity.medium,
        Map<String, dynamic>? metadata,
        String? userAction,
      }) {
    final appError = _createAppError(
      error,
      stackTrace: stackTrace,
      context: context,
      severity: severity,
      metadata: metadata,
      userAction: userAction,
    );

    _addToErrorLog(appError);
    _logToConsole(appError, context);
    _reportToCrashlytics(appError);
    _reportToAnalytics(appError);
  }

  /// Create AppError from any error type
  static AppError _createAppError(
      dynamic error, {
        StackTrace? stackTrace,
        String? context,
        ErrorSeverity severity = ErrorSeverity.medium,
        Map<String, dynamic>? metadata,
        String? userAction,
      }) {
    String message;
    String? code;
    ErrorType type;

    if (error is AppError) {
      return error;
    } else if (error is PostgrestException) {
      message = error.message;
      code = error.code;
      type = ErrorType.database;
    } else if (error is AuthException) {
      message = error.message;
      code = error.statusCode;
      type = ErrorType.authentication;
    } else if (error is StorageException) {
      message = error.message;
      code = error.statusCode;
      type = ErrorType.storage;
    } else if (error is String) {
      message = error;
      code = null;
      type = ErrorType.unknown;
    } else {
      message = error.toString();
      code = null;
      type = ErrorType.unknown;
    }

    // Detect network errors
    if (_isNetworkError(error)) {
      type = ErrorType.network;
    }

    return AppError(
      message: message,
      code: code,
      severity: severity,
      type: type,
      stackTrace: stackTrace,
      metadata: {
        if (context != null) 'context': context,
        if (_currentUserId != null) 'userId': _currentUserId,
        if (_currentUserEmail != null) 'userEmail': _currentUserEmail,
        'errorType': error.runtimeType.toString(),
        'platform': defaultTargetPlatform.name,
        ...?metadata,
      },
      userAction: userAction,
    );
  }

  /// Add error to local log
  static void _addToErrorLog(AppError error) {
    _errorLog.add(error);
    if (_errorLog.length > _maxLogSize) {
      _errorLog.removeAt(0);
    }
  }

  /// Log to console (development)
  static void _logToConsole(AppError error, String? context) {
    if (kDebugMode) {
      LogService.e(
        '${context ?? 'Error'}: ${error.message}',
        error,
        error.stackTrace,
      );
    }
  }

  /// Report to Firebase Crashlytics (production)
  static void _reportToCrashlytics(AppError error) {
    if (!kReleaseMode) return;

    try {
      _crashlytics.recordError(
        error.message,
        error.stackTrace,
        reason: error.userAction ?? error.type.name,
        fatal: error.severity == ErrorSeverity.critical,
        information: [
          if (error.code != null) 'Code: ${error.code}',
          'Type: ${error.type.name}',
          'Severity: ${error.severity.name}',
          if (error.userAction != null) 'Action: ${error.userAction}',
          if (error.metadata != null)
            ...error.metadata!.entries.map((e) => '${e.key}: ${e.value}'),
        ],
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to report to Crashlytics: $e');
      }
    }
  }

  /// Report to Firebase Analytics (production)
  static void _reportToAnalytics(AppError error) {
    if (!kReleaseMode) return;

    try {
      _analytics.logEvent(
        name: 'app_error',
        parameters: {
          'error_type': error.type.name,
          'error_code': error.code ?? 'unknown',
          'severity': error.severity.name,
          'message': error.message.length > 100
              ? error.message.substring(0, 100)
              : error.message,
          if (error.userAction != null) 'user_action': ?error.userAction,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to report to Analytics: $e');
      }
    }
  }

  /// Get user-friendly error message
  static String getErrorMessage(dynamic error) {
    if (error is AppError) {
      return _getUserMessage(error);
    }

    final appError = _createAppError(error);
    return _getUserMessage(appError);
  }

  static String _getUserMessage(AppError error) {
    // Network errors
    if (error.type == ErrorType.network) {
      return 'İnternet bağlantınızı kontrol edin.';
    }

    // Database errors
    if (error.type == ErrorType.database) {
      return _handleDatabaseError(error);
    }

    // Auth errors
    if (error.type == ErrorType.authentication) {
      return _handleAuthError(error);
    }

    // Storage errors
    if (error.type == ErrorType.storage) {
      return _handleStorageError(error);
    }

    // Default
    return 'Bir hata oluştu. Lütfen tekrar deneyin.';
  }

  static String _handleDatabaseError(AppError error) {
    switch (error.code) {
      case '23505':
        return 'Bu kayıt zaten mevcut.';
      case '23503':
        return 'İlişkili kayıt bulunamadı.';
      case '42P01':
        return 'Veritabanı hatası. Lütfen uygulamayı güncelleyin.';
      case 'PGRST116':
        return 'Kayıt bulunamadı.';
      case '42501':
        return 'Bu işlem için yetkiniz yok.';
      default:
        if (error.message.contains('duplicate key')) {
          return 'Bu kayıt zaten mevcut.';
        }
        if (error.message.contains('JWT expired')) {
          return 'Oturumunuz sona erdi. Lütfen tekrar giriş yapın.';
        }
        return 'Veritabanı hatası. Lütfen tekrar deneyin.';
    }
  }

  static String _handleAuthError(AppError error) {
    final message = error.message.toLowerCase();

    if (message.contains('invalid login credentials')) {
      return 'E-posta veya şifre hatalı.';
    }
    if (message.contains('email not confirmed')) {
      return 'E-posta adresinizi onaylamanız gerekiyor.';
    }
    if (message.contains('user already registered')) {
      return 'Bu e-posta adresi zaten kayıtlı.';
    }
    if (message.contains('rate limit')) {
      return 'Çok fazla deneme yaptınız. Lütfen daha sonra tekrar deneyin.';
    }
    if (message.contains('weak password')) {
      return 'Şifreniz çok zayıf. En az 8 karakter kullanın.';
    }

    return error.message;
  }

  static String _handleStorageError(AppError error) {
    final message = error.message.toLowerCase();

    if (message.contains('size') || message.contains('large')) {
      return 'Dosya çok büyük. Maksimum 10MB yükleyebilirsiniz.';
    }
    if (message.contains('format') || message.contains('type')) {
      return 'Desteklenmeyen dosya formatı.';
    }
    if (message.contains('permission') || message.contains('unauthorized')) {
      return 'Dosya yükleme izniniz yok.';
    }

    return 'Dosya yükleme hatası.';
  }

  /// Set user context (call on login)
  static Future<void> setUserContext(String userId, {String? email}) async {
    _currentUserId = userId;
    _currentUserEmail = email;

    if (kReleaseMode) {
      await _crashlytics.setUserIdentifier(userId);
      if (email != null) {
        await _crashlytics.setCustomKey('user_email', email);
      }
    }

    if (kDebugMode) {
      LogService.i('User context set: $userId');
    }
  }

  /// Clear user context (call on logout)
  static Future<void> clearUserContext() async {
    _currentUserId = null;
    _currentUserEmail = null;

    if (kReleaseMode) {
      await _crashlytics.setUserIdentifier('anonymous');
    }
  }

  /// Add breadcrumb (track user flow)
  static void log(String message, {Map<String, dynamic>? data}) {
    final logMessage = data != null
        ? '$message | ${data.entries.map((e) => '${e.key}=${e.value}').join(', ')}'
        : message;

    if (kReleaseMode) {
      _crashlytics.log(logMessage);
    } else {
      LogService.d(logMessage);
    }
  }

  /// Set custom key (for debugging)
  static Future<void> setCustomKey(String key, dynamic value) async {
    if (kReleaseMode) {
      await _crashlytics.setCustomKey(key, value);
    }
  }

  /// Check if error is network related
  static bool _isNetworkError(dynamic error) {
    final message = error.toString().toLowerCase();
    return message.contains('socket') ||
        message.contains('network') ||
        message.contains('connection') ||
        message.contains('timeout') ||
        message.contains('unreachable');
  }

  /// Check if error is retryable
  static bool isRetryable(dynamic error) {
    if (_isNetworkError(error)) return true;

    if (error is PostgrestException) {
      // Timeout veya temporary errors
      return error.code == null || error.code == 'PGRST301';
    }

    return false;
  }

  /// Get error log (for debugging/support)
  static List<AppError> getErrorLog() => List.unmodifiable(_errorLog);

  /// Clear error log
  static void clearErrorLog() => _errorLog.clear();

  /// Export error log as JSON (for support tickets)
  static String exportErrorLog() {
    final logs = _errorLog.map((e) => e.toJson()).toList();
    return logs.toString();
  }

  /// Test crash (debug only)
  static void testCrash() {
    if (kDebugMode) {
      throw Exception('Test crash from ErrorHandler');
    }
  }

  /// Force crash report (production test)
  static Future<void> testCrashlytics() async {
    await _crashlytics.recordError(
      Exception('Test Crashlytics Error'),
      StackTrace.current,
      reason: 'Manual test',
      fatal: false,
    );
  }
}
