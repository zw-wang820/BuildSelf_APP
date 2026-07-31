import 'package:flutter/material.dart';
import 'package:buildself/core/constants/colors.dart';

/// 空状态组件 — NEXUS 科技风
class EmptyState extends StatelessWidget {
  final String? message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyState({
    Key? key,
    this.message,
    this.icon = Icons.edit_note_outlined,
    this.onAction,
    this.actionLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppColors.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 六边形光环节号 — 用旋转方框 + 光晕模拟
            Container(
              width: 96,
              height: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: accent.withOpacity(0.4), width: 1),
                color: accent.withOpacity(0.06),
                boxShadow: [BoxShadow(color: accent.withOpacity(0.3), blurRadius: 24)],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 四角 HUD 角标
                  ..._buildCorners(accent),
                  Icon(icon, size: 38, color: accent, shadows: [
                    Shadow(color: accent.withOpacity(0.8), blurRadius: 10),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message ?? '还没有记录，开始写下第一条吧',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    letterSpacing: 0.3,
                  ),
              textAlign: TextAlign.center,
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add, size: 18),
                label: Text(actionLabel!, style: const TextStyle(letterSpacing: 0.5)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: accent,
                  side: BorderSide(color: accent.withOpacity(0.6), width: 1),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 四角 HUD 角标
  List<Widget> _buildCorners(Color accent) {
    const cornerSize = 10.0;
    final common = BoxDecoration(
      border: Border(top: BorderSide(color: accent, width: 1.5), left: BorderSide(color: accent, width: 1.5)),
    );
    return [
      Positioned(top: 8, left: 8, child: Container(width: cornerSize, height: cornerSize, decoration: common)),
      Positioned(top: 8, right: 8, child: Transform.rotate(angle: 1.5708, child: Container(width: cornerSize, height: cornerSize, decoration: common))),
      Positioned(bottom: 8, right: 8, child: Transform.rotate(angle: 3.1416, child: Container(width: cornerSize, height: cornerSize, decoration: common))),
      Positioned(bottom: 8, left: 8, child: Transform.rotate(angle: 4.7124, child: Container(width: cornerSize, height: cornerSize, decoration: common))),
    ];
  }
}
