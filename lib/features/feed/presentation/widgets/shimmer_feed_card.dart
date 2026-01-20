// shimmer_feed_card.dart - Daha performanslı versiyon

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerFeedCard extends StatelessWidget {
  const ShimmerFeedCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return RepaintBoundary(
      // ✨ RepaintBoundary
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Shimmer.fromColors(
              baseColor: isDark ? Colors.grey[850]! : Colors.grey[300]!,
              highlightColor: isDark ? Colors.grey[800]! : Colors.grey[100]!,
              period: const Duration(milliseconds: 1500), // 🎨 Smooth animation
              child: Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
              ),
            ),

            // Content placeholder
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Caption lines
                  Shimmer.fromColors(
                    baseColor: isDark ? Colors.grey[850]! : Colors.grey[300]!,
                    highlightColor: isDark
                        ? Colors.grey[800]!
                        : Colors.grey[100]!,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.grey[850],
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: MediaQuery.of(context).size.width * 0.7,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.grey[850],
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Bottom row
                  Shimmer.fromColors(
                    baseColor: isDark ? Colors.grey[850]! : Colors.grey[300]!,
                    highlightColor: isDark
                        ? Colors.grey[800]!
                        : Colors.grey[100]!,
                    child: Row(
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey[850],
                        ),
                        const SizedBox(width: 10),
                        // Username
                        Container(
                          width: 100,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.grey[850],
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const Spacer(),
                        // Action buttons
                        Container(
                          width: 60,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.grey[850],
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
