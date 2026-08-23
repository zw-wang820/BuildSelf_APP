import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/core/constants/strings.dart';
import 'package:buildself/data/models/enums.dart';
import 'package:buildself/features/auth/providers/app_provider.dart';

/// 个人资料页
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppProvider>().currentUser;
    final nickname =
        user?.nickname.isNotEmpty == true ? user!.nickname : AppStrings.explorer;
    final id = user?.userId ?? '';
    final phone = user?.phone ?? '未绑定';
    final loginTypeLabel = user?.loginType == LoginType.wechat
        ? '微信登录'
        : '手机号登录';
    final created = user?.createdAt;
    final lastLogin = user?.lastLoginAt;
    final messenger = ScaffoldMessenger.of(context);

    final stats = [
      _Stat(icon: Icons.article_outlined, label: '总记录', value: '128', color: AppColors.primary),
      _Stat(icon: Icons.timer_outlined, label: '专注时长', value: '64h', color: AppColors.work),
      _Stat(icon: Icons.flag_outlined, label: '进行中目标', value: '9', color: AppColors.goalMid),
      _Stat(icon: Icons.local_fire_department_outlined, label: '连续天数', value: '12', color: AppColors.warning),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('个人资料')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部：大头像 + 昵称 + ID + 简介
            Center(
              child: Column(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      image: const DecorationImage(
                        image: AssetImage('assets/images/avatar.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    nickname,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${id.length > 14 ? '${id.substring(0, 14)}…' : id}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary(context),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '记录成长，成为更好的自己',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 数据统计卡片
            _sectionLabel('数据统计', context),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
              ),
              itemCount: stats.length,
              itemBuilder: (context, i) => _buildStatCard(stats[i], context),
            ),
            const SizedBox(height: 26),

            // 基本信息
            _sectionLabel('基本信息', context),
            const SizedBox(height: 10),
            _card(
              context,
              children: [
                _infoRow('手机号', phone, context),
                const Divider(height: 1),
                _infoRow('注册时间',
                    created != null ? _fmt(created) : '—', context),
                const Divider(height: 1),
                _infoRow('最后登录',
                    lastLogin != null ? _fmt(lastLogin) : '—', context),
                const Divider(height: 1),
                _infoRow('登录方式', loginTypeLabel, context),
              ],
            ),
            const SizedBox(height: 26),

            // 账号安全
            _sectionLabel('账号安全', context),
            const SizedBox(height: 10),
            _card(
              context,
              children: [
                _tapRow(context, Icons.lock_outline, '修改密码',
                    '定期更新密码更安全', () {
                  messenger.showSnackBar(const SnackBar(
                      content: Text('修改密码功能开发中')));
                }),
                const Divider(height: 1),
                _tapRow(context, Icons.phone_android_outlined, '绑定手机号',
                    phone == '未绑定' ? '未绑定' : '已绑定', () {
                  messenger.showSnackBar(const SnackBar(
                      content: Text('绑定手机号功能开发中')));
                }),
                const Divider(height: 1),
                _tapRow(context, Icons.devices_outlined, '登录设备管理',
                    '管理已登录设备', () {
                  messenger.showSnackBar(const SnackBar(
                      content: Text('登录设备管理功能开发中')));
                }),
                const Divider(height: 1),
                _tapRow(context, Icons.no_accounts_outlined, '注销账号',
                    '永久删除账号与数据', () {
                  messenger.showSnackBar(const SnackBar(
                      content: Text('注销账号功能开发中')));
                }, danger: true),
              ],
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

  Widget _card(BuildContext context, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildStatCard(_Stat s, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: s.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(s.icon, color: s.color, size: 20),
          const SizedBox(height: 6),
          Text(
            s.value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: s.color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            s.label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary(context),
              )),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tapRow(
    BuildContext context,
    IconData icon,
    String title,
    String sub,
    VoidCallback onTap, {
    bool danger = false,
  }) {
    final color = danger ? AppColors.error : AppColors.textPrimary(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon,
                size: 20, color: danger ? AppColors.error : AppColors.textSecondary(context)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
                  const SizedBox(height: 2),
                  Text(sub,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary(context),
                      )),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textSecondary(context)),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
}

class _Stat {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  _Stat({required this.icon, required this.label, required this.value, required this.color});
}
