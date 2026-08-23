import 'package:uuid/uuid.dart';
import 'package:buildself/data/database/database_provider.dart';
import 'package:buildself/data/database/tables.dart';
import 'package:buildself/features/todo/models/todo_model.dart';

/// 待办仓库
class TodoRepository {
  final DatabaseProvider _db = DatabaseProvider.instance;
  final _uuid = const Uuid();

  /// 创建待办
  /// [repeat] 传入非 none 规则时，本条即为重复模板（时间驱动，到周期自动生成新实例）
  Future<Todo> create({
    required String userId,
    required String content,
    String note = '',
    required TodoCategory category,
    required TodoPriority priority,
    required TodoDueType dueType,
    DateTime? dueDate,
    TodoRepeat? repeat,
  }) async {
    final now = DateTime.now();
    final isRepeat = repeat != null && !repeat.isNone;
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
      repeat: isRepeat ? repeat : null,
      // 模板自身 origin 为空；后续自动生成的实例指向模板 id
      repeatOriginId: null,
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

  /// 更新整条待办（编辑保存）
  Future<void> update(Todo todo) async {
    await _db.update(
      AppTables.todos,
      todo.toMap(),
      where: 'id = ?',
      whereArgs: [todo.id],
    );
  }

  /// 物理删除
  Future<void> delete(String id) async {
    await _db.delete(AppTables.todos, where: 'id = ?', whereArgs: [id]);
  }

  // ==================== 周期重复 ====================

  /// 日期键（yyyy-MM-dd）
  static String dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// 计算 [after] 之后的下一个周期日期（不含 after 当日）
  static DateTime? nextOccurrence(DateTime after, TodoRepeat rule) {
    switch (rule.type) {
      case TodoRepeatType.none:
        return null;
      case TodoRepeatType.daily:
        return after.add(Duration(days: rule.interval));
      case TodoRepeatType.weekly:
        if (rule.weekdays.isNotEmpty) {
          // 从 after 下一天起找第一个匹配的周几（扫描 interval 周内）
          var d = after.add(const Duration(days: 1));
          for (var i = 0; i < 7 * rule.interval; i++) {
            if (rule.weekdays.contains(d.weekday)) return d;
            d = d.add(const Duration(days: 1));
          }
          return null;
        }
        return after.add(Duration(days: 7 * rule.interval));
      case TodoRepeatType.monthly:
        final m = after.month + rule.interval;
        final year = after.year + (m - 1) ~/ 12;
        final month = (m - 1) % 12 + 1;
        final day = _clampDay(after.day, year, month);
        return DateTime(year, month, day);
      case TodoRepeatType.yearly:
        final year = after.year + rule.interval;
        final day = _clampDay(after.day, year, after.month);
        return DateTime(year, after.month, day);
    }
  }

  /// 惰性生成最近一期缺失的重复实例（时间驱动）。
  ///
  /// 对每个重复模板：沿周期从模板首期推进，取「<= now 的最后一个周期日期」；
  /// 若该期尚未生成且未达终止条件，则补建一条。错过多期也只补最近一期。
  /// 返回本次生成的实例数。
  Future<int> ensureDueInstances(String userId, {DateTime? now}) async {
    final nowDate = now ?? DateTime.now();
    final maps = await _db.queryAll(
      AppTables.todos,
      where: 'user_id = ? AND repeat_type != ?',
      whereArgs: [userId, TodoRepeatType.none.name],
    );
    if (maps.isEmpty) return 0;
    final todos = maps.map(Todo.fromMap).toList();

    // 按模板分组：模板 repeatOriginId 为空（用自身 id），实例指向模板 id
    final groups = <String, List<Todo>>{};
    for (final t in todos) {
      final origin = t.repeatOriginId ?? t.id;
      groups.putIfAbsent(origin, () => []).add(t);
    }

    var created = 0;
    for (final group in groups.values) {
      Todo? template;
      for (final t in group) {
        if (t.repeatOriginId == null) {
          template = t;
          break;
        }
      }
      template ??= group.first;
      final rule = template.repeat;
      if (rule == null || rule.isNone || template.dueDate == null) continue;

      // 已达总实例数上限
      final maxCount = rule.maxCount;
      if (maxCount != null && group.length >= maxCount) continue;

      // 组内已存在的到期日期
      final dues = <String>{
        for (final t in group)
          if (t.dueDate != null) dateKey(t.dueDate!),
      };

      // 沿周期推进，记录最后一个 <= now 的周期日期
      var cursor = template.dueDate!;
      DateTime? lastPeriod;
      var safety = 0;
      while (safety++ < 2000) {
        final next = nextOccurrence(cursor, rule);
        if (next == null) break;
        if (rule.endDate != null && next.isAfter(_endOfDay(rule.endDate!))) break;
        if (next.isAfter(nowDate)) break;
        lastPeriod = next;
        cursor = next;
      }
      if (lastPeriod == null) continue; // 尚未到第一个周期
      if (dues.contains(dateKey(lastPeriod))) continue; // 最近一期已存在
      if (maxCount != null && group.length + 1 > maxCount) continue;

      await _db.insert(AppTables.todos, {
        ...template.toMap(),
        'id': _uuid.v4(),
        'is_completed': 0,
        'completed_at': null,
        'due_date': lastPeriod.toIso8601String(),
        'created_at': nowDate.toIso8601String(),
        'repeat_origin_id': template.repeatOriginId ?? template.id,
      });
      created++;
    }
    return created;
  }

  static int _clampDay(int day, int year, int month) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return day > lastDay ? lastDay : day;
  }

  static DateTime _endOfDay(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59, 59);
}
