import 'package:flutter/material.dart';

class AnimatedHeartOverlay extends StatefulWidget {
  final bool isAnimating;
  final VoidCallback onEnd;
  final double size; // 🎨 Boyut parametresi eklendi

  const AnimatedHeartOverlay({
    super.key,
    required this.isAnimating,
    required this.onEnd,
    this.size = 180, // Default 180px
  });

  @override
  State<AnimatedHeartOverlay> createState() => _AnimatedHeartOverlayState();
}

class _AnimatedHeartOverlayState extends State<AnimatedHeartOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // 🎨 700 → 800ms
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.5,
          end: 1.2,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.2,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_controller);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_controller);

    if (widget.isAnimating) {
      _controller.forward().then((_) {
        widget.onEnd();
        if (mounted) {
          _controller.reset();
        }
      });
    }
  }

  @override
  void didUpdateWidget(AnimatedHeartOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimating && !oldWidget.isAnimating) {
      _controller.forward().then((_) {
        widget.onEnd();
        if (mounted) {
          _controller.reset();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Icon(
              Icons.favorite,
              color: Colors.white,
              size: widget.size, // 🎨 Dinamik boyut
              shadows: const [Shadow(color: Colors.red, blurRadius: 20)],
            ),
          ),
        );
      },
    );
  }
}
