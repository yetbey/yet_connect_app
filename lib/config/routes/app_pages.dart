import 'package:flutter/material.dart';
import 'package:yet_x_app/config/routes/app_routes.dart';
import 'package:yet_x_app/features/auth/presentation/pages/auth_wrapper.dart';
import 'package:yet_x_app/features/auth/presentation/pages/change_password_page.dart';
import 'package:yet_x_app/features/auth/presentation/pages/email_verification_page.dart';
import 'package:yet_x_app/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:yet_x_app/features/auth/presentation/pages/login_page.dart';
import 'package:yet_x_app/features/auth/presentation/pages/register_page.dart';
import 'package:yet_x_app/features/auth/presentation/pages/start_page.dart';
import 'package:yet_x_app/features/auth/presentation/pages/verify_reset_otp_page.dart';
import 'package:yet_x_app/features/chat/presentation/pages/chat_detail_page.dart';
import 'package:yet_x_app/features/chat/presentation/pages/chat_list_page.dart';
import 'package:yet_x_app/features/chat/presentation/widgets/image_viewer/full_screen_image_viewer.dart';
import 'package:yet_x_app/features/dashboard/presentation/pages/navigation_page.dart';
import 'package:yet_x_app/features/feed/presentation/pages/create_post_page.dart';
import 'package:yet_x_app/features/feed/presentation/pages/detailed_post_page.dart';
import 'package:yet_x_app/features/feed/presentation/pages/edit_profile_page.dart';
import 'package:yet_x_app/features/feed/presentation/pages/explore_page.dart';
import 'package:yet_x_app/features/feed/presentation/pages/follow_list_page.dart';
import 'package:yet_x_app/features/feed/presentation/pages/full_screen_video_viewer.dart';
import 'package:yet_x_app/features/feed/presentation/pages/search_page.dart';
import 'package:yet_x_app/features/feed/presentation/pages/tag_posts_page.dart';
import 'package:yet_x_app/features/notifications/presentation/pages/notifications_page.dart';
import 'package:yet_x_app/features/profile/presentation/pages/profile_page.dart';
import 'package:yet_x_app/features/scrabble/presentation/screens/scrabble_game_screen.dart';
import 'package:yet_x_app/features/scrabble/presentation/screens/scrabble_lobby_screen.dart';
import 'package:yet_x_app/features/settings/presentation/pages/settings_page.dart';

import '../../features/story/presentation/pages/create_story_page.dart';
import '../../features/story/presentation/pages/story_viewer_page.dart';

class AppPages {
  static Map<String, WidgetBuilder> get routes {
    return {
      AppRoutes.start: (context) => const StartPage(),
      AppRoutes.authWrapper: (context) => const AuthWrapper(),
      AppRoutes.login: (context) => const LoginPage(),
      AppRoutes.register: (context) => const RegisterPage(),
      AppRoutes.home: (context) => const NavigationPage(),
      AppRoutes.chatList: (context) => const ChatListPage(),
      AppRoutes.createPost: (context) => const CreatePostScreen(),
      AppRoutes.explore: (context) => const HomePage(),
      AppRoutes.search: (context) => const SearchPage(),
      AppRoutes.editProfile: (context) => const EditProfilePage(),
      AppRoutes.settings: (context) => const SettingsPage(),
      AppRoutes.forgotPassword: (context) => const ForgotPasswordPage(),
      AppRoutes.changePassword: (context) => const ChangePasswordPage(),
      AppRoutes.scrabbleLobby: (context) => const ScrabbleLobbyScreen(),
    };
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Chat Detail Page
      case AppRoutes.chatDetail:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (context) => ChatDetailPage(
            chatId: args['chatId'],
            otherUser: args['otherUser'],
          ),
          settings: settings,
        );

      // Follow List Page
      case AppRoutes.followList:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (context) => FollowerListPage(
            userId: args['userId'],
            initialTabIndex: args['initialTabIndex'],
          ),
          settings: settings,
        );

      // Detailed Post Page
      case AppRoutes.detailedPost:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (context) => DetailedPostPage(post: args['post']),
          settings: settings,
        );

      // Full Image Viewer Page
      case AppRoutes.fullImageViewer:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (context) =>
              FullScreenImageViewer(imageUrl: args['imageUrl']),
          settings: settings,
        );

      //
      case AppRoutes.notifications:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (context) => NotificationsPage(userId: args['userId']),
          settings: settings,
        );

      // Full Screeen Video Viewer
      case AppRoutes.fullVideoViewer:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (context) => FullScreenVideoViewer(post: args['post']),
          settings: settings,
          fullscreenDialog: true,
        );

      // Profile Page
      case AppRoutes.profile:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (context) => ProfilePage(userId: args['userId']),
          settings: settings,
        );

      case AppRoutes.emailVerification:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (context) => EmailVerificationPage(email: args['email']),
          settings: settings,
        );

      case AppRoutes.verifyResetOtp:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (context) => VerifyResetOtpPage(email: args['email']),
        );

      case AppRoutes.scrabbleGame:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (context) => ScrabbleGameScreen(roomId: args['roomId'] as String, userId: args['userId'] as String),
        );

      case AppRoutes.tagPosts:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (context) => TagPostsPage(tag: args['tag']),
          settings: settings,
        );

      case AppRoutes.storyViewer:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(builder: (context) => StoryViewerPage(
          storyGroups: args['storyGroups'],
          initialIndex: args['initialIndex'] ?? 0,
        ),
          settings: settings,
          fullscreenDialog: true,
        );

      case AppRoutes.createStory:
        return MaterialPageRoute(builder: (context) => const CreateStoryPage(), fullscreenDialog: true);

      default:
        return null;
    }
  }

  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (context) => const NotFoundPage(),
      settings: settings,
    );
  }
}

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sayfa Bulunamadı'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              '404',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sayfa bulunamadı',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
              },
              icon: const Icon(Icons.home),
              label: const Text('Ana Sayfaya Dön'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
