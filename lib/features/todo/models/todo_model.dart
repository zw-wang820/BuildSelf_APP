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

/// 重复周期类型
enum TodoRepeatType { none, daily, weekly, monthly, yearly }

/// 重复规则 — 时间驱动：到周期自动生成新实例
class TodoRepeat {
  final TodoRepeatType type;
  final int interval; // 每 N 个周期（日/周/月/年），默认 1
  final Set<int> weekdays; // weekly 时生效：1=周一 … 7=周日
  final int? maxCount; // 终止：总共最多生成 N 个实例（含模板本身）
  final DateTime? endDate; // 终止：超过该日期后不再生成

  const TodoRepeat({
    required this.type,
    this.interval = 1,
    this.weekdays = const {},
    this.maxCount,
    this.endDate,
  });

  bool get isNone => type == TodoRepeatType.none;

  /// 周期摘要：每天 / 每周五 / 每 2 周 / 每月 15 日 / 每年 3 月 1 日
  /// [due] 传入模板截止日，用于每月/每年取"日"与"月日"
  String label({DateTime? due}) {
    switch (type) {
      case TodoRepeatType.daily:
        return interval > 1 ? '每 $interval 天' : '每天';
      case TodoRepeatType.weekly:
        if (weekdays.isNotEmpty) {
          final names = weekdays.map(_weekdayName).toList()..sort();
          final daysText = names.join('、');
          return interval > 1 ? '每 $interval 周（$daysText）' : '每周$daysText';
        }
        return interval > 1 ? '每 $interval 周' : '每周';
      case TodoRepeatType.monthly:
        final day = due?.day ?? DateTime.now().day;
        return interval > 1 ? '每 $interval 个月 $day 日' : '每月 $day 日';
      case TodoRepeatType.yearly:
        if (due != null) {
          return interval > 1
              ? '每 $interval 年 ${due.month} 月 ${due.day} 日'
              : '每年 ${due.month} 月 ${due.day} 日';
        }
        return interval > 1 ? '每 $interval 年' : '每年';
      case TodoRepeatType.none:
        return '不重复';
    }
  }

  /// 完整摘要（含终止条件）：每天 · 永不结束 / 每周五 · 共 5 次 / 每月 1 日 · 至 12/31
  String fullLabel({DateTime? due}) {
    if (isNone) return '不重复';
    final parts = <String>[label(due: due)];
    if (maxCount != null) {
      parts.add('共 $maxCount 次');
    } else if (endDate != null) {
      final d = endDate!;
      parts.add('至 ${d.month}/${d.day}');
    } else {
      parts.add('永不结束');
    }
    return parts.join(' · ');
  }

  static const weekdayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  static String _weekdayName(int w) {
    final i = w - 1;
    if (i >= 0 && i < weekdayNames.length) return weekdayNames[i];
    return '周$w';
  }

  Map<String, dynamic> toMap() {
    final sorted = weekdays.toList()..sort();
    return {
      'repeat_type': type.name,
      'repeat_interval': interval,
      'repeat_weekdays': sorted.isEmpty ? null : sorted.join(','),
      'repeat_max_count': maxCount,
      'repeat_end_date': endDate?.toIso8601String(),
    };
  }

  factory TodoRepeat.fromMap(Map<String, dynamic> map) {
    final type = TodoRepeatType.values.firstWhere(
      (e) => e.name == map['repeat_type'],
      orElse: () => TodoRepeatType.none,
    );
    if (type == TodoRepeatType.none) return const TodoRepeat(type: TodoRepeatType.none);
    final weekdaysRaw = map['repeat_weekdays'] as String?;
    final weekdays = <int>{};
    if (weekdaysRaw != null && weekdaysRaw.isNotEmpty) {
      for (final part in weekdaysRaw.split(',')) {
        final v = int.tryParse(part);
        if (v != null && v >= 1 && v <= 7) weekdays.add(v);
      }
    }
    return TodoRepeat(
      type: type,
      interval: ((map['repeat_interval'] as int? ?? 1)).clamp(1, 99).toInt(),
      weekdays: weekdays,
      maxCount: map['repeat_max_count'] as int?,
      endDate: map['repeat_end_date'] == null
          ? null
          : DateTime.tryParse(map['repeat_end_date'] as String),
    );
  }
}

