import 'package:flutter/material.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/features/todo/models/todo_model.dart';
import 'package:buildself/features/todo/widgets/todo_checkbox.dart';
import 'package:buildself/shared/widgets/emoji_icon.dart';

/// 待办列表项 — 左侧优先级色条 + 圆形复选框 + 内容 + 分类/截止信息
class TodoItemCard extends StatelessWidget {
  final Todo todo;
  final ValueChanged<Todo> onToggle;

  const TodoItemCard({Key? key, required this.todo, required this.onToggle})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final divider = isDark ? AppColors.dividerDark : AppColors.dividerLight;
    final priColor = todo.priority.color;
    final cat = todo.category;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 优先级色条：红=高 / 黄=中 / 绿=低
            Container(width: 4, color: priColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Row(
                  children: [
                    TodoCheckbox(
                      value: todo.isCompleted,
                      activeColor: priColor,
                      onChanged: (_) => onToggle(todo),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            todo.content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: todo.isCompleted
                                  ? AppColors.textSecondary(context)
                                  : AppColors.textPrimary(context),
                              decoration: todo.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: AppColors.textSecondary(context),
                            ),
                          ),
                          if (todo.note.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              todo.note,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _CategoryBadge(category: cat),
                              const SizedBox(width: 8),
                              _DueBadge(todo: todo),
                              if (todo.isOverdue) ...[
                                const SizedBox(width: 8),
                                const Text(
                                  '已逾期',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.error,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 分类徽章 — 彩色浅底 + emoji + 名称
class _CategoryBadge extends StatelessWidget {
  final TodoCategory category;
  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${category.emoji} ${category.label}',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: category.color,
        ),
      ),
    );
  }
}

/// 截止时间徽章
class _DueBadge extends StatelessWidget {
  final Todo todo;
  const _DueBadge({required this.todo});

  @override
  Widget build(BuildContext context) {
    final overdue = todo.isOverdue;
    final color = overdue ? AppColors.error : AppColors.textSecondary(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        EmojiIcon('⏰', size: 11),
        const SizedBox(width: 2),
        Text(
          todo.dueLabel,
          style: TextStyle(fontSize: 11, color: color),
        ),
      ],
    );
  }
}
