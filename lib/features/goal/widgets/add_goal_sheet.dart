import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/data/models/enums.dart';
import 'package:buildself/data/models/goal_model.dart';
import 'package:buildself/data/repositories/goal_repository.dart';
import 'package:buildself/shared/widgets/emoji_icon.dart';
import 'package:buildself/shared/widgets/gradient_button.dart';
import 'package:buildself/shared/widgets/toast.dart';

/// 弹出「新建目标」底部表单
///
/// 创建成功后调用 [onCreated] 并关闭表单
Future<void> showAddGoalSheet(
  BuildContext context, {
  required String userId,
  required GoalRepository repository,
  required ValueChanged<Goal> onCreated,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddGoalSheet(
      userId: userId,
      repository: repository,
      onCreated: onCreated,
    ),
  );
}

/// 截止时间快速选项
enum _GoalDue { oneWeek, oneMonth, threeMonths, custom }

extension on _GoalDue {
  String get label {
    switch (this) {
      case _GoalDue.oneWeek:
        return '1周后';
      case _GoalDue.oneMonth:
        return '1个月后';
      case _GoalDue.threeMonths:
        return '3个月后';
      case _GoalDue.custom:
        return '选择日期';
    }
  }
}

class _AddGoalSheet extends StatefulWidget {
  final String userId;
  final GoalRepository repository;
  final ValueChanged<Goal> onCreated;

  const _AddGoalSheet({
    required this.userId,
    required this.repository,
    required this.onCreated,
  });

  @override
  State<_AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends State<_AddGoalSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _rewardCtrl = TextEditingController();
  final _milestoneCtrl = TextEditingController();

