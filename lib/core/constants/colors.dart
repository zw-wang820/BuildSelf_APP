import 'package:flutter/material.dart';

/// Buildself 颜色定义 — NEXUS 科技风
///
/// 设计理念：深邃、未来、有呼吸感
/// 主色：电光青 — 象征清醒与专注
/// 辅色：霓虹薄荷 — 象征生长与活力
class AppColors {
  AppColors._();

  // ========== 品牌主色 — 电光青 ==========
  static const Color primary = Color(0xFF00E5FF);       // 电光青
  static const Color primaryLight = Color(0xFF7AF7FF);  // 浅电光青
  static const Color primaryDark = Color(0xFF0097A7);   // 深电光青

  // ========== 辅助色 — 霓虹薄荷 ==========
  static const Color accent = Color(0xFF5EFF8A);        // 霓虹薄荷
  static const Color accentLight = Color(0xFFB8FFD0);   // 浅霓虹薄荷

  // ========== 模块专属色 — 霓虹变体 ==========
  static const Color work = Color(0xFF4D9FFF);          // 电光蓝
  static const Color life = Color(0xFFFFB547);          // 琥珀脉冲
  static const Color goal = Color(0xFF5EFF8A);          // 霓虹薄荷（生长）
  static const Color reading = Color(0xFFB388FF);       // 电光紫
  static const Color murmur = Color(0xFFFF5C8A);        // 热粉

  // ========== 中性色 (浅色模式 — 冷调科技白) ==========
  static const Color backgroundLight = Color(0xFFEFF2F8);  // 冷调浅底
  static const Color surfaceLight = Color(0xFFFFFFFF);     // 卡片背景
  static const Color textPrimaryLight = Color(0xFF0F1420); // 主文字
  static const Color textSecondaryLight = Color(0xFF5A6478);// 次文字
  static const Color dividerLight = Color(0xFFD8DEE9);     // 分割线
  static const Color placeholderLight = Color(0xFFA0A8B8);  // 占位符

  // ========== 中性色 (深色模式 — 深空底) ==========
  static const Color backgroundDark = Color(0xFF0A0E1A);   // 深空背景
  static const Color surfaceDark = Color(0xFF121829);      // 抬升面板
  static const Color textPrimaryDark = Color(0xFFE8ECF4);  // 主文字
  static const Color textSecondaryDark = Color(0xFF8B95B0);// 次文字
  static const Color dividerDark = Color(0xFF1F2940);      // 分割线

  // ========== 功能色 ==========
  static const Color success = Color(0xFF5EFF8A);   // 薄荷
  static const Color warning = Color(0xFFFFB547);   // 琥珀
  static const Color error = Color(0xFFFF5C6C);     // 红粉
  static const Color info = Color(0xFF4D9FFF);      // 电光蓝

  // ========== 心情色 ==========
  static const Color moodHappy = Color(0xFFFFD54F);     // 😊
  static const Color moodNeutral = Color(0xFF8B95B0);   // 😐
  static const Color moodAngry = Color(0xFFFF5C6C);     // 😤
  static const Color moodSad = Color(0xFF4D9FFF);       // 😢
  static const Color moodThink = Color(0xFFB388FF);     // 🤔

  // ========== NEXUS 科技扩展 ==========

  // 玻璃拟态覆层
  static const Color glassOverlayLight = Color(0x66FFFFFF);  // 浅色玻璃覆层
  static const Color glassOverlayDark = Color(0x14FFFFFF);   // 深色玻璃覆层
  static const Color glassStrokeLight = Color(0x55FFFFFF);   // 浅色玻璃描边
  static const Color glassStrokeDark = Color(0x2BFFFFFF);    // 深色玻璃描边

  // 蓝图网格 / 氛围
  static const Color gridLineDark = Color(0xFF1A2138);   // 深色蓝图网格线
  static const Color gridLineLight = Color(0xFFDDE3EE);  // 浅色蓝图网格线
  static const Color gridDotDark = Color(0x337AF7FF);    // 深色网格点

  // 霓虹光晕
  static const Color glowCyan = Color(0x6600E5FF);       // 柔和青色光晕
  static const Color glowMint = Color(0x665EFF8A);       // 柔和薄荷光晕
  static const Color glowPink = Color(0x66FF5C8A);       // 柔和粉色光晕

  // 深空渐变端点
  static const Color spaceDeep = Color(0xFF050810);      // 近黑深空
  static const Color spaceMid = Color(0xFF0A0E1A);       // 中层深空
  static const Color spaceHigh = Color(0xFF121829);      // 抬升深空
  static const Color spacePanel = Color(0xFF161D33);     // 面板深空

  // 签名渐变端点（用于 mesh / 背景氛围）
  static const Color gradCyan = Color(0xFF00E5FF);
  static const Color gradMint = Color(0xFF5EFF8A);
  static const Color gradViolet = Color(0xFFB388FF);
  static const Color gradPink = Color(0xFFFF5C8A);
  static const Color gradBlue = Color(0xFF4D9FFF);

  // 角标 / HUD 强调
  static const Color hudAmber = Color(0xFFFFB547);       // HUD 琥珀
  static const Color hudLine = Color(0x5500E5FF);        // HUD 青色线

  /// 根据亮度返回合适的玻璃覆层
  static Color glassOverlay(Brightness b) =>
      b == Brightness.dark ? glassOverlayDark : glassOverlayLight;

  /// 根据亮度返回合适的玻璃描边
  static Color glassStroke(Brightness b) =>
      b == Brightness.dark ? glassStrokeDark : glassStrokeLight;

  /// 根据亮度返回合适的网格线
  static Color gridLine(Brightness b) =>
      b == Brightness.dark ? gridLineDark : gridLineLight;
}
