import 'package:flutter/material.dart';
import 'package:buildself/core/constants/colors.dart';

/// 卡片 — Kimi 风格：16 圆角 + 柔和阴影 + 可选细边框
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  /// 强调色：用于 InkWell ripple 效果
  final Color? accent;

  /// 兼容旧参数
  final bool glow;

  /// 圆角
  final double radius;

  /// 是否显示柔和阴影（Kimi 卡片默认开启）
  final bool shadow;

  const AppCard({
    Key? key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.accent,
    this.glow = false,
    this.radius = 16,
    this.shadow = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = accent ?? AppColors.primary;
    final divider = isDark ? AppColors.dividerDark : AppColors.dividerLight;
    final surface = Theme.of(context).cardTheme.color ??
        (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: divider, width: 0.5),
        boxShadow: (shadow || glow)
            ? [
                BoxShadow(
                  color: isDark ? AppColors.shadowDark : AppColors.shadowLight,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          highlightColor: accentColor.withValues(alpha: 0.06),
          splashColor: accentColor.withValues(alpha: 0.08),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}
