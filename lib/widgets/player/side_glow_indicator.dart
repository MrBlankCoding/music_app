import 'package:flutter/material.dart';

class SideGlowIndicator extends StatelessWidget {
  final bool isLeft;
  final double intensity;
  final Animation<double> glowAnimation;

  const SideGlowIndicator({
    super.key,
    required this.isLeft,
    required this.intensity,
    required this.glowAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: isLeft ? 0 : null,
      right: isLeft ? null : 0,
      top: 0,
      bottom: 0,
      width: 120,
      child: AnimatedBuilder(
        animation: glowAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: isLeft ? Alignment.centerLeft : Alignment.centerRight,
                end: isLeft ? Alignment.centerRight : Alignment.centerLeft,
                colors: [
                  Colors.white.withOpacity(intensity * glowAnimation.value * 0.3),
                  Colors.transparent,
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isLeft ? Icons.skip_previous : Icons.skip_next,
                    color: Colors.white.withOpacity(intensity * glowAnimation.value),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isLeft ? 'Previous' : 'Next',
                    style: TextStyle(
                      color: Colors.white.withOpacity(intensity * glowAnimation.value),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
