import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/features/auth/providers/app_provider.dart';
import 'package:buildself/features/todo/data/todo_repository.dart';
import 'package:buildself/features/todo/models/todo_category_info.dart';
import 'package:buildself/features/todo/models/todo_model.dart';
import 'package:buildself/features/todo/models/todo_stats.dart';
import 'package:buildself/features/todo/widgets/add_todo_sheet.dart';
import 'package:buildself/features/todo/widgets/todo_item_card.dart';
import 'package:buildself/shared/widgets/app_card.dart';
import 'package:buildself/shared/widgets/emoji_icon.dart';
import 'package:buildself/shared/widgets/nexus_background.dart';
import 'package:buildself/shared/widgets/toast.dart';

/// 时间段快捷档
enum _StatsRange { thisWeek, thisMonth, last30, custom }

extension on _StatsRange {
  String get label {
    switch (this) {
      case _StatsRange.thisWeek:
        return '本周';
      case _StatsRange.thisMonth:
        return '本月';
      case _StatsRange.last30:
        return '近30天';
      case _StatsRange.custom:
        return '自定义';
    }
  }
}

/// 统计维度
enum _StatsDim { category, priority }

/// 待办统计页 — 时间段内到期口径完成/未完成统计 + 按分类/优先级维度 + 近 7 天趋势
class TodoStatsScreen extends StatefulWidget {
  const TodoStatsScreen({Key? key}) : super(key: key);

  @override
  State<TodoStatsScreen> createState() => _TodoStatsScreenState();
}

class _TodoStatsScreenState extends State<TodoStatsScreen> {
  final TodoRepository _repo = TodoRepository();

  _StatsRange _range = _StatsRange.thisWeek;
  _StatsDim _dim = _StatsDim.category;
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now();
  bool _loading = true;
  TodoStats? _stats;

  @override
  void initState() {
    super.initState();
    _applyRange(_StatsRange.thisWeek);
    _load();
  }

  /// 计算快捷档对应的起止日期（自定义档保留用户上次选择）
  void _applyRange(_StatsRange r) {
    final now = DateTime.now();
    switch (r) {
      case _StatsRange.thisWeek:
        _start = DateTime(now.year, now.month, now.day - (now.weekday - 1));
        _end = now;
        break;
      case _StatsRange.thisMonth:
        _start = DateTime(now.year, now.month, 1);
        _end = now;
        break;
      case _StatsRange.last30:
        _start = DateTime(now.year, now.month, now.day - 29);
        _end = now;
        break;
      case _StatsRange.custom:
        break;
    }
  }

