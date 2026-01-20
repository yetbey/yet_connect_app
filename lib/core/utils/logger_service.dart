import 'package:logger/logger.dart';

class LogService {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0, // Hata olmayan durumlarda stack trace göstermemek için
      errorMethodCount: 8, // Hata durumunda 8 satır stack trace göstermek için
      lineLength: 120, // Satır genişliği
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.dateAndTime,
    ),
  );

  /// Debug logları
  static void d(String message) {
    _logger.d(message);
  }

  /// Bilgilendirme logları
  static void i(String message) {
    _logger.i(message);
  }

  /// Uyarı logları
  static void w(String message) {
    _logger.w(message);
  }

  /// Hata logları
  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}
