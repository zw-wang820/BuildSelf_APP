import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/core/constants/strings.dart';
import 'package:buildself/core/router/routes.dart';
import 'package:buildself/data/models/enums.dart';
import 'package:buildself/data/models/goal_model.dart';
import 'package:buildself/data/repositories/goal_repository.dart';
import 'package:buildself/features/auth/providers/app_provider.dart';
import 'package:buildself/features/goal/widgets/add_goal_sheet.dart';
import 'package:buildself/features/goal/widgets/goal_item_card.dart';
import 'package:buildself/shared/widgets/nexus_background.dart';
import 'package:buildself/shared/widgets/toast.dart';

/// 目标列表页 — 统计概览 + 筛选标签 + 目标卡片列表 + 右下角「+」新建
class GoalBoardScreen extends StatefulWidget {
  const GoalBoardScreen({Key? key}) : super(key: key);

  @override
  State<GoalBoardScreen> createState() => _GoalBoardScreenState();
}

enum _GoalFilter { all, short, mid, long, completed }

extension _GoalFilterX on _GoalFilter {
  String get label {
    switch (this) {
      case _GoalFilter.all:
        return '全部';
      case _GoalFilter.short:
        return '短期';
      case _GoalFilter.mid:
        return '中期';
      case _GoalFilter.long:
        return '长期';
      case _GoalFilter.completed:
        return '已完成';
    }
  }

  GoalType? get type {
    switch (this) {
      case _GoalFilter.short:
        return GoalType.shortTerm;
      case _GoalFilter.mid:
        return GoalType.midTerm;
      case _GoalFilter.long:
        return GoalType.longTerm;
      default:
        return null;
    }
  }

  bool get showCompleted => this == _GoalFilter.completed;

  Color get accent {
    switch (this) {
      case _GoalFilter.all:
        return AppColors.goal;
      case _GoalFilter.short:
        return AppColors.goalShort;
      case _GoalFilter.mid:
        return AppColors.goalMid;
      case _GoalFilter.long:
        return AppColors.goalLong;
      case _GoalFilter.completed:
        return AppColors.success;
    }
  }
}

class _GoalBoardScreenState extends State<GoalBoardScreen> {
  final GoalRepository _goalRepo = GoalRepository();
  _GoalFilter _filter = _GoalFilter.all;
  List<Goal> _goals = [];
  bool _loading = true;

  // 统计概览数量
  int _shortCount = 0;
  int _midCount = 0;
  int _longCount = 0;
  int _completedCount = 0;

  // 新创建目标 id：其卡片进度条做 0→5% 入场动画
  String? _newGoalId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = context.read<AppProvider>().userId;
    if (userId.isEmpty) return;
    setState(() => _loading = true);

    // 统计概览
    final short =
        await _goalRepo.getByType(userId, GoalType.shortTerm, status: GoalStatus.active);
    final mid =
        await _goalRepo.getByType(userId, GoalType.midTerm, status: GoalStatus.active);
    final long =
        await _goalRepo.getByType(userId, GoalType.longTerm, status: GoalStatus.active);
    final completed = await _goalRepo.getCompletedGoals(userId);

    // 当前筛选列表
    final List<Goal> list;
    if (_filter.showCompleted) {
      list = completed;
    } else if (_filter.type != null) {
      list = await _goalRepo.getByType(userId, _filter.type!,
          status: GoalStatus.active);
    } else {
      list = await _goalRepo.getActiveGoals(userId);
    }

    if (mounted) {
      setState(() {
        _shortCount = short.length;
        _midCount = mid.length;
        _longCount = long.length;
        _completedCount = completed.length;
        _goals = list;
        _loading = false;
      });
    }
  }

  void _changeFilter(_GoalFilter f) {
    if (_filter == f) {
      return;
    }
    setState(() => _filter = f);
    _loadData();
  }

  Future<void> _openAddSheet() async {
    final userId = context.read<AppProvider>().userId;
    if (userId.isEmpty) return;
    await showAddGoalSheet(
      context,
      userId: userId,
      repository: _goalRepo,
      onCreated: (goal) {
        setState(() => _newGoalId = goal.id);
        _loadData();
        ToastHelper.show(
          context,
          '🎯 目标创建成功！加油！',
          icon: Icons.gps_fixed,
          color: AppColors.goal,
        );
      },
    );
  }

  void _onAnimationDone(String id) {
    if (mounted && _newGoalId == id) {
      setState(() => _newGoalId = null);
    }
  }

  Future<void> _openDetail(Goal goal) async {
    await Navigator.pushNamed(context, AppRoutes.goalDetail, arguments: goal.id);
    if (mounted) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('目标管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined),
            tooltip: AppStrings.achievementWall,
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.achievementWall),
          ),
        ],
      ),
      body: NexusBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildStatsBar(),
              const SizedBox(height: 8),
              _buildFilterBar(),
              const SizedBox(height: 4),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddSheet,
        backgroundColor: AppColors.goal,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 顶部统计概览 — 短期/中期/长期/已完成 数量
  Widget _buildStatsBar() {
    final stats = [
      _StatItem(
        label: '短期',
        count: _shortCount,
        icon: Icons.bolt,
        color: AppColors.goalShort,
      ),
      _StatItem(
        label: '中期',
        count: _midCount,
        icon: Icons.gps_fixed,
        color: AppColors.goalMid,
      ),
      _StatItem(
        label: '长期',
        count: _longCount,
        icon: Icons.auto_awesome,
        color: AppColors.goalLong,
      ),
      _StatItem(
        label: '已完成',
        count: _completedCount,
        icon: Icons.emoji_events_outlined,
        color: AppColors.success,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: stats.map((s) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: s == stats.last ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              decoration: BoxDecoration(
                color: s.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Icon(s.icon, size: 18, color: s.color),
                  const SizedBox(height: 6),
                  Text(
                    '${s.count}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: s.color,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    s.label,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFilterBar() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _GoalFilter.values.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final f = _GoalFilter.values[i];
          final selected = _filter == f;
          return GestureDetector(
            onTap: () => _changeFilter(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? f.accent.withValues(alpha: 0.16)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? f.accent : Theme.of(context).dividerColor,
                  width: selected ? 1.4 : 1,
                ),
              ),
              child: Text(
                f.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? f.accent : AppColors.textSecondary(context),
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
      return Center(
        child: CircularProgressIndicator(
          color: _filter.accent,
          strokeWidth: 2,
        ),
      );
    }
    if (_goals.isEmpty) {
      return _buildEmpty();
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        itemCount: _goals.length,
        itemBuilder: (context, i) {
          final goal = _goals[i];
          final isNew = goal.id == _newGoalId;
          return GoalItemCard(
            key: ValueKey(goal.id),
            goal: goal,
            onTap: () => _openDetail(goal),
            animateProgress: isNew,
            onAnimationDone: () => _onAnimationDone(goal.id),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    final isCompleted = _filter.showCompleted;
    final accent = _filter.accent;
    final hint = isCompleted
        ? '完成一个目标后会出现在这里'
        : '点击右下角 + 设定一个目标吧';
    final label = _filter.label;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.emoji_events_outlined : Icons.gps_fixed,
              color: accent,
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isCompleted ? '还没有完成的目标' : '还没有$label目标',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hint,
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

class _StatItem {
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  _StatItem({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });
}
