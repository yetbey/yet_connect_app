import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yet_x_app/shared/models/user_model.dart';
import 'package:yet_x_app/core/utils/logger_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // Database Bilgileri
  static const int _databaseVersion = 8; // ✅ 7'den 8'e çıkarıldı
  static const String _databaseName = 'yet_x_app.db';
  static const String _usersTable = 'users';
  static const String _postsTable = 'posts';
  static const String _messagesTable = 'messages';
  static const String _chatsTable = 'chats';
  static const String _storiesTable = 'stories';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, _databaseName);
      LogService.i('📂 Veritabanı yolu: $path');
      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onOpen: (db) {
          LogService.i('✅ Veritabanı açıldı');
        },
      );
    } catch (e) {
      LogService.e('❌ Veritabanı başlatma hatası', e);
      rethrow;
    }
  }

  /// --- İlk Veritabanı Oluşturma
  Future<void> _onCreate(Database db, int version) async {
    try {
      LogService.i('🔨 Veritabanı tabloları oluşturuluyor...');

      // Users Table
      await db.execute('''
        CREATE TABLE $_usersTable (
          id TEXT PRIMARY KEY,
          full_name TEXT,
          username TEXT,
          email TEXT,
          phone_number TEXT,
          profile_image_url TEXT,
          bio TEXT,
          followers TEXT,
          following TEXT,
          created_at TEXT,
          cached_at TEXT NOT NULL,
          expires_at TEXT
        )
      ''');

      // Posts Table - ✅ top_likers kolonu eklendi
      await db.execute('''
        CREATE TABLE $_postsTable (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          caption TEXT,
          username TEXT,
          user_full_name TEXT,
          user_profile_image TEXT,
          image_url TEXT,
          video_url TEXT,
          alignment_x REAL DEFAULT 0.0,
          alignment_y REAL DEFAULT 0.0,
          likes_count INTEGER DEFAULT 0,
          comments_count INTEGER DEFAULT 0,
          is_liked INTEGER DEFAULT 0,
          tags TEXT DEFAULT '[]',
          top_likers TEXT,
          created_at TEXT,
          cached_at TEXT NOT NULL,
          expires_at TEXT,
          FOREIGN KEY (user_id) REFERENCES $_usersTable (id) ON DELETE CASCADE
        )
      ''');

      // Messages Table
      await db.execute('''
        CREATE TABLE $_messagesTable (
          id TEXT PRIMARY KEY,
          chat_id TEXT NOT NULL,
          sender_id TEXT NOT NULL,
          receiver_id TEXT,
          content TEXT,
          image_url TEXT,
          is_read INTEGER DEFAULT 0,
          created_at TEXT,
          cached_at TEXT NOT NULL,
          reply_to_message_id TEXT,
          reply_to_content TEXT,
          reply_to_image_url TEXT,
          reply_to_sender_name TEXT,
          FOREIGN KEY (sender_id) REFERENCES $_usersTable (id) ON DELETE CASCADE
        )
      ''');

      // Chats Table
      await db.execute('''
        CREATE TABLE $_chatsTable (
          id TEXT PRIMARY KEY,
          last_message TEXT,
          last_message_at TEXT,
          other_user_id TEXT,
          other_user_name TEXT,
          other_user_image TEXT,
          unread_count INTEGER DEFAULT 0,
          cached_at TEXT NOT NULL
        )
      ''');

      // Stories Table
      await db.execute('''
        CREATE TABLE $_storiesTable (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          username TEXT,
          user_full_name TEXT,
          user_profile_image TEXT,
          media_url TEXT NOT NULL,
          media_type TEXT NOT NULL,
          thumbnail_url TEXT,
          duration INTEGER,
          view_count INTEGER DEFAULT 0,
          is_viewed_by_me INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          expires_at TEXT NOT NULL,
          cached_at TEXT NOT NULL
        )
      ''');

      // Indexes
      await db.execute(
        'CREATE INDEX idx_stories_user_id ON $_storiesTable (user_id)',
      );
      await db.execute(
        'CREATE INDEX idx_stories_expires_at ON $_storiesTable (expires_at DESC)',
      );
      await db.execute(
        'CREATE INDEX idx_posts_user_id ON $_postsTable (user_id)',
      );
      await db.execute(
        'CREATE INDEX idx_posts_created_at ON $_postsTable (created_at DESC)',
      );
      await db.execute(
        'CREATE INDEX idx_messages_chat_id ON $_messagesTable (chat_id)',
      );
      await db.execute(
        'CREATE INDEX idx_messages_created_at ON $_messagesTable (created_at DESC)',
      );
      await db.execute(
        'CREATE INDEX idx_users_username ON $_usersTable (username)',
      );

      LogService.i('✅ Veritabanı tabloları oluşturuldu');
    } catch (e) {
      LogService.e('❌ Tablo oluşturma hatası', e);
      rethrow;
    }
  }

  /// --- When Database is upgraded
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      LogService.i('🔄 Veritabanı güncelleniyor: v$oldVersion -> v$newVersion');

      // Version 1 -> 2
      if (oldVersion < 2) {
        await db.execute('ALTER TABLE $_usersTable ADD COLUMN cached_at TEXT');
        await db.execute('ALTER TABLE $_usersTable ADD COLUMN expires_at TEXT');
        LogService.i('✅ Kullanıcı tablosuna cache alanları eklendi');
      }

      // Version 2 -> 3
      if (oldVersion < 3) {
        try {
          await db.execute(
            'ALTER TABLE $_postsTable ADD COLUMN user_profile_image TEXT',
          );
          await db.execute(
            'ALTER TABLE $_postsTable ADD COLUMN alignment_x REAL DEFAULT 0.0',
          );
          await db.execute(
            'ALTER TABLE $_postsTable ADD COLUMN alignment_y REAL DEFAULT 0.0',
          );
          LogService.i('✅ Posts tablosuna yeni alanlar eklendi');
        } catch (e) {
          LogService.w('⚠️ Posts tablosu güncelleme hatası (zaten var olabilir)');
        }

        try {
          await db.execute('DROP TABLE IF EXISTS ${_messagesTable}_old');
          await db.execute(
            'ALTER TABLE $_messagesTable RENAME TO ${_messagesTable}_old',
          );
          await db.execute('''
            CREATE TABLE $_messagesTable (
              id TEXT PRIMARY KEY,
              chat_id TEXT NOT NULL,
              sender_id TEXT NOT NULL,
              receiver_id TEXT,
              content TEXT,
              image_url TEXT,
              is_read INTEGER DEFAULT 0,
              created_at TEXT,
              cached_at TEXT NOT NULL
            )
          ''');
          await db.execute('''
            INSERT INTO $_messagesTable
            SELECT * FROM ${_messagesTable}_old
          ''');
          await db.execute('DROP TABLE ${_messagesTable}_old');
          LogService.i('✅ Messages tablosu güncellendi');
        } catch (e) {
          LogService.w('⚠️ Messages tablosu güncelleme hatası: $e');
        }
      }

      // Version 3 -> 4
      if (oldVersion < 4) {
        try {
          await db.execute(
            'ALTER TABLE $_chatsTable ADD COLUMN unread_count INTEGER DEFAULT 0',
          );
          LogService.i('✅ Chats tablosuna unread_count eklendi');
        } catch (e) {
          LogService.w('⚠️ unread_count zaten var olabilir: $e');
        }
      }

      // Version 4 -> 5
      if (oldVersion < 5) {
        try {
          await db.execute(
            'ALTER TABLE $_messagesTable ADD COLUMN reply_to_message_id TEXT',
          );
          await db.execute(
            'ALTER TABLE $_messagesTable ADD COLUMN reply_to_content TEXT',
          );
          await db.execute(
            'ALTER TABLE $_messagesTable ADD COLUMN reply_to_image_url TEXT',
          );
          await db.execute(
            'ALTER TABLE $_messagesTable ADD COLUMN reply_to_sender_name TEXT',
          );
          LogService.i('✅ Messages tablosuna reply kolonları eklendi');
        } catch (e) {
          LogService.w('⚠️ Reply kolonları zaten var olabilir: $e');
        }
      }

      // Version 5 -> 6
      if (oldVersion < 6) {
        try {
          final tableInfo = await db.rawQuery('PRAGMA table_info($_postsTable)');
          final hasTagsColumn = tableInfo.any((column) => column['name'] == 'tags');

          if (!hasTagsColumn) {
            await db.execute(
              'ALTER TABLE $_postsTable ADD COLUMN tags TEXT DEFAULT \'[]\'',
            );
            LogService.i('✅ Posts tablosuna tags kolonu eklendi');
          } else {
            LogService.i('ℹ️ Tags kolonu zaten mevcut');
          }
        } catch (e) {
          LogService.w('⚠️ Tags kolonu ekleme hatası: $e');
        }
      }

      // Version 6 -> 7
      if (oldVersion < 7) {
        try {
          await db.execute('''
            CREATE TABLE $_storiesTable (
              id TEXT PRIMARY KEY,
              user_id TEXT NOT NULL,
              username TEXT,
              user_full_name TEXT,
              user_profile_image TEXT,
              media_url TEXT NOT NULL,
              media_type TEXT NOT NULL,
              thumbnail_url TEXT,
              duration INTEGER,
              view_count INTEGER DEFAULT 0,
              is_viewed_by_me INTEGER DEFAULT 0,
              created_at TEXT NOT NULL,
              expires_at TEXT NOT NULL,
              cached_at TEXT NOT NULL
            )
          ''');
          await db.execute(
            'CREATE INDEX idx_stories_user_id ON $_storiesTable (user_id)',
          );
          await db.execute(
            'CREATE INDEX idx_stories_expires_at ON $_storiesTable (expires_at DESC)',
          );
          LogService.i('✅ Stories tablosu oluşturuldu');
        } catch (e) {
          LogService.w('⚠️ Stories tablosu zaten var olabilir: $e');
        }
      }

      // ✅ Version 7 -> 8: top_likers kolonu ekleme
      if (oldVersion < 8) {
        try {
          final tableInfo = await db.rawQuery('PRAGMA table_info($_postsTable)');
          final hasTopLikersColumn = tableInfo.any(
                (column) => column['name'] == 'top_likers',
          );

          if (!hasTopLikersColumn) {
            await db.execute(
              'ALTER TABLE $_postsTable ADD COLUMN top_likers TEXT',
            );
            LogService.i('✅ Posts tablosuna top_likers kolonu eklendi');
          } else {
            LogService.i('ℹ️ top_likers kolonu zaten mevcut');
          }
        } catch (e) {
          LogService.w('⚠️ top_likers kolonu ekleme hatası: $e');
        }
      }
    } catch (e) {
      LogService.e('❌ Veritabanı güncelleme hatası', e);
    }
  }

  // ==================== USER TRANSACTIONS ====================

  Future<void> saveUser(UserModel user, {Duration? cacheDuration}) async {
    try {
      final db = await database;
      final now = DateTime.now();
      final expiresAt = now.add(cacheDuration ?? const Duration(days: 7));

      final userMap = {
        'id': user.id,
        'full_name': user.fullName,
        'username': user.userName,
        'email': user.email,
        'phone_number': user.phoneNumber,
        'profile_image_url': user.profileImageUrl,
        'bio': user.bio,
        'followers': jsonEncode(user.followers),
        'following': jsonEncode(user.following),
        'created_at': user.createdAt?.toIso8601String(),
        'cached_at': now.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
      };

      await db.insert(
        _usersTable,
        userMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      LogService.d('💾 Kullanıcı kaydedildi: ${user.userName}');
    } catch (e) {
      LogService.e('❌ Kullanıcı kaydetme hatası', e);
    }
  }

  Future<UserModel?> getUser(String userId) async {
    try {
      final db = await database;
      final maps = await db.query(_usersTable, where: 'id = ?', whereArgs: [userId]);

      if (maps.isEmpty) return null;

      final map = Map<String, dynamic>.from(maps.first);
      if (map['expires_at'] != null) {
        final expiresAt = DateTime.parse(map['expires_at']);
        if (DateTime.now().isAfter(expiresAt)) {
          LogService.d('⏰ Kullanıcı cache süresi dolmuş: $userId');
          await deleteUser(userId);
          return null;
        }
      }

      map['followers'] = jsonDecode(map['followers'] as String? ?? '[]');
      map['following'] = jsonDecode(map['following'] as String? ?? '[]');
      return UserModel.fromJsonLocal(map);
    } catch (e) {
      LogService.e('❌ Kullanıcı okuma hatası: $userId', e);
      return null;
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      final db = await database;
      await db.delete(_usersTable, where: 'id = ?', whereArgs: [userId]);
      LogService.d('🗑️ Kullanıcı silindi: $userId');
    } catch (e) {
      LogService.e('❌ Kullanıcı silme hatası', e);
    }
  }

  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final db = await database;
      final maps = await db.query(
        _usersTable,
        where: 'username LIKE ?',
        whereArgs: ['%$query%'],
        orderBy: 'username ASC',
        limit: 20,
      );

      return maps.map((map) {
        final userMap = Map<String, dynamic>.from(map);
        userMap['followers'] = jsonDecode(userMap['followers'] as String? ?? '[]');
        userMap['following'] = jsonDecode(userMap['following'] as String? ?? '[]');
        return UserModel.fromJsonLocal(userMap);
      }).toList();
    } catch (e) {
      LogService.e('❌ Kullanıcı arama hatası', e);
      return [];
    }
  }

  // ==================== POST TRANSACTIONS ====================

  /// ✅ Save the posts all - top_likers eklendi
  Future<void> savePosts(
      List<Map<String, dynamic>> posts, {
        bool replaceAll = false,
      }) async {
    try {
      final db = await database;

      if (replaceAll) {
        await db.delete(_postsTable);
        LogService.d('🗑️ Post cache temizlendi');
      }

      final batch = db.batch();
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(hours: 24));

      for (var post in posts) {
        // Tags JSON
        String? tagsJson;
        if (post['tags'] != null) {
          if (post['tags'] is List) {
            tagsJson = jsonEncode(post['tags']);
          } else if (post['tags'] is String) {
            tagsJson = post['tags'];
          }
        }

        // ✅ Top likers JSON
        String? topLikersJson;
        if (post['top_likers'] != null) {
          if (post['top_likers'] is List) {
            topLikersJson = jsonEncode(post['top_likers']);
          } else if (post['top_likers'] is String) {
            topLikersJson = post['top_likers'];
          }
        }

        final postMap = {
          'id': post['id']?.toString() ?? '',
          'user_id': post['user_id']?.toString() ?? '',
          'caption': post['caption']?.toString(),
          'image_url': post['image_url']?.toString(),
          'video_url': post['video_url']?.toString(),
          'created_at': post['created_at']?.toString(),
          'username': post['username']?.toString(),
          'user_full_name': post['user_full_name']?.toString(),
          'user_profile_image': post['user_profile_image']?.toString(),
          'alignment_x': (post['alignment_x'] as num?)?.toDouble() ?? 0.0,
          'alignment_y': (post['alignment_y'] as num?)?.toDouble() ?? 0.0,
          'likes_count': _toInt(
            post['likes'] ?? post['likes_count'] ?? post['like_count'],
          ),
          'is_liked': _toBool(
            post['is_liked_by_current_user'] ??
                post['is_liked_by_user'] ??
                post['is_liked'],
          ),
          'comments_count': _toInt(
            post['comment_count'] ?? post['comments_count'] ?? post['comment_count'],
          ),
          'tags': tagsJson,
          'top_likers': topLikersJson, // ✅ YENİ
          'cached_at': now.toIso8601String(),
          'expires_at': expiresAt.toIso8601String(),
        };

        batch.insert(
          _postsTable,
          postMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
      LogService.d(
        '💾 ${posts.length} post ${replaceAll ? "replace ile" : "incremental"} kaydedildi',
      );
    } catch (e) {
      LogService.e('❌ Post kaydetme hatası', e);
    }
  }

  Future<void> updatePostInCache({
    required String postId,
    int? likes,
    bool? isLiked,
    int? commentCount,
  }) async {
    try {
      final db = await database;
      final updateData = <String, dynamic>{};

      if (likes != null) updateData['likes_count'] = likes;
      if (isLiked != null) updateData['is_liked'] = isLiked ? 1 : 0;
      if (commentCount != null) updateData['comments_count'] = commentCount;

      if (updateData.isEmpty) return;

      final updated = await db.update(
        _postsTable,
        updateData,
        where: 'id = ?',
        whereArgs: [postId],
      );

      if (updated > 0) {
        LogService.d('✅ Post $postId cache\'de güncellendi');
      }
    } catch (e) {
      LogService.e('❌ Post cache güncelleme hatası', e);
    }
  }

  /// ✅ Get Cached Posts - top_likers eklendi
  Future<List<Map<String, dynamic>>> getCachedPosts({int limit = 50}) async {
    try {
      final db = await database;
      await _deleteExpiredPosts();

      final results = await db.query(
        _postsTable,
        orderBy: 'created_at DESC',
        limit: limit,
      );

      return results.map((row) {
        return {
          'id': row['id'],
          'user_id': row['user_id'],
          'caption': row['caption'],
          'image_url': row['image_url'],
          'video_url': row['video_url'],
          'created_at': row['created_at'],
          'username': row['username'],
          'user_full_name': row['user_full_name'],
          'user_profile_image': row['user_profile_image'],
          'alignment_x': row['alignment_x'],
          'alignment_y': row['alignment_y'],
          'likes': row['likes_count'] ?? 0,
          'is_liked_by_current_user': (row['is_liked'] ?? 0) == 1,
          'comment_count': row['comments_count'] ?? 0,
          'tags': row['tags'] ?? '[]',
          'top_likers': row['top_likers'], // ✅ YENİ
        };
      }).toList();
    } catch (e) {
      LogService.e('❌ Post okuma hatası', e);
      return [];
    }
  }

  /// ✅ Get Cached Posts Paginated - top_likers eklendi
  Future<List<Map<String, dynamic>>> getCachedPostsPaginated({
    required int offset,
    required int limit,
  }) async {
    try {
      final db = await database;
      await _deleteExpiredPosts();

      final results = await db.query(
        _postsTable,
        orderBy: 'created_at DESC',
        limit: limit,
        offset: offset,
      );

      return results.map((row) {
        return {
          'id': row['id'],
          'user_id': row['user_id'],
          'caption': row['caption'],
          'image_url': row['image_url'],
          'video_url': row['video_url'],
          'created_at': row['created_at'],
          'username': row['username'],
          'user_full_name': row['user_full_name'],
          'user_profile_image': row['user_profile_image'],
          'alignment_x': row['alignment_x'],
          'alignment_y': row['alignment_y'],
          'likes': row['likes_count'] ?? 0,
          'is_liked_by_current_user': (row['is_liked'] ?? 0) == 1,
          'comment_count': row['comments_count'] ?? 0,
          'tags': row['tags'] ?? '[]',
          'top_likers': row['top_likers'], // ✅ YENİ
        };
      }).toList();
    } catch (e) {
      LogService.e('❌ Paginated cache okuma hatası', e);
      return [];
    }
  }

  /// ✅ Get User Posts - top_likers eklendi
  Future<List<Map<String, dynamic>>> getUserPosts(String userId) async {
    try {
      final db = await database;
      final results = await db.query(
        _postsTable,
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );

      return results.map((row) {
        return {
          'id': row['id'],
          'user_id': row['user_id'],
          'caption': row['caption'],
          'image_url': row['image_url'],
          'video_url': row['video_url'],
          'created_at': row['created_at'],
          'username': row['username'],
          'user_full_name': row['user_full_name'],
          'user_profile_image': row['user_profile_image'],
          'alignment_x': row['alignment_x'],
          'alignment_y': row['alignment_y'],
          'likes': row['likes_count'] ?? 0,
          'is_liked_by_current_user': (row['is_liked'] ?? 0) == 1,
          'comment_count': row['comments_count'] ?? 0,
          'tags': row['tags'] ?? '[]',
          'top_likers': row['top_likers'], // ✅ YENİ
        };
      }).toList();
    } catch (e) {
      LogService.e('❌ Kullanıcı postları okuma hatası', e);
      return [];
    }
  }

  Future<int> getCachedPostCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_postsTable');
      return result.first['count'] as int;
    } catch (e) {
      LogService.e('❌ Cache count hatası', e);
      return 0;
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      final db = await database;
      await db.delete(_postsTable, where: 'id = ?', whereArgs: [postId]);
    } catch (e) {
      LogService.e('❌ Post silme hatası', e);
    }
  }

  Future<void> _deleteExpiredPosts() async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();
      final count = await db.delete(
        _postsTable,
        where: 'expires_at < ?',
        whereArgs: [now],
      );
      if (count > 0) {
        LogService.d('🗑️ $count süresi dolmuş post silindi');
      }
    } catch (e) {
      LogService.e('❌ Expired post silme hatası', e);
    }
  }

  // Helper metodlar
  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  int _toBool(dynamic value) {
    if (value == null) return 0;
    if (value is bool) return value ? 1 : 0;
    if (value is int) return value;
    if (value is String) return value.toLowerCase() == 'true' ? 1 : 0;
    return 0;
  }

  // ==================== MESSAGE TRANSACTIONS ====================

  Future<void> saveMessages(
      String chatId,
      List<Map<String, dynamic>> messages,
      ) async {
    try {
      final db = await database;
      final batch = db.batch();
      final now = DateTime.now().toIso8601String();

      for (var message in messages) {
        final msgMap = {...message, 'chat_id': chatId, 'cached_at': now};
        batch.insert(
          _messagesTable,
          msgMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
      LogService.d('💾 ${messages.length} mesaj kaydedildi');
    } catch (e) {
      LogService.e('❌ Mesaj kaydetme hatası', e);
    }
  }

  Future<List<Map<String, dynamic>>> getChatMessages(
      String chatId, {
        int limit = 100,
      }) async {
    try {
      final db = await database;
      return await db.query(
        _messagesTable,
        where: 'chat_id = ?',
        whereArgs: [chatId],
        orderBy: 'created_at DESC',
        limit: limit,
      );
    } catch (e) {
      LogService.e('❌ Mesaj okuma hatası', e);
      return [];
    }
  }

  // ==================== CHAT TRANSACTIONS ====================

  Future<void> saveChats(List<Map<String, dynamic>> chats) async {
    try {
      final db = await database;
      final batch = db.batch();
      final now = DateTime.now().toIso8601String();

      for (var chat in chats) {
        final chatMap = {...chat, 'cached_at': now};
        batch.insert(
          _chatsTable,
          chatMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
      LogService.d('💾 ${chats.length} chat kaydedildi');
    } catch (e) {
      LogService.e('❌ Chat kaydetme hatası', e);
    }
  }

  Future<List<Map<String, dynamic>>> getCachedChats() async {
    try {
      final db = await database;
      return await db.query(_chatsTable, orderBy: 'last_message_at DESC');
    } catch (e) {
      LogService.e('❌ Chat okuma hatası', e);
      return [];
    }
  }

  Future<void> deleteChat(String chatId) async {
    try {
      final db = await database;
      await db.delete(_chatsTable, where: 'id = ?', whereArgs: [chatId]);
      await db.delete(_messagesTable, where: 'chat_id = ?', whereArgs: [chatId]);
      LogService.d('🗑️ Chat silindi: $chatId');
    } catch (e) {
      LogService.e('❌ Chat silme hatası', e);
    }
  }

  // ==================== STORY TRANSACTIONS ====================

  Future<void> saveStories(List<Map<String, dynamic>> stories) async {
    try {
      final db = await database;
      final batch = db.batch();
      final now = DateTime.now().toIso8601String();

      for (var story in stories) {
        final storyMap = {
          'id': story['id']?.toString() ?? '',
          'user_id': story['user_id']?.toString() ?? '',
          'username': story['username']?.toString(),
          'user_full_name': story['user_full_name']?.toString(),
          'user_profile_image': story['user_profile_image']?.toString(),
          'media_url': story['media_url']?.toString() ?? '',
          'media_type': story['media_type']?.toString() ?? 'image',
          'thumbnail_url': story['thumbnail_url']?.toString(),
          'duration': story['duration'] as int?,
          'view_count': story['view_count'] as int? ?? 0,
          'is_viewed_by_me': _toBool(story['is_viewed_by_me']),
          'created_at': story['created_at']?.toString() ?? now,
          'expires_at': story['expires_at']?.toString() ??
              DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
          'cached_at': now,
        };
        batch.insert(
          _storiesTable,
          storyMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
      LogService.d('💾 ${stories.length} story kaydedildi');
    } catch (e) {
      LogService.e('❌ Story kaydetme hatası', e);
    }
  }

  Future<List<Map<String, dynamic>>> getCachedStories() async {
    try {
      final db = await database;
      await _deleteExpiredStories();

      final results = await db.query(
        _storiesTable,
        orderBy: 'created_at DESC',
      );

      return results.map((row) {
        return {
          'id': int.tryParse(row['id'].toString()) ?? 0,
          'user_id': row['user_id'],
          'username': row['username'],
          'user_full_name': row['user_full_name'],
          'user_profile_image': row['user_profile_image'],
          'media_url': row['media_url'],
          'media_type': row['media_type'],
          'thumbnail_url': row['thumbnail_url'],
          'duration': row['duration'],
          'view_count': row['view_count'],
          'is_viewed_by_me': (row['is_viewed_by_me'] ?? 0) == 1,
          'created_at': row['created_at'],
          'expires_at': row['expires_at'],
        };
      }).toList();
    } catch (e) {
      LogService.e('❌ Story okuma hatası', e);
      return [];
    }
  }

  Future<void> _deleteExpiredStories() async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();
      final count = await db.delete(
        _storiesTable,
        where: 'expires_at < ?',
        whereArgs: [now],
      );
      if (count > 0) {
        LogService.d('🗑️ $count süresi dolmuş story silindi');
      }
    } catch (e) {
      LogService.e('❌ Expired story silme hatası', e);
    }
  }

  // ==================== CLEAR TRANSACTIONS ====================

  Future<void> cleanExpiredData() async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();

      final userCount = await db.delete(
        _usersTable,
        where: 'expires_at IS NOT NULL AND expires_at < ?',
        whereArgs: [now],
      );

      await _deleteExpiredPosts();

      final oldDate =
      DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
      final msgCount = await db.delete(
        _messagesTable,
        where: 'cached_at < ?',
        whereArgs: [oldDate],
      );

      LogService.i(
        '🧹 Cache temizlendi: $userCount kullanıcı, $msgCount mesaj silindi',
      );
    } catch (e) {
      LogService.e('❌ Cache temizleme hatası', e);
    }
  }

  Future<void> clearAllData() async {
    try {
      final db = await database;
      await db.delete(_usersTable);
      await db.delete(_postsTable);
      await db.delete(_messagesTable);
      await db.delete(_chatsTable);
      await db.delete(_storiesTable);
      LogService.i('🧹 Tüm veritabanı temizlendi');
    } catch (e) {
      LogService.e('❌ Veritabanı temizleme hatası', e);
    }
  }

  Future<Map<String, int>> getDatabaseStats() async {
    try {
      final db = await database;

      final userCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $_usersTable'),
      ) ?? 0;

      final postCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $_postsTable'),
      ) ?? 0;

      final messageCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $_messagesTable'),
      ) ?? 0;

      final chatCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $_chatsTable'),
      ) ?? 0;

      final storyCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $_storiesTable'),
      ) ?? 0;

      return {
        'users': userCount,
        'posts': postCount,
        'messages': messageCount,
        'chats': chatCount,
        'stories': storyCount,
      };
    } catch (e) {
      LogService.e('❌ İstatistik alma hatası', e);
      return {};
    }
  }

  Future<void> closeDatabase() async {
    try {
      final db = await database;
      await db.close();
      _database = null;
      LogService.i('🔒 Veritabanı kapatıldı');
    } catch (e) {
      LogService.e('❌ Veritabanı kapatma hatası', e);
    }
  }
}

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});
