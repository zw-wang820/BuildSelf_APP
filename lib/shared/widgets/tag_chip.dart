import 'package:flutter/material.dart';
import 'package:buildself/core/constants/colors.dart';

/// 标签 Chip — 极简风格
class TagChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onDeleted;
  final String? color;

  const TagChip({
    Key? key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.onDeleted,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final unselectedBg = isDark ? AppColors.spacePanel : AppColors.backgroundLight;
    final unselectedFg = AppColors.textSecondary(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? accent.withOpacity(0.16) : unselectedBg.withOpacity(0.6),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? accent.withOpacity(0.7) : (isDark ? AppColors.dividerDark : AppColors.dividerLight),
            width: selected ? 1 : 0.6,
          ),
          boxShadow: selected
              ? null
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: selected ? accent : unselectedFg,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                letterSpacing: 0.3,
              ),
            ),
            if (onDeleted != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onDeleted,
                child: Icon(Icons.close, size: 13, color: unselectedFg),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
