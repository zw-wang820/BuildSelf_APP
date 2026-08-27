import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/core/constants/strings.dart';
import 'package:buildself/data/models/enums.dart';
import 'package:buildself/data/models/reading_models.dart';
import 'package:buildself/data/repositories/reading_repository.dart';
import 'package:buildself/features/auth/providers/app_provider.dart';
import 'package:buildself/features/reading/reading_cover.dart';
import 'package:buildself/shared/widgets/emoji_icon.dart';

/// 添加 / 编辑书籍页 — book 非空时进入编辑模式
class BookAddScreen extends StatefulWidget {
  final Book? book;

  const BookAddScreen({Key? key, this.book}) : super(key: key);

  @override
  State<BookAddScreen> createState() => _BookAddScreenState();
}

class _BookAddScreenState extends State<BookAddScreen> {
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _repo = ReadingRepository();
  BookStatus _status = BookStatus.planned;
  String? _coverEmoji; // null = 按书名自动分配
  bool _saving = false;

  bool get _isEdit => widget.book != null;

  @override
  void initState() {
    super.initState();
    final book = widget.book;
    if (book != null) {
      _titleController.text = book.title;
      _authorController.text = book.author ?? '';
      _status = book.status;
      _coverEmoji = book.coverEmoji;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请输入书名')));
      return;
    }
    setState(() => _saving = true);
    try {
      final title = _titleController.text.trim();
      final author = _authorController.text.trim().isEmpty
          ? null
          : _authorController.text.trim();
      final book = widget.book;
      if (book != null) {
        // 编辑模式：原地修改并维护状态日期
        book.title = title;
        book.author = author;
        book.status = _status;
        book.coverEmoji = _coverEmoji;
        final now = DateTime.now();
        if (_status == BookStatus.reading && book.startDate == null) {
          book.startDate = now;
        }
        if (_status == BookStatus.finished && book.finishDate == null) {
          book.finishDate = now;
        }
        await _repo.updateBook(book);
      } else {
        final userId = context.read<AppProvider>().userId;
        await _repo.createBook(
          userId: userId,
          title: title,
          author: author,
          status: _status,
          coverEmoji: _coverEmoji,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.saveSuccess), duration: const Duration(seconds: 1)),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存失败，请重试')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppStrings.cancel),
        ),
        title: Text(_isEdit ? AppStrings.editBook : AppStrings.addBook),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(AppStrings.save, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCoverPreview(),
            const SizedBox(height: 24),

            TextField(
              controller: _titleController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: '书名',
                prefixIcon: EmojiIcon('📚', size: 20),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _authorController,
              decoration: const InputDecoration(
                hintText: '作者（选填）',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),

            const Text('阅读状态', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: BookStatus.values.map((status) {
                return FilterChip(
                  label: Text(status.label),
                  selected: _status == status,
                  onSelected: (_) => setState(() => _status = status),
                  selectedColor: AppColors.reading.withValues(alpha: 0.15),
                  checkmarkColor: AppColors.reading,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            Text(AppStrings.coverIcon,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(
              AppStrings.coverIconAutoHint,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context)),
            ),
            const SizedBox(height: 10),
            _buildEmojiPicker(),
          ],
        ),
      ),
    );
  }

  /// 封面实时预览 — 渐变底色 + emoji + 书名
  Widget _buildCoverPreview() {
    final colorIdx = (widget.book?.coverColor ?? 0) % AppColors.bookCovers.length;
    final gradient = AppColors.bookCovers[colorIdx];
    final emoji = resolveCoverEmojiFor(_titleController.text.trim(), _coverEmoji);
    final title =
        _titleController.text.trim().isEmpty ? '书名' : _titleController.text.trim();
    return Center(
      child: Container(
        width: 132,
        height: 178,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 34)),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 封面 emoji 选择器 — 点选高亮，再点取消（回自动匹配）
  Widget _buildEmojiPicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: bookCoverEmojis.map((e) {
        final selected = _coverEmoji == e;
        return GestureDetector(
          onTap: () => setState(() => _coverEmoji = selected ? null : e),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.reading.withValues(alpha: 0.16)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? AppColors.reading : Theme.of(context).dividerColor,
                width: selected ? 1.6 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(e, style: const TextStyle(fontSize: 19)),
          ),
        );
      }).toList(),
    );
  }
}
