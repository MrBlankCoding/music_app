import 'package:flutter/material.dart';
import './playback_controls.dart';

class PlayerHeader extends StatelessWidget {
  final VoidCallback onOptionsPressed;

  const PlayerHeader({super.key, required this.onOptionsPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 5,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PlayerIconButton(
                icon: Icons.keyboard_arrow_down,
                onPressed: () => Navigator.pop(context),
              ),
              PlayerIconButton(
                icon: Icons.more_horiz,
                onPressed: onOptionsPressed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
