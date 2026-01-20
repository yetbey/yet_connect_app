import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:yet_x_app/core/utils/logger_service.dart';

abstract class StorageService {
  Future<void> init();
  Future<void> write<T>(String key, T value);
  Future<T?> read<T>(String key);
  bool hasData(String key);
  Future<void> remove(String key);
  Future<void> clear();
  Future<void> clearExpired();
  Future<void> clearByPrefix(String prefix);
}

class StorageKeys {
  // User Data
  static const String userProfile = 'user_profile';
  static const String userToken = 'user_token';
  static const String userSettings = 'user_settings';

  // App Settings
  static const String themeMode = 'theme_mode';
  static const String language = 'language';
  static const String notifications = 'notifications_enabled';

  // Cache
  static const String cachedPosts = 'cached_posts';
  static const String cachedUsers = 'cached_users';
}

/// Önbelleklenmiş Veri İçin Wrapper
class CachedData<T> {
  final T data;
  final DateTime timestamp;
  final Duration? ttl; // Time to live

  CachedData({required this.data, required this.timestamp, this.ttl});

  bool get isExpired {
    if (ttl == null) return false;
    return DateTime.now().difference(timestamp) > ttl!;
  }

  Map<String, dynamic> toJson() => {
    'data': data,
    'timestamp': timestamp.toIso8601String(),
    'ttl': ttl?.inSeconds,
  };

  factory CachedData.fromJson(Map<String, dynamic> json) {
    return CachedData(
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp']),
      ttl: json['ttl'] != null ? Duration(seconds: json['ttl']) : null,
    );
  }
}

class HiveStorageService implements StorageService {
  static const String _mainBox = 'app_data';
  static const String _cacheBox = 'app_cache';
  static const String _settingsBox = 'app_settings';

  Box? _mainBoxInstance;
  Box? _cacheBoxInstance;
  Box? _settingsBoxInstance;

  bool _isInitialized = false;

  @override
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await Hive.initFlutter();

      _mainBoxInstance = await Hive.openBox(_mainBox);
      _cacheBoxInstance = await Hive.openBox(_cacheBox);
      _settingsBoxInstance = await Hive.openBox(_settingsBox);

      _isInitialized = true;
      LogService.i('Storage Service başlatıldı.');

      await clearExpired();
    } catch (e) {
      LogService.e('Storage init hatası', e);
      rethrow;
    }
  }

  /// Box seçimi - key ile otomatik seçim
  Box _getBox(String key) {
    _ensureInitialized();

    if (key.startsWith('cache_')) {
      return _cacheBoxInstance!;
    } else if (key.startsWith('settings_')) {
      return _settingsBoxInstance!;
    }

    return _mainBoxInstance!;
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'Storage servisi henüz başlatılmadı. init() metodunu çağırın.',
      );
    }
  }

  @override
  Future<void> write<T>(String key, T value) async {
    try {
      final box = _getBox(key);

      if (value is CachedData) {
        await box.put(key, jsonEncode(value.toJson()));
      } else {
        if (value is String ||
            value is int ||
            value is double ||
            value is bool) {
          await box.put(key, value);
        } else {
          await box.put(key, jsonEncode(value));
        }
      }

      LogService.d('Veri yazıldı: $key');
    } catch (e) {
      LogService.e('Storage write hatası: $key', e);
      rethrow;
    }
  }

  @override
  Future<T?> read<T>(String key) async {
    try {
      final box = _getBox(key);

      if (!box.containsKey(key)) return null;

      final value = box.get(key);

      if (value == null) return null;

      if (T == CachedData) {
        final cached = CachedData.fromJson(jsonDecode(value));
        if (cached.isExpired) {
          await remove(key);
          return null;
        }
        return cached as T;
      }

      if (value is T) {
        return value;
      }

      if (value is String) {
        try {
          return jsonDecode(value) as T;
        } catch (_) {
          return value as T;
        }
      }

      return value as T;
    } catch (e) {
      LogService.e('Storage read hatası: $key', e);
      return null;
    }
  }

  @override
  bool hasData(String key) {
    try {
      _ensureInitialized();
      final box = _getBox(key);
      return box.containsKey(key);
    } catch (e) {
      LogService.e('Storage hasData hatası: $key', e);
      return false;
    }
  }

  @override
  Future<void> remove(String key) async {
    try {
      final box = _getBox(key);
      await box.delete(key);
      LogService.d('🗑️ Veri silindi: $key');
    } catch (e) {
      LogService.e('Storage remove hatası: $key', e);
    }
  }

  @override
  Future<void> clear() async {
    try {
      _ensureInitialized();
      await Future.wait([
        _mainBoxInstance!.clear(),
        _cacheBoxInstance!.clear(),
        _settingsBoxInstance!.clear(),
      ]);
      LogService.i('🧹 Tüm storage temizlendi');
    } catch (e) {
      LogService.e('Storage clear hatası', e);
    }
  }

  @override
  Future<void> clearExpired() async {
    try {
      _ensureInitialized();

      final box = _cacheBoxInstance!;
      final keysToRemove = <String>[];

      for (var key in box.keys) {
        try {
          final value = box.get(key);
          if (value is String) {
            final json = jsonDecode(value);
            if (json is Map && json.containsKey('timestamp')) {
              // Map<dynamic, dynamic> -> Map<String, dynamic> dönüşümü
              final jsonMap = Map<String, dynamic>.from(json);
              final cached = CachedData.fromJson(jsonMap);
              if (cached.isExpired) {
                keysToRemove.add(key.toString());
              }
            }
          }
        } catch (e) {
          // JSON parse edilemezse veya hata varsa geç
          LogService.d('clearExpired: $key için hata (atlandı): $e');
          continue;
        }
      }

      if (keysToRemove.isNotEmpty) {
        await box.deleteAll(keysToRemove);
        LogService.i('🧹 ${keysToRemove.length} süresi dolmuş cache silindi');
      }
    } catch (e) {
      LogService.e('clearExpired hatası', e);
    }
  }
  @override
  Future<void> clearByPrefix(String prefix) async {
    try {
      _ensureInitialized();

      // Tüm box'ları kontrol et
      final boxes = [
        _mainBoxInstance!,
        _cacheBoxInstance!,
        _settingsBoxInstance!,
      ];
      int totalDeleted = 0;

      for (var box in boxes) {
        final keysToRemove = box.keys
            .where((key) => key.toString().startsWith(prefix))
            .toList();

        if (keysToRemove.isNotEmpty) {
          await box.deleteAll(keysToRemove);
          totalDeleted += keysToRemove.length;
        }
      }

      if (totalDeleted > 0) {
        LogService.i('🧹 $prefix ile başlayan $totalDeleted veri silindi');
      }
    } catch (e) {
      LogService.e('clearByPrefix hatası: $prefix', e);
    }
  }

  Future<Map<String, int>> getStorageInfo() async {
    try {
      _ensureInitialized();
      return {
        'main': _mainBoxInstance!.length,
        'cache': _cacheBoxInstance!.length,
        'settings': _settingsBoxInstance!.length,
      };
    } catch (e) {
      LogService.e('getStorageInfo hatası', e);
      return {'main': 0, 'cache': 0, 'settings': 0};
    }
  }
}

final storageServiceProvider = Provider<StorageService>((ref) {
  return HiveStorageService();
});
