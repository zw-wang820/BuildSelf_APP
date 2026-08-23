import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/core/constants/strings.dart';
import 'package:buildself/data/models/goal_model.dart';
import 'package:buildself/data/repositories/goal_repository.dart';
import 'package:buildself/features/auth/providers/app_provider.dart';
import 'package:buildself/shared/widgets/app_card.dart';
import 'package:buildself/shared/widgets/empty_state.dart';

/// 成就墙 — 展示已完成的目标
class AchievementWallScreen extends StatefulWidget {
  const AchievementWallScreen({Key? key}) : super(key: key);

  @override
  State<AchievementWallScreen> createState() => _AchievementWallScreenState();
}

class _AchievementWallScreenState extends State<AchievementWallScreen> {
  final GoalRepository _goalRepo = GoalRepository();
  List<Goal> _goals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = context.read<AppProvider>().userId;
    setState(() => _loading = true);

    final goals = await _goalRepo.getCompletedGoals(userId);

    if (mounted) {
      setState(() {
        _goals = goals;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.achievementWall)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _goals.isEmpty
              ? const EmptyState(
                  icon: Icons.emoji_events_outlined,
                  message: '还没有完成的目标\n加油，期待你的第一个成就！',
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _goals.length,
                    itemBuilder: (context, index) => _buildAchievementCard(_goals[index]),
                  ),
                ),
    );
  }

  Widget _buildAchievementCard(Goal goal) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // 奖杯图标
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.emoji_events, color: AppColors.accent, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildTag(goal.goalType.label),
                    const SizedBox(width: 6),
                    if (goal.category != null) _buildTag(goal.category!.label),
                    const SizedBox(width: 6),
                    if (goal.completedAt != null)
                      Text(
                        '完成于 ${goal.completedAt!.year}/${goal.completedAt!.month}/${goal.completedAt!.day}',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary(context)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '奖励: ${goal.reward.description}',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: const TextStyle(fontSize: 10, color: AppColors.accent)),
    );
  }
}
