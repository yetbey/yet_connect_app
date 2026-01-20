import 'package:flutter/material.dart';
import 'package:yet_x_app/config/theme/app_text_styles.dart';
import 'package:yet_x_app/core/constants/app_colors.dart';

class Utils {
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  static void showSnackBar({String? text, bool? isError}) {
    if (text == null) return;
    isError ??= false;

    final snackBar = SnackBar(
      content: Text(text, style: AppTextStyles.postCaption),
      backgroundColor: isError ? AppColors.error : AppColors.success,
    );

    messengerKey.currentState!
      ..removeCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}
