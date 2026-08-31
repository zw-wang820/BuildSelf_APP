import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/data/models/enums.dart';
import 'package:buildself/data/models/image_ref_model.dart';

/// 工作记录模型
class WorkNote {
  final String id;
  final String userId;
  String title;
  String content;
  String recordType;
  List<String> tags;
  Mood? mood;
  List<ImageRef> attachments;

  /// 待学习项完成状态（仅 recordType = 待学习项 时使用）
  bool done;
  DateTime? doneAt;

  final DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;

  WorkNote({
    required this.id,
    required this.userId,
    this.title = '',
    required this.content,
    required this.recordType,
    this.tags = const [],
    this.mood,
    this.attachments = const [],
    this.done = false,
    this.doneAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  /// 兼容旧数据：将旧枚举名/旧中文类型归并为新 4 类
  static String _normalizeRecordType(String raw) {
    const map = {
      'experience': '心得',
      'insight': '心得',
      'reflection': '思考',
      '经验': '心得',
      '反思': '思考',
    };
    return map[raw] ?? raw;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'content': content,
        'record_type': recordType,
        'tags': jsonEncode(tags),
        'mood': mood?.name,
        'attachments': jsonEncode(attachments.map((e) => e.toJson()).toList()),
        'done': done ? 1 : 0,
        'done_at': doneAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
      };

  factory WorkNote.fromMap(Map<String, dynamic> map) => WorkNote(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        title: (map['title'] as String?) ?? '',
        content: map['content'] as String,
        recordType: _normalizeRecordType(map['record_type'] as String),
        tags: map['tags'] != null
            ? List<String>.from(jsonDecode(map['tags'] as String))
            : [],
        mood: map['mood'] != null
            ? Mood.values.firstWhere(
                (e) => e.name == map['mood'],
                orElse: () => Mood.neutral,
              )
            : null,
        attachments: map['attachments'] != null
            ? (jsonDecode(map['attachments'] as String) as List)
                .map((e) => ImageRef.fromJson(e as Map<String, dynamic>))
                .toList()
            : [],
        done: (map['done'] as int? ?? 0) == 1,
        doneAt: map['done_at'] != null
            ? DateTime.parse(map['done_at'] as String)
            : null,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
        deletedAt: map['deleted_at'] != null
            ? DateTime.parse(map['deleted_at'] as String)
            : null,
      );
}

/// 记录类型对应的 emoji（自定义分类返回 📌）
String workTypeEmoji(String type) {
  for (final t in WorkRecordType.values) {
    if (t.label == type) return t.emoji;
  }
  return '📌';
}

/// 记录类型对应的场景色（自定义分类回落工作主题色）
Color workTypeColor(String type) {
  switch (type) {
    case '思考':
      return AppColors.info;
    case '工作日志':
      return AppColors.todo;
    case '待学习项':
      return AppColors.success;
    default:
      return AppColors.work;
  }
}
