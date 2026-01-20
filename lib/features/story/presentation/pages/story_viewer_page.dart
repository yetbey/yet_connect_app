import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:yet_x_app/config/routes/app_routes.dart';
import 'package:yet_x_app/core/services/navigation_service.dart';
import 'package:yet_x_app/features/profile/presentation/providers/user_provider.dart';
import 'package:yet_x_app/features/story/data/models/story_model.dart';
import 'package:yet_x_app/features/story/presentation/providers/story_provider.dart';

class StoryViewerPage extends ConsumerStatefulWidget {
  final List<UserStoryGroup> storyGroups;
  final int initialIndex;

  const StoryViewerPage({
    super.key,
    required this.storyGroups,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<StoryViewerPage> createState() => _StoryViewerPageState();
}

class _StoryViewerPageState extends ConsumerState<StoryViewerPage> {
  late PageController _pageController;
  int _currentUserIndex = 0;
  int _currentStoryIndex = 0;

  VideoPlayerController? _videoController;
  Timer? _storyTimer;
  bool _isPaused = false;
  bool _isMediaLoaded = false; // ✅ Yeni: Medya yüklenme durumu
  final List<double> _storyProgress = [];

  @override
  void initState() {
    super.initState();
    _currentUserIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _initializeStoryProgress();
    _loadStory();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoController?.dispose();
    _storyTimer?.cancel();
    super.dispose();
  }

  void _initializeStoryProgress() {
    final currentGroup = widget.storyGroups[_currentUserIndex];
    _storyProgress.clear();
    _storyProgress.addAll(List.filled(currentGroup.stories.length, 0.0));
  }

  Future<void> _loadStory() async {
    final currentGroup = widget.storyGroups[_currentUserIndex];
    final story = currentGroup.stories[_currentStoryIndex];

    // Video controller'ı temizle
    await _videoController?.dispose();
    _videoController = null;
    _storyTimer?.cancel();
    _isMediaLoaded = false; // ✅ Reset

    if (story.isVideo) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(story.mediaUrl));
      await _videoController!.initialize();
      await _videoController!.play();

      // ✅ Video yüklendiğinde timer başlat
      _isMediaLoaded = true;
      _startStoryTimer(story.duration ?? 15000);
    } else {
      // ✅ Image için timer daha sonra başlayacak (onImageLoaded callback'inde)
      _isMediaLoaded = false;
    }

    // Story'yi görüntülendi olarak işaretle
    final currentUser = ref.read(userProvider).currentUser;
    if (currentUser != null && story.userId != currentUser.id) {
      ref.read(storyRepositoryProvider).viewStory(story.id, currentUser.id);
    }

    if (mounted) setState(() {});
  }

  // ✅ Yeni: Image yüklendiğinde çağrılacak
  void _onImageLoaded() {
    if (!_isMediaLoaded) {
      _isMediaLoaded = true;
      _startStoryTimer(5000); // Image için 5 saniye
    }
  }

  void _startStoryTimer(int duration) {
    _storyTimer?.cancel();
    final interval = 50; // 50ms interval for smooth progress
    final totalTicks = duration ~/ interval;
    int currentTick = 0;

    _storyTimer = Timer.periodic(Duration(milliseconds: interval), (timer) {
      if (!_isPaused && mounted) {
        currentTick++;
        setState(() {
          _storyProgress[_currentStoryIndex] = currentTick / totalTicks;
        });

        if (currentTick >= totalTicks) {
          timer.cancel();
          _nextStory();
        }
      }
    });
  }

  void _nextStory() {
    final currentGroup = widget.storyGroups[_currentUserIndex];

    if (_currentStoryIndex < currentGroup.stories.length - 1) {
      setState(() {
        _storyProgress[_currentStoryIndex] = 1.0;
        _currentStoryIndex++;
      });
      _loadStory();
    } else {
      _nextUser();
    }
  }

  void _previousStory() {
    if (_currentStoryIndex > 0) {
      setState(() {
        _storyProgress[_currentStoryIndex] = 0.0;
        _currentStoryIndex--;
        _storyProgress[_currentStoryIndex] = 0.0;
      });
      _loadStory();
    } else {
      _previousUser();
    }
  }

