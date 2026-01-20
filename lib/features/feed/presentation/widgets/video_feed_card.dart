import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:yet_x_app/core/services/navigation_service.dart';
import 'package:yet_x_app/features/feed/presentation/providers/video_feed_provider.dart';
import 'package:yet_x_app/features/feed/presentation/pages/comments_sheet.dart';
import 'package:yet_x_app/features/feed/data/models/post_model.dart';
import 'package:yet_x_app/features/feed/presentation/providers/post_provider.dart';
import 'package:yet_x_app/config/routes/app_routes.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:yet_x_app/core/services/custom_cache_manager.dart';

class VideoFeedCard extends ConsumerStatefulWidget {
  final PostModel post;
  const VideoFeedCard({super.key, required this.post});

  @override
  ConsumerState<VideoFeedCard> createState() => _VideoFeedCardState();
}

class _VideoFeedCardState extends ConsumerState<VideoFeedCard>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool isLiked = false;
  int likesCount = 0;
  bool isMuted = true;
  bool _showPlayPauseIcon = false;
  late AnimationController _likeController;
  bool _isDisposed = false; // ✅ YENİ: Dispose flag'i

  @override
  void initState() {
    super.initState();
    isLiked = widget.post.isLikedByCurrentUser;
    likesCount = widget.post.likes;
    _initializeVideoPlayer();
    _likeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  // ✅ YENİ: Named listener method
  void _videoControllerListener() {
    if (!_isDisposed && mounted) {
      setState(() {});
    }
  }

  void _initializeVideoPlayer() {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.post.videoUrl!))
      ..initialize().then((_) {
        if (!_isDisposed && mounted) {
          setState(() => _isInitialized = true);
          _controller.setLooping(true);
          _controller.setVolume(0.0);
        }
      });

    // ✅ YENİ: Named listener ekle
    _controller.addListener(_videoControllerListener);
  }

  @override
  void dispose() {
    _isDisposed = true; // ✅ YENİ: Önce flag'i set et

    // ✅ YENİ: Listener'ı kaldır
    _controller.removeListener(_videoControllerListener);

    // Sonra controller'ı temizle
    _controller.pause();
    _controller.dispose();

    _likeController.dispose();
    super.dispose();
  }

  void _handleLike() {
    HapticFeedback.mediumImpact();
    final previousState = isLiked;
    final previousCount = likesCount;
    setState(() {
      isLiked = !isLiked;
      likesCount = isLiked ? likesCount + 1 : likesCount - 1;
    });
    if (isLiked) {
      _likeController.forward().then((_) => _likeController.reverse());
    }

    final postToSend = widget.post.copyWith(
      isLikedByCurrentUser: previousState,
      likes: previousCount,
    );
    ref.read(postActionsProvider.notifier).toggleLike(postToSend).catchError((e) {
      if (mounted) {
        setState(() {
          isLiked = previousState;
          likesCount = previousCount;
        });
      }
    });
  }

  void _toggleMute() {
    HapticFeedback.selectionClick();
    setState(() {
      isMuted = !isMuted;
      _controller.setVolume(isMuted ? 0.0 : 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final playingPostId = ref.watch(videoFeedProvider);
    final shouldPlay = playingPostId == widget.post.id;

    if (_isInitialized && !_isDisposed) { // ✅ YENİ: _isDisposed kontrolü
      if (shouldPlay && !_controller.value.isPlaying) {
        _controller.play();
      } else if (!shouldPlay && _controller.value.isPlaying) {
        _controller.pause();
      }
    }

    return RepaintBoundary(
      child: VisibilityDetector(
        key: Key('video-${widget.post.id}'),
        onVisibilityChanged: (info) {
          if (!mounted || _isDisposed) return; // ✅ YENİ: _isDisposed kontrolü
          if (info.visibleFraction > 0.7) {
            ref.read(videoFeedProvider.notifier).playVideo(widget.post.id);
          }
        },
        child: AnimatedScale(
          scale: 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
            height: 480,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.zero,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildVideoPlayer(),
                  _buildTopGradient(),
                  _buildBottomGradient(),
                  if (_isInitialized)
                    Positioned(top: 12, right: 12, child: _buildMuteButton()),
                  _buildRightActionBar(),
                  _buildBottomInfo(),
                  if (_isInitialized) _buildProgressBar(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (!_isInitialized || _isDisposed) return; // ✅ YENİ: _isDisposed kontrolü
        HapticFeedback.selectionClick();
        setState(() {
          if (_controller.value.isPlaying) {
            _controller.pause();
            ref.read(videoFeedProvider.notifier).stopAll();
            _showPlayPauseIcon = true;
          } else {
            _controller.play();
            ref.read(videoFeedProvider.notifier).playVideo(widget.post.id);
            _showPlayPauseIcon = true;
          }
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && !_isDisposed) { // ✅ YENİ: _isDisposed kontrolü
            setState(() => _showPlayPauseIcon = false);
          }
        });
      },
      onDoubleTap: () {
        if (!_isInitialized || _isDisposed) return; // ✅ YENİ: _isDisposed kontrolü
        HapticFeedback.mediumImpact();
        _handleLike();
      },
      child: Container(
        color: Colors.black,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_isInitialized)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              )
            else
              _buildLoadingPlaceholder(),
            if (_showPlayPauseIcon)
              Center(
                child: TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 200),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Opacity(
                        opacity: value,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _controller.value.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (_isInitialized && !_controller.value.isPlaying && !_showPlayPauseIcon)
              IgnorePointer(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
      ),
    );
  }

  Widget _buildTopGradient() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomGradient() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.8),
              Colors.black.withValues(alpha: 0.3),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMuteButton() {
    return GestureDetector(
      onTap: _toggleMute,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
        ),
        child: Icon(
          isMuted ? Icons.volume_off : Icons.volume_up,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildRightActionBar() {
    return Positioned(
      right: 12,
      bottom: 80,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            children: [
              _buildProfileButton(),
              const SizedBox(height: 2),
              Text(
                '@${widget.post.username}',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  shadows: const [Shadow(color: Colors.black, blurRadius: 8)],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            icon: isLiked ? Icons.favorite : Icons.favorite_border,
            label: _formatCount(likesCount),
            color: isLiked ? Colors.red : Colors.white,
            onTap: _handleLike,
            scale: _likeController,
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            icon: Icons.chat_bubble_outline,
            label: _formatCount(widget.post.commentCount),
            color: Colors.white,
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                useSafeArea: true,
                builder: (context) => CommentBottomSheet(postId: widget.post.id),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            icon: Icons.share,
            label: '',
            color: Colors.white,
            onTap: () {
              HapticFeedback.lightImpact();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileButton() {
    return GestureDetector(
      onTap: () => NavigationService.toNamed(
        AppRoutes.profile,
        arguments: {'userId': widget.post.userId},
      ),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: widget.post.userProfileImage != null
            ? CachedNetworkImage(
          imageUrl: widget.post.userProfileImage!,
          cacheManager: CustomImageCacheManager(),
          imageBuilder: (context, imageProvider) =>
              CircleAvatar(backgroundImage: imageProvider),
          placeholder: (context, url) =>
          const CircleAvatar(backgroundColor: Colors.grey),
          errorWidget: (context, url, error) => CircleAvatar(
            backgroundColor: Colors.grey[800],
            child: const Icon(Icons.person, color: Colors.white),
          ),
        )
            : CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            widget.post.username?[0].toUpperCase() ?? 'U',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    Animation<double>? scale,
  }) {
    final Widget button = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onTap,
          icon: Icon(icon, color: color, size: 28),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              shadows: [Shadow(color: Colors.black, blurRadius: 4)],
            ),
          ),
        ],
      ],
    );

    if (scale != null) {
      return ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 1.3)
            .animate(CurvedAnimation(parent: scale, curve: Curves.elasticOut)),
        child: button,
      );
    }

    return button;
  }

  Widget _buildBottomInfo() {
    return Positioned(
      left: 12,
      right: 70,
      bottom: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => NavigationService.toNamed(
              AppRoutes.profile,
              arguments: {'userId': widget.post.userId},
            ),
            child: Text(
              widget.post.userFullName!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (widget.post.caption != null && widget.post.caption!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              widget.post.caption!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.3,
                shadows: [Shadow(color: Colors.black, blurRadius: 8)],
              ),
            ),
          ],
          if (widget.post.tags.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: widget.post.tags.take(3).map((tag) {
                return GestureDetector(
                  onTap: () {
                    NavigationService.toNamed(
                      AppRoutes.tagPosts,
                      arguments: {'tag': tag},
                    );
                  },
                  child: Text(
                    '#$tag',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    if (!_controller.value.isInitialized) return const SizedBox.shrink();
    final position = _controller.value.position;
    final duration = _controller.value.duration;
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 2,
        color: Colors.white.withValues(alpha: 0.3),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: progress.clamp(0.0, 1.0),
          child: Container(color: Colors.white),
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}B';
    }
    return count.toString();
  }
}
