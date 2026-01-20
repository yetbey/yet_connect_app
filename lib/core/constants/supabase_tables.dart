// lib/core/constants/supabase_tables.dart

/// Base abstract class for all tables
abstract class SupabaseTable {
  const SupabaseTable();
  String get tableName;
}

/// Profiles table
class ProfilesTable implements SupabaseTable {
  const ProfilesTable();

  @override
  String get tableName => 'profiles';

  String get id => 'id';
  String get username => 'username';
  String get fullName => 'full_name';
  String get bio => 'bio';
  String get profileImageUrl => 'profile_image_url';
  String get phoneNumber => 'phone_number';
  String get createdAt => 'created_at';
}

/// Posts table
class PostsTable implements SupabaseTable {
  const PostsTable();

  @override
  String get tableName => 'posts';

  String get id => 'id';
  String get caption => 'caption';
  String get imageUrl => 'image_url';
  String get videoUrl => 'video_url';
  String get userId => 'user_id';
  String get alignmentX => 'alignment_x';
  String get alignmentY => 'alignment_y';
  String get tags => 'tags';
  String get createdAt => 'created_at';
}

/// Comments table
class CommentsTable implements SupabaseTable {
  const CommentsTable();

  @override
  String get tableName => 'comments';

  String get id => 'id';
  String get content => 'content';
  String get userId => 'user_id';
  String get postId => 'post_id';
  String get createdAt => 'created_at';
}

/// Post Likes table
class PostLikesTable implements SupabaseTable {
  const PostLikesTable();

  @override
  String get tableName => 'post_likes';

  String get userId => 'user_id';
  String get postId => 'post_id';
  String get createdAt => 'created_at';
}

/// Follows table
class FollowsTable implements SupabaseTable {
  const FollowsTable();

  @override
  String get tableName => 'follows';

  String get followerId => 'follower_id';
  String get followingId => 'following_id';
  String get createdAt => 'created_at';
}

/// Tags table
class TagsTable implements SupabaseTable {
  const TagsTable();

  @override
  String get tableName => 'tags';

  String get id => 'id';
  String get name => 'name';
  String get postCount => 'post_count';
  String get createdAt => 'created_at';
  String get updatedAt => 'updated_at';
}

/// Tag Follows table
class TagFollowsTable implements SupabaseTable {
  const TagFollowsTable();

  @override
  String get tableName => 'tag_follows';

  String get userId => 'user_id';
  String get tagName => 'tag_name';
  String get createdAt => 'created_at';
}

/// Chats table
class ChatsTable implements SupabaseTable {
  const ChatsTable();

  @override
  String get tableName => 'chats';

  String get id => 'id';
  String get lastMessage => 'last_message';
  String get lastMessageAt => 'last_message_at';
  String get createdAt => 'created_at';
}

/// Chat Participants table
class ChatParticipantsTable implements SupabaseTable {
  const ChatParticipantsTable();

  @override
  String get tableName => 'chat_participants';

  String get id => 'id';
  String get chatId => 'chat_id';
  String get userId => 'user_id';
  String get createdAt => 'created_at';
  String get deletedAt => 'deleted_at';
}

/// Messages table
class MessagesTable implements SupabaseTable {
  const MessagesTable();

  @override
  String get tableName => 'messages';

  String get id => 'id';
  String get content => 'content';
  String get imageUrl => 'image_url';
  String get senderId => 'sender_id';
  String get receiverId => 'receiver_id';
  String get chatId => 'chat_id';
  String get isRead => 'is_read';
  String get replyToId => 'reply_to_id';
  String get replyToMessageId => 'reply_to_message_id';
  String get replyToContent => 'reply_to_content';
  String get replyToImageUrl => 'reply_to_image_url';
  String get replyToSenderName => 'reply_to_sender_name';
  String get createdAt => 'created_at';
}

/// Notifications table
class NotificationsTable implements SupabaseTable {
  const NotificationsTable();

  @override
  String get tableName => 'notifications';

  String get id => 'id';
  String get type => 'type';
  String get message => 'message';
  String get isRead => 'is_read';
  String get receiverId => 'receiver_id';
  String get senderId => 'sender_id';
  String get postId => 'post_id';
  String get createdAt => 'created_at';
}

/// Login Sessions table
class LoginSessionsTable implements SupabaseTable {
  const LoginSessionsTable();

  @override
  String get tableName => 'login_sessions';

  String get id => 'id';
  String get sessionToken => 'session_token';
  String get userId => 'user_id';
  String get isAuthenticated => 'is_authenticated';
  String get deviceInfo => 'device_info';
  String get createdAt => 'created_at';
  String get expiresAt => 'expires_at';
}

/// App Versions table
class AppVersionsTable implements SupabaseTable {
  const AppVersionsTable();

  @override
  String get tableName => 'app_versions';

  String get id => 'id';
  String get version => 'version';
  String get downloadUrl => 'download_url';
  String get isMandatory => 'is_mandatory';
  String get createdAt => 'created_at';
}

// ============================================
// Storage Fields
// ============================================
class Uploads implements SupabaseTable {
  const Uploads();

  @override
  String get tableName => 'uploads';
}

// ============================================
// RPC Functions
// ============================================

abstract class SupabaseRpc {
  // User Operations
  static const String deleteUserAccount = 'delete_user_account';
}

// ============================================
// Global Table Instances
// ============================================

const profilesTable = ProfilesTable();
const postsTable = PostsTable();
const commentsTable = CommentsTable();
const postLikesTable = PostLikesTable();
const followsTable = FollowsTable();
const tagsTable = TagsTable();
const tagFollowsTable = TagFollowsTable();
const chatsTable = ChatsTable();
const chatParticipantsTable = ChatParticipantsTable();
const messagesTable = MessagesTable();
const notificationsTable = NotificationsTable();
const loginSessionsTable = LoginSessionsTable();
const appVersionsTable = AppVersionsTable();
const uploadsStorage = Uploads();

/// Rpc Functions Names
String get deleteUserAccount => 'delete_user_account';
