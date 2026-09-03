import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/core/constants/strings.dart';
import 'package:buildself/core/router/routes.dart';
import 'package:buildself/features/auth/providers/app_provider.dart';
import 'package:buildself/features/review/data/review_repository.dart';
import 'package:buildself/features/review/models/review_quadrant.dart';
import 'package:buildself/features/review/models/review_session.dart';
import 'package:buildself/shared/widgets/toast.dart';

/// KISS 复盘历史 — 按日倒序；点击某日进入只读详情
class ReviewHistoryScreen extends StatefulWidget {
  const ReviewHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ReviewHistoryScreen> createState() => _ReviewHistoryScreenState();
}

class _ReviewHistoryScreenState extends State<ReviewHistoryScreen> {
  final ReviewRepository _repo = ReviewRepository();
  List<ReviewSession> _sessions = [];
  bool _loading = true;

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
      final all = await _repo.getHistory(userId);
      // 过滤已软删除
      final active =
          all.where((s) => !s.isDeleted && s.itemCount > 0).toList();
      if (!mounted) return;
      setState(() {
        _sessions = active;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Review history load failed: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openDay(ReviewSession s) async {
    final date = DateTime.parse(s.reviewDate);
    await Navigator.pushNamed(context, AppRoutes.review, arguments: date);
  }

  Future<void> _deleteDay(ReviewSession s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.reviewDeleteDay),
        content: Text(AppStrings.reviewDeleteDayConfirm),
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
      await _repo.softDeleteSession(s.id);
      if (mounted) {
        ToastHelper.show(context, AppStrings.reviewDayDeleted);
      }
      await _load();
    }
  }

  String _title(ReviewSession s) {
    final d = DateTime.parse(s.reviewDate);
    const week = ['一', '二', '三', '四', '五', '六', '日'];
    return '${d.month}月${d.day}日 · 周${week[d.weekday - 1]} · ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final divider = isDark ? AppColors.dividerDark : AppColors.dividerLight;

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.reviewHistory)),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(strokeWidth: 2.5))
          : _sessions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🗂️', style: TextStyle(fontSize: 44)),
                      const SizedBox(height: 10),
                      Text(
                        '还没有历史复盘',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                  itemCount: _sessions.length,
                  itemBuilder: (ctx, i) {
                    final s = _sessions[i];
                    return _buildDayCard(context, s, surface, divider);
                  },
                ),
    );
  }

  Widget _buildDayCard(BuildContext context, ReviewSession s, Color surface,
      Color divider) {
    final k = s.items[ReviewQuadrant.keep]?.length ?? 0;
    final im = s.items[ReviewQuadrant.improve]?.length ?? 0;
    final st = s.items[ReviewQuadrant.start]?.length ?? 0;
    final sp = s.items[ReviewQuadrant.stop]?.length ?? 0;

    Widget dot(Color c) => Container(
          width: 8,
          height: 8,
          decoration:
              BoxDecoration(color: c, shape: BoxShape.circle),
        );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: divider, width: 0.5),
        boxShadow: [
          BoxShadow(
            color:
                isDarkMode(context) ? AppColors.shadowDark : AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openDay(s),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(
              children: [
                // 日期竖条
                Container(
                  width: 4,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _title(s),
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          dot(AppColors.reviewKeep),
                          const SizedBox(width: 3),
                          Text('$k',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.reviewKeep,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          dot(AppColors.reviewImprove),
                          const SizedBox(width: 3),
                          Text('$im',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.reviewImprove,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          dot(AppColors.reviewStart),
                          const SizedBox(width: 3),
                          Text('$st',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.reviewStart,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          dot(AppColors.reviewStop),
                          const SizedBox(width: 3),
                          Text('$sp',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.reviewStop,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                      if (s.summary != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          s.summary!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // 删除整日（软删入回收站）
                IconButton(
                  tooltip: AppStrings.reviewDeleteDay,
                  icon: Icon(Icons.delete_outline_rounded,
                      size: 20,
                      color: AppColors.textSecondary(context)),
                  onPressed: () => _deleteDay(s),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.textSecondary(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool isDarkMode(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
}
