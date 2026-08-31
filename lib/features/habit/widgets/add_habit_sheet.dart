import 'package:flutter/material.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/features/habit/data/habit_repository.dart';
import 'package:buildself/features/habit/models/habit_model.dart';
import 'package:buildself/shared/widgets/emoji_icon.dart';
import 'package:buildself/shared/widgets/gradient_button.dart';
import 'package:buildself/shared/widgets/toast.dart';

/// 弹出「新建/编辑习惯」底部表单
///
/// [habit] 非空 = 编辑模式（预填 + 保存更新 + 提供删除）。
/// 创建/更新成功后调用 [onChanged] 并关闭表单；删除成功后调用 [onDeleted]。
Future<void> showAddHabitSheet(
  BuildContext context, {
  required String userId,
  required HabitRepository repository,
  Habit? habit,
  required ValueChanged<Habit> onChanged,
  VoidCallback? onDeleted,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddHabitSheet(
      userId: userId,
      repository: repository,
      habit: habit,
      onChanged: onChanged,
      onDeleted: onDeleted,
    ),
  );
}

class _AddHabitSheet extends StatefulWidget {
  final String userId;
  final HabitRepository repository;
  final Habit? habit;
  final ValueChanged<Habit> onChanged;
  final VoidCallback? onDeleted;

  const _AddHabitSheet({
    required this.userId,
    required this.repository,
    this.habit,
    required this.onChanged,
    this.onDeleted,
  });

  @override
  State<_AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends State<_AddHabitSheet> {
  final _nameCtrl = TextEditingController();
  late String _icon;
  late int _colorIndex;
  bool _saving = false;

  bool get _isEdit => widget.habit != null;

  @override
  void initState() {
    super.initState();
    final habit = widget.habit;
    _icon = habit?.icon ?? kHabitIcons.first;
    _colorIndex = habit?.colorIndex ?? 0;
    if (habit != null) {
      _nameCtrl.text = habit.name;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ToastHelper.show(context, '请先输入习惯名称');
      return;
    }
    setState(() => _saving = true);
    try {
      final habit = widget.habit;
      if (habit != null) {
        // 编辑模式
        habit.name = name;
        habit.icon = _icon;
        habit.colorIndex = _colorIndex;
        await widget.repository.update(habit);
        if (!mounted) return;
        widget.onChanged(habit);
      } else {
        // 新建模式
        final created = await widget.repository.create(
          userId: widget.userId,
          name: name,
          icon: _icon,
          colorIndex: _colorIndex,
        );
        if (!mounted) return;
        widget.onChanged(created);
      }
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ToastHelper.show(context, '保存失败，请重试');
    }
  }

  /// 删除习惯 — 二次确认（打卡记录级联删除）
  Future<void> _confirmDelete() async {
    final habit = widget.habit;
    if (habit == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除习惯'),
        content: Text('确定删除「${habit.name}」吗？\n该习惯的全部打卡记录将一并删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await widget.repository.delete(habit.id);
      if (!mounted) return;
      widget.onDeleted?.call();
      Navigator.pop(context);
    } catch (_) {
      if (mounted) ToastHelper.show(context, '删除失败，请重试');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final fieldFill = isDark ? const Color(0xFF0F172A) : Colors.white;
    final accent = kHabitPalette[_colorIndex];

    return Padding(
      // 键盘避让
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题 + 关闭
              Row(
                children: [
                  Text(
                    _isEdit ? '编辑习惯' : '新建习惯',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const EmojiIcon('❌', size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 习惯名称
              TextField(
                controller: _nameCtrl,
                maxLength: 20,
                decoration: InputDecoration(
                  labelText: '习惯名称',
                  hintText: '如：每天阅读 30 分钟',
                  counterText: '',
                  filled: true,
                  fillColor: fieldFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 16),
              // 图标选择
              const Text(
                '选择图标',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final icon in kHabitIcons)
                    _buildIconOption(icon, accent),
                ],
              ),
              const SizedBox(height: 16),
              // 颜色选择
              const Text(
                '选择颜色',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (var i = 0; i < kHabitPalette.length; i++)
                    _buildColorOption(i),
                ],
              ),
              const SizedBox(height: 20),
              // 保存按钮
              GradientButton(
                label: _isEdit ? '保存修改' : '创建习惯',
                icon: _isEdit ? Icons.save_outlined : Icons.auto_awesome,
                gradient: LinearGradient(
                  colors: [accent, accent.withValues(alpha: 0.75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onPressed: _saving ? null : _save,
              ),
              // 编辑模式：删除习惯
              if (_isEdit) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : _confirmDelete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(
                        color: AppColors.error.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text(
                      '删除习惯',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconOption(String icon, Color accent) {
    final selected = _icon == icon;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => setState(() => _icon = icon),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? accent
                : (isDark ? AppColors.dividerDark : AppColors.dividerLight),
            width: selected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(icon, style: const TextStyle(fontSize: 22)),
        ),
      ),
    );
  }

  Widget _buildColorOption(int index) {
    final color = kHabitPalette[index];
    final selected = _colorIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _colorIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: selected
              ? Border.all(color: Colors.white, width: 3)
              : null,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: selected
            ? const Center(child: EmojiIcon('✅', size: 15))
            : null,
      ),
    );
  }
}
