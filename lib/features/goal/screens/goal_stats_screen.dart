import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/core/router/routes.dart';
import 'package:buildself/data/models/enums.dart';
import 'package:buildself/data/models/goal_model.dart';
import 'package:buildself/data/repositories/goal_repository.dart';
import 'package:buildself/features/auth/providers/app_provider.dart';
import 'package:buildself/shared/widgets/nexus_background.dart';

/// 时间段类型
enum _RangeType { week, month, days90, custom }

/// 目标统计页 — 按时间段统计目标完成/未完成情况
class GoalStatsScreen extends StatefulWidget {
  const GoalStatsScreen({Key? key}) : super(key: key);

  @override
  State<GoalStatsScreen> createState() => _GoalStatsScreenState();
}

class _GoalStatsScreenState extends State<GoalStatsScreen> {
  final _repo = GoalRepository();
  List<Goal> _goals = [];
  bool _loading = true;

  _RangeType _rangeType = _RangeType.month;
  DateTimeRange? _customRange;
  GoalStatus _statusFilter = GoalStatus.completed;

  String get _userId => context.read<AppProvider>().userId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final goals = await _repo.getAllGoals(_userId);
      if (mounted) {
        setState(() {
          _goals = goals;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ==================== 时间段 ====================

  DateTime get _now => DateTime.now();

  List<DateTime> get _range {
    final now = _now;
    switch (_rangeType) {
      case _RangeType.week:
        final start = DateTime(now.year, now.month, now.day - (now.weekday - 1));
        return [start, now];
      case _RangeType.month:
        return [DateTime(now.year, now.month, 1), now];
      case _RangeType.days90:
        return [now.subtract(const Duration(days: 90)), now];
      case _RangeType.custom:
        final r = _customRange ?? DateTimeRange(start: now, end: now);
        return [r.start, r.end];
    }
  }

  Future<void> _pickCustomRange() async {
    final now = _now;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: _customRange,
      helpText: '选择统计时间段',
    );
    if (picked != null) {
      setState(() {
        _customRange = picked;
        _rangeType = _RangeType.custom;
      });
    }
  }

  // ==================== 统计 ====================

  /// 时间段内启动的目标
  List<Goal> get _started {
    final range = _range;
    final start = range[0];
    final end = range[1];
    return _goals
        .where((g) =>
            !g.startDate.isBefore(start) && !g.startDate.isAfter(end))
        .toList();
  }

  /// 时间段内完成的目标（completedAt 落在区间，含早前启动）
  List<Goal> get _doneInRange {
    final range = _range;
    final start = range[0];
    final end = range[1];
    return _goals.where((g) {
      final c = g.completedAt;
      return c != null && !c.isBefore(start) && !c.isAfter(end);
    }).toList();
  }

  int get _total => _started.length;
  int get _completed => _started.where((g) => g.status == GoalStatus.completed).length;
  int get _doing =>
      _started.where((g) => g.status == GoalStatus.active).length;
  int get _abandoned =>
      _started.where((g) => g.status == GoalStatus.abandoned).length;

  /// 逾期未完成：进行中且截止日期早于今天
  int get _overdue {
    final today = DateTime(_now.year, _now.month, _now.day);
    return _started.where((g) {
      final t = g.targetDate;
      return g.status == GoalStatus.active && t != null && t.isBefore(today);
    }).length;
  }

  double get _rate => _total == 0 ? 0 : _completed / _total;

  /// 当前状态列表（按时间倒序）
  List<Goal> get _filtered {
    final list = _started.where((g) => g.status == _statusFilter).toList();
    list.sort((a, b) {
      final da = _sortTime(a);
      final db = _sortTime(b);
      return db.compareTo(da);
    });
    return list;
  }

  DateTime _sortTime(Goal g) {
    if (g.status == GoalStatus.completed) {
      return g.completedAt ?? g.updatedAt;
    }
    return g.updatedAt;
  }

  // ==================== UI ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('目标统计')),
      body: NexusBackground(
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      _buildRangeBar(context),
                      const SizedBox(height: 14),
                      _buildSummary(context),
                      const SizedBox(height: 8),
                      _buildDoneNote(context),
                      const SizedBox(height: 16),
                      _buildStatusBar(context),
                      const SizedBox(height: 10),
                      if (_total == 0)
                        _buildEmpty(context)
                      else if (_filtered.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 28),
                          child: Center(
                            child: Text(
                              '该状态下暂无目标',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                          ),
                        )
                      else
                        for (final goal in _filtered) ...[
                          _buildGoalRow(context, goal),
                          const SizedBox(height: 10),
                        ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  /// 时间段选择 chips
  Widget _buildRangeBar(BuildContext context) {
    final entries = <MapEntry<_RangeType, String>>[
      const MapEntry(_RangeType.week, '本周'),
      const MapEntry(_RangeType.month, '本月'),
      const MapEntry(_RangeType.days90, '近 90 天'),
      MapEntry(
        _RangeType.custom,
        _customRange == null
            ? '自定义'
            : '${_fmt(_customRange!.start)} - ${_fmt(_customRange!.end)}',
      ),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: entries.map((e) {
        final type = e.key;
        final label = e.value;
        final selected = _rangeType == type;
        const accent = AppColors.goal;
        return GestureDetector(
          onTap: type == _RangeType.custom ? _pickCustomRange : () {
            setState(() => _rangeType = type);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: selected
                  ? accent.withValues(alpha: 0.14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected
                    ? accent
                    : (Theme.of(context).brightness == Brightness.dark
                        ? AppColors.dividerDark
                        : AppColors.dividerLight),
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? accent : AppColors.textSecondary(context),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 摘要卡 — 环形达成率 + 完成/未完成细分
  Widget _buildSummary(BuildContext context) {
    final done = _completed;
    final undone = _total - done;
    const color = AppColors.goal;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _DonutChart(
            progress: _rate,
            color: color,
            centerText: '${(_rate * 100).round()}%',
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '启动目标 $_total 个',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _tag(context, '✅ 完成 $done', AppColors.success),
                    const SizedBox(width: 6),
                    _tag(context, '未完成 $undone', AppColors.goalShort),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _miniTag('▶ 进行中 $_doing', AppColors.info),
                    _miniTag('⏸ 放弃 $_abandoned', AppColors.textSecondary(context)),
                    if (_overdue > 0)
                      _miniTag('⚠️ 逾期 $_overdue', AppColors.error),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  Widget _miniTag(String text, Color color) {
    return Text(
      text,
      style: TextStyle(fontSize: 11, color: color),
    );
  }

  /// 附注：本段共完成 M 个
  Widget _buildDoneNote(BuildContext context) {
    final m = _doneInRange.length;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '🎉 本段共完成 $m 个目标',
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: AppColors.success,
        ),
      ),
    );
  }

  /// 状态筛选 — 已完成 / 进行中 / 已放弃
  Widget _buildStatusBar(BuildContext context) {
    final entries = <MapEntry<GoalStatus, String>>[
      const MapEntry(GoalStatus.completed, '已完成'),
      const MapEntry(GoalStatus.active, '进行中'),
      const MapEntry(GoalStatus.abandoned, '已放弃'),
    ];
    return Row(
      children: [
        for (final e in entries) ...[
          _buildStatusChip(e.key, e.value),
          if (e.key != entries.last.key) const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _buildStatusChip(GoalStatus status, String label) {
    final selected = _statusFilter == status;
    final accent = _statusColor(status);
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? accent
                : (Theme.of(context).brightness == Brightness.dark
                    ? AppColors.dividerDark
                    : AppColors.dividerLight),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? accent : AppColors.textSecondary(context),
          ),
        ),
      ),
    );
  }

  Color _statusColor(GoalStatus status) {
    switch (status) {
      case GoalStatus.completed:
        return AppColors.success;
      case GoalStatus.active:
        return AppColors.info;
      case GoalStatus.abandoned:
        return AppColors.textSecondary(context);
    }
  }

  Widget _buildEmpty(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          const Text('🗓️', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            '该时间段没有启动的目标',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '切换时间段查看其他区间',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  /// 目标行 — 点击进详情
  Widget _buildGoalRow(BuildContext context, Goal goal) {
    final color = _statusColor(goal.status);
    final today = DateTime(_now.year, _now.month, _now.day);
    final overdue = goal.status == GoalStatus.active &&
        goal.targetDate != null &&
        goal.targetDate!.isBefore(today);
    return GestureDetector(
      onTap: () async {
        await Navigator.pushNamed(context, AppRoutes.goalDetail,
            arguments: goal.id);
        if (mounted) _loadData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ??
              (Theme.of(context).brightness == Brightness.dark
                  ? AppColors.surfaceDark
                  : AppColors.surfaceLight),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.dividerDark
                : AppColors.dividerLight,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🎯', style: TextStyle(fontSize: 17)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _subtitle(goal, overdue),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: overdue ? AppColors.error : AppColors.textSecondary(context),
                      fontWeight: overdue ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (goal.status == GoalStatus.active) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 44,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: goal.progress / 100,
                    minHeight: 4,
                    backgroundColor: AppColors.info.withValues(alpha: 0.15),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.info),
                  ),
                ),
              ),
            ],
            Icon(Icons.chevron_right,
                size: 18, color: AppColors.textSecondary(context)),
          ],
        ),
      ),
    );
  }

  String _subtitle(Goal goal, bool overdue) {
    switch (goal.status) {
      case GoalStatus.completed:
        final c = goal.completedAt;
        return c != null ? '✅ 已完成 · ${_fmt(c)}' : '✅ 已完成';
      case GoalStatus.active:
        final t = goal.targetDate;
        if (overdue) {
          return '⚠️ 已逾期 · 截止 ${_fmt(t!)}';
        }
        return t != null ? '进行中 · 截止 ${_fmt(t)}' : '进行中 · 进度 ${goal.progress}%';
      case GoalStatus.abandoned:
        return '已放弃';
    }
  }

  String _fmt(DateTime d) =>
      '${d.month}/${d.day}';
}

/// 环形达成率图 — 纯 CustomPaint 自绘，零依赖
class _DonutChart extends StatelessWidget {
  final double progress; // 0-1
  final Color color;
  final String centerText;

  const _DonutChart({
    required this.progress,
    required this.color,
    required this.centerText,
  });

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dividerDark
        : AppColors.dividerLight;
    return SizedBox(
      width: 92,
      height: 92,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(92, 92),
            painter: _DonutPainter(progress: progress, color: color, bg: bg),
          ),
          Text(
            centerText,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bg;

  _DonutPainter({
    required this.progress,
    required this.color,
    required this.bg,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 10.0;
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2;

    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = bg;
    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    final arc = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(arc, -math.pi / 2, 2 * math.pi * progress, false, fgPaint);
  }

  @override
  bool shouldRepaint(_DonutPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.bg != bg;
}
