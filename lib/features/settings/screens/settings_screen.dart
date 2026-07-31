import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:buildself/core/constants/app_constants.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/core/constants/strings.dart';
import 'package:buildself/core/router/routes.dart';
import 'package:buildself/data/models/enums.dart';
import 'package:buildself/data/repositories/work_repository.dart';
import 'package:buildself/data/repositories/life_repository.dart';
import 'package:buildself/data/repositories/goal_repository.dart';
import 'package:buildself/data/repositories/murmur_repository.dart';
import 'package:buildself/data/repositories/reading_repository.dart';
import 'package:buildself/shared/widgets/app_card.dart';
import 'package:buildself/features/auth/providers/app_provider.dart';

/// 设置页
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settings)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 用户信息卡
            _buildUserCard(context),
            const SizedBox(height: 24),

            // 数据管理
            _buildSectionLabel('数据管理'),
            AppCard(
              child: Column(
                children: [
                  _buildMenuItem(
                    context,
                    icon: Icons.backup_outlined,
                    title: AppStrings.backupRestore,
                    subtitle: '上次备份：从未',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.backup),
                  ),
                  const Divider(height: 1),
                  _buildMenuItem(
                    context,
                    icon: Icons.file_download_outlined,
                    title: AppStrings.dataExport,
                    subtitle: '导出为 Markdown 文件',
                    onTap: () => _exportData(context),
                  ),
                  const Divider(height: 1),
                  _buildMenuItem(
                    context,
                    icon: Icons.delete_outline,
                    title: AppStrings.trash,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.trash),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 安全与隐私
            _buildSectionLabel('安全与隐私'),
            AppCard(
              child: Column(
                children: [
                  _buildSwitchItem(
                    icon: Icons.lock_outline,
                    title: AppStrings.appLock,
                    subtitle: '使用指纹/PIN保护应用',
                    value: false,
                    onChanged: (val) {
                      // TODO: 应用锁开关
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 外观
            _buildSectionLabel('外观'),
            AppCard(
              child: Column(
                children: [
                  _buildMenuItem(
                    context,
                    icon: Icons.dark_mode_outlined,
                    title: AppStrings.themeSetting,
                    subtitle: _themeModeLabel(context.read<AppProvider>().themeMode),
                    onTap: () => Navigator.pushNamed(context, AppRoutes.theme),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 关于
            _buildSectionLabel('关于'),
            AppCard(
              child: Column(
                children: [
                  _buildMenuItem(
                    context,
                    icon: Icons.info_outline,
                    title: AppStrings.about,
                    subtitle: '${AppConstants.appName} v${AppConstants.appVersion}',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.about),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 退出登录
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showLogoutDialog(context),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('退出登录'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context) {
    final user = context.watch<AppProvider>().currentUser;
    final loginTypeLabel = user?.loginType == LoginType.wechat ? '微信登录' : '手机号登录';
    return AppCard(
      onTap: () => _showUserProfile(context),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary.withOpacity(0.15),
            child: const Icon(Icons.person, size: 32, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('探索者', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(loginTypeLabel, style: TextStyle(fontSize: 13, color: AppColors.textSecondaryDark)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondaryDark),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text, style: TextStyle(fontSize: 13, color: AppColors.textSecondaryDark, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.textSecondaryDark),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      subtitle: subtitle != null
          ? Text(subtitle, style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark))
          : null,
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondaryDark),
      onTap: onTap,
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.textSecondaryDark),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      subtitle: subtitle != null
          ? Text(subtitle, style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark))
          : null,
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('退出后本地数据不会删除，重新登录可继续使用。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text(AppStrings.cancel)),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AppProvider>().logout();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return '跟随系统';
      case ThemeMode.light:
        return '浅色模式';
      case ThemeMode.dark:
        return '深色模式';
    }
  }

  /// 用户信息弹窗
  void _showUserProfile(BuildContext context) {
    final user = context.read<AppProvider>().currentUser;
    if (user == null) return;

    final loginTypeLabel = user.loginType == LoginType.wechat ? '微信登录' : '手机号登录';
    final phoneLabel = user.phone ?? '未绑定';
    final createdLabel =
        '${user.createdAt.year}.${user.createdAt.month.toString().padLeft(2, '0')}.${user.createdAt.day.toString().padLeft(2, '0')}';
    final lastLoginLabel =
        '${user.lastLoginAt.year}.${user.lastLoginAt.month.toString().padLeft(2, '0')}.${user.lastLoginAt.day.toString().padLeft(2, '0')}';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.spaceHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 拖拽指示条
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.dividerDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // 头像 + 昵称
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 0.8),
                  ),
                  child: const Icon(Icons.person, size: 30, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('探索者',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(loginTypeLabel,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryDark)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            _profileRow('用户 ID', user.userId.substring(0, user.userId.length > 16 ? 16 : user.userId.length) + '…'),
            _profileRow('手机号', phoneLabel),
            _profileRow('注册时间', createdLabel),
            _profileRow('最近登录', lastLoginLabel),
          ],
        ),
      ),
    );
  }

  Widget _profileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryDark, letterSpacing: 0.3)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimaryDark,
                fontFamily: 'monospace',
                letterSpacing: 0.3,
              )),
        ],
      ),
    );
  }

  /// 数据导出为 Markdown 文件
  Future<void> _exportData(BuildContext context) async {
    final userId = context.read<AppProvider>().userId;
    if (userId.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.spaceDeep)),
            SizedBox(width: 12),
            Text('正在导出数据…'),
          ],
        ),
        backgroundColor: AppColors.primary.withOpacity(0.2),
        duration: const Duration(seconds: 10),
      ),
    );

    try {
      final workRepo = WorkRepository();
      final lifeRepo = LifeRepository();
      final goalRepo = GoalRepository();
      final murmurRepo = MurmurRepository();
      final readingRepo = ReadingRepository();

      final buf = StringBuffer();
      buf.writeln('# BuildSelf 数据导出');
      buf.writeln();
      buf.writeln('> 导出时间：${DateTime.now().toIso8601String()}');
      buf.writeln();

      // 工作记录
      final works = await workRepo.getAll(userId);
      buf.writeln('## 工作记录（${works.length} 条）');
      buf.writeln();
      for (final w in works) {
        buf.writeln('### ${w.title.isNotEmpty ? w.title : "（无标题）"}');
        buf.writeln();
        buf.writeln('- **类型**：${w.recordType}');
        buf.writeln('- **时间**：${w.createdAt.toIso8601String()}');
        if (w.tags.isNotEmpty) buf.writeln('- **标签**：${w.tags.map((t) => '#$t').join(' ')}');
        if (w.mood != null) buf.writeln('- **心情**：${w.mood!.emoji} ${w.mood!.label}');
        buf.writeln();
        buf.writeln(w.content);
        buf.writeln();
        buf.writeln('---');
        buf.writeln();
      }

      // 生活记录
      final lives = await lifeRepo.getAll(userId);
      buf.writeln('## 生活记录（${lives.length} 条）');
      buf.writeln();
      for (final l in lives) {
        buf.writeln('### ${l.title.isNotEmpty ? l.title : "（无标题）"}');
        buf.writeln();
        buf.writeln('- **类型**：${l.recordType}');
        buf.writeln('- **时间**：${l.createdAt.toIso8601String()}');
        if (l.tags.isNotEmpty) buf.writeln('- **标签**：${l.tags.map((t) => '#$t').join(' ')}');
        if (l.mood != null) buf.writeln('- **心情**：${l.mood!.emoji} ${l.mood!.label}');
        if (l.weather != null) buf.writeln('- **天气**：${l.weather!.label}');
        if (l.location != null) buf.writeln('- **位置**：${l.location}');
        buf.writeln();
        buf.writeln(l.content);
        buf.writeln();
        buf.writeln('---');
        buf.writeln();
      }

      // 目标
      final goals = await goalRepo.getActiveGoals(userId);
      buf.writeln('## 目标（${goals.length} 个）');
      buf.writeln();
      for (final g in goals) {
        buf.writeln('### ${g.title}');
        buf.writeln();
        buf.writeln('- **类型**：${g.goalType.name}');
        buf.writeln('- **进度**：${g.calculatedProgress}%');
        buf.writeln('- **状态**：${g.status.name}');
        if (g.targetDate != null) buf.writeln('- **目标日期**：${g.targetDate!.toIso8601String()}');
        if (g.description.isNotEmpty) {
          buf.writeln();
          buf.writeln(g.description);
        }
        buf.writeln();
        buf.writeln('---');
        buf.writeln();
      }

      // 阅读笔记
      final changes = await readingRepo.getAllChanges(userId);
      buf.writeln('## 阅读改变（${changes.length} 条）');
      buf.writeln();
      for (final c in changes) {
        buf.writeln('- ${c.createdAt.toIso8601String()}：${c.content}');
      }
      buf.writeln();

      // 碎碎念
      final murmurs = await murmurRepo.getAll(userId);
      buf.writeln('## 碎碎念（${murmurs.length} 条）');
      buf.writeln();
      for (final m in murmurs) {
        buf.writeln('### ${m.createdAt.toIso8601String()}');
        buf.writeln();
        if (m.mood != null) buf.writeln('> 心情：${m.mood!.emoji} ${m.mood!.label}');
        buf.writeln(m.content);
        if (m.tags.isNotEmpty) buf.writeln('\n${m.tags.map((t) => '#$t').join(' ')}');
        buf.writeln();
        buf.writeln('---');
        buf.writeln();
      }

      // 写入文件
      final dir = await getApplicationDocumentsDirectory();
      final exportDir = Directory(p.join(dir.path, 'exports'));
      if (!exportDir.existsSync()) exportDir.createSync(recursive: true);
      final stamp = DateTime.now()
          .toIso8601String()
          .replaceAll(RegExp(r'[:.]'), '-')
          .substring(0, 19);
      final filePath = p.join(exportDir.path, 'buildself_export_$stamp.md');
      final file = File(filePath);
      await file.writeAsString(buf.toString());

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('导出成功：$filePath'),
          backgroundColor: AppColors.accent.withOpacity(0.2),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('导出失败：$e'),
          backgroundColor: AppColors.error.withOpacity(0.2),
        ),
      );
    }
  }
}
