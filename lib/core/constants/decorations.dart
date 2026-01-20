import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:yet_x_app/config/theme/app_text_styles.dart';
import 'app_colors.dart';

// ═══════════════════════════════════════════════════════════════════════
// 🎨 BUTTONS
// ═══════════════════════════════════════════════════════════════════════

/// Auth button style with modern elevation and colors
ButtonStyle kAuthButtonStyle(
  BuildContext context, {
  bool? isStartPage = false,
}) {
  isStartPage ??= false;
  return ElevatedButton.styleFrom(
    elevation: 4,
    backgroundColor: !isStartPage
        ? Theme.of(context).buttonTheme.colorScheme!.surface
        : AppColors.cardColor, // ✨ Colors.grey → AppColors.cardColor
    foregroundColor: Theme.of(context).colorScheme.onSurface,
    minimumSize: const Size(double.infinity, 50),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    shadowColor: AppColors.shadow, // ✨ Eklendi
  );
}

// ═══════════════════════════════════════════════════════════════════════
// 📝 INPUT DECORATIONS
// ═══════════════════════════════════════════════════════════════════════

/// Auth text form field decoration with modern styling
InputDecoration kAuthTextFormFieldDecoration(
  BuildContext context, {
  String? hintText = '',
}) {
  hintText ??= '';
  return InputDecoration(
    contentPadding: const EdgeInsets.all(18),
    hintText: hintText,
    fillColor: Theme.of(
      context,
    ).colorScheme.surfaceContainerHighest, // ✨ Güncellendi
    focusColor: Theme.of(context).colorScheme.primary, // ✨ Güncellendi
    hoverColor: Theme.of(
      context,
    ).colorScheme.surfaceContainerHigh, // ✨ Güncellendi
    hintStyle: AppTextStyles.bodyMedium.copyWith(
      // ✨ Güncellendi
      color: AppColors.textHint,
    ),
    border: OutlineInputBorder(
      borderSide: const BorderSide(
        color: AppColors.divider,
      ), // ✨ Colors.red → AppColors.divider
      borderRadius: BorderRadius.circular(12),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: AppColors.divider), // ✨ Eklendi
      borderRadius: BorderRadius.circular(12),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(
        color: AppColors.primary,
        width: 2,
      ), // ✨ Eklendi
      borderRadius: BorderRadius.circular(12),
    ),
    errorBorder: OutlineInputBorder(
      // ✨ Eklendi
      borderSide: const BorderSide(color: AppColors.error),
      borderRadius: BorderRadius.circular(12),
    ),
  );
}

/// Message text field decoration
const kMessageTextFieldDecoration = InputDecoration(
  contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
  hintText: 'Mesaj Gönder ...',
  hintStyle: TextStyle(color: AppColors.textHint), // ✨ Eklendi
  border: InputBorder.none,
);

/// General text field decoration
const kTextFieldDecoration = InputDecoration(
  hintText: 'Enter your value.',
  hintStyle: TextStyle(color: AppColors.textHint), // ✨ Eklendi
  contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(32.0)),
  ),
  enabledBorder: OutlineInputBorder(
    borderSide: BorderSide(
      color: AppColors.divider,
      width: 1.0,
    ), // ✨ Güncellendi
    borderRadius: BorderRadius.all(Radius.circular(32.0)),
  ),
  focusedBorder: OutlineInputBorder(
    borderSide: BorderSide(color: AppColors.primary, width: 2.0),
    borderRadius: BorderRadius.all(Radius.circular(32.0)),
  ),
);

// ═══════════════════════════════════════════════════════════════════════
// 📦 BOX DECORATIONS
// ═══════════════════════════════════════════════════════════════════════

/// Message container decoration
const kMessageContainerDecoration = BoxDecoration(
  border: Border(top: BorderSide(color: AppColors.primary, width: 2.0)),
);

/// Media feed card decoration with shadow
BoxDecoration kMediaFeedCardBoxDecoration(BuildContext context) {
  return BoxDecoration(
    color: Theme.of(context).cardColor, // ✨ Güncellendi
    borderRadius: BorderRadius.circular(16), // ✨ Eklendi
    boxShadow: const [
      BoxShadow(
        color: AppColors.shadow, // ✨ Güncellendi
        blurRadius: 8, // ✨ 15 → 8
        offset: Offset(0, 4), // ✨ 0,8 → 0,4
      ),
    ],
  );
}

/// Profile image decoration for text feed card
BoxDecoration kProfileImageTextFeedCardBoxDecoration(BuildContext context) {
  return BoxDecoration(
    color: AppColors.cardColor.withAlpha(51), // ✨ Güncellendi
    shape: BoxShape.circle,
    border: Border.all(
      color: AppColors.divider, // ✨ Güncellendi
      width: 1.5, // ✨ Eklendi
    ),
  );
}

/// Shimmer feed card decoration
BoxDecoration kShimmerFeedCardBoxDecoration(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return BoxDecoration(
    color: isDark ? AppColors.cardColor : Colors.grey[200], // ✨ Güncellendi
    borderRadius: BorderRadius.circular(16), // ✨ 24 → 16
    boxShadow: const [
      BoxShadow(
        color: AppColors.shadow, // ✨ Güncellendi
        blurRadius: 8, // ✨ 10 → 8
        offset: Offset(0, 4), // ✨ 0,5 → 0,4
      ),
    ],
  );
}

