import 'package:flutter/material.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/data/models/enums.dart';

/// 心情选择器 — 极简风格
class MoodSelector extends StatelessWidget {
  final Mood? selected;
  final ValueChanged<Mood?> onChanged;

  const MoodSelector({
    Key? key,
    this.selected,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: Mood.values.map((mood) {
        final isSelected = selected == mood;
        final accent = AppColors.primary;
        final baseBg = isDark ? AppColors.spacePanel : AppColors.backgroundLight;
        final divider = isDark ? AppColors.dividerDark : AppColors.dividerLight;
        return GestureDetector(
          onTap: () => onChanged(isSelected ? null : mood),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? accent.withOpacity(0.16) : baseBg.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? accent.withOpacity(0.7) : divider,
                width: isSelected ? 1 : 0.6,
              ),
              boxShadow: isSelected
                  ? null
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(mood.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(
                  mood.label,
                  style: TextStyle(
                    fontSize: 13,
                    color: isSelected
                        ? accent
                        : (AppColors.textSecondary(context)),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
