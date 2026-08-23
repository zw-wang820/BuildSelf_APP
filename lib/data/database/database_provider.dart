import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:buildself/core/constants/app_constants.dart';
import 'package:buildself/data/database/tables.dart';

/// 数据库 Provider — 单例管理 SQLite 数据库连接
///
/// 负责：
/// 1. 数据库创建与版本管理
/// 2. 建表与索引
/// 3. 提供 CRUD 基础方法
class DatabaseProvider {
  DatabaseProvider._();
  static final DatabaseProvider instance = DatabaseProvider._();

  Database? _database;

  /// 获取数据库实例
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(documentsDir.path, AppConstants.databaseName);

    return await openDatabase(
      dbPath,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 创建所有表
    for (final sql in AppSql.allCreateStatements) {
      await db.execute(sql);
    }
    // 创建索引
    for (final sql in AppSql.indexStatements) {
      await db.execute(sql);
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 后续版本迁移脚本在此添加
    // v2: 新增待办表
    if (oldVersion < 2) {
      await db.execute(AppSql.createTodos);
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_todos_user ON ${AppTables.todos}(user_id)',
      );
    }
    // v3: 书籍新增阅读进度 / 封面色 / 最近阅读字段
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE ${AppTables.books} ADD COLUMN current_page INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE ${AppTables.books} ADD COLUMN total_pages INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE ${AppTables.books} ADD COLUMN cover_color INTEGER',
      );
      await db.execute(
        'ALTER TABLE ${AppTables.books} ADD COLUMN last_read_at TEXT',
      );
    }
    // v4: 新增习惯打卡表
    if (oldVersion < 4) {
      await db.execute(AppSql.createHabits);
      await db.execute(AppSql.createHabitLogs);
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_habits_user ON ${AppTables.habits}(user_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_habit_logs_habit ON ${AppTables.habitLogs}(habit_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_habit_logs_date ON ${AppTables.habitLogs}(date)',
      );
    }
  }

  // ==================== 通用 CRUD 方法 ====================

  /// 插入记录
  Future<int> insert(String table, Map<String, dynamic> values) async {
    final db = await database;
    return await db.insert(table, values);
  }

  /// 批量插入
  Future<void> batchInsert(String table, List<Map<String, dynamic>> valuesList) async {
    final db = await database;
    final batch = db.batch();
    for (final values in valuesList) {
      batch.insert(table, values);
    }
    await batch.commit(noResult: true);
  }

  /// 查询单条记录
  Future<Map<String, dynamic>?> queryOne(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    final results = await db.query(table, where: where, whereArgs: whereArgs, limit: 1);
    return results.isEmpty ? null : results.first;
  }

  /// 查询多条记录
  Future<List<Map<String, dynamic>>> queryAll(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  /// 更新记录
  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return await db.update(table, values, where: where, whereArgs: whereArgs);
  }

  /// 删除记录（物理删除）
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  /// 软删除（设置 deleted_at）
  Future<int> softDelete(
    String table,
    String id, {
    DateTime? deletedAt,
  }) async {
    final db = await database;
    return await db.update(
      table,
      {
        'deleted_at': (deletedAt ?? DateTime.now()).toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 恢复软删除
  Future<int> restore(String table, String id) async {
    final db = await database;
    return await db.update(
      table,
      {
        'deleted_at': null,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 执行原始 SQL
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<Object?>? arguments]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  Future<int> rawUpdate(String sql, [List<Object?>? arguments]) async {
    final db = await database;
    return await db.rawUpdate(sql, arguments);
  }

  Future<int> rawDelete(String sql, [List<Object?>? arguments]) async {
    final db = await database;
    return await db.rawDelete(sql, arguments);
  }

  /// 事务执行
  Future<T> transaction<T>(Future<T> Function(dynamic txn) action) async {
    final db = await database;
    return await db.transaction((txn) async {
      return await action(txn);
    });
  }

  /// 清理过期回收站数据（超过30天）
  Future<void> purgeExpiredTrash() async {
    final purgeBefore = DateTime.now().subtract(Duration(days: AppConstants.trashAutoPurgeDays));
    final db = await database;

    // 清理 work_notes
    await db.delete(AppTables.workNotes,
        where: 'deleted_at IS NOT NULL AND deleted_at < ?', whereArgs: [purgeBefore.toIso8601String()]);
    // 清理 life_records
    await db.delete(AppTables.lifeRecords,
        where: 'deleted_at IS NOT NULL AND deleted_at < ?', whereArgs: [purgeBefore.toIso8601String()]);
    // 清理 murmurs
    await db.delete(AppTables.murmurs,
        where: 'deleted_at IS NOT NULL AND deleted_at < ?', whereArgs: [purgeBefore.toIso8601String()]);
    // 清理 goals
    await db.delete(AppTables.goals,
        where: 'deleted_at IS NOT NULL AND deleted_at < ?', whereArgs: [purgeBefore.toIso8601String()]);

    // 清理 trash_items
    await db.delete(AppTables.trashItems,
        where: 'auto_purge_at < ?', whereArgs: [DateTime.now().toIso8601String()]);
  }

  /// 关闭数据库
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
