import 'package:uuid/uuid.dart';
import 'package:buildself/data/database/database_provider.dart';
import 'package:buildself/data/database/tables.dart';
import 'package:buildself/features/todo/models/todo_model.dart';

/// 待办仓库
class TodoRepository {
  final DatabaseProvider _db = DatabaseProvider.instance;
  final _uuid = const Uuid();

  /// 创建待办
  Future<Todo> create({
    required String userId,
    required String content,
    String note = '',
    required TodoCategory category,
    required TodoPriority priority,
    required TodoDueType dueType,
    DateTime? dueDate,
  }) async {
    final now = DateTime.now();
    final todo = Todo(
      id: _uuid.v4(),
      userId: userId,
      content: content,
      note: note,
      category: category,
      priority: priority,
      dueType: dueType,
      dueDate: dueDate,
      createdAt: now,
    );
    await _db.insert(AppTables.todos, todo.toMap());
    return todo;
  }

  /// 列表查询
  /// [category] 指定分类过滤；[completed] 为 true 仅已完成、false 仅未完成、null 全部
  /// [limit] 限制返回条数（预览场景使用）
  Future<List<Todo>> getAll(
    String userId, {
    TodoCategory? category,
    bool? completed,
    int? limit,
  }) async {
    final where = <String>['user_id = ?'];
    final args = <Object?>[userId];
    if (category != null) {
      where.add('category = ?');
      args.add(category.name);
    }
    if (completed != null) {
      where.add('is_completed = ?');
      args.add(completed ? 1 : 0);
    }
    final maps = await _db.queryAll(
      AppTables.todos,
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: completed == true ? 'completed_at DESC' : 'created_at DESC',
      limit: limit,
    );
    return maps.map(Todo.fromMap).toList();
  }

  /// 进行中（未完成）待办数量 — 用于首页数据条
  Future<int> getActiveCount(String userId) async {
    final maps = await _db.queryAll(
      AppTables.todos,
      where: 'user_id = ? AND is_completed = ?',
      whereArgs: [userId, 0],
    );
    return maps.length;
  }

  /// 标记完成
  Future<void> markCompleted(String id, {DateTime? at}) async {
    await _db.update(
      AppTables.todos,
      {
        'is_completed': 1,
        'completed_at': (at ?? DateTime.now()).toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 恢复为未完成
  Future<void> markActive(String id) async {
    await _db.update(
      AppTables.todos,
      {'is_completed': 0, 'completed_at': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 物理删除
  Future<void> delete(String id) async {
    await _db.delete(AppTables.todos, where: 'id = ?', whereArgs: [id]);
  }
}
