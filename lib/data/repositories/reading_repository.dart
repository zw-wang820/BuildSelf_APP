import 'package:uuid/uuid.dart';
import 'package:buildself/data/database/database_provider.dart';
import 'package:buildself/data/database/tables.dart';
import 'package:buildself/data/models/enums.dart';
import 'package:buildself/data/models/reading_models.dart';

/// 阅读仓库 — 管理书籍和读书笔记
class ReadingRepository {
  final DatabaseProvider _db = DatabaseProvider.instance;
  final _uuid = const Uuid();

  // ==================== 书籍操作 ====================

  Future<Book> createBook({
    required String userId,
    required String title,
    String? author,
    BookStatus status = BookStatus.planned,
    List<String> tags = const [],
    int currentPage = 0,
    int totalPages = 0,
    int? coverColor,
    String? coverEmoji,
  }) async {
    final now = DateTime.now();
    final book = Book(
      id: _uuid.v4(),
      userId: userId,
      title: title,
      author: author,
      status: status,
      startDate: status == BookStatus.reading ? now : null,
      finishDate: status == BookStatus.finished ? now : null,
      tags: tags,
      currentPage:
          status == BookStatus.finished && totalPages > 0 ? totalPages : currentPage,
      totalPages: totalPages,
      coverColor: coverColor,
      coverEmoji: coverEmoji,
      lastReadAt: status == BookStatus.reading || status == BookStatus.finished
          ? now
          : null,
      createdAt: now,
    );
    await _db.insert(AppTables.books, book.toMap());
    return book;
  }

  Future<Book> updateBook(Book book) async {
    book.lastReadAt = DateTime.now();
    await _db.update(AppTables.books, book.toMap(),
        where: 'id = ?', whereArgs: [book.id]);
    return book;
  }

  Future<void> deleteBook(String id) async =>
      _db.delete(AppTables.books, where: 'id = ?', whereArgs: [id]);

  Future<Book?> getBookById(String id) async {
    final map = await _db.queryOne(AppTables.books, where: 'id = ?', whereArgs: [id]);
    return map != null ? Book.fromMap(map) : null;
  }

  Future<List<Book>> getAllBooks(String userId, {BookStatus? status}) async {
    String where = 'user_id = ?';
    List<Object?> args = [userId];
    if (status != null) {
      where += ' AND status = ?';
      args.add(status.name);
    }
    final maps = await _db.queryAll(AppTables.books,
        where: where, whereArgs: args, orderBy: 'created_at DESC');
    return maps.map(Book.fromMap).toList();
  }

  Future<List<Book>> searchBooks(String userId, String keyword) async {
    final maps = await _db.queryAll(AppTables.books,
        where: 'user_id = ? AND (title LIKE ? OR author LIKE ?)',
        whereArgs: [userId, '%$keyword%', '%$keyword%'],
        orderBy: 'created_at DESC');
    return maps.map(Book.fromMap).toList();
  }

  /// 最近阅读 — 按最近阅读时间（无则回退创建时间）倒序
  Future<List<Book>> getRecentBooks(String userId, {int limit = 10}) async {
    final maps = await _db.rawQuery('''
      SELECT * FROM ${AppTables.books}
      WHERE user_id = ?
      ORDER BY COALESCE(last_read_at, created_at) DESC
      LIMIT ?
    ''', [userId, limit]);
    return maps.map(Book.fromMap).toList();
  }

  // ==================== 笔记操作 ====================

  Future<ReadingNote> createNote({
    required String bookId,
    required NoteType noteType,
    String? chapter,
    required String content,
  }) async {
    final now = DateTime.now();
    final note = ReadingNote(
      id: _uuid.v4(),
      bookId: bookId,
      noteType: noteType,
      chapter: chapter,
      content: content,
      createdAt: now,
      updatedAt: now,
    );
    await _db.insert(AppTables.readingNotes, note.toMap());
    return note;
  }

  Future<ReadingNote> updateNote(ReadingNote note) async {
    note.updatedAt = DateTime.now();
    await _db.update(AppTables.readingNotes, note.toMap(),
        where: 'id = ?', whereArgs: [note.id]);
    return note;
  }

  Future<void> deleteNote(String id) async =>
      _db.delete(AppTables.readingNotes, where: 'id = ?', whereArgs: [id]);

  Future<List<ReadingNote>> getNotesByBook(String bookId, {NoteType? type}) async {
    String where = 'book_id = ?';
    List<Object?> args = [bookId];
    if (type != null) {
      where += ' AND note_type = ?';
      args.add(type.name);
    }
    final maps = await _db.queryAll(AppTables.readingNotes,
        where: where, whereArgs: args, orderBy: 'created_at DESC');
    return maps.map(ReadingNote.fromMap).toList();
  }

  /// 获取所有「改变」类笔记（用于首页展示）
  Future<List<ReadingNote>> getAllChanges(String userId) async {
    final maps = await _db.rawQuery('''
      SELECT rn.* FROM ${AppTables.readingNotes} rn
      INNER JOIN ${AppTables.books} b ON rn.book_id = b.id
      WHERE b.user_id = ? AND rn.note_type = ?
      ORDER BY rn.created_at DESC
      LIMIT 5
    ''', [userId, NoteType.change.name]);
    return maps.map(ReadingNote.fromMap).toList();
  }

  /// 取近段时间内有读书笔记的日期戳，用于连续天数推导
  Future<List<String>> getActiveDateStamps(String userId, DateTime since) async {
    final maps = await _db.rawQuery('''
      SELECT DISTINCT substr(rn.created_at,1,10) as d
      FROM ${AppTables.readingNotes} rn
      INNER JOIN ${AppTables.books} b ON rn.book_id = b.id
      WHERE b.user_id = ? AND rn.created_at >= ?
    ''', [userId, since.toIso8601String()]);
    return maps.map((m) => m['d'] as String).toList();
  }

  /// 搜索笔记
  Future<List<ReadingNote>> searchNotes(String userId, String keyword) async {
    final maps = await _db.rawQuery('''
      SELECT rn.* FROM ${AppTables.readingNotes} rn
      INNER JOIN ${AppTables.books} b ON rn.book_id = b.id
      WHERE b.user_id = ? AND rn.content LIKE ?
      ORDER BY rn.created_at DESC
    ''', [userId, '%$keyword%']);
    return maps.map(ReadingNote.fromMap).toList();
  }

  /// 阅读统计
  Future<Map<String, int>> getStats(String userId) async {
    final finishedCount = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM ${AppTables.books} WHERE user_id = ? AND status = ?',
      [userId, BookStatus.finished.name],
    );
    final readingCount = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM ${AppTables.books} WHERE user_id = ? AND status = ?',
      [userId, BookStatus.reading.name],
    );
    final noteCountResult = await _db.rawQuery('''
      SELECT COUNT(*) as count FROM ${AppTables.readingNotes} rn
      INNER JOIN ${AppTables.books} b ON rn.book_id = b.id
      WHERE b.user_id = ?
    ''', [userId]);

    return {
      'finished': finishedCount.first['count'] as int? ?? 0,
      'reading': readingCount.first['count'] as int? ?? 0,
      'notes': noteCountResult.first['count'] as int? ?? 0,
    };
  }
}
