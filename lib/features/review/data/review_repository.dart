import 'package:uuid/uuid.dart';
import 'package:buildself/data/database/database_provider.dart';
import 'package:buildself/data/database/tables.dart';
import 'package:buildself/features/review/models/review_item.dart';
import 'package:buildself/features/review/models/review_quadrant.dart';
import 'package:buildself/features/review/models/review_session.dart';

/// KISS 复盘仓库
///
/// - Session：按日软删除（可进回收站恢复），items 随恢复原样可见
/// - Item：物理删除（编辑性质）；整日删除时 session 进回收站，items 保留
class ReviewRepository {
  final DatabaseProvider _db = DatabaseProvider.instance;
  final _uuid = const Uuid();

  /// 把 [date] 格式化为本地 YYYY-MM-DD
  String _dayKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// 获取指定日 session（不含已删除），无则返回 null
  Future<ReviewSession?> getSessionByDate(
      String userId, DateTime date) async {
    final key = _dayKey(date);
    final map = await _db.queryOne(
      AppTables.reviewSessions,
      where: 'user_id = ? AND review_date = ? AND deleted_at IS NULL',
      whereArgs: [userId, key],
    );
    if (map == null) return null;
    final session = ReviewSession.fromMap(map);
    await _loadItems(session);
    return session;
  }

  /// 按 id 取 session（含已删除），用于回收站恢复判定
  Future<ReviewSession?> getSessionById(String id) async {
    final map = await _db.queryOne(AppTables.reviewSessions,
        where: 'id = ?', whereArgs: [id]);
    if (map == null) return null;
    final session = ReviewSession.fromMap(map);
    await _loadItems(session);
    return session;
  }

  /// 获取/创建当日 session（幂等：已存在直接返回并装配 items）
  Future<ReviewSession> getOrCreateSession(
      String userId, DateTime date) async {
    final existing = await getSessionByDate(userId, date);
    if (existing != null) return existing;

    final now = DateTime.now();
    final session = ReviewSession(
      id: _uuid.v4(),
      userId: userId,
      reviewDate: _dayKey(date),
      createdAt: now,
      updatedAt: now,
    );
    await _db.insert(AppTables.reviewSessions, session.toMap());
    return session;
  }

  /// 装配 session 的 items（按象限 + position 升序）
  Future<void> _loadItems(ReviewSession session) async {
    final maps = await _db.queryAll(
      AppTables.reviewItems,
      where: 'session_id = ?',
      whereArgs: [session.id],
      orderBy: 'position ASC, created_at ASC',
    );
    final grouped = <ReviewQuadrant, List<ReviewItem>>{
      for (final q in ReviewQuadrant.values) q: [],
    };
    for (final m in maps) {
      final item = ReviewItem.fromMap(m);
      grouped[item.quadrant]!.add(item);
    }
    session.items = grouped;
  }

  /// 新增一条复盘项（追加到对应象限尾部）
  Future<ReviewItem> addItem(
      String userId, DateTime date, ReviewQuadrant quadrant,
      String content) async {
    final session = await getOrCreateSession(userId, date);
    final now = DateTime.now();
    final count =
        session.items[quadrant]?.length ?? 0;
    final item = ReviewItem(
      id: _uuid.v4(),
      sessionId: session.id,
      quadrant: quadrant,
      content: content.trim(),
      position: count,
      createdAt: now,
      updatedAt: now,
    );
    await _db.insert(AppTables.reviewItems, item.toMap());
    return item;
  }

  /// 更新单条复盘项内容
  Future<void> updateItemContent(String itemId, String content) async {
    final now = DateTime.now();
    await _db.update(
      AppTables.reviewItems,
      {'content': content.trim(), 'updated_at': now.toIso8601String()},
      where: 'id = ?',
      whereArgs: [itemId],
    );
    // 同步 session 更新时间
    await _touchSessionByItem(itemId, now);
  }

  /// 物理删除单条复盘项
  Future<void> deleteItem(String itemId) async {
    await _db.delete(AppTables.reviewItems,
        where: 'id = ?', whereArgs: [itemId]);
  }

  /// 保存/更新 session 的总结文本
  Future<void> saveSummary(String sessionId, String summary) async {
    final now = DateTime.now();
    await _db.update(
      AppTables.reviewSessions,
      {
        'summary': summary,
        'summary_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  /// 软删除整日复盘（items 保留，恢复后原样可见）
  Future<void> softDeleteSession(String sessionId) async {
    await _db.softDelete(AppTables.reviewSessions, sessionId);
  }

  /// 恢复整日复盘
  Future<void> restoreSession(String sessionId) async {
    await _db.restore(AppTables.reviewSessions, sessionId);
  }

  /// 历史复盘列表（含已删除），按日期倒序
  Future<List<ReviewSession>> getHistory(String userId) async {
    final maps = await _db.queryAll(
      AppTables.reviewSessions,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'review_date DESC',
    );
    final sessions = maps.map(ReviewSession.fromMap).toList();
    for (final s in sessions) {
      await _loadItems(s);
    }
    return sessions;
  }

  /// 今日已记录条目总数（首页第 5 卡 subtitle）
  Future<int> countItemsByDate(String userId, DateTime date) async {
    final session = await getSessionByDate(userId, date);
    return session?.itemCount ?? 0;
  }

  /// 全局搜索：按内容命中复盘条目
  ///
  /// review_items 无 user_id，需 JOIN review_sessions 过滤归属用户与
  /// 未删除（回收站内的整日复盘不参与搜索）。
  Future<List<ReviewItem>> searchByContent(
      String userId, String keyword) async {
    final maps = await _db.rawQuery(
      'SELECT i.* FROM ${AppTables.reviewItems} i '
      'INNER JOIN ${AppTables.reviewSessions} s ON s.id = i.session_id '
      'WHERE s.user_id = ? AND s.deleted_at IS NULL AND i.content LIKE ? '
      'ORDER BY i.created_at DESC',
      [userId, '%$keyword%'],
    );
    return maps.map(ReviewItem.fromMap).toList();
  }

  /// 最近 N 天是否有复盘（首页连续天数/督促），返回有复盘的天数
  Future<int> countReviewedDays(String userId, {int days = 7}) async {
    final since = DateTime.now().subtract(Duration(days: days - 1));
    final sinceKey = _dayKey(since);
    final maps = await _db.rawQuery(
      'SELECT COUNT(*) AS c FROM ${AppTables.reviewSessions} '
      'WHERE user_id = ? AND deleted_at IS NULL AND review_date >= ?',
      [userId, sinceKey],
    );
    return (maps.first['c'] as int?) ?? 0;
  }

  /// 更新 item 后同步刷新所属 session 的 updated_at（保持列表排序直觉）
  Future<void> _touchSessionByItem(String itemId, DateTime time) async {
    final maps = await _db.queryOne(AppTables.reviewItems,
        where: 'id = ?', whereArgs: [itemId]);
    final sessionId = maps?['session_id'] as String?;
    if (sessionId == null) return;
    await _db.update(
      AppTables.reviewSessions,
      {'updated_at': time.toIso8601String()},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }
}
