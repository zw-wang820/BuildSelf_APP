import 'package:flutter/material.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/core/constants/strings.dart';
import 'package:buildself/core/router/routes.dart';
import 'package:buildself/data/models/enums.dart';
import 'package:buildself/data/models/reading_models.dart';
import 'package:buildself/data/repositories/reading_repository.dart';
import 'package:buildself/features/reading/reading_cover.dart';
import 'package:buildself/features/reading/screens/note_edit_screen.dart';
import 'package:buildself/shared/widgets/emoji_icon.dart';
import 'package:buildself/shared/widgets/empty_state.dart';

/// 书籍详情页 — 展示书籍信息和笔记
class BookDetailScreen extends StatefulWidget {
  final String? bookId;

  const BookDetailScreen({Key? key, this.bookId}) : super(key: key);

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen>
    with SingleTickerProviderStateMixin {
  final _repo = ReadingRepository();
  late TabController _tabController;
  Book? _book;
  bool _loading = true;

  /// 5 个 Tab 各自的笔记列表 key — 用于编辑/新建返回后强制刷新各列表
  final List<GlobalKey<_NotesListState>> _notesKeys =
      List.generate(5, (_) => GlobalKey<_NotesListState>());

  /// 5 个 Tab：全部 / 摘抄 / 心得 / 思考 / 改变
  /// 对应 noteTypeFilter: null=全部, 其余为 NoteType 值
  final List<NoteType?> _tabFilters = [
    null,
    NoteType.excerpt,
    NoteType.insight,
    NoteType.thought,
    NoteType.change,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadBook();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 笔记编辑/新建返回后刷新所有 Tab 的笔记列表（keepAlive 列表需主动触发）
  void _refreshNotes() {
    for (final key in _notesKeys) {
      key.currentState?._loadNotes();
    }
  }

  /// 打开书籍编辑页，返回后刷新书籍信息
  Future<void> _openEditBook() async {
    await Navigator.pushNamed(context, AppRoutes.bookAdd, arguments: _book);
    if (mounted) _loadBook();
  }

  /// 阅读统计 — 取该书全部笔记，分组计数后弹出统计面板
  Future<void> _openStats() async {
    final bookId = widget.bookId;
    if (bookId == null) return;
    List<ReadingNote> notes;
    try {
      notes = await _repo.getNotesByBook(bookId);
    } catch (_) {
      notes = [];
    }
    if (!mounted) return;

    final total = notes.length;
    final counts = <NoteType, int>{for (final t in NoteType.values) t: 0};
    for (final n in notes) {
      counts[n.noteType] = counts[n.noteType]! + 1;
    }
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final weekCount = notes.where((n) => n.createdAt.isAfter(weekAgo)).length;

    // 返回选中的 Tab 下标（null = 仅关闭不跳转）
    final selectedIndex = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _buildStatsSheet(
        sheetContext,
        _book?.title ?? '本书',
        total,
        counts,
        weekCount,
      ),
    );
    if (selectedIndex != null && mounted) {
      _tabController.animateTo(selectedIndex);
    }
  }

  /// 统计面板内容
  Widget _buildStatsSheet(
    BuildContext context,
    String bookTitle,
    int total,
    Map<NoteType, int> counts,
    int weekCount,
  ) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 拖拽条
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.dividerDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            // 标题行
            Row(
              children: [
                const Text('📊 阅读统计',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const Spacer(),
                Flexible(
                  child: Text(
                    bookTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 18),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '笔记总数 $total 条',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary(context),
              ),
            ),
            const SizedBox(height: 14),
            if (total == 0)
              _buildStatsEmpty(context)
            else ...[
              for (final t in NoteType.values) ...[
                _buildStatRow(context, t, counts[t]!, total),
                const SizedBox(height: 8),
              ],
            ],
            // 近 7 天新增
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Text('🆕', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Text(
                    '近 7 天新增',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$weekCount 条',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 单类统计行 — 点击收起面板并跳到对应笔记 Tab
  Widget _buildStatRow(
    BuildContext context,
    NoteType type,
    int count,
    int total,
  ) {
    final color = _noteTypeColor(type);
    final ratio = total == 0 ? 0.0 : count / total;
    final percent = (ratio * 100).round();
    return GestureDetector(
      onTap: () => Navigator.pop(context, _tabFilters.indexOf(type)),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(_noteTypeEmoji(type), style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        type.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$count 条',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 5,
                      backgroundColor: color.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '$percent%',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary(context),
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.chevron_right,
                size: 16, color: AppColors.textSecondary(context)),
          ],
        ),
      ),
    );
  }

  /// 无笔记空状态 — 点击收起并切到全部 Tab
  Widget _buildStatsEmpty(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, 0),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.reading.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Text('📝', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '这本书还没有笔记',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '点击去添加第一条笔记',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                size: 16, color: AppColors.textSecondary(context)),
          ],
        ),
      ),
    );
  }

  Color _noteTypeColor(NoteType type) {
    switch (type) {
      case NoteType.excerpt:
        return AppColors.reading;
      case NoteType.insight:
        return AppColors.info;
      case NoteType.thought:
        return AppColors.warning;
      case NoteType.change:
        return AppColors.success;
    }
  }

  String _noteTypeEmoji(NoteType type) {
    switch (type) {
      case NoteType.excerpt:
        return '📝';
      case NoteType.insight:
        return '💡';
      case NoteType.thought:
        return '🤔';
      case NoteType.change:
        return '🔄';
    }
  }

  Future<void> _loadBook() async {
    if (widget.bookId == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final book = await _repo.getBookById(widget.bookId!);
      if (mounted) {
        setState(() {
          _book = book;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_book?.title ?? AppStrings.readingTitle),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _openEditBook();
              } else if (value == 'delete') {
                _showDeleteDialog(context);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'edit', child: Text(AppStrings.edit)),
              PopupMenuItem(value: 'delete', child: Text(AppStrings.delete)),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: '全部'),
            Tab(text: '摘抄'),
            Tab(text: '心得'),
            Tab(text: '思考'),
            Tab(text: '改变'),
          ],
          labelColor: AppColors.reading,
          unselectedLabelColor: AppColors.textSecondary(context),
          indicatorColor: AppColors.reading,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildBookInfo(context, _book),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: _tabFilters.asMap().entries.map((entry) {
                      final i = entry.key;
                      final filter = entry.value;
                      return _NotesList(
                        key: _notesKeys[i],
                        repo: _repo,
                        bookId: widget.bookId!,
                        noteType: filter,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(
            context,
            AppRoutes.noteEdit,
            arguments: NoteEditArgs(bookId: widget.bookId!),
          );
          // 返回后刷新书籍信息与所有 Tab 的笔记列表
          _loadBook();
          _refreshNotes();
        },
        backgroundColor: AppColors.reading,
        child: const EmojiIcon('➕', size: 22),
      ),
    );
  }

  Widget _buildBookInfo(BuildContext context, Book? book) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 封面 — 渐变 + emoji + 书名
          Container(
            width: 64,
            height: 88,
            decoration: BoxDecoration(
              gradient: AppColors.bookCovers[
                  (book?.coverColor ?? 0) % AppColors.bookCovers.length],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  book != null ? resolveCoverEmoji(book) : '📚',
                  style: const TextStyle(fontSize: 20),
                ),
                if (book != null && book.title.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book?.title ?? '书名',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (book?.author != null && book!.author!.isNotEmpty)
                  Text(book.author!, style: TextStyle(fontSize: 13, color: AppColors.textSecondary(context))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.reading.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        book?.status.label ?? '想读',
                        style: const TextStyle(fontSize: 11, color: AppColors.reading),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 阅读统计入口
          IconButton(
            onPressed: _openStats,
            icon: const EmojiIcon('📊', size: 18),
            color: AppColors.reading,
            tooltip: '阅读统计',
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除书籍'),
        content: const Text('删除书籍将同时删除所有相关笔记，确定删除吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppStrings.cancel)),
          TextButton(
            onPressed: () async {
              if (widget.bookId != null) {
                await _repo.deleteBook(widget.bookId!);
              }
              if (!mounted) return;
              Navigator.pop(context); // 关闭对话框
              Navigator.pop(context); // 返回书架
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }
}

/// 笔记列表子组件 — 每个 Tab 一个实例，自行加载数据
class _NotesList extends StatefulWidget {
  final ReadingRepository repo;
  final String bookId;
  final NoteType? noteType;

  const _NotesList({
    Key? key,
    required this.repo,
    required this.bookId,
    this.noteType,
  }) : super(key: key);

  @override
  State<_NotesList> createState() => _NotesListState();
}

class _NotesListState extends State<_NotesList> with AutomaticKeepAliveClientMixin {
  List<ReadingNote> _notes = [];
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    try {
      final notes = await widget.repo.getNotesByBook(widget.bookId, type: widget.noteType);
      if (mounted) {
        setState(() {
          _notes = notes;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_notes.isEmpty) {
      final label = widget.noteType?.label ?? '笔记';
      return EmptyState(
        emoji: '📝',
        message: '暂无$label\n点击右下角 + 添加笔记',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadNotes,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        itemCount: _notes.length,
        itemBuilder: (context, index) => _buildNoteItem(_notes[index]),
      ),
    );
  }

  Widget _buildNoteItem(ReadingNote note) {
    return GestureDetector(
      // 点击进入编辑页（页内展示首次创建 / 最后修改时间）
      onTap: () => _openEditNote(note),
      onLongPress: () => _showDeleteNoteDialog(note),
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.reading.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      note.noteType.label,
                      style: const TextStyle(fontSize: 11, color: AppColors.reading),
                    ),
                  ),
                  if (note.chapter != null && note.chapter!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.bookmark_outline, size: 14, color: AppColors.textSecondary(context)),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        note.chapter!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context)),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    _formatDate(note.createdAt),
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary(context)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                note.content,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 打开笔记编辑页，返回后刷新当前列表
  Future<void> _openEditNote(ReadingNote note) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.noteEdit,
      arguments: NoteEditArgs(bookId: widget.bookId, note: note),
    );
    if (mounted) _loadNotes();
  }

  /// 列表时间显示：今天 → 今天 HH:mm；今年 → M月d日；跨年 → yyyy年M月d日
  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    if (day == today) {
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return '今天 $hh:$mm';
    }
    if (dt.year == now.year) return '${dt.month}月${dt.day}日';
    return '${dt.year}年${dt.month}月${dt.day}日';
  }

  void _showDeleteNoteDialog(ReadingNote note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除笔记'),
        content: const Text('确定删除这条笔记吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppStrings.cancel)),
          TextButton(
            onPressed: () async {
              await widget.repo.deleteNote(note.id);
              if (!mounted) return;
              Navigator.pop(context);
              _loadNotes();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }
}