/// 待办实体
class Todo {
  final String id;
  final String userId;
  final String content;
  final String note;

  /// 分类名：内置枚举 name（work/life/reading/study）或自定义分类名
  final String category;
  final TodoPriority priority;
  final TodoDueType dueType;
  final DateTime? dueDate;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;
  final TodoRepeat? repeat; // 重复规则（null = 不重复）
  final String? repeatOriginId; // 由同一模板生成的实例共享模板 id

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
    this.repeat,
    this.repeatOriginId,
  });

  /// 是否为重复待办
  bool get isRepeat => repeat != null && !repeat!.isNone;

  /// 重复摘要（卡片徽章用）：每周五
  String? get repeatLabel => isRepeat ? repeat!.label(due: dueDate) : null;

  /// 是否内置分类
  bool get isBuiltinCategory =>
      TodoCategory.values.any((c) => c.name == category);

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'content': content,
        'note': note,
        'category': category,
        'priority': priority.name,
        'due_type': dueType.name,
        'due_date': dueDate?.toIso8601String(),
        'is_completed': isCompleted ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
        ...?repeat?.toMap(),
        'repeat_origin_id': repeatOriginId,
      };

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      content: (map['content'] as String?) ?? '',
      note: (map['note'] as String?) ?? '',
      category: (map['category'] as String?) ?? TodoCategory.work.name,
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
      repeat: TodoRepeat.fromMap(map),
      repeatOriginId: map['repeat_origin_id'] as String?,
    );
  }

  Todo copyWith({
    String? content,
    String? note,
    String? category,
    TodoPriority? priority,
    TodoDueType? dueType,
    DateTime? dueDate,
    bool? isCompleted,
    DateTime? completedAt,
    TodoRepeat? repeat,
    String? repeatOriginId,
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
      repeat: repeat ?? this.repeat,
      repeatOriginId: repeatOriginId ?? this.repeatOriginId,
    );
  }

  /// 截止文案：基于 dueDate 与"今天"动态计算
  /// 今天/明天/昨天 → 相对文案；更早/更晚 → MM/DD；无 dueDate 回退到类型文案
  String get dueLabel {
    final due = dueDate;
    if (due == null) {
      return dueType == TodoDueType.custom ? '未设日期' : dueType.label;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(due.year, due.month, due.day);
    final diff = dueDay.difference(today).inDays;
    if (diff == 0) return '今天';
    if (diff == 1) return '明天';
    if (diff == -1) return '昨天';
    return '${due.month.toString().padLeft(2, '0')}/${due.day.toString().padLeft(2, '0')}';
  }

  /// 是否逾期（未完成且截止日早于今天 0 点）
  bool get isOverdue {
    if (isCompleted || dueDate == null) return false;
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    return dueDate!.isBefore(midnight);
  }

  // ==================== 排序 ====================

  /// 未完成段排序：截止日期升序（无截止排最后）→ 优先级高→低
  /// 首页"今日待办"与待办清单页共用
  static int compareActive(Todo a, Todo b) {
    final da = a.dueDate;
    final db = b.dueDate;
    if (da == null && db == null) return 0;
    if (da == null) return 1;
    if (db == null) return -1;
    final c = da.compareTo(db);
    if (c != 0) return c;
    return _priorityWeight(a.priority).compareTo(_priorityWeight(b.priority));
  }

  /// 列表页完整排序：未完成优先 → 未完成按 [compareActive] → 已完成按完成时间倒序
  static int compareForList(Todo a, Todo b) {
    if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
    if (!a.isCompleted) return compareActive(a, b);
    final ca = a.completedAt;
    final cb = b.completedAt;
    if (ca == null && cb == null) return 0;
    if (ca == null) return 1;
    if (cb == null) return -1;
    return cb.compareTo(ca);
  }

  static int _priorityWeight(TodoPriority p) {
    switch (p) {
      case TodoPriority.high:
        return 0;
      case TodoPriority.medium:
        return 1;
      case TodoPriority.low:
        return 2;
    }
  }
}
