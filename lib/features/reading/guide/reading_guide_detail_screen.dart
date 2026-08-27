import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/core/router/routes.dart';
import 'package:buildself/data/models/reading_models.dart';
import 'package:buildself/data/repositories/reading_repository.dart';
import 'package:buildself/features/auth/providers/app_provider.dart';
import 'package:buildself/features/reading/guide/guide_articles.dart';
import 'package:buildself/features/reading/reading_cover.dart';
import 'package:buildself/features/reading/screens/note_edit_screen.dart';
import 'package:buildself/shared/widgets/nexus_background.dart';
import 'package:buildself/shared/widgets/toast.dart';

/// 阅读指南 — 方法论详情页
///
/// 接收路由参数 int index（guideArticles 下标）。
/// 含「如何落地」文章的行动引导：选书 → 新建「改变」笔记。
class ReadingGuideDetailScreen extends StatefulWidget {
  final int index;

  const ReadingGuideDetailScreen({Key? key, required this.index})
      : super(key: key);

  @override
  State<ReadingGuideDetailScreen> createState() =>
      _ReadingGuideDetailScreenState();
}

class _ReadingGuideDetailScreenState extends State<ReadingGuideDetailScreen> {
  final _repo = ReadingRepository();

  GuideArticle get _article => guideArticles[widget.index];

  Color get _accent {
    const colors = [
      AppColors.reading,
      AppColors.warning,
      AppColors.info,
      AppColors.success,
    ];
    return colors[widget.index % colors.length];
  }

  /// 行动引导：选书 → 打开新建「改变」笔记
  Future<void> _startAction() async {
    final userId = context.read<AppProvider>().userId;
    if (userId.isEmpty) return;
    List<Book> books;
    try {
      books = await _repo.getAllBooks(userId);
    } catch (_) {
      books = [];
    }
    if (!mounted) return;
    if (books.isEmpty) {
      ToastHelper.show(context, '📚 书架还没有书，先去添加一本吧',
          icon: Icons.menu_book, color: AppColors.reading);
      return;
    }
    final book = await showModalBottomSheet<Book>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                '选择一本书，写下你的下一步行动',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary(sheetContext),
                ),
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                itemCount: books.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 4),
                itemBuilder: (context, i) {
                  final b = books[i];
                  return ListTile(
                    leading: Container(
                      width: 34,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: AppColors.bookCovers[(b.coverColor ?? 0) %
                            AppColors.bookCovers.length],
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Center(
                        child: Text(resolveCoverEmoji(b),
                            style: const TextStyle(fontSize: 15)),
                      ),
                    ),
                    title: Text(
                      b.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary(sheetContext),
                      ),
                    ),
                    subtitle: b.author != null && b.author!.isNotEmpty
                        ? Text(
                            b.author!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  AppColors.textSecondary(sheetContext),
                            ),
                          )
                        : null,
                    onTap: () => Navigator.pop(sheetContext, b),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (book == null || !mounted) return;
    await Navigator.pushNamed(
      context,
      AppRoutes.noteEdit,
      arguments: NoteEditArgs(
        bookId: book.id,
        initialType: guideActionNoteType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${_article.emoji} ${_article.title}')),
      body: NexusBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              for (final block in _article.blocks) ...[
                _buildBlock(context, block),
                const SizedBox(height: 14),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlock(BuildContext context, GuideBlock block) {
    switch (block.type) {
      case GuideBlockType.paragraph:
        return Text(
          block.text,
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: AppColors.textPrimary(context),
          ),
        );
      case GuideBlockType.quote:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border(left: BorderSide(color: _accent, width: 3)),
          ),
          child: Text(
            block.text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.5,
              color: _accent,
            ),
          ),
        );
      case GuideBlockType.points:
        return _buildPoints(block);
      case GuideBlockType.steps:
        return _buildSteps(block);
      case GuideBlockType.action:
        return _buildAction();
    }
  }

  Widget _buildPoints(GuideBlock block) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (block.title != null && block.title!.isNotEmpty) ...[
          Text(
            block.title!,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
        ],
        ...block.items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.5,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSteps(GuideBlock block) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (block.title != null && block.title!.isNotEmpty) ...[
          Text(
            block.title!,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
        ],
        ...block.items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _accent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.5,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  /// 行动引导按钮 — 把方法变成行动
  Widget _buildAction() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '读完一本书，最难的一步是「开始行动」。',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _startAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.rocket_launch, size: 18),
              label: const Text(
                '把这本书的方法变成行动',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '选择一本书，记下你的「改变」笔记',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
