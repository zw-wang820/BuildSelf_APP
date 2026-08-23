import 'package:flutter/material.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/features/todo/data/todo_repository.dart';
import 'package:buildself/features/todo/models/todo_model.dart';
import 'package:buildself/shared/widgets/gradient_button.dart';
import 'package:buildself/shared/widgets/toast.dart';

/// 弹出「新建待办」底部表单
///
/// 创建成功后调用 [onCreated] 并关闭表单
Future<void> showAddTodoSheet(
  BuildContext context, {
  required String userId,
  required TodoRepository repository,
  required ValueChanged<Todo> onCreated,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddTodoSheet(
      userId: userId,
      repository: repository,
      onCreated: onCreated,
    ),
  );
}

class _AddTodoSheet extends StatefulWidget {
  final String userId;
  final TodoRepository repository;
  final ValueChanged<Todo> onCreated;

  const _AddTodoSheet({
    required this.userId,
    required this.repository,
    required this.onCreated,
  });

  @override
  State<_AddTodoSheet> createState() => _AddTodoSheetState();
}

class _AddTodoSheetState extends State<_AddTodoSheet> {
  final _contentCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  TodoCategory _category = TodoCategory.work;
  TodoPriority _priority = TodoPriority.medium;
  TodoDueType _dueType = TodoDueType.today;
  DateTime? _customDueDate;
  bool _creating = false;

  @override
  void dispose() {
    _contentCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  /// 依据所选类型计算截止日期（今天/明天/后天取当日零点，自定义取所选日期）
  DateTime? _resolveDueDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_dueType) {
      case TodoDueType.today:
        return today;
      case TodoDueType.tomorrow:
        return today.add(const Duration(days: 1));
      case TodoDueType.dayAfter:
        return today.add(const Duration(days: 2));
      case TodoDueType.custom:
        return _customDueDate;
    }
  }

  Future<void> _pickCustomDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _customDueDate ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 3650)),
      helpText: '选择截止日期',
    );
    if (picked == null) return;
    if (mounted) {
      setState(() {
        _dueType = TodoDueType.custom;
        _customDueDate = picked;
      });
    }
  }

  Future<void> _create() async {
    final content = _contentCtrl.text.trim();
    if (content.isEmpty) {
      ToastHelper.show(context, '请输入待办内容', icon: Icons.info_outline);
      return;
    }
    if (_creating) return;
    setState(() => _creating = true);
    try {
      final todo = await widget.repository.create(
        userId: widget.userId,
        content: content,
        note: _noteCtrl.text.trim(),
        category: _category,
        priority: _priority,
        dueType: _dueType,
        dueDate: _resolveDueDate(),
      );
      if (mounted) {
        widget.onCreated(todo);
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
                '新建待办',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 18),
              // 待办内容
              TextField(
                controller: _contentCtrl,
                autofocus: false,
                maxLength: 60,
                decoration: const InputDecoration(
                  labelText: '待办内容',
                  hintText: '今天要做什么？',
                  counterText: '',
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              // 备注
              TextField(
                controller: _noteCtrl,
                maxLines: 3,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: '备注',
                  hintText: '补充说明（选填）',
                  counterText: '',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 18),
              // 分类标签
              Text('分类标签', style: labelStyle),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: TodoCategory.values.map((cat) {
                  final selected = _category == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _category = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: selected
                            ? cat.color.withValues(alpha: 0.16)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? cat.color : divider,
                          width: selected ? 1.4 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(cat.emoji, style: const TextStyle(fontSize: 15)),
                          const SizedBox(width: 5),
                          Text(
                            cat.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? cat.color
                                  : AppColors.textPrimary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              // 优先级
              Text('优先级', style: labelStyle),
              const SizedBox(height: 10),
              Row(
                children: TodoPriority.values.map((pri) {
                  final selected = _priority == pri;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _priority = pri),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: EdgeInsets.only(
                          right: pri == TodoPriority.values.last ? 0 : 10,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selected
                              ? pri.color.withValues(alpha: 0.14)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? pri.color : divider,
                            width: selected ? 1.6 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: pri.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${pri.label}优先级',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? pri.color
                                    : AppColors.textPrimary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              // 截止时间
              Text('截止时间', style: labelStyle),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ...TodoDueType.values
                      .where((t) => t != TodoDueType.custom)
                      .map((t) => _buildDueChip(t, t == _dueType)),
                  _buildDueChip(
                    TodoDueType.custom,
                    _dueType == TodoDueType.custom,
                    trailing: _customDueDate == null
                        ? null
                        : '${_customDueDate!.month}/${_customDueDate!.day}',
                    onTap: _pickCustomDate,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // 创建按钮
              GradientButton(
                label: _creating ? '创建中…' : '创建待办',
                icon: Icons.add_task,
                onPressed: _creating ? null : _create,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDueChip(
    TodoDueType type,
    bool selected, {
    String? trailing,
    VoidCallback? onTap,
  }) {
    final divider = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dividerDark
        : AppColors.dividerLight;
    final accent = selected ? AppColors.primary : AppColors.textSecondary(context);
    return GestureDetector(
      onTap: onTap ?? () => setState(() => _dueType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : divider,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              trailing ?? type.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: accent,
              ),
            ),
            if (type == TodoDueType.custom) ...[
              const SizedBox(width: 2),
              Icon(Icons.calendar_today, size: 12, color: accent),
            ],
          ],
        ),
      ),
    );
  }
}
