// lib/features/learn/widgets/lesson_stars.dart
import 'package:flutter/material.dart';

/// Displays 0–3 filled/empty stars for a lesson.
class LessonStars extends StatelessWidget {
  const LessonStars({super.key, required this.stars, this.size = 18.0});
  final int stars;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final filled = i < stars;
        return Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: filled ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
        );
      }),
    );
  }
}
