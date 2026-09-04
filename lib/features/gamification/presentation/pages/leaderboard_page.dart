import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:yet_x_app/core/constants/app_colors.dart';
import 'package:yet_x_app/features/gamification/presentation/providers/leaderboard_provider.dart';

class LeaderboardPage extends ConsumerWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(leaderboardProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          '🏆 Liderlik Tablosu',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
      ),
      body: Column(
        children: [
          // Period Tabs
          _buildPeriodTabs(context, ref, state.period),

          // Leaderboard List
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.leaderboard.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
              onRefresh: () => ref.read(leaderboardProvider.notifier).refresh(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.leaderboard.length,
                itemBuilder: (context, index) {
                  final user = state.leaderboard[index];
                  return _buildLeaderboardItem(
                    context,
                    user,
                    index + 1,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodTabs(BuildContext context, WidgetRef ref, String currentPeriod) {
    final periods = [
      {'id': 'all_time', 'label': 'Tüm Zamanlar'},
      {'id': 'monthly', 'label': 'Bu Ay'},
      {'id': 'weekly', 'label': 'Bu Hafta'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: periods.map((period) {
          final isSelected = currentPeriod == period['id'];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                ref.read(leaderboardProvider.notifier).changePeriod(period['id']!);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF9C27B0)],
                  )
                      : null,
                  color: isSelected ? null : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  period['label']!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLeaderboardItem(BuildContext context, Map<String, dynamic> user, int position) {
    final theme = Theme.of(context);
    final isTopThree = position <= 3;

    Color? medalColor;
    IconData? medalIcon;

    if (position == 1) {
      medalColor = const Color(0xFFFFD700); // Gold
      medalIcon = Icons.emoji_events;
    } else if (position == 2) {
      medalColor = const Color(0xFFC0C0C0); // Silver
      medalIcon = Icons.emoji_events;
    } else if (position == 3) {
      medalColor = const Color(0xFFCD7F32); // Bronze
      medalIcon = Icons.emoji_events;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isTopThree
            ? LinearGradient(
          colors: [
            medalColor!.withValues(alpha: 0.1),
            medalColor.withValues(alpha: 0.05),
          ],
        )
            : null,
        color: isTopThree ? null : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: isTopThree
            ? Border.all(color: medalColor!, width: 2)
            : null,
      ),
      child: Row(
        children: [
          // Position
          SizedBox(
            width: 40,
            child: isTopThree && medalIcon != null
                ? Icon(medalIcon, color: medalColor, size: 32)
                : Text(
              '#$position',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundImage: user['profile_image_url'] != null
                ? CachedNetworkImageProvider(user['profile_image_url'])
                : null,
            child: user['profile_image_url'] == null
                ? Text(
              (user['username'] as String?)?.substring(0, 1).toUpperCase() ?? '?',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            )
                : null,
          ),

          const SizedBox(width: 12),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['full_name'] ?? user['username'] ?? 'Anonim',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (user['username'] != null)
                  Text(
                    '@${user['username']}',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Points
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${user['total_points']} XP',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isTopThree ? medalColor : AppColors.primary,
                ),
              ),
              if (user['rank_display_name'] != null)
                Text(
                  user['rank_display_name'],
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.leaderboard, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Henüz kimse yok',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
