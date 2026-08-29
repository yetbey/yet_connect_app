import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yet_x_app/core/utils/logger_service.dart';
import 'package:yet_x_app/features/gamification/data/models/announcement_model.dart';
import 'package:yet_x_app/features/gamification/data/services/announcement_service.dart';

class AnnouncementsState {
  final List<AnnouncementModel> announcements;
  final bool isLoading;
  final String? error;

  const AnnouncementsState({
    this.announcements = const [],
    this.isLoading = false,
    this.error,
});

  AnnouncementsState copyWith({
    List<AnnouncementModel>? announcements,
    bool? isLoading,
    String? error,
  }) {
    return AnnouncementsState(
      announcements: announcements ?? this.announcements,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AnnouncementsNotifier extends Notifier<AnnouncementsState> {
  final _announcementService = AnnouncementService();

  @override
  AnnouncementsState build() {
    // build() bitmeden state değiştirmemek için microtask ile geciktiriyoruz
    Future.microtask(() => _loadAnnouncements());
    return const AnnouncementsState();
  }

  Future<void> _loadAnnouncements() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final announcements = await _announcementService.getActiveAnnouncements();
      state = state.copyWith(announcements: announcements, isLoading: false);
      LogService.i('✅ Duyurular yüklendi: ${announcements.length}');
    } catch (e) {
      LogService.e('❌ Duyuru provider hatası', e);
      state = state.copyWith(
        isLoading: false,
        error: 'Duyurular yüklenemedi',
      );
    }
  }

  Future<void> refresh() async {
    await _loadAnnouncements();
  }
}

final announcementsProvider =
NotifierProvider<AnnouncementsNotifier, AnnouncementsState>(() {
  return AnnouncementsNotifier();
});