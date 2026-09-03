import 'package:flutter/material.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/features/review/models/review_item.dart';
import 'package:buildself/features/review/models/review_quadrant.dart';

/// 复盘单条目行 — 同色色条 + 内容 + 时间；长按触发操作回调
class ReviewItemTile extends StatelessWidget {
  final ReviewItem item;
  final ReviewQuadrant quadrant;
  final GestureLongPressCallback? onLongPress;
  final bool showTime;

  const ReviewItemTile({
    Key? key,
    required this.item,
    required this.quadrant,
    this.onLongPress,
    this.showTime = true,
  }) : super(key: key);

  String _time(DateTime t) {
    final local = t.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final qColor = quadrant.color;
    return GestureDetector(
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 象限色条
            Container(
              width: 3,
              height: 18,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: qColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.content,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.35,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ),
            if (showTime) ...[
              const SizedBox(width: 6),
              Text(
                _time(item.createdAt),
                style: TextStyle(
                  fontSize: 10.5,
                  color: qColor.withValues(alpha: 0.8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
