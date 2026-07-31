import 'package:uuid/uuid.dart';
import 'package:buildself/data/database/database_provider.dart';
import 'package:buildself/data/database/tables.dart';
import 'package:buildself/data/models/enums.dart';
import 'package:buildself/data/models/goal_model.dart';
import 'package:buildself/data/models/reading_models.dart';

/// 目标仓库
class GoalRepository {
  final DatabaseProvider _db = DatabaseProvider.instance;
  final _uuid = const Uuid();

  /// 创建目标
  Future<Goal> create({
    required String userId,
    required String title,
    String description = '',
    required GoalType goalType,
    GoalCategory? category,
    DateTime? targetDate,
    required ProgressType progressType,
    List<Milestone> milestones = const [],
    List<ChecklistItem> checklist = const [],
    required Reward reward,
  }) async {
    final now = DateTime.now();
    final goal = Goal(
      id: _uuid.v4(),
      userId: userId,
      title: title,
      description: description,
      goalType: goalType,
      category: category,
      startDate: now,
      targetDate: targetDate,
      progressType: progressType,
      milestones: milestones,
      checklist: checklist,
      reward: reward,
      createdAt: now,
      updatedAt: now,
    );
    await _db.insert(AppTables.goals, goal.toMap());
    return goal;
  }

  /// 更新目标
  Future<Goal> update(Goal goal) async {
    goal.updatedAt = DateTime.now();
    await _db.update(AppTables.goals, goal.toMap(),
        where: 'id = ?', whereArgs: [goal.id]);
    return goal;
  }

  /// 更新进度并记录日志
  Future<void> updateProgress(Goal goal, int newProgress, {String? note}) async {
    final oldProgress = goal.progress;
    goal.progress = newProgress;
    goal.updatedAt = DateTime.now();

    if (newProgress >= 100 && goal.status == GoalStatus.active) {
      goal.status = GoalStatus.completed;
      goal.completedAt = DateTime.now();
    }

    await _db.transaction((txn) async {
      await txn.update(AppTables.goals, goal.toMap(),
          where: 'id = ?', whereArgs: [goal.id]);
      // 记录日志
      final log = GoalLog(
        id: _uuid.v4(),
        goalId: goal.id,
        progressBefore: oldProgress,
        progressAfter: newProgress,
        note: note,
        createdAt: DateTime.now(),
      );
      await txn.insert(AppTables.goalLogs, log.toMap());
    });
  }

  /// 标记目标完成
  Future<void> markCompleted(Goal goal) async {
    goal.status = GoalStatus.completed;
    goal.completedAt = DateTime.now();
    goal.progress = 100;
    goal.updatedAt = DateTime.now();
    await _db.update(AppTables.goals, goal.toMap(),
        where: 'id = ?', whereArgs: [goal.id]);
  }

  /// 放弃目标
  Future<void> abandon(Goal goal) async {
    goal.status = GoalStatus.abandoned;
    goal.updatedAt = DateTime.now();
    await _db.update(AppTables.goals, goal.toMap(),
        where: 'id = ?', whereArgs: [goal.id]);
  }

  Future<void> softDelete(String id) async => _db.softDelete(AppTables.goals, id);
  Future<void> delete(String id) async =>
      _db.delete(AppTables.goals, where: 'id = ?', whereArgs: [id]);

  Future<Goal?> getById(String id) async {
    final map = await _db.queryOne(AppTables.goals, where: 'id = ?', whereArgs: [id]);
    return map != null ? Goal.fromMap(map) : null;
  }

  /// 按类型获取目标
  Future<List<Goal>> getByType(String userId, GoalType type, {GoalStatus? status}) async {
    String where = 'user_id = ? AND goal_type = ? AND deleted_at IS NULL';
    List<Object?> args = [userId, type.name];
    if (status != null) {
      where += ' AND status = ?';
      args.add(status.name);
    }
    final maps = await _db.queryAll(AppTables.goals,
        where: where, whereArgs: args, orderBy: 'updated_at DESC');
    return maps.map(Goal.fromMap).toList();
  }

  /// 获取进行中的目标
  Future<List<Goal>> getActiveGoals(String userId) async {
    final maps = await _db.queryAll(AppTables.goals,
        where: 'user_id = ? AND status = ? AND deleted_at IS NULL',
        whereArgs: [userId, GoalStatus.active.name],
        orderBy: 'updated_at DESC');
    return maps.map(Goal.fromMap).toList();
  }

  /// 获取已完成目标（成就墙）
  Future<List<Goal>> getCompletedGoals(String userId) async {
    final maps = await _db.queryAll(AppTables.goals,
        where: 'user_id = ? AND status = ? AND deleted_at IS NULL',
        whereArgs: [userId, GoalStatus.completed.name],
        orderBy: 'completed_at DESC');
    return maps.map(Goal.fromMap).toList();
  }

  /// 获取目标推进日志
  Future<List<GoalLog>> getGoalLogs(String goalId) async {
    final maps = await _db.queryAll(AppTables.goalLogs,
        where: 'goal_id = ?', whereArgs: [goalId], orderBy: 'created_at DESC');
    return maps.map(GoalLog.fromMap).toList();
  }

  /// 搜索目标
  Future<List<Goal>> search(String userId, String keyword) async {
    final maps = await _db.queryAll(AppTables.goals,
        where: 'user_id = ? AND deleted_at IS NULL AND (title LIKE ? OR description LIKE ?)',
        whereArgs: [userId, '%$keyword%', '%$keyword%'],
        orderBy: 'updated_at DESC');
    return maps.map(Goal.fromMap).toList();
  }
}
