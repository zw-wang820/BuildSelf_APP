import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/data/models/enums.dart';
import 'package:buildself/data/models/reading_models.dart';
import 'package:buildself/data/repositories/reading_repository.dart';
import 'package:buildself/shared/widgets/emoji_icon.dart';
import 'package:buildself/shared/widgets/gradient_button.dart';
import 'package:buildself/shared/widgets/toast.dart';

/// 弹出「添加书籍」底部表单
///
/// 左侧实时封面预览，创建成功后调用 [onCreated] 并关闭表单
Future<void> showAddBookSheet(
  BuildContext context, {
  required String userId,
  required ReadingRepository repository,
  required ValueChanged<Book> onCreated,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddBookSheet(
      userId: userId,
      repository: repository,
      onCreated: onCreated,
    ),
  );
}

class _AddBookSheet extends StatefulWidget {
  final String userId;
  final ReadingRepository repository;
  final ValueChanged<Book> onCreated;

  const _AddBookSheet({
    required this.userId,
    required this.repository,
    required this.onCreated,
  });

  @override
  State<_AddBookSheet> createState() => _AddBookSheetState();
}

class _AddBookSheetState extends State<_AddBookSheet> {
  final _titleCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();
  final _currentPageCtrl = TextEditingController();
  final _totalPageCtrl = TextEditingController();

  BookStatus _status = BookStatus.planned;
  int _coverColor = 0;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    // 实时同步到封面预览
    _titleCtrl.addListener(_onInputChanged);
    _authorCtrl.addListener(_onInputChanged);
  }

  void _onInputChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    _currentPageCtrl.dispose();
    _totalPageCtrl.dispose();
    super.dispose();
  }

  bool get _showProgress => _status != BookStatus.planned;

  int _parseInt(TextEditingController ctrl) => int.tryParse(ctrl.text) ?? 0;

  Future<void> _create() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ToastHelper.show(context, '请输入书名', icon: Icons.info_outline);
      return;
    }
    if (_creating) return;
    setState(() => _creating = true);
    try {
      final totalPages = _parseInt(_totalPageCtrl);
      final currentPage = _status == BookStatus.finished
          ? totalPages
          : _parseInt(_currentPageCtrl);

      final book = await widget.repository.createBook(
        userId: widget.userId,
        title: title,
        author: _authorCtrl.text.trim().isEmpty
            ? null
            : _authorCtrl.text.trim(),
        status: _status,
        currentPage: currentPage,
        totalPages: totalPages,
        coverColor: _coverColor,
      );
      if (mounted) {
        widget.onCreated(book);
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        ToastHelper.show(context, '添加失败，请重试', icon: Icons.error_outline);
        setState(() => _creating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final divider = isDark ? AppColors.dividerDark : AppColors.dividerLight;
    final labelStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary(context),
    );

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '添加书籍',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 16),
              // 左侧实时封面预览 + 右侧书名/作者
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCoverPreview(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        TextField(
                          controller: _titleCtrl,
                          maxLength: 30,
                          decoration: const InputDecoration(
                            labelText: '书名',
                            hintText: '输入书名',
                            counterText: '',
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _authorCtrl,
                          maxLength: 20,
                          decoration: const InputDecoration(
                            labelText: '作者',
                            hintText: '选填',
                            counterText: '',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // 阅读状态
              Text('阅读状态', style: labelStyle),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildStatusCard(
                    BookStatus.planned,
                    '📖',
                    '想读',
                    AppColors.reading,
                  ),
                  const SizedBox(width: 10),
                  _buildStatusCard(
                    BookStatus.reading,
                    '👀',
                    '在读',
                    AppColors.todo,
                  ),
                  const SizedBox(width: 10),
                  _buildStatusCard(
                    BookStatus.finished,
                    '✅',
                    '已读完',
                    AppColors.success,
                  ),
                ],
              ),
              // 阅读进度（想读时不显示）
              if (_showProgress) ...[
                const SizedBox(height: 18),
                Text('阅读进度', style: labelStyle),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _currentPageCtrl,
                        enabled: _status != BookStatus.finished,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: '当前页',
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _totalPageCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: '总页数',
                          counterText: '',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              // 封面颜色
              Text('封面颜色', style: labelStyle),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(AppColors.bookCovers.length, (i) {
                  final selected = _coverColor == i;
                  return GestureDetector(
                    onTap: () => setState(() => _coverColor = i),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        gradient: AppColors.bookCovers[i],
                        shape: BoxShape.circle,
                        border: selected
                            ? Border.all(
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimaryLight,
                                width: 2.5,
                              )
                            : null,
                      ),
                      child: selected
                          ? const Center(child: EmojiIcon('✅', size: 15))
                          : null,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              // 创建按钮
              GradientButton(
                label: _creating ? '添加中…' : '添加书籍',
                icon: Icons.menu_book,
                onPressed: _creating ? null : _create,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 左侧实时封面预览 — 渐变 + 书名/作者 + 状态徽章
  Widget _buildCoverPreview() {
    final title = _titleCtrl.text.trim();
    final author = _authorCtrl.text.trim();
    final gradient = AppColors.bookCovers[_coverColor % AppColors.bookCovers.length];
    return Container(
      width: 104,
      height: 148,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 状态徽章
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _statusEmoji(_status) + _statusLabel(_status),
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const Spacer(),
          // 书名
          Text(
            title.isEmpty ? '书名预览' : title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          // 作者
          Text(
            author.isEmpty ? '作者' : author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          // 进度提示
          if (_showProgress) ...[
            const SizedBox(height: 6),
            Text(
              _status == BookStatus.finished
                  ? '100%'
                  : '${_parseInt(_currentPageCtrl)}/${_parseInt(_totalPageCtrl)}',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 状态三列卡片
  Widget _buildStatusCard(
    BookStatus status,
    String emoji,
    String label,
    Color color,
  ) {
    final selected = _status == status;
    final divider = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dividerDark
        : AppColors.dividerLight;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _status = status),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.14) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : divider,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? color : AppColors.textPrimary(context),
                ),
              ),
            ],
          ),
        ),
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
