// core/animations/staggered_animation.dart (yeni dosya)

import 'package:flutter/material.dart';

class StaggeredAnimationHelper {
  static Widget staggeredList({
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    int delay = 50,
  }) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: const AlwaysStoppedAnimation(0),
          builder: (context, child) {
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 300 + (index * delay)),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: itemBuilder(context, index),
            );
          },
        );
      },
    );
  }
}
