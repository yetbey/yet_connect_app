import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yet_x_app/core/services/storage_service.dart';

class ChatBackgroundState {
  final bool isImage;
  final Color? color;
  final String? imagePath;

  ChatBackgroundState({this.isImage = false, this.color, this.imagePath});

  factory ChatBackgroundState.defaultBg() {
    return ChatBackgroundState(isImage: false, color: null);
  }
}

class ChatBackgroundNotifier extends Notifier<ChatBackgroundState> {
  late final StorageService _storage;

  static const _keyIsImage = 'settings_chat_bg_is_image';
  static const _keyColor = 'settings_chat_bg_color';
  static const _keyPath = 'settings_chat_bg_path';

  @override
  ChatBackgroundState build() {
    _storage = ref.read(storageServiceProvider);
    // ✅ İlk başta default döndür, sonra async yükle
    _loadBackground();
    return ChatBackgroundState.defaultBg();
  }

  // ✅ Async olarak background'u yükle
  Future<void> _loadBackground() async {
    final isImage = await _storage.read<bool>(_keyIsImage) ?? false;

    if (isImage) {
      final path = await _storage.read<String>(_keyPath);
      state = ChatBackgroundState(isImage: true, imagePath: path);
    } else {
      final colorValue = await _storage.read<int>(_keyColor);
      state = ChatBackgroundState(
        isImage: false,
        color: colorValue != null ? Color(colorValue) : null,
      );
    }
  }

  Future<void> setColor(Color color) async {
    state = ChatBackgroundState(isImage: false, color: color);
    await _storage.write(_keyIsImage, false);
    await _storage.write(_keyColor, color.r);
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      state = ChatBackgroundState(isImage: true, imagePath: image.path);
      await _storage.write(_keyIsImage, true);
      await _storage.write(_keyPath, image.path);
    }
  }

  Future<void> resetToDefault() async {
    state = ChatBackgroundState.defaultBg();
    await _storage.remove(_keyIsImage);
    await _storage.remove(_keyColor);
    await _storage.remove(_keyPath);
  }
}

final chatBackgroundProvider =
    NotifierProvider<ChatBackgroundNotifier, ChatBackgroundState>(() {
      return ChatBackgroundNotifier();
    });
