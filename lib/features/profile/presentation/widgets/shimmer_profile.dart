import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerProfile extends StatelessWidget {
  const ShimmerProfile({super.key});

  static const _spacing8 = SizedBox(height: 8);
  static const _spacing16 = SizedBox(height: 16);
  static const _spacing24 = SizedBox(height: 24);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: const SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profil başlığı iskeleti
              _ProfileHeader(),
              _spacing8,
              // İsim ve buton iskeleti
              _NamePlaceholder(),
              _spacing16,
              _ButtonPlaceholder(),
              _spacing24,
              // Gönderi listesi iskeleti
              _DividerPlaceholder(),
              _spacing8,
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        CircleAvatar(radius: 40, backgroundColor: Colors.white),
        SizedBox(width: 20),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatPlaceholder(),
              _StatPlaceholder(),
              _StatPlaceholder(),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatPlaceholder extends StatelessWidget {
  const _StatPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(width: 30, height: 18, color: Colors.white),
        const SizedBox(height: 4),
        Container(width: 50, height: 14, color: Colors.white),
      ],
    );
  }
}

class _NamePlaceholder extends StatelessWidget {
  const _NamePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(width: 150, height: 20, color: Colors.white);
  }
}

class _ButtonPlaceholder extends StatelessWidget {
  const _ButtonPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _DividerPlaceholder extends StatelessWidget {
  const _DividerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(width: double.infinity, height: 1, color: Colors.grey);
  }
}
