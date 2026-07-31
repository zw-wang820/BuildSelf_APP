import 'package:uuid/uuid.dart';
import 'package:buildself/data/database/database_provider.dart';
import 'package:buildself/data/database/tables.dart';
import 'package:buildself/data/models/enums.dart';
import 'package:buildself/data/models/murmur_model.dart';

/// 碎碎念仓库
class MurmurRepository {
  final DatabaseProvider _db = DatabaseProvider.instance;
  final _uuid = const Uuid();

  Future<Murmur> create({
    required String userId,
    required String content,
    Mood? mood,
    List<String> tags = const [],
  }) async {
    final now = DateTime.now();
    final murmur = Murmur(
      id: _uuid.v4(),
      userId: userId,
      content: content,
      mood: mood,
      tags: tags,
      createdAt: now,
      updatedAt: now,
    );
    await _db.insert(AppTables.murmurs, murmur.toMap());
    return murmur;
  }

  Future<Murmur> update(Murmur murmur) async {
    murmur.updatedAt = DateTime.now();
    await _db.update(AppTables.murmurs, murmur.toMap(),
        where: 'id = ?', whereArgs: [murmur.id]);
    return murmur;
  }

  Future<void> softDelete(String id) async => _db.softDelete(AppTables.murmurs, id);
  Future<void> delete(String id) async =>
      _db.delete(AppTables.murmurs, where: 'id = ?', whereArgs: [id]);

  Future<Murmur?> getById(String id) async {
    final map = await _db.queryOne(AppTables.murmurs, where: 'id = ?', whereArgs: [id]);
    return map != null ? Murmur.fromMap(map) : null;
  }

  Future<List<Murmur>> getAll(String userId, {int? limit, int offset = 0}) async {
    final maps = await _db.queryAll(AppTables.murmurs,
        where: 'user_id = ? AND deleted_at IS NULL',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
        limit: limit,
        offset: offset);
    return maps.map(Murmur.fromMap).toList();
  }

  Future<List<Murmur>> search(String userId, String keyword) async {
    final maps = await _db.queryAll(AppTables.murmurs,
        where: 'user_id = ? AND deleted_at IS NULL AND content LIKE ?',
        whereArgs: [userId, '%$keyword%'],
        orderBy: 'created_at DESC');
    return maps.map(Murmur.fromMap).toList();
  }

  Future<int> count(String userId) async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count, SUM(LENGTH(content)) as total_chars FROM ${AppTables.murmurs} WHERE user_id = ? AND deleted_at IS NULL',
      [userId],
    );
    return result.first['count'] as int? ?? 0;
  }

  /// 获取总字数
  Future<int> totalChars(String userId) async {
    final result = await _db.rawQuery(
      'SELECT SUM(LENGTH(content)) as total FROM ${AppTables.murmurs} WHERE user_id = ? AND deleted_at IS NULL',
      [userId],
    );
    return result.first['total'] as int? ?? 0;
  }
}
