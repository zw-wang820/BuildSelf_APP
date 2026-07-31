import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:buildself/data/database/database_provider.dart';
import 'package:buildself/data/database/tables.dart';
import 'package:buildself/data/models/enums.dart';
import 'package:buildself/data/models/work_note_model.dart';

/// 工作记录仓库
class WorkRepository {
  final DatabaseProvider _db = DatabaseProvider.instance;
  final _uuid = const Uuid();

  /// 内置分类
  static const List<String> builtinCategories = ['经验', '心得', '反思'];

  /// 获取用户的所有分类（内置 + 自定义）
  Future<List<String>> getCategories(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final custom = prefs.getStringList('work_categories_$userId') ?? [];
    return [...builtinCategories, ...custom];
  }

  /// 添加自定义分类
  Future<void> addCategory(String userId, String name) async {
    final prefs = await SharedPreferences.getInstance();
    final custom = prefs.getStringList('work_categories_$userId') ?? [];
    if (!custom.contains(name) && !builtinCategories.contains(name)) {
      custom.add(name);
      await prefs.setStringList('work_categories_$userId', custom);
    }
  }

  /// 删除自定义分类
  Future<void> removeCategory(String userId, String name) async {
    final prefs = await SharedPreferences.getInstance();
    final custom = prefs.getStringList('work_categories_$userId') ?? [];
    custom.remove(name);
    await prefs.setStringList('work_categories_$userId', custom);
  }

  /// 新建工作记录
  Future<WorkNote> create({
    required String userId,
    String title = '',
    required String content,
    required String recordType,
    List<String> tags = const [],
    Mood? mood,
  }) async {
    final now = DateTime.now();
    final note = WorkNote(
      id: _uuid.v4(),
      userId: userId,
      title: title,
      content: content,
      recordType: recordType,
      tags: tags,
      mood: mood,
      createdAt: now,
      updatedAt: now,
    );
    await _db.insert(AppTables.workNotes, note.toMap());
    return note;
  }

  /// 更新工作记录
  Future<WorkNote> update(WorkNote note) async {
    note.updatedAt = DateTime.now();
    await _db.update(AppTables.workNotes, note.toMap(),
        where: 'id = ?', whereArgs: [note.id]);
    return note;
  }

  /// 软删除
  Future<void> softDelete(String id) async {
    await _db.softDelete(AppTables.workNotes, id);
  }

  /// 恢复
  Future<void> restore(String id) async {
    await _db.restore(AppTables.workNotes, id);
  }

  /// 物理删除
  Future<void> delete(String id) async {
    await _db.delete(AppTables.workNotes, where: 'id = ?', whereArgs: [id]);
  }

  /// 获取单条记录
  Future<WorkNote?> getById(String id) async {
    final map = await _db.queryOne(AppTables.workNotes,
        where: 'id = ?', whereArgs: [id]);
    return map != null ? WorkNote.fromMap(map) : null;
  }

  /// 获取用户的所有工作记录（不含已删除）
  Future<List<WorkNote>> getAll(String userId, {String? type, int? limit, int offset = 0}) async {
    String where = 'user_id = ? AND deleted_at IS NULL';
    List<Object?> args = [userId];
    if (type != null) {
      where += ' AND record_type = ?';
      args.add(type);
    }
    final maps = await _db.queryAll(
      AppTables.workNotes,
      where: where,
      whereArgs: args,
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map(WorkNote.fromMap).toList();
  }

  /// 搜索
  Future<List<WorkNote>> search(String userId, String keyword) async {
    final maps = await _db.queryAll(
      AppTables.workNotes,
      where: 'user_id = ? AND deleted_at IS NULL AND (title LIKE ? OR content LIKE ?)',
      whereArgs: [userId, '%$keyword%', '%$keyword%'],
      orderBy: 'created_at DESC',
    );
    return maps.map(WorkNote.fromMap).toList();
  }

  /// 按标签筛选
  Future<List<WorkNote>> getByTag(String userId, String tag) async {
    final maps = await _db.queryAll(
      AppTables.workNotes,
      where: "user_id = ? AND deleted_at IS NULL AND tags LIKE ?",
      whereArgs: [userId, '%$tag%'],
      orderBy: 'created_at DESC',
    );
    return maps.map(WorkNote.fromMap).toList();
  }

  /// 获取回收站记录
  Future<List<WorkNote>> getTrashed(String userId) async {
    final maps = await _db.queryAll(
      AppTables.workNotes,
      where: 'user_id = ? AND deleted_at IS NOT NULL',
      whereArgs: [userId],
      orderBy: 'deleted_at DESC',
    );
    return maps.map(WorkNote.fromMap).toList();
  }

  /// 获取记录数量
  Future<int> count(String userId) async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM ${AppTables.workNotes} WHERE user_id = ? AND deleted_at IS NULL',
      [userId],
    );
    return result.first['count'] as int? ?? 0;
  }
}
