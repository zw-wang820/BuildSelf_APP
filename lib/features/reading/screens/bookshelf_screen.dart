import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/core/router/routes.dart';
import 'package:buildself/data/models/enums.dart';
import 'package:buildself/data/models/reading_models.dart';
import 'package:buildself/data/repositories/reading_repository.dart';
import 'package:buildself/features/auth/providers/app_provider.dart';
import 'package:buildself/features/reading/widgets/add_book_sheet.dart';
import 'package:buildself/shared/layouts/main_scaffold.dart';
import 'package:buildself/shared/widgets/emoji_icon.dart';
import 'package:buildself/shared/widgets/nexus_background.dart';
import 'package:buildself/shared/widgets/toast.dart';

/// 书架页 — 阅读统计 + 筛选标签 + 3列网格 + 底部「最近阅读」
class BookshelfScreen extends StatefulWidget {
  const BookshelfScreen({Key? key}) : super(key: key);

  @override
  State<BookshelfScreen> createState() => _BookshelfScreenState();
}

enum _BookFilter { all, planned, reading, finished }

extension _BookFilterX on _BookFilter {
  String get label {
    switch (this) {
      case _BookFilter.all:
        return '全部';
      case _BookFilter.planned:
        return '想读';
      case _BookFilter.reading:
        return '在读';
      case _BookFilter.finished:
        return '已读完';
    }
  }

  BookStatus? get status {
    switch (this) {
      case _BookFilter.planned:
        return BookStatus.planned;
      case _BookFilter.reading:
        return BookStatus.reading;
      case _BookFilter.finished:
        return BookStatus.finished;
      default:
        return null;
    }
  }

  Color get accent {
    switch (this) {
      case _BookFilter.all:
        return AppColors.reading;
      case _BookFilter.planned:
        return AppColors.warning;
      case _BookFilter.reading:
        return AppColors.todo;
      case _BookFilter.finished:
        return AppColors.success;
    }
  }
}

class _BookshelfScreenState extends State<BookshelfScreen> {
  final ReadingRepository _repo = ReadingRepository();
  List<Book> _books = [];
  List<Book> _recent = [];
  _BookFilter _filter = _BookFilter.all;
  bool _loading = true;

  // 统计概览
  int _totalCount = 0;
  int _finishedCount = 0;
  int _readingCount = 0;
  int _plannedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = context.read<AppProvider>().userId;
    if (userId.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final books = await _repo.getAllBooks(userId);
      final recent = await _repo.getRecentBooks(userId, limit: 10);
      if (mounted) {
        setState(() {
          _books = books;
          _recent = recent;
          _totalCount = books.length;
          _finishedCount =
              books.where((b) => b.status == BookStatus.finished).length;
          _readingCount =
              books.where((b) => b.status == BookStatus.reading).length;
          _plannedCount =
              books.where((b) => b.status == BookStatus.planned).length;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changeFilter(_BookFilter f) {
    if (_filter == f) {
      return;
    }
    setState(() => _filter = f);
  }

  List<Book> get _filteredBooks {
    final status = _filter.status;
    if (status == null) return _books;
    return _books.where((b) => b.status == status).toList();
  }

  Future<void> _openAddSheet() async {
    final userId = context.read<AppProvider>().userId;
    if (userId.isEmpty) return;
    await showAddBookSheet(
      context,
      userId: userId,
      repository: _repo,
      onCreated: (_) {
        _loadData();
        ToastHelper.show(
          context,
          '📚 书籍添加成功！',
          icon: Icons.menu_book,
          color: AppColors.reading,
        );
      },
    );
  }

  Future<void> _openDetail(Book book) async {
    await Navigator.pushNamed(context, AppRoutes.bookDetail, arguments: book.id);
    if (mounted) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('书架'),
        actions: [
          IconButton(
            icon: const EmojiIcon('🔍', size: 21),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.search,
                arguments: 'reading'),
          ),
        ],
      ),
      body: NexusBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildStatsBar(),
              const SizedBox(height: 8),
              _buildFilterBar(),
              const SizedBox(height: 4),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddSheet,
        backgroundColor: AppColors.reading,
        foregroundColor: Colors.white,
        child: const EmojiIcon('➕', size: 22),
      ),
      // tab 常驻页与 push 全屏页统一：FAB 抬到底栏上方，避免被毛玻璃底栏遮挡
      floatingActionButtonLocation: const FloatingAboveNavLocation(),
    );
  }

