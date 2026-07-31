import 'dart:convert';
import 'package:buildself/data/models/enums.dart';
import 'package:buildself/data/models/image_ref_model.dart';

/// 生活记录模型
class LifeRecord {
  /// 兼容旧数据：将枚举名映射为中文标签
  static String _normalizeRecordType(String raw) {
    const map = {
      'beauty': '美好',
      'insight': '感悟',
      'reflection': '反思',
    };
    return map[raw] ?? raw;
  }
  final String id;
  final String userId;
  String title;
  String content;
  String recordType;
  Mood? mood;
  Weather? weather;
  String? location;
  List<ImageRef> images;
  List<String> tags;
  final DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;

  LifeRecord({
    required this.id,
    required this.userId,
    this.title = '',
    required this.content,
    required this.recordType,
    this.mood,
    this.weather,
    this.location,
    this.images = const [],
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'content': content,
        'record_type': recordType,
        'mood': mood?.name,
        'weather': weather?.name,
        'location': location,
        'images': jsonEncode(images.map((e) => e.toJson()).toList()),
        'tags': jsonEncode(tags),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
      };

  factory LifeRecord.fromMap(Map<String, dynamic> map) => LifeRecord(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        title: (map['title'] as String?) ?? '',
        content: map['content'] as String,
        recordType: _normalizeRecordType(map['record_type'] as String),
        mood: map['mood'] != null
            ? Mood.values.firstWhere((e) => e.name == map['mood'], orElse: () => Mood.neutral)
            : null,
        weather: map['weather'] != null
            ? Weather.values.firstWhere((e) => e.name == map['weather'], orElse: () => Weather.sunny)
            : null,
        location: map['location'] as String?,
        images: map['images'] != null
            ? (jsonDecode(map['images'] as String) as List)
                .map((e) => ImageRef.fromJson(e as Map<String, dynamic>))
                .toList()
            : [],
        tags: map['tags'] != null ? List<String>.from(jsonDecode(map['tags'] as String)) : [],
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
        deletedAt: map['deleted_at'] != null ? DateTime.parse(map['deleted_at'] as String) : null,
      );
}
