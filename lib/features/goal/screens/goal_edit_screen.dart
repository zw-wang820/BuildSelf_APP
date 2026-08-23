import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/core/constants/strings.dart';
import 'package:buildself/data/models/enums.dart';
import 'package:buildself/data/models/goal_model.dart';
import 'package:buildself/data/repositories/goal_repository.dart';
import 'package:buildself/features/auth/providers/app_provider.dart';

/// 目标编辑/新建页
class GoalEditScreen extends StatefulWidget {
  const GoalEditScreen({Key? key}) : super(key: key);

  @override
  State<GoalEditScreen> createState() => _GoalEditScreenState();
}

class _GoalEditScreenState extends State<GoalEditScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _rewardDescController = TextEditingController();
  final GoalRepository _goalRepo = GoalRepository();

  GoalType _goalType = GoalType.shortTerm;
  GoalCategory _category = GoalCategory.other;
  ProgressType _progressType = ProgressType.manual;
  RewardType _rewardType = RewardType.food;
  DateTime? _targetDate;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _rewardDescController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入目标标题')));
      return;
    }
    if (_rewardDescController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请设置完成目标后的奖励')));
      return;
    }

    setState(() => _saving = true);

    try {
      final userId = context.read<AppProvider>().userId;
      final reward = Reward(
        type: _rewardType,
        description: _rewardDescController.text.trim(),
      );

      await _goalRepo.create(
        userId: userId,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        goalType: _goalType,
        category: _category,
        targetDate: _targetDate,
        progressType: _progressType,
        reward: reward,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.saveSuccess), duration: Duration(seconds: 1)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _targetDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(AppStrings.cancel),
        ),
        title: Text(AppStrings.newGoal),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(AppStrings.save, style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 目标标题
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: '目标标题'),
            ),
            const SizedBox(height: 16),

            // 目标描述
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: '目标描述（选填）'),
            ),
            const SizedBox(height: 16),

            // 目标类型
            _buildSectionLabel('目标类型'),
            Wrap(
              spacing: 8,
              children: GoalType.values.map((type) {
                return FilterChip(
                  label: Text(type.label),
                  selected: _goalType == type,
                  onSelected: (_) => setState(() => _goalType = type),
                  selectedColor: AppColors.goal.withOpacity(0.15),
                  checkmarkColor: AppColors.goal,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // 目标类别
            _buildSectionLabel('目标类别'),
            Wrap(
              spacing: 8,
              children: GoalCategory.values.map((cat) {
                return FilterChip(
                  label: Text(cat.label),
                  selected: _category == cat,
                  onSelected: (_) => setState(() => _category = cat),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // 截止日期
            _buildSectionLabel('截止日期'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _targetDate != null ? _formatDate(_targetDate!) : '选择截止日期',
                style: TextStyle(color: _targetDate != null ? AppColors.textPrimary(context) : AppColors.textSecondary(context)),
              ),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _pickDate,
            ),
            const Divider(),
            const SizedBox(height: 8),

            // 进度模式
            _buildSectionLabel('进度模式'),
            Wrap(
              spacing: 8,
              children: ProgressType.values.map((type) {
                return FilterChip(
                  label: Text(type.label),
                  selected: _progressType == type,
                  onSelected: (_) => setState(() => _progressType = type),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // 奖励设置
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.accentLight.withOpacity(0.4), Colors.transparent],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('🎁 ', style: TextStyle(fontSize: 20)),
                      Text('设置奖励', style: Theme.of(context).textTheme.titleLarge),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('完成目标后，给自己一个奖励吧！',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context))),
                  const SizedBox(height: 16),

                  // 奖励类型
                  Wrap(
                    spacing: 8,
                    children: RewardType.values.map((type) {
                      return FilterChip(
                        label: Text(type.label),
                        selected: _rewardType == type,
                        onSelected: (_) => setState(() => _rewardType = type),
                        selectedColor: AppColors.accent.withOpacity(0.2),
                        checkmarkColor: AppColors.accent,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _rewardDescController,
                    decoration: const InputDecoration(
                      hintText: '想吃的、想玩的、想买的...',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}
