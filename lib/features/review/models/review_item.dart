import 'review_quadrant.dart';

/// KISS 复盘 — 单条复盘项
///
/// 归属某日 session 的某一象限。删除为物理删除（编辑性质操作，不入回收站）。
class ReviewItem {
  final String id;
  final String sessionId;
  ReviewQuadrant quadrant;
  String content;

  /// 象限内排序（插入即追加，不重排）
  final int position;
  final DateTime createdAt;
  DateTime updatedAt;

  ReviewItem({
    required this.id,
    required this.sessionId,
    required this.quadrant,
    required this.content,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'session_id': sessionId,
        'quadrant': quadrant.storage,
        'content': content,
        'position': position,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory ReviewItem.fromMap(Map<String, dynamic> map) => ReviewItem(
        id: map['id'] as String,
        sessionId: map['session_id'] as String,
        quadrant: ReviewQuadrant.fromStorage(map['quadrant'] as String?),
        content: map['content'] as String,
        position: (map['position'] as int?) ?? 0,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );
}
