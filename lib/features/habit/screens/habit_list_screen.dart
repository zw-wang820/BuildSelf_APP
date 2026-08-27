import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/core/router/routes.dart';
import 'package:buildself/features/auth/providers/app_provider.dart';
import 'package:buildself/features/habit/data/habit_repository.dart';
import 'package:buildself/features/habit/models/habit_model.dart';
import 'package:buildself/features/habit/widgets/add_habit_sheet.dart';
import 'package:buildself/features/habit/widgets/celebration_overlay.dart';
import 'package:buildself/features/habit/widgets/habit_item_card.dart';
import 'package:buildself/shared/widgets/emoji_icon.dart';
import 'package:buildself/shared/widgets/toast.dart';

/// 习惯列表页 — 统计概览 + 筛选标签 + 卡片列表 + 新建
class HabitListScreen extends StatefulWidget {
  const HabitListScreen({Key? key}) : super(key: key);

  @override
  State<HabitListScreen> createState() => _HabitListScreenState();
}

enum _HabitFilter { all, done, todo }

class _HabitListScreenState extends State<HabitListScreen> {
  final HabitRepository _repo = HabitRepository();

  List<Habit> _habits = [];
  Map<String, Set<String>> _logs = {};
  bool _loading = true;
  _HabitFilter _filter = _HabitFilter.all;

  // 统计概览
  int _total = 0;
  int _doneToday = 0;
  int _maxStreak = 0;
  int _monthDays = 0;

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
      if (!mounted) return;
      setState(() {
        _habits = habits;
        _logs = logs;
        _total = habits.length;
        _doneToday = logs.values
            .where((d) => d.contains(HabitRepository.fmtDate(DateTime.now())))
            .length;
        _maxStreak = HabitRepository.maxStreak(logs);
        _monthDays = HabitRepository.monthCheckDays(logs, DateTime.now());
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// 今日打卡 / 取消打卡
  Future<void> _toggleToday(Habit habit, bool check) async {
    final ok = await _repo.toggle(habit.id, DateTime.now());
    if (!mounted) return;
    await _loadData();
    if (ok) {
      final color = kHabitPalette[habit.colorIndex % kHabitPalette.length];
      ToastHelper.show(context, '✅ ${habit.name} 打卡成功！');
      CelebrationOverlay.show(context, color: color);
    } else {
      ToastHelper.show(context, '已取消今日打卡');
    }
  }

  /// 补打昨天
  Future<void> _makeupYesterday(Habit habit) async {
    final ok = await _repo
        .toggle(habit.id, DateTime.now().subtract(const Duration(days: 1)));
    if (!mounted) return;
    await _loadData();
    ToastHelper.show(
      context,
      ok ? '✅ 已补上昨天的 ${habit.name}' : '昨天已有打卡记录',
    );
  }

  /// 新建习惯
  Future<void> _openAdd() async {
    await showAddHabitSheet(
      context,
      userId: _userId,
      repository: _repo,
      onCreated: (habit) {
        ToastHelper.show(context, '✅ 习惯创建成功！');
      },
    );
    if (mounted) _loadData();
  }

  /// 今日已打卡的习惯集合（供筛选使用）
  Set<String> get _doneTodayIds => {
        for (final e in _logs.entries)
          if (e.value.contains(HabitRepository.fmtDate(DateTime.now())))
            e.key,
      };

  List<Habit> get _filtered {
    final doneIds = _doneTodayIds;
    switch (_filter) {
      case _HabitFilter.done:
        return _habits.where((h) => doneIds.contains(h.id)).toList();
      case _HabitFilter.todo:
        return _habits.where((h) => !doneIds.contains(h.id)).toList();
      case _HabitFilter.all:
        return _habits;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('习惯打卡')),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _buildBody(context),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAdd,
        backgroundColor: AppColors.habit,
        foregroundColor: Colors.white,
        child: const EmojiIcon('➕', size: 22),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_habits.isEmpty) {
      return _buildEmpty();
    }
    final list = _filtered;
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildStats(context)),
        SliverToBoxAdapter(child: _buildFilterBar(context)),
        if (list.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('该分组下暂无习惯')),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildItem(list[i]),
                ),
                childCount: list.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildItem(Habit habit) {
    final dates = _logs[habit.id] ?? <String>{};
    final today = HabitRepository.fmtDate(DateTime.now());
    final yesterday = HabitRepository.fmtDate(
        DateTime.now().subtract(const Duration(days: 1)));
    return HabitItemCard(
      habit: habit,
      checkedToday: dates.contains(today),
      checkedYesterday: dates.contains(yesterday),
      streak: HabitRepository.streakOf(dates),
      onToggleToday: (check) => _toggleToday(habit, check),
      onMakeupYesterday: () => _makeupYesterday(habit),
      onStats: () => _openStats(habit),
    );
  }

  /// 打开该习惯的打卡日历页，返回后刷新列表
  Future<void> _openStats(Habit habit) async {
    await Navigator.pushNamed(context, AppRoutes.habitStats,
        arguments: habit.id);
    if (mounted) _loadData();
  }

  Widget _buildEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Column(
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.habit.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🔥', style: TextStyle(fontSize: 40)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '还没有习惯',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '点击右下角 + 创建你的第一个习惯\n坚持每天打卡，见证自己的成长',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color: AppColors.textSecondary(context),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _openAdd,
              icon: const EmojiIcon('➕', size: 18),
              label: const Text('新建习惯'),
            ),
          ],
        ),
      ],
    );
  }

  /// 顶部统计概览 — 总习惯 / 今日已完成 / 连续最长 / 本月打卡
  Widget _buildStats(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.fitness_center,
              value: '$_total',
              label: '总习惯',
              color: AppColors.habit,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              icon: Icons.check_circle_outline,
              value: '$_doneToday',
              label: '今日完成',
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              icon: Icons.local_fire_department,
              value: '$_maxStreak',
              label: '连续最长',
              color: AppColors.goalShort,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              icon: Icons.calendar_month_outlined,
              value: '$_monthDays',
              label: '本月打卡',
              color: AppColors.todo,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
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
    );
  }

  /// 筛选标签 — 全部 / 已完成 / 未完成
  Widget _buildFilterBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: [
          for (final f in _HabitFilter.values) ...[
            _buildFilterChip(f),
            if (f != _HabitFilter.values.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(_HabitFilter f) {
    final selected = _filter == f;
    final accent = _filterAccent(f);
    return GestureDetector(
      onTap: () {
        if (_filter == f) return;
        setState(() => _filter = f);
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
          _filterLabel(f),
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? accent : AppColors.textSecondary(context),
          ),
        ),
      ),
    );
  }

  String _filterLabel(_HabitFilter f) {
    switch (f) {
      case _HabitFilter.all:
        return '全部';
      case _HabitFilter.done:
        return '已完成';
      case _HabitFilter.todo:
        return '未完成';
    }
  }

  Color _filterAccent(_HabitFilter f) {
    switch (f) {
      case _HabitFilter.all:
        return AppColors.habit;
      case _HabitFilter.done:
        return AppColors.success;
      case _HabitFilter.todo:
        return AppColors.goalShort;
    }
  }
}
