import 'package:flutter/material.dart';
import 'package:buildself/core/theme/light_theme.dart';
import 'package:buildself/core/theme/dark_theme.dart';

/// 主题管理
class AppTheme {
  AppTheme._();

  static ThemeData get light => buildLightTheme();
  static ThemeData get dark => buildDarkTheme();

  /// 根据亮度模式获取主题
  static ThemeData of(Brightness brightness) {
    return brightness == Brightness.dark ? dark : light;
  }
}
