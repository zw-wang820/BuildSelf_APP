import 'package:flutter/material.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/features/habit/data/habit_repository.dart';
import 'package:buildself/features/habit/models/habit_model.dart';
import 'package:buildself/shared/widgets/emoji_icon.dart';
import 'package:buildself/shared/widgets/gradient_button.dart';
import 'package:buildself/shared/widgets/toast.dart';

/// 弹出「新建习惯」底部表单
///
/// 创建成功后调用 [onCreated] 并关闭表单
Future<void> showAddHabitSheet(
  BuildContext context, {
  required String userId,
  required HabitRepository repository,
  required ValueChanged<Habit> onCreated,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddHabitSheet(
      userId: userId,
      repository: repository,
      onCreated: onCreated,
    ),
  );
}

class _AddHabitSheet extends StatefulWidget {
  final String userId;
  final HabitRepository repository;
  final ValueChanged<Habit> onCreated;

  const _AddHabitSheet({
    required this.userId,
    required this.repository,
    required this.onCreated,
  });

  @override
  State<_AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends State<_AddHabitSheet> {
  final _nameCtrl = TextEditingController();
  String _icon = kHabitIcons.first;
  int _colorIndex = 0;
  bool _creating = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ToastHelper.show(context, '请先输入习惯名称');
      return;
    }
    setState(() => _creating = true);
    try {
      final habit = await widget.repository.create(
        userId: widget.userId,
        name: name,
        icon: _icon,
        colorIndex: _colorIndex,
      );
      if (!mounted) return;
      widget.onCreated(habit);
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _creating = false);
      ToastHelper.show(context, '创建失败，请重试');
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
                  const Text(
                    '新建习惯',
                    style: TextStyle(
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
                onSubmitted: (_) => _create(),
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
              // 创建按钮
              GradientButton(
                label: '创建习惯',
                icon: Icons.auto_awesome,
                gradient: LinearGradient(
                  colors: [accent, accent.withValues(alpha: 0.75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onPressed: _creating ? null : _create,
              ),
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