  GoalType _goalType = GoalType.shortTerm;
  _GoalDue _due = _GoalDue.oneMonth;
  DateTime? _customDueDate;
  final List<String> _milestones = [];
  bool _creating = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _rewardCtrl.dispose();
    _milestoneCtrl.dispose();
    super.dispose();
  }

  /// 依据所选类型计算截止日期
  DateTime? _resolveDueDate() {
    final now = DateTime.now();
    switch (_due) {
      case _GoalDue.oneWeek:
        return now.add(const Duration(days: 7));
      case _GoalDue.oneMonth:
        return DateTime(now.year, now.month + 1, now.day);
      case _GoalDue.threeMonths:
        return DateTime(now.year, now.month + 3, now.day);
      case _GoalDue.custom:
        return _customDueDate;
    }
  }

  void _addMilestone() {
    final text = _milestoneCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _milestones.add(text);
      _milestoneCtrl.clear();
    });
  }

  void _removeMilestone(int index) {
    setState(() => _milestones.removeAt(index));
  }

  Future<void> _pickCustomDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _customDueDate ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)),
      helpText: '选择截止日期',
    );
    if (picked == null) return;
    if (mounted) {
      setState(() {
        _due = _GoalDue.custom;
        _customDueDate = picked;
      });
    }
  }

  Future<void> _create() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ToastHelper.show(context, '请输入目标名称', icon: Icons.info_outline);
      return;
    }
    if (_creating) return;
    setState(() => _creating = true);
    try {
      final rewardText = _rewardCtrl.text.trim();
      final milestones = _milestones
          .map((m) => Milestone(id: const Uuid().v4(), title: m))
          .toList();

      final goal = await widget.repository.create(
        userId: widget.userId,
        title: title,
        description: _descCtrl.text.trim(),
        goalType: _goalType,
        targetDate: _resolveDueDate(),
        progressType:
            milestones.isEmpty ? ProgressType.manual : ProgressType.milestone,
        milestones: milestones,
        reward: Reward(
          type: RewardType.other,
          description: rewardText,
        ),
        initialProgress: 5, // 新目标 5% 起步
      );
      if (mounted) {
        widget.onCreated(goal);
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        ToastHelper.show(context, '创建失败，请重试', icon: Icons.error_outline);
        setState(() => _creating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final divider = isDark ? AppColors.dividerDark : AppColors.dividerLight;
    final labelStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary(context),
    );

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '新建目标',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 18),
              // 目标名称
              TextField(
                controller: _titleCtrl,
                maxLength: 30,
                decoration: const InputDecoration(
                  labelText: '目标名称',
                  hintText: '想达成什么？',
                  counterText: '',
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              // 目标类型
              Text('目标类型', style: labelStyle),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildTypeCard(
                    GoalType.shortTerm,
                    '⚡',
                    '短期',
                    '1月内',
                    AppColors.goalShort,
                  ),
                  const SizedBox(width: 10),
                  _buildTypeCard(
                    GoalType.midTerm,
                    '🎯',
                    '中期',
                    '1-6月',
                    AppColors.goalMid,
                  ),
                  const SizedBox(width: 10),
                  _buildTypeCard(
                    GoalType.longTerm,
                    '🌟',
                    '长期',
                    '6月+',
                    AppColors.goalLong,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // 截止时间
              Text('截止时间', style: labelStyle),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ..._GoalDue.values
                      .where((d) => d != _GoalDue.custom)
                      .map((d) => _buildDueChip(d, d == _due)),
                  _buildDueChip(
                    _GoalDue.custom,
                    _due == _GoalDue.custom,
                    trailing: _customDueDate == null
                        ? null
                        : '${_customDueDate!.month}/${_customDueDate!.day}',
                    onTap: _pickCustomDate,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // 完成奖励
              Text('完成奖励', style: labelStyle),
              const SizedBox(height: 10),
              TextField(
                controller: _rewardCtrl,
                maxLength: 40,
                decoration: const InputDecoration(
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Text('🎁', style: TextStyle(fontSize: 18)),
                  ),
                  prefixIconConstraints:
                      BoxConstraints(minWidth: 40, minHeight: 40),
                  hintText: '完成后想奖励自己什么？（选填）',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 18),
              // 里程碑
              Text('里程碑', style: labelStyle),
              const SizedBox(height: 4),
              Text(
                '拆解成阶段性子目标，完成后打勾',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary(context),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _milestoneCtrl,
                maxLength: 30,
                decoration: InputDecoration(
                  hintText: '输入里程碑，按 + 或回车添加',
                  counterText: '',
                  suffixIcon: IconButton(
                    icon: const EmojiIcon('➕', size: 18),
                    onPressed: _addMilestone,
                  ),
                ),
                onSubmitted: (_) => _addMilestone(),
                textInputAction: TextInputAction.done,
              ),
              if (_milestones.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(_milestones.length, (i) {
                    final m = _milestones[i];
                    return Container(
                      padding: const EdgeInsets.only(left: 10, right: 4),
                      decoration: BoxDecoration(
                        color: AppColors.goal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            m,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                          IconButton(
                            icon: const EmojiIcon('❌', size: 14),
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                            onPressed: () => _removeMilestone(i),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
              const SizedBox(height: 18),
              // 备注
              Text('备注', style: labelStyle),
              const SizedBox(height: 10),
              TextField(
                controller: _descCtrl,
                maxLines: 3,
                maxLength: 300,
                decoration: const InputDecoration(
                  hintText: '补充说明（选填）',
                  counterText: '',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              // 创建按钮
              GradientButton(
                label: _creating ? '创建中…' : '创建目标',
                icon: Icons.gps_fixed,
                onPressed: _creating ? null : _create,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 目标类型三列卡片 — ⚡短期 / 🎯中期 / 🌟长期，带场景色
  Widget _buildTypeCard(
    GoalType type,
    String emoji,
    String title,
    String subtitle,
    Color color,
  ) {
    final selected = _goalType == type;
    final divider = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dividerDark
        : AppColors.dividerLight;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _goalType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.14) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : divider,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: selected ? color : AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: selected
                      ? color
                      : (Theme.of(context).brightness == Brightness.dark
                          ? AppColors.textSecondary(context)
                          : AppColors.textSecondaryLight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDueChip(
    _GoalDue due,
    bool selected, {
    String? trailing,
    VoidCallback? onTap,
  }) {
    final divider = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dividerDark
        : AppColors.dividerLight;
    final accent = selected ? AppColors.goal : AppColors.textSecondary(context);
    return GestureDetector(
      onTap: onTap ?? () => setState(() => _due = due),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.goal.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.goal : divider,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              trailing ?? due.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: accent,
              ),
            ),
            if (due == _GoalDue.custom) ...[
              const SizedBox(width: 2),
              const EmojiIcon('⏰', size: 11),
            ],
          ],
        ),
      ),
    );
  }
}
