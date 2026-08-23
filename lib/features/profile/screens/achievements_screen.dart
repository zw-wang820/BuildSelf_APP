import 'package:flutter/material.dart';
import 'package:buildself/core/constants/colors.dart';

/// 成就徽章页
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({Key? key}) : super(key: key);

  static const int _unlockedCount = 9;
  static const int _total = 15;

  // 已解锁（level: 3金 / 2银 / 1铜）
  static const List<_Badge> _unlocked = [
    _Badge('初次记录', Icons.edit_note, 3, null),
    _Badge('连续7天', Icons.local_fire_department, 3, null),
    _Badge('阅读10本', Icons.menu_book, 2, null),
    _Badge('完成首目标', Icons.flag, 2, null),
    _Badge('专注100h', Icons.timer, 2, null),
    _Badge('生活30天', Icons.local_cafe, 1, null),
    _Badge('碎碎念50', Icons.chat_bubble, 1, null),
    _Badge('早起达人', Icons.wb_sunny, 1, null),
    _Badge('周末不荒废', Icons.weekend, 1, null),
  ];

  // 未解锁
  static const List<_Badge> _locked = [
    _Badge('连续30天', Icons.local_fire_department, 0, '连续记录满 30 天'),
    _Badge('阅读50本', Icons.menu_book, 0, '累计读完 50 本书'),
    _Badge('专注500h', Icons.timer, 0, '累计专注 500 小时'),
    _Badge('目标达人', Icons.emoji_events, 0, '同时推进 5 个目标'),
    _Badge('百日成长', Icons.auto_awesome, 0, '坚持成长 100 天'),
    _Badge('分享达人', Icons.share, 0, '分享 10 篇记录'),
  ];

  @override
  Widget build(BuildContext context) {
    final ratio = _unlockedCount / _total;
    return Scaffold(
      appBar: AppBar(title: const Text('成就徽章')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 解锁进度
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('徽章解锁进度',
                          style: TextStyle(color: Colors.white70, fontSize: 13)),
                      Text('$_unlockedCount / $_total',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          )),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 10,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text('再解锁 ${_total - _unlockedCount} 枚即可集齐全部成就',
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 26),

            // 已解锁
            _sectionLabel('已解锁 · $_unlockedCount 枚', context),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 14,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
              children: _unlocked.map((b) => _buildBadge(b, unlocked: true, context: context)).toList(),
            ),
            const SizedBox(height: 28),

            // 未解锁
            _sectionLabel('未解锁 · ${_locked.length} 枚', context),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 14,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
              children: _locked.map((b) => _buildBadge(b, unlocked: false, context: context)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary(context),
        ),
      ),
    );
  }

  Widget _buildBadge(_Badge b, {required bool unlocked, required BuildContext context}) {
    final color = _levelColor(b.level, context);
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: unlocked ? color.withValues(alpha: 0.15) : AppColors.dividerDark,
            border: Border.all(
              color: unlocked ? color : AppColors.dividerDark,
              width: 2,
            ),
          ),
          child: Icon(
            unlocked ? b.icon : Icons.lock_outline,
            color: unlocked ? color : AppColors.placeholderDark,
            size: 28,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          b.name,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: unlocked ? AppColors.textPrimary(context) : AppColors.textSecondary(context),
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (!unlocked && b.condition != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              b.condition!,
              style: TextStyle(fontSize: 10, color: AppColors.textSecondary(context)),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Color _levelColor(int level, BuildContext context) {
    switch (level) {
      case 3:
        return const Color(0xFFF59E0B); // 金
      case 2:
        return const Color(0xFF94A3B8); // 银
      case 1:
        return const Color(0xFFB45309); // 铜
      default:
        return AppColors.textSecondary(context);
    }
  }
}

class _Badge {
  final String name;
  final IconData icon;
  final int level; // 0 未解锁 / 1 铜 / 2 银 / 3 金
  final String? condition;
  const _Badge(this.name, this.icon, this.level, this.condition);
}
