import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:buildself/data/database/database_provider.dart';
import 'package:buildself/data/database/tables.dart';
import 'package:buildself/data/models/enums.dart';
import 'package:buildself/data/models/life_record_model.dart';

/// 生活记录仓库
class LifeRepository {
  final DatabaseProvider _db = DatabaseProvider.instance;
  final _uuid = const Uuid();

  /// 内置分类
  static const List<String> builtinCategories = ['美好', '感悟', '反思'];

  /// 获取用户的所有分类（内置 + 自定义）
  Future<List<String>> getCategories(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final custom = prefs.getStringList('life_categories_$userId') ?? [];
    return [...builtinCategories, ...custom];
  }

  /// 添加自定义分类
  Future<void> addCategory(String userId, String name) async {
    final prefs = await SharedPreferences.getInstance();
    final custom = prefs.getStringList('life_categories_$userId') ?? [];
    if (!custom.contains(name) && !builtinCategories.contains(name)) {
      custom.add(name);
      await prefs.setStringList('life_categories_$userId', custom);
    }
  }

  /// 删除自定义分类
  Future<void> removeCategory(String userId, String name) async {
    final prefs = await SharedPreferences.getInstance();
    final custom = prefs.getStringList('life_categories_$userId') ?? [];
    custom.remove(name);
    await prefs.setStringList('life_categories_$userId', custom);
  }

  Future<LifeRecord> create({
    required String userId,
    String title = '',
    required String content,
    required String recordType,
    Mood? mood,
    Weather? weather,
    String? location,
    List<String> tags = const [],
  }) async {
    final now = DateTime.now();
    final record = LifeRecord(
      id: _uuid.v4(),
      userId: userId,
      title: title,
      content: content,
      recordType: recordType,
      mood: mood,
      weather: weather,
      location: location,
      tags: tags,
      createdAt: now,
      updatedAt: now,
    );
    await _db.insert(AppTables.lifeRecords, record.toMap());
    return record;
  }

  Future<LifeRecord> update(LifeRecord record) async {
    record.updatedAt = DateTime.now();
    await _db.update(AppTables.lifeRecords, record.toMap(),
        where: 'id = ?', whereArgs: [record.id]);
    return record;
  }

  Future<void> softDelete(String id) async => _db.softDelete(AppTables.lifeRecords, id);
  Future<void> restore(String id) async => _db.restore(AppTables.lifeRecords, id);
  Future<void> delete(String id) async =>
      _db.delete(AppTables.lifeRecords, where: 'id = ?', whereArgs: [id]);

  Future<LifeRecord?> getById(String id) async {
    final map = await _db.queryOne(AppTables.lifeRecords, where: 'id = ?', whereArgs: [id]);
    return map != null ? LifeRecord.fromMap(map) : null;
  }

  Future<List<LifeRecord>> getAll(String userId, {String? type, int? limit, int offset = 0}) async {
    String where = 'user_id = ? AND deleted_at IS NULL';
    List<Object?> args = [userId];
    if (type != null) {
      where += ' AND record_type = ?';
      args.add(type);
    }
    final maps = await _db.queryAll(AppTables.lifeRecords,
        where: where, whereArgs: args, orderBy: 'created_at DESC', limit: limit, offset: offset);
    return maps.map(LifeRecord.fromMap).toList();
  }

  Future<List<LifeRecord>> search(String userId, String keyword) async {
    final maps = await _db.queryAll(AppTables.lifeRecords,
        where: 'user_id = ? AND deleted_at IS NULL AND (title LIKE ? OR content LIKE ?)',
        whereArgs: [userId, '%$keyword%', '%$keyword%'],
        orderBy: 'created_at DESC');
    return maps.map(LifeRecord.fromMap).toList();
  }

  Future<int> count(String userId) async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM ${AppTables.lifeRecords} WHERE user_id = ? AND deleted_at IS NULL',
      [userId],
    );
    return result.first['count'] as int? ?? 0;
  }

  /// 获取往日今日（同月日的记录）
  Future<List<LifeRecord>> getTodayInHistory(String userId, DateTime date) async {
    final monthDay = '-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}%';
    final maps = await _db.queryAll(AppTables.lifeRecords,
        where: 'user_id = ? AND deleted_at IS NULL AND created_at LIKE ? AND created_at < ?',
        whereArgs: [userId, '%$monthDay', date.toIso8601String()],
        orderBy: 'created_at DESC');
    return maps.map(LifeRecord.fromMap).toList();
  }
}
