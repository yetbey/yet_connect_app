import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:yet_x_app/features/profile/presentation/providers/user_provider.dart';
import 'package:yet_x_app/features/story/presentation/providers/story_provider.dart';

class CreateStoryPage extends ConsumerStatefulWidget {
  const CreateStoryPage({super.key});

  @override
  ConsumerState<CreateStoryPage> createState() => _CreateStoryPageState();
}

class _CreateStoryPageState extends ConsumerState<CreateStoryPage> {
  File? _mediaFile;
  String _mediaType = 'image';
  VideoPlayerController? _videoController;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _pickMedia(ImageSource source, {bool isVideo = false}) async {
    try {
      final XFile? file = isVideo
          ? await _picker.pickVideo(source: source, maxDuration: const Duration(seconds: 30))
          : await _picker.pickImage(source: source);

      if (file != null) {
        setState(() {
          _mediaFile = File(file.path);
          _mediaType = isVideo ? 'video' : 'image';
        });

        if (isVideo) {
          _videoController = VideoPlayerController.file(_mediaFile!);
          await _videoController!.initialize();
          await _videoController!.setLooping(true);
          await _videoController!.play();
          setState(() {});
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Medya seçimi hatası: $e')),
      );
    }
  }

  Future<void> _uploadStory() async {
    if (_mediaFile == null) return;

    final currentUser = ref.read(userProvider).currentUser;
    if (currentUser == null) return;

    HapticFeedback.mediumImpact();

    await ref.read(createStoryProvider.notifier).createStory(
      userId: currentUser.id,
      mediaFile: _mediaFile!,
      mediaType: _mediaType,
      duration: _videoController?.value.duration.inMilliseconds,
    );

    final state = ref.read(createStoryProvider);

    if (!mounted) return;

    if (state.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: ${state.error}'),
          backgroundColor: Colors.red,
        ),
      );
    } else if (state.createdStory != null) {
      // Story'leri yenile
      ref.invalidate(followingStoriesProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Story paylaşıldı! 🎉'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final state = ref.watch(createStoryProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Story Oluştur',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          if (_mediaFile != null)
            TextButton(
              onPressed: state.isLoading ? null : _uploadStory,
              child: state.isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text(
                'Paylaş',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: _mediaFile == null
          ? _buildMediaPicker(colorScheme)
          : _buildPreview(colorScheme),
    );
  }

  Widget _buildMediaPicker(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 80,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 32),
          const Text(
            'Bir fotoğraf veya video seç',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 48),

          // Photo Button
          _MediaPickerButton(
            icon: Icons.photo_library_outlined,
            label: 'Galeriden Fotoğraf',
            color: colorScheme.primary,
            onTap: () => _pickMedia(ImageSource.gallery, isVideo: false),
          ),

          const SizedBox(height: 16),

          // Video Button
          _MediaPickerButton(
            icon: Icons.video_library_outlined,
            label: 'Galeriden Video',
            color: colorScheme.secondary,
            onTap: () => _pickMedia(ImageSource.gallery, isVideo: true),
          ),

          const SizedBox(height: 16),

          // Camera Button
          _MediaPickerButton(
            icon: Icons.camera_alt_outlined,
            label: 'Kamera',
            color: colorScheme.tertiary,
            onTap: () => _pickMedia(ImageSource.camera, isVideo: false),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(ColorScheme colorScheme) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Preview Content
        if (_mediaType == 'video' && _videoController != null)
          Center(
            child: AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
          )
        else if (_mediaType == 'image')
          Image.file(
            _mediaFile!,
            fit: BoxFit.contain,
          ),

        // Bottom Actions
        Positioned(
          bottom: 32,
          left: 16,
          right: 16,
          child: Row(
            children: [
              // Change Media Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _mediaFile = null;
                      _videoController?.dispose();
                      _videoController = null;
                    });
                  },
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Değiştir'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MediaPickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MediaPickerButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 280,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.8),
              color.withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
