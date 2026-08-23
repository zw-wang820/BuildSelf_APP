import 'dart:convert';
import 'package:buildself/data/models/enums.dart';
import 'package:buildself/data/models/image_ref_model.dart';

/// 目标推进日志
class GoalLog {
  final String id;
  final String goalId;
  final int progressBefore;
  final int progressAfter;
  final String? note;
  final DateTime createdAt;

  GoalLog({
    required this.id,
    required this.goalId,
    required this.progressBefore,
    required this.progressAfter,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'goal_id': goalId,
        'progress_before': progressBefore,
        'progress_after': progressAfter,
        'note': note,
        'created_at': createdAt.toIso8601String(),
      };

  factory GoalLog.fromMap(Map<String, dynamic> map) => GoalLog(
        id: map['id'] as String,
        goalId: map['goal_id'] as String,
        progressBefore: (map['progress_before'] as int?) ?? 0,
        progressAfter: (map['progress_after'] as int?) ?? 0,
        note: map['note'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

/// 书籍模型
class Book {
  final String id;
  final String userId;
  String title;
  String? author;
  ImageRef? coverImage;
  BookStatus status;
  DateTime? startDate;
  DateTime? finishDate;
  int? rating; // 1-5
  List<String> tags;
  int currentPage;
  int totalPages;

  /// 封面渐变色下标（AppColors.bookCovers），null 时按列表序号轮询
  int? coverColor;

  /// 最近阅读时间，用于「最近阅读」排序
  DateTime? lastReadAt;
  final DateTime createdAt;

  Book({
    required this.id,
    required this.userId,
    required this.title,
    this.author,
    this.coverImage,
    this.status = BookStatus.planned,
    this.startDate,
    this.finishDate,
    this.rating,
    this.tags = const [],
    this.currentPage = 0,
    this.totalPages = 0,
    this.coverColor,
    this.lastReadAt,
    required this.createdAt,
  });

  /// 阅读进度百分比（0-100）：已读完=100，无总页数=0
  int get progress {
    if (status == BookStatus.finished) return 100;
    if (totalPages <= 0) return 0;
    return ((currentPage / totalPages) * 100).clamp(0, 100).round();
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'author': author,
        'cover_image': coverImage != null ? jsonEncode(coverImage!.toJson()) : null,
        'status': status.name,
        'start_date': startDate?.toIso8601String(),
        'finish_date': finishDate?.toIso8601String(),
        'rating': rating,
        'tags': jsonEncode(tags),
        'current_page': currentPage,
        'total_pages': totalPages,
        'cover_color': coverColor,
        'last_read_at': lastReadAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  factory Book.fromMap(Map<String, dynamic> map) => Book(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        title: map['title'] as String,
        author: map['author'] as String?,
        coverImage: map['cover_image'] != null
            ? ImageRef.fromJson(jsonDecode(map['cover_image'] as String) as Map<String, dynamic>)
            : null,
        status: BookStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => BookStatus.planned,
        ),
        startDate: map['start_date'] != null ? DateTime.parse(map['start_date'] as String) : null,
        finishDate: map['finish_date'] != null ? DateTime.parse(map['finish_date'] as String) : null,
        rating: map['rating'] as int?,
        tags: map['tags'] != null ? List<String>.from(jsonDecode(map['tags'] as String)) : [],
        currentPage: (map['current_page'] as int?) ?? 0,
        totalPages: (map['total_pages'] as int?) ?? 0,
        coverColor: map['cover_color'] as int?,
        lastReadAt: map['last_read_at'] != null
            ? DateTime.tryParse(map['last_read_at'] as String)
            : null,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

/// 读书笔记模型
class ReadingNote {
  final String id;
  final String bookId;
  NoteType noteType;
  String? chapter;
  String content;
  final DateTime createdAt;
  DateTime updatedAt;

  ReadingNote({
    required this.id,
    required this.bookId,
    required this.noteType,
    this.chapter,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'book_id': bookId,
        'note_type': noteType.name,
        'chapter': chapter,
        'content': content,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory ReadingNote.fromMap(Map<String, dynamic> map) => ReadingNote(
        id: map['id'] as String,
        bookId: map['book_id'] as String,
        noteType: NoteType.values.firstWhere(
          (e) => e.name == map['note_type'],
          orElse: () => NoteType.insight,
        ),
        chapter: map['chapter'] as String?,
        content: map['content'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );
}
