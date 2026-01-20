import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  // Linkler
  static const String privacyPolicyLink =
      'https://yetbey.notion.site/Privacy-Policy-and-Terms-Conditions-2bf03651bef580778641fea3e1d52669?pvs=74';

  // Resim Yolları
  static const String mainLogo = 'assets/images/yet.jpg';

  // Uzunluklar ve Genişlikler
  static double getDefaultDeviceHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static double getDefaultDeviceWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  // Padding & Margin
  static const double smallPadding = 8.0;
  static const double mediumPadding = 10.0;
  static const double largePadding = 12.0;
  static const double defaultPadding = 16.0;
  static const double veryLargePadding = 24.0;
  static const double borderRadiusSmall = 12.0;
  static const double borderRadiusMedium = 16.0;
  static const double borderRadiusLarge = 24.0;

  // Animasyon Süreleri
  static const Duration defaultDuration = Duration(milliseconds: 300);

  // Veritabanı - API Limitleri
  static const int postsPerPage = 10;
  static const int maxBioLength = 150;
}
