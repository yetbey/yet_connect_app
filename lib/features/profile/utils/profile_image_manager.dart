import 'package:path_provider/path_provider.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:io';

import 'package:yet_x_app/core/utils/logger_service.dart';

class ProfileImageManager {
  static Future<File?> saveProfileImage(String imageUrl, String userId) async {
    try {
      final file = await DefaultCacheManager().getSingleFile(imageUrl);

      final directory = await getApplicationDocumentsDirectory();
      final permanentPath = '${directory.path}/profile_images';

      await Directory(permanentPath).create(recursive: true);

      final savedImage = File('$permanentPath/$userId.jpg');
      await file.copy(savedImage.path);

      return savedImage;
    } catch (e, s) {
      LogService.e('', e, s);
      return null;
    }
  }

  static Future<File?> loadProfileImage(String userId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/profile_images/$userId.jpg';
      final file = File(imagePath);

      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