/// Shimmer feed card image field decoration
BoxDecoration kShimmerFeedCardImageFieldBoxDecoration(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return BoxDecoration(
    color: isDark ? AppColors.cardColor : Colors.grey[300], // ✨ Güncellendi
    borderRadius: const BorderRadius.vertical(
      top: Radius.circular(16), // ✨ 24 → 16
    ),
  );
}

/// Likes bottom sheet decoration
BoxDecoration kLikesBottomSheetBoxDecoration(BuildContext context) {
  return BoxDecoration(
    color: Theme.of(context).scaffoldBackgroundColor,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
    boxShadow: [
      // ✨ Eklendi
      BoxShadow(
        color: AppColors.shadow.withAlpha(128),
        blurRadius: 20,
        offset: const Offset(0, -5),
      ),
    ],
  );
}

/// Likes bottom sheet handler decoration
BoxDecoration kLikesBottomSheetHandlerBoxDecoration() {
  return BoxDecoration(
    color: AppColors.divider, // ✨ Colors.grey[400] → AppColors.divider
    borderRadius: BorderRadius.circular(10),
  );
}

// ═══════════════════════════════════════════════════════════════════════
// 🎯 TEXT STYLES
// ═══════════════════════════════════════════════════════════════════════

/// Send button text style
const kSendButtonTextStyle = TextStyle(
  color: AppColors.primary,
  fontWeight: FontWeight.bold,
  fontSize: 18.0,
  letterSpacing: 0.5, // ✨ Eklendi
);

/// App bar text style - Artık AppTextStyles'ı kullanabilirsiniz
@Deprecated('Use AppTextStyles.headline2 instead')
const kAppBarTextStyle = TextStyle(
  color: AppColors.textColor, // ✨ Güncellendi
  fontWeight: FontWeight.bold,
  fontSize: 24.0,
  letterSpacing: 0.15, // ✨ Eklendi
);

// ═══════════════════════════════════════════════════════════════════════
// 🎨 THEME DATA
// ═══════════════════════════════════════════════════════════════════════

/// Bottom navigation bar theme
const kBottomNavigationBarThemeData = BottomNavigationBarThemeData(
  backgroundColor:
      AppColors.baachgroundColor, // ✨ Colors.black → AppColors.baachgroundColor
  selectedItemColor: AppColors.primary, // ✨ Güncellendi
  unselectedItemColor: AppColors.textSecondary, // ✨ Güncellendi
  elevation: 0,
  type: BottomNavigationBarType.fixed,
  selectedLabelStyle: TextStyle(
    // ✨ Eklendi
    fontWeight: FontWeight.w600,
    fontSize: 12,
  ),
  unselectedLabelStyle: TextStyle(
    // ✨ Eklendi
    fontWeight: FontWeight.normal,
    fontSize: 12,
  ),
);

// ═══════════════════════════════════════════════════════════════════════
// 🎯 ICONS
// ═══════════════════════════════════════════════════════════════════════

/// Back icon with consistent styling
Icon kBackIcon(BuildContext context) {
  return Icon(
    IconsaxPlusLinear.arrow_left_2,
    size: 30,
    color: Theme.of(context).colorScheme.onSurface,
  );
}

/// Person card icon
Icon kPersonCardIcon(BuildContext context) {
  return Icon(
    Icons.person,
    size: 20,
    color: Theme.of(context).colorScheme.onSurface,
  );
}

// ═══════════════════════════════════════════════════════════════════════
// 🎨 GRADIENT DECORATIONS
// ═══════════════════════════════════════════════════════════════════════

/// Gradient card decoration for special cards
BoxDecoration kGradientCardDecoration({
  required int index,
  double borderRadius = 16,
}) {
  return BoxDecoration(
    gradient: AppColors.getGradient(index),
    borderRadius: BorderRadius.circular(borderRadius),
    boxShadow: const [
      BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 4)),
    ],
  );
}

/// Glassmorphism decoration
BoxDecoration kGlassmorphismDecoration({
  double borderRadius = 20,
  double backgroundOpacity = 0.3,
  double borderOpacity = 0.1,
}) {
  return BoxDecoration(
    color: AppColors.glassBackground(backgroundOpacity),
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(color: AppColors.glassBorder(borderOpacity), width: 1),
    boxShadow: [
      BoxShadow(
        color: AppColors.shadow.withAlpha(77),
        blurRadius: 10,
        offset: const Offset(0, 5),
      ),
    ],
  );
}

// ═══════════════════════════════════════════════════════════════════════
// 🎯 UTILITY FUNCTIONS
// ═══════════════════════════════════════════════════════════════════════

/// Get consistent border radius
BorderRadius kBorderRadius({double radius = 16}) {
  return BorderRadius.circular(radius);
}

/// Get consistent shadow
List<BoxShadow> kBoxShadow({
  Color? color,
  double blurRadius = 8,
  Offset offset = const Offset(0, 4),
}) {
  return [
    BoxShadow(
      color: color ?? AppColors.shadow,
      blurRadius: blurRadius,
      offset: offset,
    ),
  ];
}

/// Get consistent divider
Divider kDivider({double? thickness, Color? color}) {
  return Divider(
    thickness: thickness ?? 1,
    color: color ?? AppColors.divider,
    height: 1,
  );
}
