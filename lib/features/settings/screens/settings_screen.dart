import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/core/constants/strings.dart';
import 'package:buildself/core/router/routes.dart';
import 'package:buildself/features/auth/providers/app_provider.dart';

/// 设置页
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 通知
  bool _reminderCheckIn = true;
  bool _reminderGoalDue = true;
  bool _reminderDaily = false;
  // 隐私
  bool _appLock = false;
  bool _dataEncrypt = false;

  final List<_FontOpt> _fontOptions = [
    _FontOpt('小', 0.85),
    _FontOpt('标准', 1.0),
    _FontOpt('大', 1.15),
    _FontOpt('特大', 1.3),
  ];

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.primary.withValues(alpha: 0.2)),
    );
  }

  Future<void> _toggleDark(bool value) async {
    final provider = context.read<AppProvider>();
    await provider.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
    _showSnack(value ? '深色模式已开启' : '深色模式已关闭');
  }

  Future<void> _setFont(double scale) async {
    await context.read<AppProvider>().setTextScale(scale);
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出当前账号吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppStrings.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(AppStrings.logoutButton),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await context.read<AppProvider>().logout();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.welcome, (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = provider.themeMode == ThemeMode.dark;
    final currentScale = provider.textScale;
    final activeFont = _fontOptions
        .firstWhere((o) => (o.scale - currentScale).abs() < 0.001,
            orElse: () => _fontOptions[1])
        .label;

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 外观
            _sectionLabel('外观'),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('深色模式', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    subtitle: Text('开启后界面切换为暗色', style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context))),
                    value: isDark,
                    activeColor: AppColors.primary,
                    onChanged: _toggleDark,
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('字体大小', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                              SizedBox(height: 2),
                              Text('当前：$activeFont', style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context))),
                            ],
                          ),
                        ),
                        ..._fontOptions.map((o) => _fontChip(o, currentScale)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 通知
            _sectionLabel('通知'),
            const SizedBox(height: 10),
            _switchCard([
              _Switch('打卡提醒', '每天提醒你记录成长', _reminderCheckIn, (v) => setState(() => _reminderCheckIn = v)),
              _Switch('目标到期', '目标临近截止时提醒', _reminderGoalDue, (v) => setState(() => _reminderGoalDue = v)),
              _Switch('每日回顾', '晚上推送今日成长回顾', _reminderDaily, (v) => setState(() => _reminderDaily = v)),
            ]),
            const SizedBox(height: 24),

            // 隐私
            _sectionLabel('隐私'),
            const SizedBox(height: 10),
            _switchCard([
              _Switch('应用锁', '进入 App 需要验证', _appLock, (v) => setState(() => _appLock = v)),
              _Switch('数据加密', '本地数据加密存储', _dataEncrypt, (v) => setState(() => _dataEncrypt = v)),
            ]),
            const SizedBox(height: 24),

            // 其他
            _sectionLabel('其他'),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  _tapRow(Icons.language_outlined, '语言', '简体中文', () => Navigator.pushNamed(context, AppRoutes.language)),
                  const Divider(height: 1),
                  _tapRow(Icons.info_outline, '关于', 'BuildSelf v1.0.0', () => Navigator.pushNamed(context, AppRoutes.about)),
                  const Divider(height: 1),
                  _tapRow(Icons.logout, '退出登录', '切换或退出当前账号', () => _logout(), danger: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
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

  Widget _fontChip(_FontOpt opt, double current) {
    final selected = (opt.scale - current).abs() < 0.001;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: InkWell(
        onTap: () => _setFont(opt.scale),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.dividerDark,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            opt.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textSecondary(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _switchCard(List<_Switch> items) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: Text(items[i].title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              subtitle: Text(items[i].sub, style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context))),
              value: items[i].value,
              activeColor: AppColors.primary,
              onChanged: items[i].onChanged,
            ),
          ],
        ],
      ),
    );
  }

  Widget _tapRow(IconData icon, String title, String sub, VoidCallback onTap, {bool danger = false}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: danger ? AppColors.error : AppColors.textSecondary(context)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: danger ? AppColors.error : AppColors.textPrimary(context))),
                  const SizedBox(height: 2),
                  Text(sub, style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context))),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textSecondary(context)),
          ],
        ),
      ),
    );
  }
}

class _FontOpt {
  final String label;
  final double scale;
  _FontOpt(this.label, this.scale);
}

class _Switch {
  final String title;
  final String sub;
  final bool value;
  final ValueChanged<bool> onChanged;
  _Switch(this.title, this.sub, this.value, this.onChanged);
}
