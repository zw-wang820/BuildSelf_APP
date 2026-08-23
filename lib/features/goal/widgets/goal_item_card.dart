import 'package:flutter/material.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/data/models/enums.dart';
import 'package:buildself/data/models/goal_model.dart';

/// 目标列表项 — 类型徽章 + 截止时间 + 奖励 + 进度条(可入场动画) + 里程碑
///
/// [animateProgress] 为 true 时，进度条首次从 0 动画到当前值（用于新建目标 0→5% 起步效果），
/// 动画结束回调 [onAnimationDone]
class GoalItemCard extends StatefulWidget {
  final Goal goal;
  final VoidCallback onTap;
  final bool animateProgress;
  final VoidCallback? onAnimationDone;

  const GoalItemCard({
    Key? key,
    required this.goal,
    required this.onTap,
    this.animateProgress = false,
    this.onAnimationDone,
  }) : super(key: key);

  @override
  State<GoalItemCard> createState() => _GoalItemCardState();
}

class _GoalItemCardState extends State<GoalItemCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.animateProgress) {
      _ctrl.forward(from: 0).whenComplete(() {
        if (mounted) widget.onAnimationDone?.call();
      });
    } else {
      _ctrl.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant GoalItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 列表数据刷新（如勾选里程碑后重载）时保持当前进度，不重新动画
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color _goalColor(GoalType type) {
    switch (type) {
      case GoalType.shortTerm:
        return AppColors.goalShort;
      case GoalType.midTerm:
        return AppColors.goalMid;
      case GoalType.longTerm:
        return AppColors.goalLong;
    }
  }

  String _typeEmoji(GoalType type) {
    switch (type) {
      case GoalType.shortTerm:
        return '⚡';
      case GoalType.midTerm:
        return '🎯';
      case GoalType.longTerm:
        return '🌟';
    }
  }

  @override
  Widget build(BuildContext context) {
    final goal = widget.goal;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final divider = isDark ? AppColors.dividerDark : AppColors.dividerLight;
    final color = _goalColor(goal.goalType);
    final progress = goal.calculatedProgress.clamp(0, 100);
    final isCompleted = goal.status == GoalStatus.completed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: divider, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: isDark ? AppColors.shadowDark : AppColors.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          splashColor: color.withValues(alpha: 0.06),
          highlightColor: color.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 类型徽章 + 状态/截止
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${_typeEmoji(goal.goalType)} ${goal.goalType.label}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (isCompleted)
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle,
                              size: 14, color: AppColors.success),
                          SizedBox(width: 3),
                          Text(
                            '已完成',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      )
                    else if (goal.targetDate != null)
                      _buildDeadline(goal),
                  ],
                ),
                const SizedBox(height: 10),
                // 标题
                Text(
                  goal.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isCompleted
                        ? AppColors.textSecondary(context)
                        : AppColors.textPrimary(context),
                    decoration:
                        isCompleted ? TextDecoration.lineThrough : null,
                    decorationColor: AppColors.textSecondary(context),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                // 奖励
                if (goal.reward.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('🎁', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          goal.reward.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                // 进度条 + 百分比
                Row(
                  children: [
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _ctrl,
                        builder: (context, _) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: SizedBox(
                              height: 8,
                              child: LayoutBuilder(
                                builder: (context, c) => Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Container(
                                      color: isDark
                                          ? AppColors.dividerDark
                                          : AppColors.dividerLight,
                                    ),
                                    Positioned(
                                      left: 0,
                                      top: 0,
                                      bottom: 0,
                                      width:
                                          c.maxWidth * (progress / 100) * _ctrl.value,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              color.withValues(alpha: 0.6),
                                              color,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$progress%',
                      style: TextStyle(
                        fontSize: 13,
                        color: color,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                // 里程碑
                if (goal.milestones.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...List.generate(
                    goal.milestones.length > 3 ? 3 : goal.milestones.length,
                    (i) => _buildMilestoneRow(goal.milestones[i]),
                  ),
                  if (goal.milestones.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '还有 ${goal.milestones.length - 3} 个里程碑…',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeadline(Goal goal) {
    final days = goal.targetDate!
        .difference(DateTime.now())
        .inDays;
    final overdue = days < 0 && goal.status != GoalStatus.completed;
    final color = overdue ? AppColors.error : AppColors.textSecondary(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          overdue ? Icons.error_outline : Icons.schedule,
          size: 13,
          color: color,
        ),
        const SizedBox(width: 3),
        Text(
          overdue
              ? '已过期 $days 天'
              : '截止 ${goal.targetDate!.month.toString().padLeft(2, '0')}.${goal.targetDate!.day.toString().padLeft(2, '0')} · 剩余$days天',
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 里程碑行 — 完成=✓ 绿色对勾，未完成=空心圆
  Widget _buildMilestoneRow(Milestone m) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            m.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: m.isCompleted ? AppColors.success : AppColors.textSecondary(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              m.title,
              style: TextStyle(
                fontSize: 12,
                color: m.isCompleted
                    ? AppColors.textSecondary(context)
                    : AppColors.textPrimary(context),
                decoration:
                    m.isCompleted ? TextDecoration.lineThrough : null,
                decorationColor: AppColors.textSecondary(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
