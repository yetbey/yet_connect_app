import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yet_x_app/core/utils/logger_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class MediaService {
  final ImagePicker _picker = ImagePicker();

  /// Temp dosyaları temizle
  Future<void> clearTempFiles() async {
    try {
      final dir = await getTemporaryDirectory();
      final tempFiles = dir.listSync().whereType<File>().where(
            (file) => file.path.contains('temp_'),
      );

      for (var file in tempFiles) {
        try {
          await file.delete();
        } catch (_) {}
      }

      LogService.i('🧹 Geçici dosyalar temizlendi');
    } catch (e) {
      LogService.e('clearTempFiles hatası', e);
    }
  }

  Future<File?> _compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = p.join(
        dir.absolute.path,
        'temp_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      // Sıkıştırma parametrelerini biraz daha optimize ettik
      final XFile? result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 70,
        minWidth: 1080,
        minHeight: 1080,
      );

      if (result == null) return file;

      final compressedFile = File(result.path);
      // Eski dosyayı silme işlemi riskli olabilir, bazen picker'ın döndüğü dosya
      // cache'de olmayabilir. Şimdilik bu kısmı yoruma alıyoruz veya
      // sadece path temp içindeyse siliyoruz.
      if (file.path != compressedFile.path && file.path.contains('cache')) {
        try { await file.delete(); } catch (_) {}
      }

      return compressedFile;
    } catch (e) {
      LogService.e('Resim sıkıştırma hatası', e);
      return file;
    }
  }

  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return null;
      return await _compressImage(File(image.path));
    } catch (e) {
      LogService.e('Galeri Hatası:', e);
      return null;
    }
  }

  // ✅ KRİTİK GÜNCELLEME BURADA
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        // Kameradan devasa (4000x3000 gibi) fotolar gelmesini engelliyoruz.
        // Bu, RAM kullanımını ciddi oranda düşürür ve app'in çökmesini engeller.
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
        requestFullMetadata: false, // Ekstra veri yükünü azaltır
      );

      if (image == null) return null;
      return await _compressImage(File(image.path));
    } catch (e) {
      LogService.e('Kamera hatası', e);
      return null;
    }
  }

  Future<File?> pickVideoFromGallery() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      return video != null ? File(video.path) : null;
    } catch (e) {
      LogService.e('Video seçme hatası', e);
      return null;
    }
  }

  Future<File?> pickVideoFromCamera() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 1), // Video süresini sınırla
      );
      return video != null ? File(video.path) : null;
    } catch (e) {
      LogService.e('Video çekme hatası', e);
      return null;
    }
  }
}

final mediaServiceProvider = Provider((ref) => MediaService());