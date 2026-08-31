import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/core/router/routes.dart';
import 'package:buildself/features/auth/providers/app_provider.dart';
import 'package:buildself/features/habit/data/habit_repository.dart';
import 'package:buildself/features/habit/models/habit_model.dart';
import 'package:buildself/shared/widgets/app_card.dart';
import 'package:buildself/shared/widgets/nexus_background.dart';

/// 习惯总览统计页 — 全局摘要 + 近 7 天趋势 + 各习惯排行
class HabitOverviewScreen extends StatefulWidget {
  const HabitOverviewScreen({Key? key}) : super(key: key);

  @override
  State<HabitOverviewScreen> createState() => _HabitOverviewScreenState();
}

class _HabitOverviewScreenState extends State<HabitOverviewScreen> {
  final _repo = HabitRepository();
  List<Habit> _habits = [];
  Map<String, Set<String>> _logs = {};
  bool _loading = true;

  String get _userId => context.read<AppProvider>().userId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final habits = await _repo.getAll(_userId);
      final logs = await _repo.getLogsByHabit(_userId);
      if (mounted) {
        setState(() {
          _habits = habits;
          _logs = logs;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ==================== 统计 ====================

  int get _total => _habits.length;

  int get _doneToday {
    final today = HabitRepository.fmtDate(DateTime.now());
    return _logs.values.where((d) => d.contains(today)).length;
  }

  int get _maxStreak => HabitRepository.maxStreak(_logs);

  int get _monthDays =>
      HabitRepository.monthCheckDays(_logs, DateTime.now());

  /// 累计打卡总次数（所有习惯打卡记录之和）
  int get _totalChecks {
    var sum = 0;
    for (final dates in _logs.values) {
      sum += dates.length;
    }
    return sum;
  }

  /// 近 7 天每日打卡习惯数（今天-6 .. 今天）
  List<int> get _weekCounts {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      final ds = HabitRepository.fmtDate(d);
      return _logs.values.where((s) => s.contains(ds)).length;
    });
  }

  /// 各习惯排行（按本月打卡天数倒序）
  List<_HabitStatRow> get _rows {
    final now = DateTime.now();
    final prefix = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final rows = _habits.map((h) {
      final dates = _logs[h.id] ?? <String>{};
      return _HabitStatRow(
        habit: h,
        month: dates.where((d) => d.startsWith(prefix)).length,
        streak: HabitRepository.streakOf(dates),
        total: dates.length,
      );
    }).toList();
    rows.sort((a, b) => b.month.compareTo(a.month));
    return rows;
  }

  // ==================== UI ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('习惯总览')),
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
                      _buildSummary(context),
                      const SizedBox(height: 20),
                      _buildSectionTitle(context, '📈 近 7 天打卡趋势'),
                      const SizedBox(height: 10),
                      _buildWeekChart(context),
                      const SizedBox(height: 20),
                      _buildSectionTitle(context, '🏆 各习惯统计'),
                      const SizedBox(height: 10),
                      if (_rows.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              '还没有习惯',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                          ),
                        )
                      else
                        for (final row in _rows) ...[
                          _buildHabitRow(context, row),
                          const SizedBox(height: 10),
                        ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary(context),
      ),
    );
  }

  /// 全局摘要 — 5 卡（两行：3 + 2）
  Widget _buildSummary(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _buildStatCard(context, Icons.fitness_center, '$_total', '总习惯',
                AppColors.habit),
            const SizedBox(width: 8),
            _buildStatCard(context, Icons.check_circle_outline, '$_doneToday',
                '今日完成', AppColors.success),
            const SizedBox(width: 8),
            _buildStatCard(context, Icons.local_fire_department, '$_maxStreak',
                '连续最长', AppColors.goalShort),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildStatCard(context, Icons.calendar_month_outlined, '$_monthDays',
                '本月打卡', AppColors.todo),
            const SizedBox(width: 8),
            _buildStatCard(context, Icons.done_all, '$_totalChecks', '累计打卡',
                AppColors.info),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// 近 7 天柱状图 — 纯 widget 自绘，零依赖
  Widget _buildWeekChart(BuildContext context) {
    final counts = _weekCounts;
    var maxV = 0;
    for (final c in counts) {
      if (c > maxV) maxV = c;
    }
    final now = DateTime.now();
    const maxH = 90.0;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.habit.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: SizedBox(
        height: 130,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(7, (i) {
            final d = now.subtract(Duration(days: 6 - i));
            final v = counts[i];
            final h = maxV == 0 ? 6.0 : (v / maxV) * maxH;
            return Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '$v',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.habit,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: h < 6 ? 6 : h,
                    decoration: BoxDecoration(
                      color: AppColors.habit.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${d.month}/${d.day}',
                    style: TextStyle(
                      fontSize: 9,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  /// 各习惯排行行 — 点击进入该习惯日历统计
  Widget _buildHabitRow(BuildContext context, _HabitStatRow row) {
    final habit = row.habit;
    final color = kHabitPalette[habit.colorIndex % kHabitPalette.length];
    return AppCard(
      accent: color,
      onTap: () async {
        await Navigator.pushNamed(context, AppRoutes.habitStats,
            arguments: habit.id);
        if (mounted) _loadData();
      },
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(habit.icon, style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '本月 ${row.month} 天 · 连续 ${row.streak} 天 · 累计 ${row.total} 次',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right,
              size: 18, color: AppColors.textSecondary(context)),
        ],
      ),
    );
  }
}

/// 排行行数据
class _HabitStatRow {
  final Habit habit;
  final int month;
  final int streak;
  final int total;

  _HabitStatRow({
    required this.habit,
    required this.month,
    required this.streak,
    required this.total,
  });
}
