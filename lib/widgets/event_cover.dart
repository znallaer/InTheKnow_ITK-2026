import 'package:flutter/material.dart';

import '../models/event.dart';
import '../theme/app_colors.dart';


class EventCover extends StatelessWidget {
  final Event event;
  final double height;

  const EventCover({super.key, required this.event, this.height = 200});

  @override
  Widget build(BuildContext context) {
    final fallback = _GeneratedCover(event: event, height: height);

    if (event.imageAsset.isNotEmpty) {
      return Image.asset(
        event.imageAsset,
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    if (event.imageUrl.isNotEmpty) {
      return Image.network(
        event.imageUrl,
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    return fallback;
  }
}

class _GeneratedCover extends StatelessWidget {
  final Event event;
  final double height;

  const _GeneratedCover({required this.event, required this.height});

  IconData get _icon {
    switch (event.category.toLowerCase()) {
      case 'seminar':
        return Icons.record_voice_over_rounded;
      case 'workshop':
        return Icons.laptop_chromebook_rounded;
      case 'academic':
        return Icons.school_rounded;
      case 'sports':
        return Icons.sports_basketball_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.green, AppColors.darkGreen],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -30,
            child: _circle(150, 0.10),
          ),
          Positioned(
            bottom: -50,
            left: -20,
            child: _circle(130, 0.08),
          ),
          Positioned(
            top: 36,
            left: 28,
            child: _circle(34, 0.14),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_icon, size: 76, color: Colors.white),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    event.category.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.yellow,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}
