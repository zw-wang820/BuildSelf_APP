import 'package:flutter/material.dart';
import 'package:buildself/features/todo/models/todo_model.dart';

/// 单个维度（分类 / 优先级）的统计结果
class TodoStatsGroup {
  /// 维度键：category.name 或 priority.name
  final String key;

  /// 显示名称（如：工作 / 高）
  final String label;

  /// 展示图标：分类 emoji 或优先级 emoji
  final String emoji;

  /// 维度场景色
  final Color color;

  /// 到期总数
  final int total;

  /// 已完成数
  final int completed;

  const TodoStatsGroup({
    required this.key,
    required this.label,
    required this.emoji,
    required this.color,
    required this.total,
    required this.completed,
  });

  /// 未完成数
  int get pending => total - completed;

  /// 完成率 0~1（无到期数据为 0）
  double get rate => total == 0 ? 0 : completed / total;
}

/// 待办统计 — 时间段内到期口径 + 近 7 天完成趋势
class TodoStats {
  /// 到期总数（due_date 落在时间段内）
  final int totalDue;

  /// 已完成（到期且 is_completed）
  final int completed;

  /// 未完成（到期且未完成）
  final int pending;

  /// 按分类分组
  final List<TodoStatsGroup> byCategory;

  /// 按优先级分组
  final List<TodoStatsGroup> byPriority;

  /// 近 7 天每日完成数（index 0 = 最早一天 … 6 = 今天）
  final List<int> dailyCompleted;

  /// 近 7 天每日标签（周一…周日）
  final List<String> dailyLabels;

  /// 时间段内到期全集（下钻明细用）
  final List<Todo> dueTodos;

  /// 近 7 天已完成全集（趋势柱下钻用）
  final List<Todo> weekDoneTodos;

  const TodoStats({
    required this.totalDue,
    required this.completed,
    required this.pending,
    required this.byCategory,
    required this.byPriority,
    required this.dailyCompleted,
    required this.dailyLabels,
    required this.dueTodos,
    required this.weekDoneTodos,
  });

  /// 完成率 0~1（无到期数据为 0）
  double get rate => totalDue == 0 ? 0 : completed / totalDue;

  /// 按分类统计（仅统计维度为分类时展示）
  static List<TodoStatsGroup> groupByCategory(List<Todo> todos) {
    return TodoCategory.values.map((c) {
      final inCat = todos.where((t) => t.category == c).toList();
      return TodoStatsGroup(
        key: c.name,
        label: c.label,
        emoji: c.emoji,
        color: c.color,
        total: inCat.length,
        completed: inCat.where((t) => t.isCompleted).length,
      );
    }).toList();
  }

  /// 按优先级统计
  static List<TodoStatsGroup> groupByPriority(List<Todo> todos) {
    return TodoPriority.values.map((p) {
      final inP = todos.where((t) => t.priority == p).toList();
      return TodoStatsGroup(
        key: p.name,
        label: p.label,
        emoji: _priorityEmoji(p),
        color: p.color,
        total: inP.length,
        completed: inP.where((t) => t.isCompleted).length,
      );
    }).toList();
  }

  static String _priorityEmoji(TodoPriority p) {
    switch (p) {
      case TodoPriority.high:
        return '🔴';
      case TodoPriority.medium:
        return '🟡';
      case TodoPriority.low:
        return '🟢';
    }
  }
}
