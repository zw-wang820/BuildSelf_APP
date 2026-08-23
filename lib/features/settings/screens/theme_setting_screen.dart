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
        title: Text(AppStrings.themeSetting),
      ),
      body: ListView(
        children: [
          _buildOption(
            context,
            icon: Icons.brightness_auto_outlined,
            title: AppStrings.themeSystem,
            subtitle: AppStrings.themeSystemSubtitle,
            isSelected: currentMode == ThemeMode.system,
            onTap: () => appProvider.setThemeMode(ThemeMode.system),
          ),
          _buildOption(
            context,
            icon: Icons.light_mode_outlined,
            title: AppStrings.themeLight,
            subtitle: AppStrings.themeLightSubtitle,
            isSelected: currentMode == ThemeMode.light,
            onTap: () => appProvider.setThemeMode(ThemeMode.light),
          ),
          _buildOption(
            context,
            icon: Icons.dark_mode_outlined,
            title: AppStrings.themeDark,
            subtitle: AppStrings.themeDarkSubtitle,
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
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context))),
      trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green) : null,
      onTap: onTap,
    );
  }
}
