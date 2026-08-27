import 'package:uuid/uuid.dart';
import 'package:buildself/data/database/database_provider.dart';
import 'package:buildself/data/database/tables.dart';
import 'package:buildself/features/habit/models/habit_model.dart';

/// 习惯打卡仓库 — 最简版：每天打卡
class HabitRepository {
  final DatabaseProvider _db = DatabaseProvider.instance;
  final _uuid = const Uuid();

  /// 日期 → yyyy-MM-dd
  static String fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// 创建习惯
  Future<Habit> create({
    required String userId,
    required String name,
    String icon = '💪',
    int colorIndex = 0,
  }) async {
    final habit = Habit(
      id: _uuid.v4(),
      userId: userId,
      name: name,
      icon: icon,
      colorIndex: colorIndex,
      createdAt: DateTime.now(),
    );
    await _db.insert(AppTables.habits, habit.toMap());
    return habit;
  }

  /// 全部习惯（按创建时间倒序）
  Future<List<Habit>> getAll(String userId) async {
    final maps = await _db.queryAll(
      AppTables.habits,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return maps.map(Habit.fromMap).toList();
  }

  /// 单个习惯（日历统计页用）
  Future<Habit?> getById(String habitId) async {
    final map = await _db.queryOne(
      AppTables.habits,
      where: 'id = ?',
      whereArgs: [habitId],
    );
    return map != null ? Habit.fromMap(map) : null;
  }

  /// 单个习惯的全部打卡日期集合
  Future<Set<String>> getLogsByHabitId(String habitId) async {
    final maps = await _db.queryAll(
      AppTables.habitLogs,
      where: 'habit_id = ?',
      whereArgs: [habitId],
    );
    return maps.map((m) => m['date'] as String).toSet();
  }

  /// 习惯全部打卡日期集合 — habitId -> Set<yyyy-MM-dd>
  Future<Map<String, Set<String>>> getLogsByHabit(String userId) async {
    final habits = await getAll(userId);
    if (habits.isEmpty) return {};
    final ids = habits.map((h) => h.id).toList();
    final placeholders = List.filled(ids.length, '?').join(',');
    final maps = await _db.queryAll(
      AppTables.habitLogs,
      where: 'habit_id IN ($placeholders)',
      whereArgs: ids,
    );
    final result = <String, Set<String>>{};
    for (final h in habits) {
      result[h.id] = <String>{};
    }
    for (final m in maps) {
      result[m['habit_id']]?.add(m['date'] as String);
    }
    return result;
  }

  /// 今日已打卡的习惯数 — 用于首页数据条
  Future<int> getTodayDoneCount(String userId) async {
    final logs = await getLogsByHabit(userId);
    final today = fmtDate(DateTime.now());
    return logs.values.where((dates) => dates.contains(today)).length;
  }

  /// 打卡 / 取消打卡。返回 true 表示本次为打卡成功
  Future<bool> toggle(String habitId, DateTime date) async {
    final ds = fmtDate(date);
    final existing = await _db.queryAll(
      AppTables.habitLogs,
      where: 'habit_id = ? AND date = ?',
      whereArgs: [habitId, ds],
    );
    if (existing.isNotEmpty) {
      await _db.delete(
        AppTables.habitLogs,
        where: 'habit_id = ? AND date = ?',
        whereArgs: [habitId, ds],
      );
      return false;
    }
    await _db.insert(AppTables.habitLogs, {
      'id': _uuid.v4(),
      'habit_id': habitId,
      'date': ds,
    });
    return true;
  }

  /// 连续打卡天数 — 今天没打从昨天起算（不打断连续）
  static int streakOf(Set<String> dates) {
    var d = DateTime.now();
    if (!dates.contains(fmtDate(d))) {
      d = d.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (dates.contains(fmtDate(d))) {
      streak++;
      d = d.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// 所有习惯中最长连续天数
  static int maxStreak(Map<String, Set<String>> logsByHabit) {
    var max = 0;
    for (final dates in logsByHabit.values) {
      final s = streakOf(dates);
      if (s > max) max = s;
    }
    return max;
  }

  /// 指定月份内打卡天数（所有习惯合计，按日期去重）
  static int monthCheckDays(Map<String, Set<String>> logsByHabit, DateTime month) {
    final prefix =
        '${month.year}-${month.month.toString().padLeft(2, '0')}';
    final days = <String>{};
    for (final dates in logsByHabit.values) {
      for (final d in dates) {
        if (d.startsWith(prefix)) days.add(d);
      }
    }
    return days.length;
  }
}
