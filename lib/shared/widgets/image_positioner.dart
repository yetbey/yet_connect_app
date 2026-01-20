import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:yet_x_app/config/theme/app_text_styles.dart';
import 'package:yet_x_app/core/constants/app_colors.dart';

class ImagePositioner extends StatefulWidget {
  final File imageFile;
  final double aspectRatio;
  final Function(Alignment) onPositionChanged;

  const ImagePositioner({
    super.key,
    required this.imageFile,
    this.aspectRatio = 4 / 5,
    required this.onPositionChanged,
  });

  @override
  State<ImagePositioner> createState() => _ImagePositionerState();
}

class _ImagePositionerState extends State<ImagePositioner> {
  Alignment _alignment = Alignment.center;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: Stack(
        alignment: Alignment.center,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    final double dx =
                        details.delta.dx / (constraints.maxWidth / 2);
                    final double dy =
                        details.delta.dy / (constraints.maxHeight / 2);
                    double newX = _alignment.x - dx;
                    double newY = _alignment.y - dy;

                    if (newX > 1.0) newX = 1.0;
                    if (newX < -1.0) newX = -1.0;
                    if (newY > 1.0) newY = 1.0;
                    if (newY < -1.0) newY = -1.0;

                    _alignment = Alignment(newX, newY);
                  });
                  widget.onPositionChanged(_alignment);
                },
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black,
                  child: Image.file(
                    widget.imageFile,
                    fit: BoxFit.cover,
                    alignment: _alignment,
                  ),
                ),
              );
            },
          ),

          // Bilgilendirme yazısı
          Positioned(
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.touch_app, color: AppColors.flat, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'slide_to_align'.tr(),
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
