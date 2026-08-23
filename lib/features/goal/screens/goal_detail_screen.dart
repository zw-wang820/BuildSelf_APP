import 'package:flutter/material.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/core/constants/strings.dart';
import 'package:buildself/core/router/routes.dart';
import 'package:buildself/data/models/enums.dart';
import 'package:buildself/data/models/goal_model.dart';
import 'package:buildself/data/models/reading_models.dart';
import 'package:buildself/data/repositories/goal_repository.dart';
import 'package:buildself/shared/widgets/app_card.dart';
import 'package:buildself/shared/widgets/emoji_icon.dart';

/// 目标详情页
class GoalDetailScreen extends StatefulWidget {
  final String? goalId;

  const GoalDetailScreen({Key? key, this.goalId}) : super(key: key);

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  final GoalRepository _goalRepo = GoalRepository();

  Goal? _goal;
  List<GoalLog> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final id = widget.goalId;
    if (id == null) return;
    setState(() => _loading = true);

    final goal = await _goalRepo.getById(id);
    final logs = goal != null ? await _goalRepo.getGoalLogs(id) : <GoalLog>[];

    if (mounted) {
      setState(() {
        _goal = goal;
        _logs = logs;
        _loading = false;
      });
    }
  }

  Future<void> _showUpdateProgressDialog() async {
    if (_goal == null) return;
    double value = _goal!.progress.toDouble();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(AppStrings.updateProgress),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('当前进度: ${value.toInt()}%',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  Slider(
                    value: value,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: '${value.toInt()}%',
                    activeColor: AppColors.goal,
                    onChanged: (v) => setDialogState(() => value = v),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(AppStrings.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(AppStrings.confirm),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && _goal != null) {
      await _goalRepo.updateProgress(_goal!, value.toInt());
      _loadData();
    }
  }

  Future<void> _markCompleted() async {
    if (_goal == null) return;
    await _goalRepo.markCompleted(_goal!);
    _loadData();
  }

  Future<void> _abandonGoal() async {
    if (_goal == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('放弃目标'),
        content: const Text('确定放弃这个目标吗？放弃后可在设置中查看。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppStrings.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('放弃'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _goalRepo.abandon(_goal!);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _deleteGoal() async {
    if (_goal == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.delete),
        content: const Text('确定删除这个目标吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppStrings.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(AppStrings.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _goalRepo.softDelete(_goal!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(AppStrings.goalTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final goal = _goal;
    if (goal == null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppStrings.goalTitle)),
        body: const Center(child: Text('目标不存在')),
      );
    }

    final isActive = goal.status == GoalStatus.active;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.goalTitle),
        actions: [
          if (isActive)
            IconButton(
              icon: const EmojiIcon('✏️', size: 20),
              onPressed: () async {
                await Navigator.pushNamed(context, AppRoutes.goalEdit);
                _loadData();
              },
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'complete') {
                _markCompleted();
              } else if (value == 'abandon') {
                _abandonGoal();
              } else if (value == 'delete') {
                _deleteGoal();
              }
            },
            itemBuilder: (context) {
              final items = <PopupMenuEntry<String>>[];
              if (isActive) {
                items.add(const PopupMenuItem(value: 'complete', child: Text('标记完成')));
                items.add(const PopupMenuItem(value: 'abandon', child: Text('放弃目标')));
              }
              items.add(const PopupMenuItem(value: 'delete', child: Text('删除目标')));
              return items;
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 目标标题与元信息
            Text(goal.title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildMetaChip(goal.goalType.label, AppColors.goal),
                if (goal.category != null)
                  _buildMetaChip(goal.category!.label, AppColors.accent),
                _buildMetaChip(goal.status.label, goal.status == GoalStatus.completed ? AppColors.success : goal.status == GoalStatus.abandoned ? AppColors.error : AppColors.info),
                if (goal.targetDate != null)
                  _buildMetaChip(
                    '截止: ${_formatDate(goal.targetDate!)}',
                    Colors.blueGrey,
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // 进度
            Text('进度', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: goal.calculatedProgress / 100,
                      backgroundColor: AppColors.dividerDark,
                      color: AppColors.goal,
                      minHeight: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${goal.calculatedProgress}%',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.goal,
                  ),
                ),
              ],
            ),
            if (isActive) ...[
              const SizedBox(height: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(foregroundColor: AppColors.goal),
                onPressed: _showUpdateProgressDialog,
                child: Text(AppStrings.updateProgress),
              ),
            ],
            const SizedBox(height: 24),

            // 奖励卡片
            _buildRewardCard(context, goal),
            const SizedBox(height: 24),

            // 推进记录
            Text(AppStrings.goalLog, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (_logs.isEmpty)
              AppCard(
                child: Text('暂无推进记录', style: TextStyle(color: AppColors.textSecondary(context))),
              )
            else
              ..._logs.map((log) => AppCard(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        log.progressAfter >= 100
                            ? const EmojiIcon('✅', size: 18)
                            : Icon(
                                Icons.trending_up,
                                color: AppColors.goal,
                                size: 20,
                              ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${log.progressBefore}% → ${log.progressAfter}%',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              if (log.note != null && log.note!.isNotEmpty)
                                Text(log.note!, style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context))),
                            ],
                          ),
                        ),
                        Text(
                          _formatDate(log.createdAt),
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary(context)),
                        ),
                      ],
                    ),
                  )),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildRewardCard(BuildContext context, Goal goal) {
    final reward = goal.reward;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accentLight.withOpacity(0.5), AppColors.accentLight.withOpacity(0.2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: EmojiIcon('🎁', size: 26)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🎁 ', style: TextStyle(fontSize: 16)),
                    Text(AppStrings.rewardLabel, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(reward.type.label, style: const TextStyle(fontSize: 11, color: AppColors.accent)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  reward.description,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                if (reward.estimatedCost != null)
                  Text('预估 ¥${reward.estimatedCost!.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}
