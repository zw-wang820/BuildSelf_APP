import 'package:flutter/material.dart';
import 'package:buildself/core/constants/colors.dart';

/// 渐变主按钮 — Kimi 风格（48 高、12 圆角、primaryGradient 背景）
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Gradient gradient;
  final bool fullWidth;
  final double height;
  final double radius;

  const GradientButton({
    Key? key,
    required this.label,
    this.onPressed,
    this.icon,
    this.gradient = AppColors.primaryGradient,
    this.fullWidth = true,
    this.height = 48,
    this.radius = 12,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: Colors.white),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );

    final box = Container(
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          splashColor: Colors.white.withValues(alpha: 0.18),
          highlightColor: Colors.white.withValues(alpha: 0.1),
          child: Center(child: child),
        ),
      ),
    );

    return fullWidth ? SizedBox(width: double.infinity, child: box) : box;
  }
}
