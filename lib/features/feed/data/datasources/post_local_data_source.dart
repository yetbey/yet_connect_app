import 'package:yet_x_app/core/services/database_service.dart';
import 'package:yet_x_app/features/feed/data/models/post_model.dart';

abstract class PostLocalDataSource {
  Future<List<PostModel>> getCachedFeed({int limit = 50});
  Future<List<PostModel>> getUserPosts(String userId);
  Future<void> cachePosts(List<PostModel> posts, {bool replaceAll = false});
  Future<void> deletePost(String postId);
  Future<void> updatePost(
    String postId, {
    int? likes,
    bool? isLiked,
    int? commentCount,
  });
}

class PostLocalDataSourceImpl implements PostLocalDataSource {
  final DatabaseService _dbService;

  PostLocalDataSourceImpl(this._dbService);

  @override
  Future<List<PostModel>> getCachedFeed({int limit = 50}) async {
    final result = await _dbService.getCachedPosts(limit: limit);
    return result.map((e) => PostModel.fromJsonLocal(e)).toList();
  }

  @override
  Future<List<PostModel>> getUserPosts(String userId) async {
    final result = await _dbService.getUserPosts(userId);
    return result.map((e) => PostModel.fromJsonLocal(e)).toList();
  }

  @override
  Future<void> cachePosts(
    List<PostModel> posts, {
    bool replaceAll = false,
  }) async {
    await _dbService.savePosts(
      posts.map((e) => e.toJson()).toList(),
      replaceAll: replaceAll, // ✅ Parametre geçir
    );
  }

  @override
  Future<void> deletePost(String postId) async {
    await _dbService.deletePost(postId);
  }

  @override
  Future<void> updatePost(
    String postId, {
    int? likes,
    bool? isLiked,
    int? commentCount,
  }) async {
    await _dbService.updatePostInCache(
      postId: postId,
      likes: likes,
      isLiked: isLiked,
      commentCount: commentCount,
    );
  }
}
