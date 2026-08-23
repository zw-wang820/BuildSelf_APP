import 'dart:convert';
import 'package:buildself/data/models/enums.dart';
import 'package:buildself/data/models/image_ref_model.dart';

/// 里程碑
class Milestone {
  final String id;
  String title;
  bool isCompleted;
  DateTime? completedAt;

  Milestone({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.completedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'is_completed': isCompleted,
        'completed_at': completedAt?.toIso8601String(),
      };

  factory Milestone.fromJson(Map<String, dynamic> json) => Milestone(
        id: json['id'] as String,
        title: json['title'] as String,
        isCompleted: json['is_completed'] as bool? ?? false,
        completedAt: json['completed_at'] != null
            ? DateTime.parse(json['completed_at'] as String)
            : null,
      );
}

/// 清单项
class ChecklistItem {
  final String id;
  String title;
  bool isCompleted;

  ChecklistItem({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'is_completed': isCompleted,
      };

  factory ChecklistItem.fromJson(Map<String, dynamic> json) => ChecklistItem(
        id: json['id'] as String,
        title: json['title'] as String,
        isCompleted: json['is_completed'] as bool? ?? false,
      );
}

/// 奖励
class Reward {
  final RewardType type;
  String description;
  ImageRef? image;
  double? estimatedCost;

  Reward({
    required this.type,
    required this.description,
    this.image,
    this.estimatedCost,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'description': description,
        'image': image?.toJson(),
        'estimated_cost': estimatedCost,
      };

  factory Reward.fromJson(Map<String, dynamic> json) => Reward(
        type: RewardType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => RewardType.other,
        ),
        description: json['description'] as String,
        image: json['image'] != null
            ? ImageRef.fromJson(json['image'] as Map<String, dynamic>)
            : null,
        estimatedCost: (json['estimated_cost'] as num?)?.toDouble(),
      );
}

/// 目标模型
class Goal {
  final String id;
  final String userId;
  String title;
  String description;
  GoalType goalType;
  GoalCategory? category;
  DateTime startDate;
  DateTime? targetDate;
  ProgressType progressType;
  int progress; // 0-100
  List<Milestone> milestones;
  List<ChecklistItem> checklist;
  Reward reward;
  GoalStatus status;
  final DateTime createdAt;
  DateTime updatedAt;
  DateTime? completedAt;
  DateTime? deletedAt;

  Goal({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    required this.goalType,
    this.category,
    required this.startDate,
    this.targetDate,
    required this.progressType,
    this.progress = 0,
    this.milestones = const [],
    this.checklist = const [],
    required this.reward,
    this.status = GoalStatus.active,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  /// 计算实际进度（milestone/checklist 模式自动计算）
  int get calculatedProgress {
    switch (progressType) {
      case ProgressType.manual:
        return progress;
      case ProgressType.milestone:
        if (milestones.isEmpty) return 0;
        final completed = milestones.where((m) => m.isCompleted).length;
        return (completed / milestones.length * 100).round();
      case ProgressType.checklist:
        if (checklist.isEmpty) return 0;
        final completed = checklist.where((c) => c.isCompleted).length;
        return (completed / checklist.length * 100).round();
    }
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'description': description,
        'goal_type': goalType.name,
        'category': category?.name,
        'start_date': startDate.toIso8601String(),
        'target_date': targetDate?.toIso8601String(),
        'progress_type': progressType.name,
        'progress': progress,
        'milestones': jsonEncode(milestones.map((m) => m.toJson()).toList()),
        'checklist': jsonEncode(checklist.map((c) => c.toJson()).toList()),
        'reward': jsonEncode(reward.toJson()),
        'status': status.name,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
      };

  factory Goal.fromMap(Map<String, dynamic> map) => Goal(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        title: map['title'] as String,
        description: (map['description'] as String?) ?? '',
        goalType: GoalType.values.firstWhere(
          (e) => e.name == map['goal_type'],
          orElse: () => GoalType.shortTerm,
        ),
        category: map['category'] != null
            ? GoalCategory.values.firstWhere(
                (e) => e.name == map['category'],
                orElse: () => GoalCategory.other,
              )
            : null,
        startDate: DateTime.parse(map['start_date'] as String),
        targetDate: map['target_date'] != null
            ? DateTime.parse(map['target_date'] as String)
            : null,
        progressType: ProgressType.values.firstWhere(
          (e) => e.name == map['progress_type'],
          orElse: () => ProgressType.manual,
        ),
        progress: (map['progress'] as int?) ?? 0,
        milestones: map['milestones'] != null
            ? (jsonDecode(map['milestones'] as String) as List)
                .map((e) => Milestone.fromJson(e as Map<String, dynamic>))
                .toList()
            : [],
        checklist: map['checklist'] != null
            ? (jsonDecode(map['checklist'] as String) as List)
                .map((e) => ChecklistItem.fromJson(e as Map<String, dynamic>))
                .toList()
            : [],
        reward: Reward.fromJson(
            jsonDecode(map['reward'] as String) as Map<String, dynamic>),
        status: GoalStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => GoalStatus.active,
        ),
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
        completedAt: map['completed_at'] != null
            ? DateTime.parse(map['completed_at'] as String)
            : null,
        deletedAt: map['deleted_at'] != null
            ? DateTime.parse(map['deleted_at'] as String)
            : null,
      );
}