  Future<void> _load() async {
    final userId = context.read<AppProvider>().userId;
    if (userId.isEmpty) return;
    setState(() => _loading = true);
    try {
      final stats = await _repo.getStats(userId, start: _start, end: _end);
      if (mounted) {
        setState(() {
          _stats = stats;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changeRange(_StatsRange r) {
    if (_range == r) return;
    setState(() {
      _range = r;
      _applyRange(r);
    });
    _load();
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: DateTimeRange(start: _start, end: _end),
      helpText: '选择统计时间段',
      saveText: '确定',
    );
    if (picked == null) return;
    setState(() {
      _range = _StatsRange.custom;
      _start = picked.start;
      _end = picked.end;
    });
    _load();
  }

  /// 标签行下钻 — 该标签 + 时间段内到期待办（未完成在前）
  void _openGroupDetail(TodoStats stats, TodoStatsGroup group) {
    final list = stats.dueTodos.where((t) {
      if (_dim == _StatsDim.category) return t.category == group.key;
      return t.priority.name == group.key;
    }).toList()
      ..sort((a, b) {
        if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
        return b.createdAt.compareTo(a.createdAt);
      });
    _openDetailSheet(context, list, '${group.emoji} ${group.label}',
        customs: stats.customs);
  }

  /// 趋势柱下钻 — 该日完成的待办
  void _openDayDetail(List<Todo> weekDone, int dayIndex) {
    final day = _weekStart().add(Duration(days: dayIndex));
    final key = TodoRepository.dateKey(day);
    final list = weekDone
        .where((t) =>
            t.completedAt != null && TodoRepository.dateKey(t.completedAt!) == key)
        .toList()
      ..sort((a, b) =>
          (b.completedAt ?? b.createdAt).compareTo(a.completedAt ?? a.createdAt));
    _openDetailSheet(context, list, '${TodoRepository.dateKey(day)} 完成');
  }

  DateTime _weekStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - 6);
  }

  /// 下钻明细底部弹层 — 复用 TodoItemCard，可勾选/编辑
  void _openDetailSheet(
    BuildContext context,
    List<Todo> todos,
    String title, {
    List<TodoCategoryInfo> customs = const [],
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TodoDetailSheet(
        title: title,
        todos: todos,
        repository: _repo,
        customCategories: customs,
        onChanged: () {
          if (mounted) _load();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('待办统计')),
      body: NexusBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildRangeBar(),
              const SizedBox(height: 4),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  /// 时间段快捷切换（本周 / 本月 / 近30天 / 自定义）
  Widget _buildRangeBar() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _StatsRange.values.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final r = _StatsRange.values[i];
          final selected = _range == r;
          return GestureDetector(
            onTap: () {
              if (r == _StatsRange.custom) {
                _pickCustomRange();
              } else {
                _changeRange(r);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.todo.withValues(alpha: 0.16)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? AppColors.todo : Theme.of(context).dividerColor,
                  width: selected ? 1.4 : 1,
                ),
              ),
              child: Text(
                r.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? AppColors.todo
                      : AppColors.textSecondary(context),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child:
            CircularProgressIndicator(color: AppColors.todo, strokeWidth: 2),
      );
    }
    final stats = _stats;
    if (stats == null || stats.totalDue == 0) {
      return _buildEmpty();
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverview(stats),
          const SizedBox(height: 20),
          _buildDimTabs(),
          const SizedBox(height: 10),
          _buildGroupList(stats),
          const SizedBox(height: 20),
          _buildTrendCard(stats),
        ],
      ),
    );
  }

  /// 总览四卡 — 到期总数 / 已完成 / 未完成 / 完成率
  Widget _buildOverview(TodoStats stats) {
    final rateText = stats.totalDue == 0
        ? '—'
        : '${(stats.rate * 100).round()}%';
    return Row(
      children: [
        _buildStatCard('到期总数', '${stats.totalDue}', AppColors.todo),
        const SizedBox(width: 10),
        _buildStatCard('已完成', '${stats.completed}', AppColors.success),
        const SizedBox(width: 10),
        _buildStatCard('未完成', '${stats.pending}', AppColors.warning),
        const SizedBox(width: 10),
        _buildStatCard('完成率', rateText, AppColors.info),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: AppCard(
        accent: color,
        onTap: null,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 维度 Tab — 按分类 / 按优先级
  Widget _buildDimTabs() {
    return Row(
      children: [
        _buildDimTab(_StatsDim.category, '按分类'),
        const SizedBox(width: 8),
        _buildDimTab(_StatsDim.priority, '按优先级'),
      ],
    );
  }

  Widget _buildDimTab(_StatsDim d, String label) {
    final selected = _dim == d;
    return GestureDetector(
      onTap: () {
        if (selected) return;
        setState(() => _dim = d);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.todo.withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.todo : Theme.of(context).dividerColor,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.todo : AppColors.textSecondary(context),
          ),
        ),
      ),
    );
  }

  /// 标签行列表
  Widget _buildGroupList(TodoStats stats) {
    final groups =
        _dim == _StatsDim.category ? stats.byCategory : stats.byPriority;
    return AppCard(
      accent: AppColors.todo,
      onTap: null,
      child: Column(
        children: List.generate(groups.length, (i) {
          final g = groups[i];
          final isLast = i == groups.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
            child: _buildGroupRow(g),
          );
        }),
      ),
    );
  }

  /// 单个标签行 — emoji + 名称 + 进度条 + 完成/总数 + 完成率，点击下钻
  Widget _buildGroupRow(TodoStatsGroup g) {
    return GestureDetector(
      onTap: () {
        final stats = _stats;
        if (stats != null) _openGroupDetail(stats, g);
      },
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: g.color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Center(child: EmojiIcon(g.emoji, size: 15)),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 40,
            child: Text(
              g.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(context),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: _buildProgressBar(g.rate, g.color),
            ),
          ),
          Text(
            g.total == 0 ? '—' : '${g.completed}/${g.total}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(
              g.total == 0 ? '—' : '${(g.rate * 100).round()}%',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: g.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 进度条 — 简洁填充（同首页样式）
  Widget _buildProgressBar(double value, Color color) {
    final v = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 6,
        child: LayoutBuilder(
          builder: (context, c) {
            return Stack(
              fit: StackFit.expand,
              children: [
                Container(color: AppColors.dividerDark),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: c.maxWidth * v,
                  child: DecoratedBox(decoration: BoxDecoration(color: color)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 近 7 天完成趋势 — 自绘柱状图（每柱可点击）
  Widget _buildTrendCard(TodoStats stats) {
    final maxV = stats.dailyCompleted.fold<int>(0, max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '近 7 天完成趋势',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary(context),
          ),
        ),
        const SizedBox(height: 10),
        AppCard(
          accent: AppColors.todo,
          onTap: null,
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 10),
          child: SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final v = stats.dailyCompleted[i];
                final isToday = i == 6;
                final barH = maxV == 0 ? 3.0 : (v / maxV) * 78;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _openDayDetail(stats.weekDoneTodos, i),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '$v',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isToday
                                ? AppColors.todo
                                : AppColors.textSecondary(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: barH,
                          decoration: BoxDecoration(
                            color: isToday
                                ? AppColors.todo
                                : AppColors.todo.withValues(alpha: 0.4),
                            borderRadius:
                                const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          stats.dailyLabels[i],
                          style: TextStyle(
                            fontSize: 11,
                            color: isToday
                                ? AppColors.todo
                                : AppColors.textSecondary(context),
                            fontWeight:
                                isToday ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.todo.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Center(child: EmojiIcon('📊', size: 30)),
          ),
          const SizedBox(height: 14),
          Text(
            '该时段没有到期待办',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '换个时间段，或给待办设置截止日期',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// 下钻明细弹层 — 展示待办列表，支持勾选完成/恢复与编辑
class _TodoDetailSheet extends StatefulWidget {
  final String title;
  final List<Todo> todos;
  final TodoRepository repository;
  final List<TodoCategoryInfo> customCategories;
  final VoidCallback onChanged;

  const _TodoDetailSheet({
    required this.title,
    required this.todos,
    required this.repository,
    this.customCategories = const [],
    required this.onChanged,
  });

  @override
  State<_TodoDetailSheet> createState() => _TodoDetailSheetState();
}

class _TodoDetailSheetState extends State<_TodoDetailSheet> {
  late List<Todo> _todos;

  @override
  void initState() {
    super.initState();
    _todos = List.of(widget.todos);
  }

  Future<void> _toggle(Todo todo) async {
    final nowCompleted = !todo.isCompleted;
    setState(() {
      final idx = _todos.indexWhere((t) => t.id == todo.id);
      if (idx != -1) {
        _todos[idx] = todo.copyWith(
          isCompleted: nowCompleted,
          completedAt: nowCompleted ? DateTime.now() : null,
        );
      }
    });
    if (nowCompleted) {
      await widget.repository.markCompleted(todo.id);
    } else {
      await widget.repository.markActive(todo.id);
    }
    if (!mounted) return;
    ToastHelper.show(
      context,
      nowCompleted ? '✅ 已完成' : '已恢复为待办',
      icon: nowCompleted ? Icons.check_circle : Icons.undo,
      color: nowCompleted ? AppColors.success : AppColors.info,
    );
    widget.onChanged();
  }

  Future<void> _edit(Todo todo) async {
    await showEditTodoSheet(
      context,
      repository: widget.repository,
      todo: todo,
      onUpdated: (_) {
        widget.onChanged();
        ToastHelper.show(context, '✅ 待办已更新');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
      padding: EdgeInsets.only(bottom: bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSecondary(context).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const EmojiIcon('✖️', size: 16),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: _todos.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      '该范围没有待办',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    itemCount: _todos.length,
                    itemBuilder: (context, i) {
                      final t = _todos[i];
                      return TodoItemCard(
                        todo: t,
                        onToggle: _toggle,
                        onTap: () => _edit(t),
                        customCategories: widget.customCategories,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
