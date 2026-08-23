import 'package:flutter/material.dart';

/// 习惯打卡记录 — 一次打卡对应 habit_id + 日期（yyyy-MM-dd）
class HabitLog {
  final String id;
  final String habitId;
  final String date; // yyyy-MM-dd

  const HabitLog({
    required this.id,
    required this.habitId,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'habit_id': habitId,
        'date': date,
      };

  factory HabitLog.fromMap(Map<String, dynamic> map) => HabitLog(
        id: map['id'] as String,
        habitId: map['habit_id'] as String,
        date: map['date'] as String,
      );
}

/// 习惯 — 最简版：每天打卡
class Habit {
  final String id;
  final String userId;
  final String name;
  final String icon; // emoji
  final int colorIndex; // 习惯色板下标
  final DateTime createdAt;

  const Habit({
    required this.id,
    required this.userId,
    required this.name,
    this.icon = '💪',
    this.colorIndex = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'icon': icon,
        'color_index': colorIndex,
        'created_at': createdAt.toIso8601String(),
      };

  factory Habit.fromMap(Map<String, dynamic> map) => Habit(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        name: map['name'] as String,
        icon: (map['icon'] as String?) ?? '💪',
        colorIndex: (map['color_index'] as int?) ?? 0,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

/// 内置习惯图标库
const List<String> kHabitIcons = [
  '💪', // 健身
  '📚', // 阅读
  '🏃', // 跑步
  '🧘', // 冥想
  '💧', // 喝水
  '🥗', // 健康饮食
  '😴', // 早睡
  '✍️', // 写作
  '🎯', // 专注
  '🎸', // 练习
  '🌅', // 早起
  '🧹', // 整理
];

/// 习惯色板 — 8 色（与 AppColors 场景色一致，便于语义统一）
const List<Color> kHabitPalette = [
  Color(0xFF6366F1), // indigo 专注
  Color(0xFF14B8A6), // teal   健康
  Color(0xFF0EA5E9), // sky    学习
  Color(0xFFF59E0B), // amber  早起
  Color(0xFFF43F5E), // rose   运动
  Color(0xFF8B5CF6), // violet 冥想
  Color(0xFF10B981), // emerald 饮食
  Color(0xFFF97316), // orange 练习
];
