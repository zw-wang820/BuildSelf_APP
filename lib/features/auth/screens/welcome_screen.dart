import 'package:flutter/material.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/core/constants/strings.dart';
import 'package:buildself/core/router/routes.dart';
import 'package:buildself/shared/widgets/gradient_button.dart';

/// 欢迎页 — Buildself 启动页
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // 标志
                _buildLogo(),
                const SizedBox(height: 28),

                // 应用名
                _buildWordmark(context),
                const SizedBox(height: 14),

                // Slogan
                Text(
                  AppStrings.appSlogan,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.82),
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),

                const Spacer(flex: 3),

                // 功能亮点
                _buildFeatureItem(
                  context: context,
                  icon: Icons.hub_outlined,
                  title: '五大模块 · 全方位记录',
                  subtitle: '工作 · 生活 · 目标 · 阅读 · 碎碎念',
                  accent: AppColors.primaryLight,
                ),
                const SizedBox(height: 14),
                _buildFeatureItem(
                  context: context,
                  icon: Icons.shield_outlined,
                  title: '本地存储 · 完全私密',
                  subtitle: '你的成长数据只属于你自己',
                  accent: AppColors.accentLight,
                ),

                const Spacer(flex: 2),

                // 启动按钮
                _buildLaunchButton(context),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 标志
  Widget _buildLogo() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(Icons.bolt, color: Colors.white, size: 36),
    );
  }

  /// 应用名
  Widget _buildWordmark(BuildContext context) {
    return Text(
      AppStrings.appName,
      style: const TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 1,
      ),
    );
  }

  /// 功能亮点项
  Widget _buildFeatureItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: accent.withOpacity(0.4), size: 20),
        ],
      ),
    );
  }

  /// 启动按钮
  Widget _buildLaunchButton(BuildContext context) {
    return GradientButton(
      label: AppStrings.login,
      icon: Icons.arrow_forward,
      onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
    );
  }
}
