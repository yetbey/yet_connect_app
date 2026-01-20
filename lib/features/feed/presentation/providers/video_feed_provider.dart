import 'package:flutter_riverpod/flutter_riverpod.dart';

class VideoFeedNotifier extends Notifier<String?> {
  @override
  String? build() {
    return null; // Başlangıçta video oynamıyor
  }

  void playVideo(String postId) {
    if (state != postId) {
      state = postId;
    }
  }

  void stopAll() {
    state = null;
  }
}

final videoFeedProvider = NotifierProvider<VideoFeedNotifier, String?>(() {
  return VideoFeedNotifier();
});
