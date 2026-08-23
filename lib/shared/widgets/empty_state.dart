import 'package:flutter/material.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/shared/widgets/emoji_icon.dart';

/// 空状态组件 — 极简风
class EmptyState extends StatelessWidget {
  final String? message;
  final IconData? icon;
  final String? emoji;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyState({
    Key? key,
    this.message,
    this.icon,
    this.emoji,
    this.onAction,
    this.actionLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final secondaryColor = AppColors.textSecondary(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (emoji != null)
              EmojiIcon(emoji!, size: 48)
            else
              Icon(
                icon ?? Icons.edit_note_outlined,
                size: 48,
                color: secondaryColor,
              ),
            const SizedBox(height: 16),
            Text(
              message ?? '还没有记录，开始写下第一条吧',
              style: TextStyle(
                fontSize: 14,
                color: secondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add, size: 18),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
