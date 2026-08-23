import 'dart:convert';
import 'package:buildself/data/models/enums.dart';
import 'package:buildself/data/models/image_ref_model.dart';

/// 碎碎念模型
class Murmur {
  final String id;
  final String userId;
  String content;
  Mood? mood;
  List<String> tags;
  List<ImageRef> images;
  final DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;

  Murmur({
    required this.id,
    required this.userId,
    required this.content,
    this.mood,
    this.tags = const [],
    this.images = const [],
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'content': content,
        'mood': mood?.name,
        'tags': jsonEncode(tags),
        'images': jsonEncode(images.map((e) => e.toJson()).toList()),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
      };

  factory Murmur.fromMap(Map<String, dynamic> map) => Murmur(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        content: map['content'] as String,
        mood: map['mood'] != null
            ? Mood.values.firstWhere((e) => e.name == map['mood'], orElse: () => Mood.neutral)
            : null,
        tags: map['tags'] != null ? List<String>.from(jsonDecode(map['tags'] as String)) : [],
        images: map['images'] != null
            ? (jsonDecode(map['images'] as String) as List)
                .map((e) => ImageRef.fromJson(e as Map<String, dynamic>))
                .toList()
            : [],
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
        deletedAt: map['deleted_at'] != null ? DateTime.parse(map['deleted_at'] as String) : null,
      );
}
