import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:yet_x_app/core/constants/app_colors.dart';
import 'package:yet_x_app/core/services/navigation_service.dart';
import 'package:yet_x_app/features/feed/data/models/post_model.dart';
import 'package:yet_x_app/features/feed/presentation/providers/post_provider.dart';

class ActionMoreButton extends StatelessWidget {
  const ActionMoreButton({super.key, required this.post, required this.ref});

  final PostModel post;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      icon: const Icon(
        IconsaxPlusBold.more_square,
        size: 22,
        color: AppColors.textColor,
      ),
      padding: EdgeInsets.zero,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      itemBuilder: (context) {
        return [
          PopupMenuItem(
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(IconsaxPlusBold.trash, color: Colors.red, size: 20),
                SizedBox(width: 12),
                Text('Gönderiyi Sil', style: TextStyle(color: Colors.red)),
              ],
            ),
            onTap: () async {
              await Future.delayed(const Duration(milliseconds: 100));
              final confirm =
                  await NavigationService.showDeleteConfirmDialog(
                    message:
                        'Bu gönderiyi silmek istediğinizden emin misiniz?',
                  );
              if (confirm) {
                await ref
                    .read(postActionsProvider.notifier)
                    .deletePost(post.id);
              }
            },
          ),
        ];
      },
    );
  }
}
