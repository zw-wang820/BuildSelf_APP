import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/core/router/routes.dart';
import 'package:buildself/data/models/work_note_model.dart';
import 'package:buildself/data/repositories/work_repository.dart';
import 'package:buildself/features/auth/providers/app_provider.dart';
import 'package:buildself/shared/widgets/app_card.dart';
import 'package:buildself/shared/widgets/nexus_background.dart';

/// 时间窗口类型
enum _WindowType { week, month, quarter, year, custom }

/// 工作统计页 — 按时间窗口统计工作记录，按分类聚合
class WorkStatsScreen extends StatefulWidget {
  const WorkStatsScreen({Key? key}) : super(key: key);

  @override
  State<WorkStatsScreen> createState() => _WorkStatsScreenState();
}

class _WorkStatsScreenState extends State<WorkStatsScreen> {
  final _repo = WorkRepository();
  List<WorkNote> _notes = [];
  bool _loading = true;

  _WindowType _windowType = _WindowType.month;
  DateTimeRange? _customRange;

  /// 下钻选中的分类（null = 显示统计视图）
  String? _selectedType;

  String get _userId => context.read<AppProvider>().userId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final notes = await _repo.getAll(_userId);
      if (mounted) {
        setState(() {
          _notes = notes;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ==================== 时间窗口 ====================

  DateTime get _now => DateTime.now();

  List<DateTime> get _range {
    final now = _now;
    switch (_windowType) {
      case _WindowType.week:
        final start =
            DateTime(now.year, now.month, now.day - (now.weekday - 1));
        return [start, now];
      case _WindowType.month:
        return [DateTime(now.year, now.month, 1), now];
      case _WindowType.quarter:
        final startMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        return [DateTime(now.year, startMonth, 1), now];
      case _WindowType.year:
        return [DateTime(now.year, 1, 1), now];
      case _WindowType.custom:
        final r = _customRange ?? DateTimeRange(start: now, end: now);
        return [r.start, DateTime(r.end.year, r.end.month, r.end.day, 23, 59, 59)];
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
        _windowType = _WindowType.custom;
      });
    }
  }

  // ==================== 统计 ====================

  /// 窗口内创建的工作记录
  List<WorkNote> get _windowNotes {
    final range = _range;
    final start = range[0];
    final end = range[1];
    return _notes
        .where((n) => !n.createdAt.isBefore(start) && !n.createdAt.isAfter(end))
        .toList();
  }

  int get _total => _windowNotes.length;

  /// 窗口内完成的待学项（doneAt 落窗口，含早前创建）
  int get _doneInWindow {
    final range = _range;
    final start = range[0];
    final end = range[1];
    return _notes.where((n) {
      final d = n.doneAt;
      return n.done && d != null && !d.isBefore(start) && !d.isAfter(end);
    }).length;
  }

  /// 日均记录数
  double get _dailyAvg {
    final range = _range;
    final days = range[1].difference(range[0]).inDays + 1;
    if (days <= 0) return 0;
    return _total / days;
  }

  /// 分类聚合（数量倒序）
  List<_CategoryStat> get _categoryStats {
    final counts = <String, int>{};
    for (final n in _windowNotes) {
      counts[n.recordType] = (counts[n.recordType] ?? 0) + 1;
    }
    final stats = counts.entries
        .map((e) => _CategoryStat(
              type: e.key,
              count: e.value,
              done: _windowNotes
                  .where((n) => n.recordType == e.key && n.done)
                  .length,
            ))
        .toList();
    stats.sort((a, b) => b.count.compareTo(a.count));
    return stats;
  }

  // ==================== UI ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('工作统计')),
      body: NexusBackground(
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: _selectedType == null
                      ? _buildStatsView(context)
                      : _buildDetailView(context),
                ),
        ),
      ),
    );
  }

  /// 统计视图
  Widget _buildStatsView(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _buildWindowBar(context),
        const SizedBox(height: 14),
        _buildSummary(context),
        const SizedBox(height: 20),
        Text(
          '分类统计',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary(context),
          ),
        ),
        const SizedBox(height: 10),
        if (_total == 0)
          _buildEmpty(context)
        else
          for (final stat in _categoryStats) ...[
            _buildCategoryBar(context, stat),
            const SizedBox(height: 12),
          ],
      ],
    );
  }

  /// 时间窗口 chips
  Widget _buildWindowBar(BuildContext context) {
    final entries = <MapEntry<_WindowType, String>>[
      const MapEntry(_WindowType.week, '本周'),
      const MapEntry(_WindowType.month, '本月'),
      const MapEntry(_WindowType.quarter, '本季度'),
      const MapEntry(_WindowType.year, '今年'),
      MapEntry(
        _WindowType.custom,
        _customRange == null
            ? '自定义'
            : '${_fmt(_customRange!.start)} - ${_fmt(_customRange!.end)}',
      ),
    ];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: entries.map((e) {
        final selected = _windowType == e.key;
        const accent = AppColors.work;
        return GestureDetector(
          onTap: e.key == _WindowType.custom ? _pickCustomRange : () {
            setState(() => _windowType = e.key);
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
                    : (isDark ? AppColors.dividerDark : AppColors.dividerLight),
                width: 1,
              ),
            ),
            child: Text(
              e.value,
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

  /// 摘要卡 — 总数 / 待学完成 / 日均
  Widget _buildSummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.work.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _summaryItem(context, '$_total', '记录总数', AppColors.work),
          _summaryItem(context, '$_doneInWindow', '待学完成', AppColors.success),
          _summaryItem(
              context, _dailyAvg.toStringAsFixed(1), '日均记录', AppColors.info),
        ],
      ),
    );
  }

  Widget _summaryItem(
      BuildContext context, String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              color: AppColors.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  /// 分类横向条形图 — 点击下钻该分类记录
  Widget _buildCategoryBar(BuildContext context, _CategoryStat stat) {
    final color = workTypeColor(stat.type);
    final maxCount = _categoryStats.first.count;
    final ratio = maxCount == 0 ? 0.0 : stat.count / maxCount;
    final percent = (_total == 0 ? 0 : stat.count / _total * 100).round();
    final isLearning = stat.type == '待学习项';

    return GestureDetector(
      onTap: () => setState(() => _selectedType = stat.type),
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(workTypeEmoji(stat.type),
                  style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  stat.type,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ),
              if (isLearning)
                Text(
                  '${stat.done}/${stat.count}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                '$percent%',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(
                  height: 10,
                  width: double.infinity,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.dividerDark
                      : AppColors.dividerLight,
                ),
                FractionallySizedBox(
                  widthFactor: ratio == 0 ? 0.02 : ratio,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 下钻视图 — 选中分类的记录列表
  Widget _buildDetailView(BuildContext context) {
    final type = _selectedType!;
    final list = _windowNotes
        .where((n) => n.recordType == type)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          children: [
            TextButton.icon(
              onPressed: () => setState(() => _selectedType = null),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('返回统计'),
              style: TextButton.styleFrom(foregroundColor: AppColors.work),
            ),
            const Spacer(),
            Text(
              '${workTypeEmoji(type)} $type · ${list.length} 条',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                '该分类暂无记录',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary(context),
                ),
              ),
            ),
          )
        else
          for (final note in list) ...[
            _buildNoteRow(context, note),
            const SizedBox(height: 10),
          ],
      ],
    );
  }

  Widget _buildNoteRow(BuildContext context, WorkNote note) {
    final color = workTypeColor(note.recordType);
    return AppCard(
      accent: color,
      margin: EdgeInsets.zero,
      onTap: () async {
        await Navigator.pushNamed(context, AppRoutes.workDetail,
            arguments: note.id);
        if (mounted) _loadData();
      },
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Text(workTypeEmoji(note.recordType),
              style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (note.title.isNotEmpty) ...[
                  Text(
                    note.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  note.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${note.createdAt.month}/${note.createdAt.day}',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Text('🗓️', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            '该时间段没有工作记录',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '切换时间窗口查看其他区间',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) => '${d.month}/${d.day}';
}

/// 分类统计行数据
class _CategoryStat {
  final String type;
  final int count;
  final int done;

  _CategoryStat({
    required this.type,
    required this.count,
    required this.done,
  });
}
