import 'package:flutter/material.dart';
import 'package:buildself/core/constants/colors.dart';

/// NEXUS 通用卡片 — 玻璃质感 + 渐变描边 + 可选霓虹光晕
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  /// 强调色：用于卡片描边与光晕的色调（默认主色）
  final Color? accent;

  /// 是否启用霓虹光晕（用于重点卡片）
  final bool glow;

  /// 圆角
  final double radius;

  const AppCard({
    Key? key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.accent,
    this.glow = false,
    this.radius = 16,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = accent ?? AppColors.primary;
    final surface = Theme.of(context).cardTheme.color ?? (isDark ? AppColors.spaceHigh : Colors.white);
    final divider = isDark ? AppColors.dividerDark : AppColors.dividerLight;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withOpacity(glow ? 0.55 : 0.25),
            divider.withOpacity(0.6),
          ],
        ),
        boxShadow: glow
            ? [BoxShadow(color: accentColor.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 6))]
            : null,
      ),
      child: Padding(
        // 1px 渐变描边的内边距
        padding: const EdgeInsets.all(1),
        child: Material(
          color: isDark ? surface.withOpacity(0.92) : surface,
          borderRadius: BorderRadius.circular(radius - 1),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(radius - 1),
            highlightColor: accentColor.withOpacity(0.08),
            splashColor: accentColor.withOpacity(0.12),
            child: Padding(
              padding: padding ?? const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
