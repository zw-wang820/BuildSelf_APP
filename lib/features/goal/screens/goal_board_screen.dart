import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/core/constants/strings.dart';
import 'package:buildself/core/router/routes.dart';
import 'package:buildself/data/models/enums.dart';
import 'package:buildself/data/models/goal_model.dart';
import 'package:buildself/data/repositories/goal_repository.dart';
import 'package:buildself/features/auth/providers/app_provider.dart';
import 'package:buildself/shared/widgets/app_card.dart';
import 'package:buildself/shared/widgets/empty_state.dart';
import 'package:buildself/shared/widgets/nexus_background.dart';

/// 目标看板页
class GoalBoardScreen extends StatefulWidget {
  const GoalBoardScreen({Key? key}) : super(key: key);

  @override
  State<GoalBoardScreen> createState() => _GoalBoardScreenState();
}

class _GoalBoardScreenState extends State<GoalBoardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GoalRepository _goalRepo = GoalRepository();

  Map<GoalType, List<Goal>> _goals = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final userId = context.read<AppProvider>().userId;
    setState(() => _loading = true);

    final short = await _goalRepo.getByType(userId, GoalType.shortTerm, status: GoalStatus.active);
    final mid = await _goalRepo.getByType(userId, GoalType.midTerm, status: GoalStatus.active);
    final long = await _goalRepo.getByType(userId, GoalType.longTerm, status: GoalStatus.active);

    if (mounted) {
      setState(() {
        _goals = {
          GoalType.shortTerm: short,
          GoalType.midTerm: mid,
          GoalType.longTerm: long,
        };
        _loading = false;
      });
    }
  }

  Future<void> _navigateAndRefresh(String route) async {
    await Navigator.pushNamed(context, route);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.goal,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.goal, blurRadius: 6)],
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '// GOAL BOARD',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.goal,
                letterSpacing: 2,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                AppStrings.goalTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryDark,
                  letterSpacing: 0.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined),
            tooltip: AppStrings.achievementWall,
            onPressed: () => Navigator.pushNamed(context, AppRoutes.achievementWall),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: GoalType.shortTerm.label),
            Tab(text: GoalType.midTerm.label),
            Tab(text: GoalType.longTerm.label),
          ],
          labelColor: AppColors.goal,
          unselectedLabelColor: AppColors.textSecondaryDark,
          indicatorColor: AppColors.goal,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: NexusBackground(
        child: SafeArea(
          child: _loading
              ? Center(
                  child: CircularProgressIndicator(
                    color: AppColors.goal,
                    strokeWidth: 2,
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildGoalList(GoalType.shortTerm),
                    _buildGoalList(GoalType.midTerm),
                    _buildGoalList(GoalType.longTerm),
                  ],
                ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.goal.withOpacity(0.5),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          elevation: 0,
          onPressed: () => _navigateAndRefresh(AppRoutes.goalEdit),
          backgroundColor: AppColors.goal,
          foregroundColor: AppColors.spaceDeep,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildGoalList(GoalType type) {
    final list = _goals[type] ?? [];
    if (list.isEmpty) {
      return EmptyState(
        icon: Icons.gps_fixed_outlined,
        message: '还没有${type.label}\n点击右下角 + 设定一个目标吧',
        onAction: () => _navigateAndRefresh(AppRoutes.goalEdit),
        actionLabel: '新建目标',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: list.length,
        itemBuilder: (context, index) => _buildGoalCard(list[index]),
      ),
    );
  }

  Widget _buildGoalCard(Goal goal) {
    final progress = goal.calculatedProgress;
    final color = AppColors.goal;
    return AppCard(
      accent: color,
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () async {
        await Navigator.pushNamed(context, AppRoutes.goalDetail, arguments: goal.id);
        _loadData();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryDark,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (goal.category != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: color.withOpacity(0.5), width: 0.6),
                  ),
                  child: Text(
                    goal.category!.label,
                    style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // 进度条 — 数据条样式
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 6,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(color: AppColors.dividerDark),
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: (progress / 100).clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [color.withOpacity(0.6), color],
                              ),
                              boxShadow: [
                                BoxShadow(color: color.withOpacity(0.6), blurRadius: 6),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$progress%',
                style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 奖励摘要
          Row(
            children: [
              const Icon(Icons.card_giftcard, size: 14, color: AppColors.textSecondaryDark),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  goal.reward.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryDark,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (goal.targetDate != null) ...[
                const SizedBox(width: 8),
                Text(
                  '截止 ${goal.targetDate!.month.toString().padLeft(2, '0')}.${goal.targetDate!.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondaryDark,
                    fontFamily: 'monospace',
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
