import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/core/constants/strings.dart';
import 'package:buildself/core/router/routes.dart';
import 'package:buildself/data/models/enums.dart';
import 'package:buildself/data/models/reading_models.dart';
import 'package:buildself/data/repositories/reading_repository.dart';
import 'package:buildself/features/auth/providers/app_provider.dart';
import 'package:buildself/shared/widgets/app_card.dart';
import 'package:buildself/shared/widgets/empty_state.dart';
import 'package:buildself/shared/widgets/nexus_background.dart';

/// 书架页
class BookshelfScreen extends StatefulWidget {
  const BookshelfScreen({Key? key}) : super(key: key);

  @override
  State<BookshelfScreen> createState() => _BookshelfScreenState();
}

class _BookshelfScreenState extends State<BookshelfScreen> {
  final _repo = ReadingRepository();
  List<Book> _books = [];
  Map<String, int> _stats = {'finished': 0, 'reading': 0, 'notes': 0};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = context.read<AppProvider>().userId;
    if (userId.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    try {
      final books = await _repo.getAllBooks(userId);
      final stats = await _repo.getStats(userId);
      if (mounted) {
        setState(() {
          _books = books;
          _stats = stats;
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.reading,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.reading, blurRadius: 6)],
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '// BOOKSHELF',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.reading,
                letterSpacing: 2,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                AppStrings.readingTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryDark,
                  letterSpacing: 0.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.search, arguments: 'reading'),
          ),
        ],
      ),
      body: NexusBackground(
        child: SafeArea(
          child: _loading
              ? Center(
                  child: CircularProgressIndicator(
                    color: AppColors.reading,
                    strokeWidth: 2,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: Column(
                    children: [
                      _buildStats(context),
                      Expanded(child: _buildBookshelf(context)),
                    ],
                  ),
                ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.reading.withOpacity(0.5),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          elevation: 0,
          onPressed: () async {
            await Navigator.pushNamed(context, AppRoutes.bookAdd);
            _loadData();
          },
          backgroundColor: AppColors.reading,
          foregroundColor: AppColors.spaceDeep,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildStats(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStatItem(context, '${_stats['finished'] ?? 0}', '已读', AppColors.reading),
          const SizedBox(width: 16),
          _buildStatItem(context, '${_stats['reading'] ?? 0}', '在读', AppColors.primary),
          const SizedBox(width: 16),
          _buildStatItem(context, '${_stats['notes'] ?? 0}', '笔记', AppColors.accent),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label, Color color) {
    return Expanded(
      child: AppCard(
        accent: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: color,
                fontFamily: 'monospace',
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondaryDark,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookshelf(BuildContext context) {
    if (_books.isEmpty) {
      return EmptyState(
        icon: Icons.menu_book_outlined,
        message: '书架空空如也\n添加第一本书开始阅读之旅',
        onAction: () async {
          await Navigator.pushNamed(context, AppRoutes.bookAdd);
          _loadData();
        },
        actionLabel: '添加书籍',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.62,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _books.length,
      itemBuilder: (context, index) => _buildBookCard(context, _books[index]),
    );
  }

  Widget _buildBookCard(BuildContext context, Book book) {
    return GestureDetector(
      onTap: () async {
        await Navigator.pushNamed(context, AppRoutes.bookDetail, arguments: book.id);
        _loadData();
      },
      child: AppCard(
        accent: AppColors.reading,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 封面占位
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.reading.withOpacity(0.15),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                ),
                child: Center(
                  child: Icon(
                    Icons.menu_book,
                    color: AppColors.reading,
                    size: 40,
                    shadows: [
                      Shadow(color: AppColors.reading.withOpacity(0.8), blurRadius: 8),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryDark,
                      letterSpacing: 0.2,
                    ),
                  ),
                  if (book.author != null && book.author!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      book.author!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  _buildStatusBadge(book.status),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BookStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.reading.withOpacity(0.16),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.reading.withOpacity(0.5), width: 0.6),
      ),
      child: Text(
        status.label,
        style: const TextStyle(
          fontSize: 10,
          color: AppColors.reading,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
