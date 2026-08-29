import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yet_x_app/core/utils/logger_service.dart';
import 'package:yet_x_app/features/gamification/data/models/announcement_model.dart';

class AnnouncementService {
  final _supabase = Supabase.instance.client;

  Future<List<AnnouncementModel>> getActiveAnnouncements() async {
    try {
      final response = await _supabase.from('announcements').select()
          .order('priority', ascending: false)
          .order('created_at', ascending: false);

      return (response as List).map((json) => AnnouncementModel.fromJson(json)).toList();
    } catch (e) {
      LogService.e('❌ Duyuru yükleme hatası', e);
      return [];
    }
  }
}