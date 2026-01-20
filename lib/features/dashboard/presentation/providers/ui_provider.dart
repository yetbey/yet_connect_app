import 'package:flutter_riverpod/flutter_riverpod.dart';

class UiNotifier extends Notifier<bool> {
  @override
  bool build() {
    return true; // Varsayılan olarak görünür
  }

  void showNavBar() => state = true;
  void hideNavBar() => state = false;
}

final uiProvider = NotifierProvider<UiNotifier, bool>(() {
  return UiNotifier();
});
