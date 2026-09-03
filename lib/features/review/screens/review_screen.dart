import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/core/constants/strings.dart';
import 'package:buildself/core/router/routes.dart';
import 'package:buildself/features/auth/providers/app_provider.dart';
import 'package:buildself/features/review/data/review_repository.dart';
import 'package:buildself/features/review/data/review_summary.dart';
import 'package:buildself/features/review/models/review_item.dart';
import 'package:buildself/features/review/models/review_quadrant.dart';
import 'package:buildself/features/review/models/review_session.dart';
import 'package:buildself/features/review/widgets/review_quadrant_card.dart';
import 'package:buildself/shared/widgets/toast.dart';

/// KISS 复盘主屏 — 1×4 纵向全宽四象限
///
/// - [date] 为空表示今日；传特定日期用于历史详情
/// - [readOnly] 只读模式（历史详情进入，隐藏添加/编辑）
class ReviewScreen extends StatefulWidget {
  final DateTime? date;
  final bool readOnly;

  const ReviewScreen({Key? key, this.date, this.readOnly = false})
      : super(key: key);

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final ReviewRepository _repo = ReviewRepository();

  DateTime get _date => widget.date ?? DateTime.now();
  bool get _isToday {
    final now = DateTime.now();
    return _date.year == now.year &&
        _date.month == now.month &&
        _date.day == now.day;
  }

  ReviewSession? _session;
  bool _loading = true;
  bool _dialogShown = false;

  /// 当前展开输入的象限（同屏仅一个）
  ReviewQuadrant? _focusQuadrant;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = context.read<AppProvider>().userId;
    if (userId.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final session = await _repo.getSessionByDate(userId, _date);
      if (!mounted) return;
      setState(() {
        _session = session;
        _loading = false;
      });
      // 二次进入今日且已有内容 → 决策 B 弹确认
      if (_isToday && !widget.readOnly && !_dialogShown && mounted) {
        _dialogShown = true;
        if (session != null && session.itemCount > 0) {
          _maybeShowContinueDialog(session.itemCount);
        }
      }
    } catch (e) {
      debugPrint('Review load failed: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  /// 决策 B：今日已有条目时的继续编辑确认弹窗
  /// 返回：true=继续编辑；'history'=跳历史；其他=退出主屏
  Future<void> _maybeShowContinueDialog(int count) async {
    final result = await showDialog<Object>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.reviewTitle),
        content: Text(AppStrings.reviewEditExisting
            .replaceAll('{n}', '$count')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'history'),
            child: Text(AppStrings.reviewViewHistory),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppStrings.reviewContinueEdit),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (result == 'history') {
      await Navigator.pushNamed(context, AppRoutes.reviewHistory);
    } else if (result != true) {
      // 用户点「取消」或点弹窗外 → 退出主屏
      Navigator.maybePop(context);
    }
  }

  // ==================== 数据操作 ====================

  Future<void> _addItem(ReviewQuadrant q, String content) async {
    final userId = context.read<AppProvider>().userId;
    if (userId.isEmpty) return;
    await _repo.addItem(userId, _date, q, content);
    if (mounted) {
      ToastHelper.show(context, '已记录到 ${q.emoji} ${q.enLabel}');
    }
    await _reloadKeepInput(q);
  }

