// lib/features/feed/presentation/pages/full_screen_video_viewer.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:yet_x_app/config/routes/app_routes.dart';
import 'package:yet_x_app/config/theme/app_text_styles.dart';
import 'package:yet_x_app/core/constants/app_colors.dart';
import 'package:yet_x_app/core/services/custom_cache_manager.dart';
import 'package:yet_x_app/core/services/navigation_service.dart';
import 'package:yet_x_app/features/feed/data/models/post_model.dart';
import 'package:yet_x_app/features/feed/presentation/pages/comments_sheet.dart';
import 'package:yet_x_app/features/feed/presentation/providers/post_provider.dart';
import 'package:yet_x_app/features/feed/presentation/widgets/action_button.dart';

class FullScreenVideoViewer extends ConsumerStatefulWidget {
  final PostModel post;

  const FullScreenVideoViewer({super.key, required this.post});

  @override
  ConsumerState<FullScreenVideoViewer> createState() =>
      _FullScreenVideoViewerState();
}

class _FullScreenVideoViewerState extends ConsumerState<FullScreenVideoViewer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isPlaying = true;
  bool _isMuted = false;
  bool _showControls = true;
  bool isLiked = false;
  int likesCount = 0;

  @override
  void initState() {
    super.initState();
    isLiked = widget.post.isLikedByCurrentUser;
    likesCount = widget.post.likes;

    // ✅ Tam ekran ve landscape
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);

    _initializeVideoPlayer();
  }

  void _initializeVideoPlayer() {
    _controller =
        VideoPlayerController.networkUrl(Uri.parse(widget.post.videoUrl!))
          ..initialize().then((_) {
            if (mounted) {
              setState(() {
                _isInitialized = true;
              });
              _controller.setLooping(true);
              _controller.setVolume(1.0);
              _controller.play();
            }
          });
  }

  @override
  void dispose() {
    _controller.pause();
    _controller.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPlaying = false;
      } else {
        _controller.play();
        _isPlaying = true;
      }
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _controller.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  void _handleLike() {
    final previousState = isLiked;
    final previousCount = likesCount;

    setState(() {
      isLiked = !isLiked;
      likesCount = isLiked ? likesCount + 1 : likesCount - 1;
    });

    final postToSend = widget.post.copyWith(
      isLikedByCurrentUser: previousState,
      likes: previousCount,
    );

    ref.read(postActionsProvider.notifier).toggleLike(postToSend).catchError((
      e,
    ) {
      if (mounted) {
        setState(() {
          isLiked = previousState;
          likesCount = previousCount;
        });
      }
    });
  }

  void _showCommentsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => CommentBottomSheet(postId: widget.post.id),
    );
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });

    // ✅ 3 saniye sonra otomatik gizle
    if (_showControls) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _showControls) {
          setState(() {
            _showControls = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        onDoubleTap: _handleLike,
        child: Stack(
          children: [
            // ✅ Video Player (Centered)
            Center(
              child: _isInitialized
                  ? AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    )
                  : const CircularProgressIndicator(color: Colors.white),
            ),

            // ✅ Controls Overlay
            if (_showControls) _buildControlsOverlay(),

            // ✅ Top Bar (Close & Info)
            if (_showControls) _buildTopBar(),

            // ✅ Bottom Bar (Actions)
            if (_showControls) _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ✅ Top Bar
  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          bottom: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            // ✅ Close Button
            IconButton(
              onPressed: () => NavigationService.back(),
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
            ),
            const Spacer(),
            // ✅ Mute Button
            IconButton(
              onPressed: _toggleMute,
              icon: Icon(
                _isMuted
                    ? IconsaxPlusBold.volume_slash
                    : IconsaxPlusBold.volume_high,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Controls Overlay (Play/Pause)
  Widget _buildControlsOverlay() {
    return Center(
      child: GestureDetector(
        onTap: _togglePlayPause,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
            size: 50,
          ),
        ),
      ),
    );
  }

  // ✅ Bottom Bar (Profile, Like, Comment)
  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
          top: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Caption
            if (widget.post.caption != null && widget.post.caption!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  widget.post.caption!,
                  style: AppTextStyles.bodyLarge,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // ✅ Actions Row
            Row(
              children: [
                // Profile
                Expanded(child: _buildProfileSection()),

                // Like
                UnifiedActionButton(
                  onTap: _handleLike,
                  icon: isLiked
                      ? IconsaxPlusBold.heart
                      : IconsaxPlusLinear.heart,
                  color: isLiked ? AppColors.error : Colors.white,
                  label: '$likesCount',
                ),
                const SizedBox(width: 16),

                // Comment
                UnifiedActionButton(
                  icon: IconsaxPlusBold.message_2,
                  label: widget.post.commentCount.toString(),
                  color: Colors.white,
                  onTap: _showCommentsSheet,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Profile Section
  Widget _buildProfileSection() {
    return GestureDetector(
      onTap: () => NavigationService.toNamed(
        AppRoutes.profile,
        arguments: {'userId': widget.post.userId},
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: widget.post.userProfileImage != null
                ? CachedNetworkImageProvider(
                    widget.post.userProfileImage!,
                    cacheManager: CustomImageCacheManager(),
                  )
                : null,
            backgroundColor: Colors.white24,
            child: widget.post.userProfileImage == null
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '@${widget.post.username}',
                  style: AppTextStyles.bodyLarge,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.post.userFullName != null)
                  Text(
                    widget.post.userFullName!,
                    style: AppTextStyles.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
