import 'review_item.dart';
import 'review_quadrant.dart';

/// KISS 复盘 — 单日复盘实例
///
/// 每用户每日一行（review_date = YYYY-MM-DD）。summary 为「生成总结」保存的文本。
/// 删除为软删除（deleted_at 非空即视为已删除，可进回收站恢复）。
class ReviewSession {
  final String id;
  final String userId;

  /// 复盘日期 YYYY-MM-DD（本地时区）
  final String reviewDate;
  String? summary;
  DateTime? summaryAt;
  final DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;

  /// 各象限条目（由 item 装配填充，非 DB 直存）
  Map<ReviewQuadrant, List<ReviewItem>> items = {};

  ReviewSession({
    required this.id,
    required this.userId,
    required this.reviewDate,
    this.summary,
    this.summaryAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  /// 全部条目数
  int get itemCount =>
      items.values.fold(0, (sum, list) => sum + list.length);

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'review_date': reviewDate,
        'summary': summary,
        'summary_at': summaryAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
      };

  factory ReviewSession.fromMap(Map<String, dynamic> map) => ReviewSession(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        reviewDate: map['review_date'] as String,
        summary: map['summary'] as String?,
        summaryAt: map['summary_at'] != null
            ? DateTime.parse(map['summary_at'] as String)
            : null,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
        deletedAt: map['deleted_at'] != null
            ? DateTime.parse(map['deleted_at'] as String)
            : null,
      );
}
