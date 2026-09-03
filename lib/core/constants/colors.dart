import 'package:flutter/material.dart';

/// Buildself 颜色定义 — Kimi 风格设计令牌
///
/// 设计理念（参考 LifeWork/a APP UI 规范）：
/// - 主色：Indigo 靛蓝 — 沉稳而有活力
/// - 场景专属色：工作蓝 / 生活绿 / 阅读紫 / 目标（短橙·中靛·长粉）
/// - 渐变：主按钮、Hero、生活卡片、书籍封面
/// - 冷暖中性、克制阴影、4px 基准间距
class AppColors {
  AppColors._();

  // ========== 品牌主色 — Indigo 靛蓝 ==========
  static const Color primary = Color(0xFF6366F1);       // indigo-500
  static const Color primaryLight = Color(0xFF818CF8);  // indigo-400
  static const Color primaryDark = Color(0xFF4F46E5);   // indigo-600

  // ========== 辅助色 — Violet 紫罗兰 ==========
  static const Color accent = Color(0xFF8B5CF6);        // violet-500
  static const Color accentLight = Color(0xFFA78BFA);  // violet-400

  // ========== 模块 / 场景专属色 ==========
  static const Color work = Color(0xFF3B82F6);          // blue-500   工作
  static const Color life = Color(0xFF22C55E);          // green-500  生活
  static const Color goal = Color(0xFF6366F1);          // indigo-500 目标(通用)
  static const Color reading = Color(0xFF8B5CF6);       // violet-500 阅读
  static const Color murmur = Color(0xFFF472B6);        // pink-400   碎碎念
  static const Color todo = Color(0xFF0EA5E9);          // sky-500    待办
  static const Color habit = Color(0xFF14B8A6);         // teal-500   习惯打卡
  static const Color study = Color(0xFFF97316);         // orange-500 学习

  // 目标类型语义色
  static const Color goalShort = Color(0xFFF59E0B);     // amber-500  短期
  static const Color goalMid = Color(0xFF6366F1);       // indigo-500 中期
  static const Color goalLong = Color(0xFFEC4899);      // pink-500   长期

  // ========== 场景浅底 + 深字（标签/徽章/着色） ==========
  static const Color workLight = Color(0xFFDBEAFE);
  static const Color workText = Color(0xFF1D4ED8);
  static const Color lifeLight = Color(0xFFDCFCE7);
  static const Color lifeText = Color(0xFF15803D);
  static const Color goalLight = Color(0xFFE0E7FF);
  static const Color goalText = Color(0xFF3730A3);
  static const Color readingLight = Color(0xFFEDE9FE);
  static const Color readingText = Color(0xFF4C1D95);
  static const Color murmurLight = Color(0xFFFCE7F3);
  static const Color murmurText = Color(0xFF9D174D);

  // 场景浅底按模块取用（Key = 模块标识）
  static const Map<String, Color> sceneLight = {
    'work': workLight,
    'life': lifeLight,
    'goal': goalLight,
    'reading': readingLight,
    'murmur': murmurLight,
  };
  static const Map<String, Color> sceneText = {
    'work': workText,
    'life': lifeText,
    'goal': goalText,
    'reading': readingText,
    'murmur': murmurText,
  };

  // ========== 中性色 (浅色模式 — 清冷干净) ==========
  static const Color backgroundLight = Color(0xFFF8FAFC);  // slate-50
  static const Color surfaceLight = Color(0xFFFFFFFF);     // 纯白卡片
  static const Color surfaceVariantLight = Color(0xFFF1F5F9); // slate-100
  static const Color textPrimaryLight = Color(0xFF0F172A);  // slate-900
  static const Color textSecondaryLight = Color(0xFF64748B);// slate-500
  static const Color dividerLight = Color(0xFFE2E8F0);     // slate-200
  static const Color placeholderLight = Color(0xFF94A3B8);  // slate-400

  // ========== 中性色 (深色模式 — 深空蓝灰) ==========
  static const Color backgroundDark = Color(0xFF0B0F1A);   // 深底
  static const Color surfaceDark = Color(0xFF151B2B);      // 抬升面板
  static const Color surfaceVariantDark = Color(0xFF1E2638);// 次级面板
  static const Color textPrimaryDark = Color(0xFFE2E8F0);  // 主文字
  static const Color textSecondaryDark = Color(0xFF94A3B8);// 次文字
  static const Color dividerDark = Color(0xFF2A3346);      // 分割线
  static const Color placeholderDark = Color(0xFF64748B);

  // ========== 功能色 ==========
  static const Color success = Color(0xFF22C55E);   // green
  static const Color warning = Color(0xFFF59E0B);   // amber
  static const Color error = Color(0xFFEF4444);     // red
  static const Color info = Color(0xFF3B82F6);      // blue

  // ========== 心情色 ==========
  static const Color moodHappy = Color(0xFFF59E0B);     // 暖黄
  static const Color moodNeutral = Color(0xFF94A3B8);   // 灰
  static const Color moodAngry = Color(0xFFEF4444);     // 红
  static const Color moodSad = Color(0xFF3B82F6);       // 蓝
  static const Color moodThink = Color(0xFF8B5CF6);     // 紫

  // ========== KISS 复盘四象限 ==========
  static const Color reviewKeep = Color(0xFF22C55E);    // green-500   保持
  static const Color reviewImprove = Color(0xFF3B82F6); // blue-500    改进
  static const Color reviewStart = Color(0xFF14B8A6);   // teal-500    开始
  static const Color reviewStop = Color(0xFFEF4444);    // red-500     停止
  // 浅底 + 深字（标签/徽章/象限头）
  static const Color reviewKeepLight = Color(0xFFDCFCE7);
  static const Color reviewKeepText = Color(0xFF15803D);
  static const Color reviewImproveLight = Color(0xFFDBEAFE);
  static const Color reviewImproveText = Color(0xFF1D4ED8);
  static const Color reviewStartLight = Color(0xFFCCFBF1);
  static const Color reviewStartText = Color(0xFF0F766E);
  static const Color reviewStopLight = Color(0xFFFEE2E2);
  static const Color reviewStopText = Color(0xFFB91C1C);

  // ========== 兼容旧代码的别名（勿删） ==========
  static const Color spaceDeep = Color(0xFF0B0F1A);
  static const Color spaceMid = Color(0xFF0B0F1A);
  static const Color spaceHigh = Color(0xFF151B2B);
  static const Color spacePanel = Color(0xFF1E2638);

  // 微阴影色
  static const Color shadowLight = Color(0x14000000);  // 8% 黑
  static const Color shadowDark = Color(0x33000000);   // 20% 黑

  /// 主题自适应文字色 — 浅色模式用深色字（黑），深色模式用浅色字（白）
  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? textPrimaryDark
          : textPrimaryLight;

  static Color textSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? textSecondaryDark
          : textSecondaryLight;

  // ========== 渐变 ==========
  /// 主按钮 / FAB 渐变：135deg indigo
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
  );

  /// 启动页 / 大标题 Hero 渐变：135deg
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
  );

  /// 生活「美好瞬间」卡片渐变：135deg
  static const LinearGradient cardLifeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
  );

  /// 书籍封面渐变（无图时占位），8 套配色可实时预览
  static const List<LinearGradient> bookCovers = [
    LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
    LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFF59E0B), Color(0xFFEF4444)]),
    LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF22C55E), Color(0xFF10B981)]),
    LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)]),
    LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)]),
    LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF14B8A6), Color(0xFF0EA5E9)]),
    LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFF97316), Color(0xFFF59E0B)]),
    LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)]),
  ];
}
