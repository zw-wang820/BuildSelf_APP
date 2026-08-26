import 'package:flutter/material.dart';
import 'package:buildself/features/todo/models/todo_model.dart';

/// 自定义分类色板（8 色，避开内置四类主色）
const List<Color> customCategoryPalette = [
  Color(0xFFEC4899), // pink-500
  Color(0xFF14B8A6), // teal-500
  Color(0xFF6366F1), // indigo-500
  Color(0xFFF59E0B), // amber-500
  Color(0xFF06B6D4), // cyan-500
  Color(0xFFF43F5E), // rose-500
  Color(0xFF84CC16), // lime-500
  Color(0xFF64748B), // slate-500
];

/// 待办分类展示信息 — 内置（TodoCategory 枚举）或自定义（todo_categories 表）
class TodoCategoryInfo {
  /// 分类名：内置枚举 name（work/life/reading/study）或自定义名
  final String name;

  /// 显示名（自定义分类 = name）
  final String label;

  final String emoji;

  final Color color;

  final bool isCustom;

  /// 自定义分类 id（内置为 null）
  final String? id;

  const TodoCategoryInfo({
    required this.name,
    required this.label,
    required this.emoji,
    required this.color,
    required this.isCustom,
    this.id,
  });

  factory TodoCategoryInfo.builtin(TodoCategory c) => TodoCategoryInfo(
        name: c.name,
        label: c.label,
        emoji: c.emoji,
        color: c.color,
        isCustom: false,
      );

  factory TodoCategoryInfo.custom({
    required String id,
    required String name,
    required String emoji,
    required int colorIndex,
  }) =>
      TodoCategoryInfo(
        name: name,
        label: name,
        emoji: emoji,
        color: customCategoryPalette[colorIndex % customCategoryPalette.length],
        isCustom: true,
        id: id,
      );

  /// 解析分类名 → 展示信息：内置优先，未命中查自定义，兜底「工作」
  static TodoCategoryInfo resolve(
    String name,
    List<TodoCategoryInfo> customs,
  ) {
    for (final c in TodoCategory.values) {
      if (c.name == name) return TodoCategoryInfo.builtin(c);
    }
    for (final c in customs) {
      if (c.name == name) return c;
    }
    return TodoCategoryInfo.builtin(TodoCategory.work);
  }

  /// 全量分类列表（内置 + 自定义）
  static List<TodoCategoryInfo> all(List<TodoCategoryInfo> customs) => [
        ...TodoCategory.values.map(TodoCategoryInfo.builtin),
        ...customs,
      ];
}
