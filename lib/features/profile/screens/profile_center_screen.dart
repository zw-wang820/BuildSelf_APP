import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/core/constants/strings.dart';
import 'package:buildself/core/router/routes.dart';
import 'package:buildself/features/auth/providers/app_provider.dart';

/// 个人中心 — 枢纽页
///
/// 顶部用户信息头部（大头像 + 昵称/ID/简介 + 成长天数），
/// 下方菜单项依次进入：个人资料 / 数据统计 / 成就徽章 / 数据备份 / 设置。
class ProfileCenterScreen extends StatelessWidget {
  const ProfileCenterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppProvider>().currentUser;
    final nickname =
        user?.nickname.isNotEmpty == true ? user!.nickname : AppStrings.explorer;
    final id = user?.userId ?? '';
    final days = user != null
        ? DateTime.now().difference(user.createdAt).inDays + 1
        : 0;

    final items = [
      _MenuItem(
        icon: Icons.person_outline,
        label: '个人资料',
        sub: '查看与管理你的档案',
        color: AppColors.primary,
        route: AppRoutes.profile,
      ),
      _MenuItem(
        icon: Icons.bar_chart_outlined,
        label: '数据统计',
        sub: '专注时长与成长趋势',
        color: AppColors.work,
        route: AppRoutes.statistics,
      ),
      _MenuItem(
        icon: Icons.emoji_events_outlined,
        label: '成就徽章',
        sub: '已解锁 9 / 15 枚',
        color: AppColors.warning,
        route: AppRoutes.achievements,
      ),
      _MenuItem(
        icon: Icons.cloud_sync_outlined,
        label: '数据备份',
        sub: '云端同步与本地管理',
        color: AppColors.life,
        route: AppRoutes.backup,
      ),
      _MenuItem(
        icon: Icons.settings_outlined,
        label: '设置',
        sub: '外观 · 通知 · 隐私',
        color: AppColors.reading,
        route: AppRoutes.settings,
      ),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // 用户信息头部（渐变）
          Container(
            decoration: const BoxDecoration(gradient: AppColors.heroGradient),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 20),
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildAvatar(72),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nickname,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ID: ${id.length > 12 ? '${id.substring(0, 12)}…' : id}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                '记录成长，成为更好的自己',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // 成长概览
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _stat('成长天数', '$days'),
                          _vDivider(),
                          _stat('记录', '128'),
                          _vDivider(),
                          _stat('连续', '12天'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: items.map((e) => _buildItem(context, e)).toList(),
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _buildAvatar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        image: const DecorationImage(
          image: AssetImage('assets/images/avatar.jpg'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, _MenuItem e) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.pushNamed(context, e.route),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: e.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(e.icon, color: e.color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        e.sub,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: AppColors.textSecondary(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _vDivider() {
    return Container(
      width: 1,
      height: 28,
      color: Colors.white.withValues(alpha: 0.25),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final String route;

  _MenuItem({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
    required this.route,
  });
}
