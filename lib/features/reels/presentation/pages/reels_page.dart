import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yet_x_app/features/reels/presentation/providers/reels_provider.dart';
import 'package:yet_x_app/features/reels/presentation/widgets/reels_video_player.dart';
import 'package:yet_x_app/features/reels/presentation/widgets/reels_action_bar.dart';
import 'package:yet_x_app/features/reels/presentation/widgets/reels_bottom_info.dart';
import 'package:yet_x_app/features/feed/presentation/providers/post_provider.dart';
import 'package:yet_x_app/features/feed/presentation/pages/comments_sheet.dart';
import 'package:yet_x_app/core/services/navigation_service.dart';
import 'package:yet_x_app/config/routes/app_routes.dart';

class ReelsPage extends ConsumerStatefulWidget {
  const ReelsPage({super.key});

  @override
  ConsumerState<ReelsPage> createState() => _ReelsPageState();
}

class _ReelsPageState extends ConsumerState<ReelsPage> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // İlk yükleme
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reelsProvider.notifier).fetchReels(isRefresh: true);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reelsState = ref.watch(reelsProvider);

    if (reelsState.videos.isEmpty && reelsState.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (reelsState.videos.isEmpty && !reelsState.isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.videocam_off, size: 64, color: Colors.white54),
              const SizedBox(height: 16),
              const Text(
                'Henüz video yok',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  ref.read(reelsProvider.notifier).fetchReels(isRefresh: true);
                },
                child: const Text('Yenile'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Reels',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: reelsState.videos.length,
        onPageChanged: (index) {
          ref.read(reelsProvider.notifier).updateCurrentIndex(index);
        },
        itemBuilder: (context, index) {
          final video = reelsState.videos[index];
          final isActive = index == reelsState.currentIndex;

          return _buildReelItem(video, isActive);
        },
      ),
    );
  }

  Widget _buildReelItem(post, bool isActive) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Video Player
        ReelsVideoPlayer(
          videoUrl: post.videoUrl!,
          isActive: isActive,
          onDoubleTap: () => _handleLike(post),
        ),

        // Top Gradient
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha:  0.6),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Bottom Gradient
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha:  0.8),
                  Colors.black.withValues(alpha:  0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Action Bar (Right Side)
        ReelsActionBar(
          post: post,
          isLiked: post.isLikedByCurrentUser,
          likesCount: post.likes,
          onLike: () => _handleLike(post),
          onComment: () => _showComments(post.id),
          onShare: () => _handleShare(post),
          onProfileTap: () => NavigationService.toNamed(
            AppRoutes.profile,
            arguments: {'userId': post.userId},
          ),
        ),

        // Bottom Info
        ReelsBottomInfo(post: post),
      ],
    );
  }

  void _handleLike(post) {
    ref.read(postActionsProvider.notifier).toggleLike(post).then((_) {
      // Provider otomatik güncellenecek
    });
  }

  void _showComments(String postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => CommentBottomSheet(postId: postId),
    );
  }

  void _handleShare(post) {
    // Share fonksiyonunu implement edin
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Paylaşım özelliği yakında...')),
    );
  }
}
