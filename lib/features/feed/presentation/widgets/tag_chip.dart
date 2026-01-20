// tag_chip.dart - Tamamen güncellenmiş versiyon

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TagChip extends StatelessWidget {
  final String tag;
  final bool small;
  final VoidCallback? onTap;

  const TagChip({super.key, required this.tag, this.small = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RepaintBoundary(
      // ✨ Performans için RepaintBoundary
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap != null
              ? () {
                  HapticFeedback.selectionClick(); // ✨ Haptic feedback
                  onTap!();
                }
              : null,
          borderRadius: BorderRadius.circular(small ? 12 : 16),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: small ? 10 : 12,
              vertical: small ? 4 : 6,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(38),
              borderRadius: BorderRadius.circular(small ? 12 : 16),
              border: Border.all(
                color: theme.colorScheme.primary.withAlpha(76),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.tag,
                  size: small ? 12 : 14,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  tag,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: small ? 12 : 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
