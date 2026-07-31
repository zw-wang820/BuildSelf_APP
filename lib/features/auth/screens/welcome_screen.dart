import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/core/constants/strings.dart';
import 'package:buildself/core/router/routes.dart';
import 'package:buildself/shared/widgets/nexus_background.dart';

/// 欢迎页 — NEXUS 启动舱
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NexusBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // 标志 — 六边形 + 内核光
                _buildLogo(),
                const SizedBox(height: 28),

                // 应用名 — 渐变字
                _buildWordmark(context),
                const SizedBox(height: 10),

                // HUD 标识行
                _buildHudTag(),
                const SizedBox(height: 14),

                // Slogan
                Text(
                  AppStrings.appSlogan,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondaryDark,
                    letterSpacing: 1.2,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),

                const Spacer(flex: 3),

                // 功能亮点 — 玻璃卡片
                _buildFeatureItem(
                  icon: Icons.hub_outlined,
                  title: '五大模块 · 全方位记录',
                  subtitle: '工作 · 生活 · 目标 · 阅读 · 碎碎念',
                  accent: AppColors.primary,
                ),
                const SizedBox(height: 14),
                _buildFeatureItem(
                  icon: Icons.shield_outlined,
                  title: '本地存储 · 完全私密',
                  subtitle: '你的成长数据只属于你自己',
                  accent: AppColors.accent,
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

  /// 标志 — 旋转六边形 + 光核
  Widget _buildLogo() {
    return SizedBox(
      width: 116,
      height: 116,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 外层光晕
          Container(
            width: 116,
            height: 116,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [AppColors.primary.withOpacity(0.35), AppColors.primary.withOpacity(0)],
              ),
            ),
          ),
          // 六边形描边
          CustomPaint(
            size: const Size(92, 92),
            painter: _HexagonPainter(
              color: AppColors.primary,
              glow: true,
            ),
          ),
          // 内核
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryLight, AppColors.primary],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: AppColors.glowCyan, blurRadius: 18),
              ],
            ),
            child: const Icon(Icons.bolt, color: AppColors.spaceDeep, size: 28),
          ),
        ],
      ),
    );
  }

  /// 渐变字标
  Widget _buildWordmark(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primaryLight, AppColors.accent],
      ).createShader(bounds),
      child: const Text(
        AppStrings.appName,
        style: TextStyle(
          fontSize: 38,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 4,
          height: 1,
        ),
      ),
    );
  }

  /// HUD 标识行 — NEXUS // v1.0
  Widget _buildHudTag() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 0.8),
            borderRadius: BorderRadius.circular(4),
            color: AppColors.primary.withOpacity(0.06),
          ),
          child: const Text(
            'NEXUS // GROWTH OS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: 2,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  /// 功能亮点项
  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.spaceHigh.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withOpacity(0.25), width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.14),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: accent.withOpacity(0.4), width: 0.8),
              boxShadow: [BoxShadow(color: accent.withOpacity(0.25), blurRadius: 10)],
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryDark,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryDark,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: accent.withOpacity(0.5), size: 20),
        ],
      ),
    );
  }

  /// 启动按钮 — 霓虹青 + 光晕
  Widget _buildLaunchButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppColors.glowCyan, blurRadius: 22, offset: const Offset(0, 6))],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                AppStrings.login,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 2),
              ),
              SizedBox(width: 10),
              Icon(Icons.arrow_forward, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// 六边形画笔
class _HexagonPainter extends CustomPainter {
  final Color color;
  final bool glow;

  _HexagonPainter({required this.color, this.glow = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeJoin = StrokeJoin.round;
    if (glow) {
      paint.maskFilter = const MaskFilter.blur(BlurStyle.inner, 2);
    }

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 2;
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i - math.pi / 2;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    // 内部第二层细线
    final inner = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    final innerPath = Path();
    final ir = r - 8;
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i - math.pi / 2;
      final x = cx + ir * math.cos(angle);
      final y = cy + ir * math.sin(angle);
      if (i == 0) {
        innerPath.moveTo(x, y);
      } else {
        innerPath.lineTo(x, y);
      }
    }
    innerPath.close();
    canvas.drawPath(innerPath, inner);
  }

  @override
  bool shouldRepaint(covariant _HexagonPainter oldDelegate) => false;
}
