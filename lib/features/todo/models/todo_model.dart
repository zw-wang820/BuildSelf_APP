import 'package:flutter/material.dart';
import 'package:buildself/core/constants/colors.dart';

/// 待办分类 — 与首页快捷入口区分，待办支持 工作/生活/阅读/学习 四类
enum TodoCategory {
  work('💼', '工作', AppColors.work),
  life('🌿', '生活', AppColors.life),
  reading('📖', '阅读', AppColors.reading),
  study('📚', '学习', AppColors.study);

  const TodoCategory(this.emoji, this.label, this.color);
  final String emoji;
  final String label;
  final Color color;
}

/// 优先级 — 高=红 / 中=黄 / 低=绿
enum TodoPriority {
  high('高', AppColors.error),
  medium('中', AppColors.warning),
  low('低', AppColors.success);

  const TodoPriority(this.label, this.color);
  final String label;
  final Color color;
}

/// 截止时间类型
enum TodoDueType {
  today('今天'),
  tomorrow('明天'),
  dayAfter('后天'),
  custom('选择日期');

  const TodoDueType(this.label);
  final String label;
}

/// 待办实体
class Todo {
  final String id;
  final String userId;
  final String content;
  final String note;
  final TodoCategory category;
  final TodoPriority priority;
  final TodoDueType dueType;
  final DateTime? dueDate;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;

  const Todo({
    required this.id,
    required this.userId,
    required this.content,
    this.note = '',
    required this.category,
    required this.priority,
    required this.dueType,
    this.dueDate,
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'content': content,
        'note': note,
        'category': category.name,
        'priority': priority.name,
        'due_type': dueType.name,
        'due_date': dueDate?.toIso8601String(),
        'is_completed': isCompleted ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
      };

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      content: (map['content'] as String?) ?? '',
      note: (map['note'] as String?) ?? '',
      category: TodoCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => TodoCategory.work,
      ),
      priority: TodoPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => TodoPriority.medium,
      ),
      dueType: TodoDueType.values.firstWhere(
        (e) => e.name == map['due_type'],
        orElse: () => TodoDueType.today,
      ),
      dueDate: map['due_date'] == null
          ? null
          : DateTime.tryParse(map['due_date'] as String),
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      completedAt: map['completed_at'] == null
          ? null
          : DateTime.tryParse(map['completed_at'] as String),
    );
  }

  Todo copyWith({
    String? content,
    String? note,
    TodoCategory? category,
    TodoPriority? priority,
    TodoDueType? dueType,
    DateTime? dueDate,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return Todo(
      id: id,
      userId: userId,
      content: content ?? this.content,
      note: note ?? this.note,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      dueType: dueType ?? this.dueType,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// 截止文案：相对类型直接显示「今天/明天/后天」；自定义显示 MM/DD
  String get dueLabel {
    if (dueType == TodoDueType.custom && dueDate != null) {
      final d = dueDate!;
      return '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
    }
    return dueType.label;
  }

  /// 是否逾期（未完成且截止日早于今天 0 点）
  bool get isOverdue {
    if (isCompleted || dueDate == null) return false;
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    return dueDate!.isBefore(midnight);
  }
}
