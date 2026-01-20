// lib/features/settings/presentation/widgets/color_scheme_selector.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yet_x_app/features/settings/presentation/providers/theme_provider.dart';

class ColorSchemeSelector extends ConsumerWidget {
  const ColorSchemeSelector({super.key});

  // ✅ Color preview map
  static const Map<String, Color> _schemeColors = {
    'Mavi': Color(0xFF2196F3),
    'Indigo': Color(0xFF3F51B5),
    'Hippie Blue': Color(0xFF4FC3F7),
    'Aqua Blue': Color(0xFF00BCD4),
    'Yeşil': Color(0xFF4CAF50),
    'Kırmızı': Color(0xFFF44336),
    'Mor': Color(0xFF673AB7),
    'Pembe': Color(0xFFE91E63),
    'Turuncu': Color(0xFFFF9800),
    'Amber': Color(0xFFFFC107),
    'Kahverengi': Color(0xFF795548),
    'Gri': Color(0xFF9E9E9E),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Renk Teması',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: ThemeNotifier.colorSchemes.length,
          itemBuilder: (context, index) {
            final schemeName = ThemeNotifier.colorSchemes.keys.elementAt(index);
            final isSelected = themeState.selectedScheme == schemeName;

            return _ColorSchemeItem(
              name: schemeName,
              color: _schemeColors[schemeName] ?? Colors.blue,
              isSelected: isSelected,
              onTap: () {
                themeNotifier.changeColorScheme(schemeName);
              },
            );
          },
        ),
      ],
    );
  }
}

class _ColorSchemeItem extends StatelessWidget {
  final String name;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorSchemeItem({
    required this.name,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 12,
                spreadRadius: 2,
              ),
          ],
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 28)
            : null,
      ),
    );
  }
}
