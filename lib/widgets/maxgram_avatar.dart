
import 'package:flutter/material.dart';
import '../theme/maxgram_theme.dart';

/// Circular gradient avatar mimicking Telegram-iOS AvatarNode fallback
/// (initials + deterministic gradient based on user id hashing).
class MaxgramAvatar extends StatelessWidget {
  final String letter;
  final int colorIndex;
  final double size;

  const MaxgramAvatar({
    super.key,
    required this.letter,
    required this.colorIndex,
    this.size = 56,
  });

  List<Color> _gradientFor(int index) {
    const gradients = [
      MaxgramColors.avatarGradients0,
      MaxgramColors.avatarGradients1,
      MaxgramColors.avatarGradients2,
      MaxgramColors.avatarGradients3,
      MaxgramColors.avatarGradients4,
    ];
    return gradients[index % gradients.length];
  }

  @override
  Widget build(BuildContext context) {
    final colors = _gradientFor(colorIndex);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        letter.toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
