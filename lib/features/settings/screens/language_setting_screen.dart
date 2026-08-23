import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/core/constants/strings.dart';
import 'package:buildself/features/auth/providers/app_provider.dart';

/// 语言设置页
class LanguageSettingScreen extends StatelessWidget {
  const LanguageSettingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final currentLocale = appProvider.appLocale;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.languageSetting),
      ),
      body: ListView(
        children: AppLocale.values.map((locale) {
          return _buildOption(
            context,
            locale: locale,
            isSelected: currentLocale == locale,
            onTap: () => appProvider.setLocale(locale),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required AppLocale locale,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        Icons.language_outlined,
        color: isSelected ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(locale.displayName),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Colors.green)
          : null,
      onTap: onTap,
    );
  }
}
