import 'dart:convert';
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
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  /// 兼容旧数据：将枚举名映射为中文标签
  static String _normalizeRecordType(String raw) {
    const map = {
      'experience': '经验',
      'insight': '心得',
      'reflection': '反思',
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
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
        deletedAt: map['deleted_at'] != null
            ? DateTime.parse(map['deleted_at'] as String)
            : null,
      );
}