  Future<void> _editItem(ReviewItem item) async {
    final controller = TextEditingController(text: item.content);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑复盘项'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          maxLength: 500,
          decoration: const InputDecoration(hintText: '写下你的思考…'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppStrings.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppStrings.save),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      final text = controller.text.trim();
      if (text.isNotEmpty) {
        await _repo.updateItemContent(item.id, text);
        await _load();
      }
    }
    controller.dispose();
  }

  Future<void> _deleteItem(ReviewItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除这条复盘？'),
        content: Text(item.content,
            maxLines: 3, overflow: TextOverflow.ellipsis),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppStrings.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppStrings.delete,
                style: const TextStyle(color: AppColors.reviewStop)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await _repo.deleteItem(item.id);
      if (mounted) {
        ToastHelper.show(context, AppStrings.reviewItemDeleted);
      }
      await _load();
    }
  }

  /// 提交新条目后保留当前象限输入焦点（收起输入态）
  Future<void> _reloadKeepInput(ReviewQuadrant q) async {
    await _load();
  }

  // ==================== 总结 ====================

  void _openSummarySheet() {
    final session = _session;
    if (session == null || session.itemCount == 0) return;
    final summary = buildReviewSummary(
      dateLabel: _dateLabel(_date),
      byQuadrant: session.items,
    );
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.8),
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        decoration: BoxDecoration(
          color: Theme.of(ctx).brightness == Brightness.dark
              ? AppColors.surfaceDark
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('📋', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  '${AppStrings.reviewTitle} · 总结',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                child: SelectableText(
                  summary,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.55,
                    color: Theme.of(ctx).brightness == Brightness.dark
                        ? const Color(0xFFE2E8F0)
                        : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await _copyToClipboard(ctx, summary);
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: Text(AppStrings.reviewCopy,
                          style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: widget.readOnly
                          ? null
                          : () async {
                              await _repo.saveSummary(session.id, summary);
                              if (ctx.mounted) {
                                ToastHelper.show(ctx,
                                    AppStrings.reviewSummarySaved);
                                Navigator.pop(ctx);
                              }
                              await _load();
                            },
                      icon: const Icon(Icons.save_alt_rounded, size: 16),
                      label: Text(AppStrings.reviewSaveSummary,
                          style: const TextStyle(fontSize: 13)),
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

  Future<void> _copyToClipboard(
      BuildContext ctx, String summary) async {
    await Clipboard.setData(ClipboardData(text: summary));
    if (ctx.mounted) {
      ToastHelper.show(ctx, AppStrings.reviewCopied);
    }
  }

  // ==================== 辅助 ====================

  String _dateLabel(DateTime d) {
    const week = ['一', '二', '三', '四', '五', '六', '日'];
    final isToday = d.year == DateTime.now().year &&
        d.month == DateTime.now().month &&
        d.day == DateTime.now().day;
    // 具体日期始终展示（含今日）：今日 → 「今日 · 9月3日 · 2026」
    final datePart = '${d.month}月${d.day}日';
    final yearPart = '${d.year}';
    if (isToday) {
      return '${AppStrings.reviewToday} · $datePart · $yearPart';
    }
    return '$datePart · 周${week[d.weekday - 1]} · $yearPart';
  }

  String _dateTitle(DateTime d) {
    return '${d.month}月${d.day}日';
  }

  // ==================== UI ====================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface =
        isDark ? AppColors.surfaceDark : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.readOnly ? '${AppStrings.reviewTitle} · ${_dateTitle(_date)}' : AppStrings.reviewTitle),
        actions: [
          if (!widget.readOnly && _session != null && _session!.itemCount > 0)
            TextButton.icon(
              onPressed: _openSummarySheet,
              icon: const Icon(Icons.auto_awesome_rounded,
                  size: 16, color: AppColors.primary),
              label: Text(
                AppStrings.reviewGenerate,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.primary),
              ),
            )
          else if (!widget.readOnly && _session != null && _session!.itemCount == 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  AppStrings.reviewGenerate,
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary(context)
                          .withValues(alpha: 0.5)),
                ),
              ),
            ),
          if (!widget.readOnly)
            IconButton(
              tooltip: AppStrings.reviewHistory,
              icon: const Icon(Icons.history_rounded, size: 22),
              onPressed: () => Navigator.pushNamed(
                  context, AppRoutes.reviewHistory),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(strokeWidth: 2.5))
          : _buildBody(context, surface),
    );
  }

  Widget _buildBody(BuildContext context, Color surface) {
    final session = _session;
    final empty = session == null || session.itemCount == 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      children: [
        // ===== 顶部：副标 + 日期 + 说明 =====
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _dateLabel(_date),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                AppStrings.reviewSubtitle,
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 0.4,
                  color: AppColors.textSecondary(context),
                ),
              ),
            ],
          ),
        ),
        // 只读历史：已保存总结预览
        if (widget.readOnly && session?.summary != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDarkOf(context)
                    ? AppColors.dividerDark
                    : AppColors.dividerLight,
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('📋', style: TextStyle(fontSize: 15)),
                    SizedBox(width: 6),
                    Text('当日总结',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 6),
                SelectableText(
                  session!.summary!,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (widget.readOnly && session?.summary == null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              AppStrings.reviewNoSummary,
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary(context),
              ),
            ),
          ),
        if (empty && !widget.readOnly)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              '${AppStrings.reviewEmpty} — 从「保持」开始，写下今天最好的一件事 ✍️',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary(context),
              ),
            ),
          ),
        // ===== 1×4 四象限（纵向全宽，逐个直观） =====
        for (var i = 0; i < ReviewQuadrant.values.length; i++) ...[
          _quadrantCard(context, ReviewQuadrant.values[i]),
          if (i < ReviewQuadrant.values.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  /// 单卡全宽；内容多时天然向下生长（外层 ListView 承接滚动）
  Widget _quadrantCard(BuildContext context, ReviewQuadrant q) {
    final session = _session;
    final items = (session?.items[q]) ?? const <ReviewItem>[];
    return ReviewQuadrantCard(
      quadrant: q,
      items: items,
      readOnly: widget.readOnly,
      focused: _focusQuadrant == q,
      onAddTap: () {
        if (widget.readOnly) return;
        setState(() {
          _focusQuadrant = _focusQuadrant == q ? null : q;
        });
      },
      onSubmit: (text) => _addItem(q, text),
      onEditItem: _editItem,
      onDeleteItem: _deleteItem,
    );
  }

  bool isDarkOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
}
