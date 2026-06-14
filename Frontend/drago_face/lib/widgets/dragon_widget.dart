import 'package:flutter/material.dart';

class DragonWidget extends StatelessWidget {
  final bool isDragoMode;
  final double size;
  final double opacity;

  const DragonWidget({
    super.key,
    required this.isDragoMode,
    this.size = 280,
    this.opacity = 0.12,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          );
        },
        child: Opacity(
          key: ValueKey(isDragoMode),
          opacity: opacity,
          child: Image.asset(
            isDragoMode
                ? 'assets/images/red_dragon.png'
                : 'assets/images/blue_dragon.png',
            width: size,
            height: size,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}