  void _nextUser() {
    if (_currentUserIndex < widget.storyGroups.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _previousUser() {
    if (_currentUserIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentUserIndex = index;
      _currentStoryIndex = 0;
    });
    _initializeStoryProgress();
    _loadStory();
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_videoController != null) {
        if (_isPaused) {
          _videoController!.pause();
        } else {
          _videoController!.play();
        }
      }
    });
  }

  void _showViewers() async {
    final currentGroup = widget.storyGroups[_currentUserIndex];
    final story = currentGroup.stories[_currentStoryIndex];
    final currentUser = ref.read(userProvider).currentUser;

    if (currentUser?.id != story.userId) return;

    _togglePause();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _StoryViewersSheet(storyId: story.id),
    );

    _togglePause();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentUser = ref.watch(userProvider).currentUser;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: PageView.builder(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          itemCount: widget.storyGroups.length,
          itemBuilder: (context, index) {
            final group = widget.storyGroups[index];
            final story = group.stories[_currentStoryIndex];
            final isMyStory = currentUser?.id == story.userId;

            return GestureDetector(
              onTapDown: (details) {
                final screenWidth = MediaQuery.of(context).size.width;
                if (details.globalPosition.dx < screenWidth / 2) {
                  _previousStory();
                } else {
                  _nextStory();
                }
              },
              onLongPressStart: (_) => _togglePause(),
              onLongPressEnd: (_) => _togglePause(),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Story Content
                  if (story.isVideo && _videoController != null)
                    Center(
                      child: AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      ),
                    )
                  else
                  // ✅ Image için listener eklendi
                    CachedNetworkImage(
                      imageUrl: story.mediaUrl,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[900],
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      // ✅ Görsel yüklendiğinde timer'ı başlat
                      imageBuilder: (context, imageProvider) {
                        // İlk kez yükleniyorsa timer'ı başlat
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _onImageLoaded();
                        });
                        return Image(
                          image: imageProvider,
                          fit: BoxFit.contain,
                        );
                      },
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[900],
                        child: const Center(
                          child: Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ),
                    ),

                  // ✅ Loading overlay (görsel yüklenene kadar)
                  if (!_isMediaLoaded)
                    Container(
                      color: Colors.black87,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                    ),

                  // Gradient Overlays
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.5),
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black.withOpacity(0.5),
                          ],
                          stops: const [0.0, 0.2, 0.8, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Top Bar
                  SafeArea(
                    child: Column(
                      children: [
                        // Progress Indicators
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          child: Row(
                            children: List.generate(
                              group.stories.length,
                                  (index) => Expanded(
                                child: Container(
                                  height: 3,
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(2),
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: index < _currentStoryIndex
                                        ? 1.0
                                        : index == _currentStoryIndex
                                        ? _storyProgress[index]
                                        : 0.0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(2),
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // User Info
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: story.userProfileImage != null
                                    ? CachedNetworkImageProvider(story.userProfileImage!)
                                    : null,
                                child: story.userProfileImage == null
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      story.username ?? '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      _getTimeAgo(story.createdAt),
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isMyStory)
                                GestureDetector(
                                  onTap: _showViewers,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.visibility, color: Colors.white, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${story.viewCount}',
                                          style: const TextStyle(color: Colors.white, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Pause Indicator
                  if (_isPaused)
                    Center(
                      child: Icon(
                        Icons.pause_circle_filled,
                        color: Colors.white.withOpacity(0.7),
                        size: 80,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inHours < 1) {
      return '${difference.inMinutes}dk önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}s önce';
    } else {
      return '${difference.inDays}g önce';
    }
  }
}

// Story Viewers Bottom Sheet (değişiklik yok, aynı kalıyor)
class _StoryViewersSheet extends ConsumerWidget {
  final int storyId;

  const _StoryViewersSheet({required this.storyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(storyRepositoryProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.visibility_outlined),
                const SizedBox(width: 8),
                Text(
                  'Görüntüleyenler',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: repository.getStoryViewers(storyId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return const Center(child: Text('Görüntüleyen bulunamadı'));
                }

                final viewers = snapshot.data!;

                if (viewers.isEmpty) {
                  return const Center(child: Text('Henüz kimse görüntülemedi'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: viewers.length,
                  itemBuilder: (context, index) {
                    final viewer = viewers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: viewer['profile_image_url'] != null
                            ? CachedNetworkImageProvider(viewer['profile_image_url'])
                            : null,
                        child: viewer['profile_image_url'] == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(viewer['username'] ?? ''),
                      subtitle: Text(viewer['full_name'] ?? ''),
                      trailing: Text(
                        _getTimeAgo(DateTime.parse(viewer['viewed_at'])),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        NavigationService.toNamed(
                          AppRoutes.profile,
                          arguments: {'userId': viewer['user_id']},
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Az önce';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}dk önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}s önce';
    } else {
      return '${difference.inDays}g önce';
    }
  }
}
