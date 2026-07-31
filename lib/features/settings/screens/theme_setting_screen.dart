import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/core/constants/strings.dart';
import 'package:buildself/features/auth/providers/app_provider.dart';

/// 主题设置页
class ThemeSettingScreen extends StatelessWidget {
  const ThemeSettingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final currentMode = appProvider.themeMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.themeSetting),
      ),
      body: ListView(
        children: [
          _buildOption(
            context,
            icon: Icons.brightness_auto_outlined,
            title: '跟随系统',
            subtitle: '根据系统设置自动切换深浅色',
            isSelected: currentMode == ThemeMode.system,
            onTap: () => appProvider.setThemeMode(ThemeMode.system),
          ),
          _buildOption(
            context,
            icon: Icons.light_mode_outlined,
            title: '浅色模式',
            subtitle: '始终使用浅色主题',
            isSelected: currentMode == ThemeMode.light,
            onTap: () => appProvider.setThemeMode(ThemeMode.light),
          ),
          _buildOption(
            context,
            icon: Icons.dark_mode_outlined,
            title: '深色模式',
            subtitle: '始终使用深色主题',
            isSelected: currentMode == ThemeMode.dark,
            onTap: () => appProvider.setThemeMode(ThemeMode.dark),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? Theme.of(context).colorScheme.primary : null),
      title: Text(title),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
      trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green) : null,
      onTap: onTap,
    );
  }
}
