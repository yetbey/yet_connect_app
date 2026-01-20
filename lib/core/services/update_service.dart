import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yet_x_app/core/utils/logger_service.dart';

class UpdateService {
  final _supabase = Supabase.instance.client;

  /// Büyük güncelleme kontrolünü başlat
  Future<void> checkForMajorUpdate(BuildContext context) async {
    try {
      // 1. Telefondaki mevcut sürümü al
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version; // Örn: 1.0.0

      LogService.i('Mevcut Sürüm: $currentVersion');

      // 2. Supabase'den en son eklenen sürümü çek
      final response = await _supabase
          .from('app_versions')
          .select()
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return; // Veri yoksa çık

      final String latestVersion = response['version'];
      final String downloadUrl = response['download_url'];
      final bool isMandatory = response['is_mandatory'] ?? false;

      // 3. Versiyonları karşılaştır
      if (_isVersionNewer(currentVersion, latestVersion)) {
        LogService.i('Yeni Büyük Güncelleme Bulundu: $latestVersion');

        if (context.mounted) {
          _showUpdateDialog(context, latestVersion, downloadUrl, isMandatory);
        }
      }
    } catch (e) {
      LogService.e('Güncelleme kontrol hatası', e);
    }
  }

  /// Semantik versiyon kontrolü (Örn: 1.0.0 vs 1.0.5)
  bool _isVersionNewer(String current, String latest) {
    try {
      final List<int> c = current.split('.').map(int.parse).toList();
      final List<int> l = latest.split('.').map(int.parse).toList();

      for (int i = 0; i < l.length; i++) {
        final int cp = i < c.length ? c[i] : 0;
        if (l[i] > cp) return true;
        if (l[i] < cp) return false;
      }
    } catch (e) {
      // Versiyon formatı hatalıysa (örn: "beta-1") false dön
      return false;
    }
    return false;
  }

  void _showUpdateDialog(
    BuildContext context,
    String version,
    String url,
    bool isMandatory,
  ) {
    showDialog(
      context: context,
      barrierDismissible: !isMandatory, // Zorunluysa boşluğa basınca kapanmaz
      builder: (context) => PopScope(
        canPop: !isMandatory, // Zorunluysa geri tuşu çalışmaz
        child: AlertDialog(
          title: const Text('Yeni Sürüm Mevcut! 🚀'),
          content: Text(
            'Uygulamanın daha yeni bir sürümü ($version) yayınlandı. '
            '${isMandatory ? "Kullanmaya devam etmek için güncellemelisiniz." : "Güncellemek ister misiniz?"}',
          ),
          actions: [
            if (!isMandatory)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Daha Sonra'),
              ),
            FilledButton(
              onPressed: () async {
                final uri = Uri.parse(url);
                try {
                  // canLaunchUrl kontrolünü kaldırdık, direkt deniyoruz
                  await launchUrl(
                    uri,
                    mode: LaunchMode
                        .externalApplication, // Tarayıcıda açmaya zorla
                  );
                } catch (e) {
                  // Eğer yine açılmazsa log düş
                  LogService.e('Link açılamadı: $url', e);

                  // Kullanıcıya bilgi ver (Opsiyonel)
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Link açılamadı, lütfen daha sonra deneyin.',
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Text('İndir ve Güncelle'),
            ),
          ],
        ),
      ),
    );
  }
}
