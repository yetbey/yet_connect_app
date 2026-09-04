import 'package:flutter/material.dart';
import 'package:yet_x_app/features/gamification/data/models/rank_model.dart';

class RankBadge extends StatelessWidget {
  final RankModel rank;
  final double size;
  final bool showLabel;

  const RankBadge({
    super.key,
    required this.rank,
    this.size = 40,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                rank.colorValue,
                rank.colorValue.withValues(alpha: 0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: rank.colorValue.withValues(alpha: .3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            rank.iconData,
            color: Colors.white,
            size: size * 0.5,
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 4),
          Text(
            rank.displayName,
            style: TextStyle(
              fontSize: size * 0.25,
              fontWeight: FontWeight.bold,
              color: rank.colorValue,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// Mini badge (profil resmi üzerinde gösterilecek)
class RankBadgeMini extends StatelessWidget {
  final RankModel rank;

  const RankBadgeMini({
    super.key,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            rank.colorValue,
            rank.colorValue.withValues(alpha: .8),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: rank.colorValue.withValues(alpha: .3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            rank.iconData,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            rank.displayName.split(' ')[0], // Sadece isim kısmı (emoji hariç)
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
