import 'package:flutter/material.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/shared/widgets/emoji_icon.dart';

/// 圆形复选框 — 点击带弹簧动画（elasticOut 回弹 + 对勾弹出）
class TodoCheckbox extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color activeColor;
  final double size;

  const TodoCheckbox({
    Key? key,
    required this.value,
    this.onChanged,
    this.activeColor = AppColors.primary,
    this.size = 26,
  }) : super(key: key);

  @override
  State<TodoCheckbox> createState() => _TodoCheckboxState();
}

class _TodoCheckboxState extends State<TodoCheckbox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    if (widget.value) _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant TodoCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      // 激活：对勾弹簧弹出；取消：对勾回缩消失
      if (widget.value) {
        _ctrl.forward(from: 0);
      } else {
        _ctrl.reverse(from: 1);
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    widget.onChanged?.call(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.dividerDark : AppColors.dividerLight;

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? widget.activeColor : Colors.transparent,
          border: Border.all(
            color: active ? widget.activeColor : borderColor,
            width: 2,
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              // elasticOut 让对勾在弹出时带弹簧回弹效果
              final t = Curves.elasticOut.transform(_ctrl.value);
              return Transform.scale(
                scale: t,
                child: EmojiIcon('✅', size: widget.size * 0.66),
              );
            },
          ),
        ),
      ),
    );
  }
}
