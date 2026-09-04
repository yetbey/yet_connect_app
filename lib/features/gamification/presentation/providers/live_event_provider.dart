import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yet_x_app/features/gamification/data/models/live_event_model.dart';
import 'package:yet_x_app/features/gamification/data/services/live_event_service.dart';

/// Feels sayfasındaki "Hızlı Aksiyonlar" kartı için hafif bir provider.
/// Sohbet/presence mantığı burada değil, LiveEventPage içinde yönetiliyor.
final liveEventProvider = FutureProvider<LiveEventModel?>((ref) async {
  return LiveEventService().getCurrentLiveEvent();
});
