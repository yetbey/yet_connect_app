import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yet_x_app/config/theme/app_text_styles.dart';
import 'package:yet_x_app/core/services/custom_cache_manager.dart';
import 'package:yet_x_app/features/profile/presentation/providers/user_provider.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  late TextEditingController nameController;
  late TextEditingController bioController;
  File? newImageFile;

  @override
  void initState() {
    super.initState();
    // Mevcut kullanıcı verisini provider'dan al
    final user = ref.read(userProvider).currentUser;
    nameController = TextEditingController(text: user?.fullName ?? '');
    bioController = TextEditingController(text: user?.bio ?? '');
  }

  @override
  void dispose() {
    nameController.dispose();
    bioController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final XFile? img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      setState(() => newImageFile = File(img.path));
    }
  }

  Future<void> _saveProfile() async {
    final notifier = ref.read(userProvider.notifier);

    // 1. Metin bilgilerini güncelle
    await notifier.updateUserProfile(
      fullName: nameController.text.trim(),
      bio: bioController.text.trim(),
    );

    // 2. Resim seçildiyse güncelle
    if (newImageFile != null) {
      await notifier.updateProfileImage(newImageFile!);
    }
  }

  @override
  Widget build(BuildContext context) {
    // User state'ini dinle (Değişiklikleri anlık görmek için)
    final userState = ref.watch(userProvider);
    final user = userState.currentUser;
    final imageUrl = user?.profileImageUrl;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) {
          FocusScope.of(context).unfocus();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Profili Düzenle')),
        body: userState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20.0),
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: newImageFile != null
                              ? FileImage(newImageFile!)
                              : (imageUrl != null && imageUrl.isNotEmpty
                                        ? CachedNetworkImageProvider(
                                            imageUrl,
                                            cacheManager:
                                                CustomImageCacheManager(),
                                          )
                                        : null)
                                    as ImageProvider<Object>?,
                          child:
                              (imageUrl == null || imageUrl.isEmpty) &&
                                  newImageFile == null
                              ? const Icon(Icons.person, size: 50)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            radius: 18,
                            child: IconButton(
                              icon: const Icon(
                                Icons.edit,
                                size: 18,
                                color: Colors.white,
                              ),
                              onPressed: pickImage,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: nameController,
                    style: AppTextStyles.bodyMedium,
                    decoration: const InputDecoration(
                      labelText: 'Ad Soyad',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: bioController,
                    style: AppTextStyles.bodyMedium,
                    maxLines: 3,
                    minLines: 1,
                    decoration: const InputDecoration(
                      labelText: 'Biyografi',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text(
                        'Kaydet',
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
