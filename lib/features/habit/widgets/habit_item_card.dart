import 'package:flutter/material.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/features/habit/models/habit_model.dart';
import 'package:buildself/features/todo/widgets/todo_checkbox.dart';
import 'package:buildself/shared/widgets/app_card.dart';

/// 习惯卡片 — 图标 + 名称 + 连续天数 + 今日打卡圈 + 补昨天
class HabitItemCard extends StatelessWidget {
  final Habit habit;
  final bool checkedToday;
  final bool checkedYesterday;
  final int streak;
  final ValueChanged<bool> onToggleToday;
  final VoidCallback? onMakeupYesterday;

  const HabitItemCard({
    Key? key,
    required this.habit,
    required this.checkedToday,
    required this.checkedYesterday,
    required this.streak,
    required this.onToggleToday,
    this.onMakeupYesterday,
  }) : super(key: key);

  Color get _color =>
      kHabitPalette[habit.colorIndex % kHabitPalette.length];

  @override
  Widget build(BuildContext context) {
    final canMakeup = !checkedYesterday && onMakeupYesterday != null;
    return AppCard(
      accent: _color,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        children: [
          Row(
            children: [
              // 彩色图标圆
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    habit.icon,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 名称 + 状态
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _statusText(),
                      style: TextStyle(
                        fontSize: 12,
                        color: checkedToday
                            ? _color
                            : AppColors.textSecondary(context),
                        fontWeight:
                            checkedToday ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 今日打卡圈（复用待办弹簧复选框）
              TodoCheckbox(
                value: checkedToday,
                activeColor: _color,
                size: 26,
                onChanged: (_) => onToggleToday(!checkedToday),
              ),
            ],
          ),
          // 昨天未打卡 → 补卡入口
          if (canMakeup)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.history,
                    size: 13,
                    color: AppColors.textSecondary(context),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '昨天未打卡',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onMakeupYesterday,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: _color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '补昨天',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _color,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _statusText() {
    if (checkedToday) {
      return streak > 0 ? '🔥 连续 $streak 天' : '今日已打卡';
    }
    return streak > 0 ? '🔥 已连续 $streak 天 · 今天待打卡' : '今天待打卡';
  }
}