  /// 顶部阅读统计 — 总书籍/已读完/正在读/想读
  Widget _buildStatsBar() {
    final stats = [
      _StatItem(
        label: '总书籍',
        count: _totalCount,
        icon: Icons.collections_bookmark_outlined,
        color: AppColors.reading,
      ),
      _StatItem(
        label: '已读完',
        count: _finishedCount,
        icon: Icons.check_circle_outline,
        color: AppColors.success,
      ),
      _StatItem(
        label: '正在读',
        count: _readingCount,
        icon: Icons.auto_stories_outlined,
        color: AppColors.todo,
      ),
      _StatItem(
        label: '想读',
        count: _plannedCount,
        icon: Icons.bookmark_border,
        color: AppColors.warning,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: stats.map((s) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: s == stats.last ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              decoration: BoxDecoration(
                color: s.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Icon(s.icon, size: 18, color: s.color),
                  const SizedBox(height: 6),
                  Text(
                    '${s.count}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: s.color,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    s.label,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFilterBar() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _BookFilter.values.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final f = _BookFilter.values[i];
          final selected = _filter == f;
          return GestureDetector(
            onTap: () => _changeFilter(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? f.accent.withValues(alpha: 0.16)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? f.accent : Theme.of(context).dividerColor,
                  width: selected ? 1.4 : 1,
                ),
              ),
              child: Text(
                f.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? f.accent : AppColors.textSecondary(context),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(
          color: _filter.accent,
          strokeWidth: 2,
        ),
      );
    }

    final filtered = _filteredBooks;
    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          if (filtered.isEmpty)
            SliverFillRemaining(hasScrollBody: false, child: _buildEmpty())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.62,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _buildBookCard(filtered[i]),
                  childCount: filtered.length,
                ),
              ),
            ),
          if (_recent.isNotEmpty) ...[
            SliverToBoxAdapter(child: _buildRecentSection()),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
    );
  }

  /// 3列网格书籍卡片 — 渐变封面 + 进度条 + 状态徽章
  Widget _buildBookCard(Book book) {
    final gradient =
        AppColors.bookCovers[(book.coverColor ?? 0) % AppColors.bookCovers.length];
    final showProgress = book.totalPages > 0;
    return GestureDetector(
      onTap: () => _openDetail(book),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  const Center(
                    child: EmojiIcon('📚', size: 30),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: _buildStatusBadge(book.status),
                  ),
                  if (showProgress)
                    Positioned(
                      left: 8,
                      right: 8,
                      bottom: 8,
                      child: _buildCoverProgress(book),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            book.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(context),
            ),
          ),
          if (book.author != null && book.author!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              book.author!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary(context),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 封面底部细进度条 + 百分比
  Widget _buildCoverProgress(Book book) {
    final p = (book.progress / 100).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: SizedBox(
            height: 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: Colors.black.withValues(alpha: 0.25)),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: p,
                  child: Container(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '${book.progress}%',
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  /// 状态徽章 — 封面右上角
  Widget _buildStatusBadge(BookStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _statusEmoji(status) + _statusLabel(status),
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  /// 底部「最近阅读」— 横向阅读历史
  Widget _buildRecentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.reading.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.history, size: 16, color: AppColors.reading),
              ),
              const SizedBox(width: 10),
              Text(
                '最近阅读',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 108,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _recent.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, i) => _buildRecentCard(_recent[i], i),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentCard(Book book, int index) {
    final gradient =
        AppColors.bookCovers[(book.coverColor ?? 0) % AppColors.bookCovers.length];
    return GestureDetector(
      onTap: () => _openDetail(book),
      child: SizedBox(
        width: 64,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 64,
              height: 86,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: const EmojiIcon('📚', size: 22),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              book.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    final isAll = _filter == _BookFilter.all;
    final accent = _filter.accent;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Center(child: EmojiIcon('📚', size: 30)),
          ),
          const SizedBox(height: 14),
          Text(
            isAll ? '书架空空如也' : '还没有${_filter.label}的书',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isAll ? '点击右下角 + 添加第一本书' : '换一个状态看看',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  String _statusEmoji(BookStatus status) {
    switch (status) {
      case BookStatus.planned:
        return '📖';
      case BookStatus.reading:
        return '👀';
      case BookStatus.finished:
        return '✅';
      case BookStatus.paused:
        return '⏸️';
    }
  }

  String _statusLabel(BookStatus status) {
    switch (status) {
      case BookStatus.planned:
        return '想读';
      case BookStatus.reading:
        return '在读';
      case BookStatus.finished:
        return '已读完';
      case BookStatus.paused:
        return '暂停';
    }
  }
}

class _StatItem {
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  _StatItem({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });
}
