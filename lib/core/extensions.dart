import 'package:flutter/material.dart';
import 'app_colors.dart';

extension AppColorsExtension on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}
