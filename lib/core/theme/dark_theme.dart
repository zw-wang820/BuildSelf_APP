import 'package:flutter/material.dart';
import 'package:buildself/core/constants/colors.dart';

/// Buildself 深色主题 — NEXUS 深空科技风
/// 作为主推展示主题，强调深空底 + 霓虹青薄荷点缀 + 玻璃质感
ThemeData buildDarkTheme() {
  final ColorScheme colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.dark,
    primary: AppColors.primary,
    secondary: AppColors.accent,
    surface: AppColors.surfaceDark,
    background: AppColors.backgroundDark,
    error: AppColors.error,
    onPrimary: AppColors.spaceDeep,
    onSecondary: AppColors.spaceDeep,
    onSurface: AppColors.textPrimaryDark,
    onBackground: AppColors.textPrimaryDark,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    canvasColor: AppColors.spaceHigh,
    fontFamily: 'NotoSansSC',
    brightness: Brightness.dark,

    // AppBar — 透明悬浮于深空之上
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.textPrimaryDark,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimaryDark,
        letterSpacing: 0.3,
      ),
      iconTheme: IconThemeData(color: AppColors.primary, size: 22),
    ),

    // 卡片 — 深空面板 + 青色描边
    cardTheme: CardThemeData(
      color: AppColors.spaceHigh,
      elevation: 0,
      shadowColor: AppColors.glowCyan,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.dividerDark, width: 0.8),
      ),
      margin: EdgeInsets.zero,
    ),

    // 按钮 — 霓虹青填充
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: AppColors.spaceDeep,
        backgroundColor: AppColors.primary,
        elevation: 0,
        shadowColor: AppColors.glowCyan,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    ),

    // 文本按钮
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryLight,
        textStyle: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.3),
      ),
    ),

    // Outlined 按钮
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),

    // 输入框 — 深空面板 + 青色聚焦光
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.spaceHigh,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.dividerDark, width: 0.8),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.dividerDark, width: 0.8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      hintStyle: const TextStyle(color: AppColors.textSecondaryDark),
      labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
      prefixIconColor: AppColors.textSecondaryDark,
    ),

    // 底部导航
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.spaceHigh,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondaryDark,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),

    // 浮动按钮 — 霓虹青
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.spaceDeep,
      elevation: 0,
      highlightElevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // Chip
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.spaceHigh,
      selectedColor: AppColors.primary.withOpacity(0.18),
      labelStyle: const TextStyle(fontSize: 13, color: AppColors.textPrimaryDark),
      side: const BorderSide(color: AppColors.dividerDark, width: 0.6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),

    // 进度条
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
      linearTrackColor: AppColors.dividerDark,
      linearMinHeight: 6,
    ),

    // 分割线
    dividerTheme: const DividerThemeData(
      color: AppColors.dividerDark,
      thickness: 0.6,
      space: 1,
    ),

    // 文字样式 — 冷调高对比
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimaryDark,
        letterSpacing: 0.2,
        height: 1.2,
      ),
      headlineMedium: TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimaryDark,
        letterSpacing: 0.2,
      ),
      titleLarge: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimaryDark,
        letterSpacing: 0.2,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryDark,
      ),
      bodyLarge: TextStyle(fontSize: 15, color: AppColors.textPrimaryDark, height: 1.5),
      bodyMedium: TextStyle(fontSize: 13, color: AppColors.textSecondaryDark, height: 1.5),
      bodySmall: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
      labelSmall: TextStyle(
        fontSize: 11,
        color: AppColors.textSecondaryDark,
        letterSpacing: 0.8,
        fontWeight: FontWeight.w600,
      ),
    ),

    // SnackBar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.spacePanel,
      contentTextStyle: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 14),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.primary, width: 0.8),
      ),
    ),

    // 对话框
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.spaceHigh,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.dividerDark, width: 0.8),
      ),
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimaryDark,
      ),
      contentTextStyle: const TextStyle(
        fontSize: 14,
        color: AppColors.textSecondaryDark,
      ),
    ),
  );
}
