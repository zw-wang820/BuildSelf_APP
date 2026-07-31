import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:buildself/core/constants/colors.dart';

/// NEXUS 背景 — 蓝图网格 + 环境光晕
///
/// 作为所有主要屏幕的氛围底层，营造深空科技感。
/// 深色模式展现完整效果，浅色模式仅保留极淡网格。
class NexusBackground extends StatelessWidget {
  final Widget child;
  final bool showGlow;

  const NexusBackground({
    Key? key,
    required this.child,
    this.showGlow = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        // 1. 基底色（与 scaffold 同色，确保过渡平滑）
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [AppColors.spaceDeep, AppColors.spaceMid, AppColors.spaceDeep]
                    : [AppColors.backgroundLight, AppColors.surfaceLight, AppColors.backgroundLight],
              ),
            ),
          ),
        ),
        // 2. 蓝图网格
        Positioned.fill(
          child: CustomPaint(
            painter: _GridPainter(
              isDark: isDark,
              spacing: 28,
            ),
          ),
        ),
        // 3. 环境光晕（仅深色 + showGlow）
        if (isDark && showGlow) ..._ambientGlows(),
        // 4. 内容
        Positioned.fill(child: child),
      ],
    );
  }

  List<Widget> _ambientGlows() {
    return [
      Positioned(
        top: -80,
        right: -60,
        child: _GlowBlob(color: AppColors.gradCyan, size: 260, opacity: 0.18),
      ),
      Positioned(
        top: 280,
        left: -100,
        child: _GlowBlob(color: AppColors.gradViolet, size: 220, opacity: 0.12),
      ),
      Positioned(
        bottom: -40,
        right: -80,
        child: _GlowBlob(color: AppColors.gradMint, size: 200, opacity: 0.10),
      ),
    ];
  }
}

/// 蓝图网格画笔 — 细线 + 交叉点亮点
class _GridPainter extends CustomPainter {
  final bool isDark;
  final double spacing;

  _GridPainter({required this.isDark, required this.spacing});

  @override
  void paint(Canvas canvas, Size size) {
    final lineColor = isDark ? AppColors.gridLineDark : AppColors.gridLineLight;
    final dotColor = isDark ? AppColors.gridDotDark : AppColors.gridLineLight.withOpacity(0.6);

    final linePaint = Paint()
      ..color = lineColor.withOpacity(isDark ? 0.5 : 0.7)
      ..strokeWidth = 0.5;

    final dotPaint = Paint()..color = dotColor;

    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
    // 交叉点亮点
    for (double x = 0; x <= size.width; x += spacing) {
      for (double y = 0; y <= size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), isDark ? 1.1 : 0.8, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
      oldDelegate.isDark != isDark || oldDelegate.spacing != spacing;
}

/// 径向光晕 blob
class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;

  const _GlowBlob({required this.color, required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withOpacity(opacity), color.withOpacity(0)],
          ),
        ),
      ),
    );
  }
}

/// HUD 角标装饰 — 四角 L 形线，用于强调容器
class HudCorners extends StatelessWidget {
  final Color color;
  final double size;
  final double length;
  final double strokeWidth;

  const HudCorners({
    Key? key,
    this.color = AppColors.primary,
    this.size = 14,
    this.length = 14,
    this.strokeWidth = 1.5,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(top: 0, left: 0, child: _corner(0)),
          Positioned(top: 0, right: 0, child: _corner(math.pi / 2)),
          Positioned(bottom: 0, right: 0, child: _corner(math.pi)),
          Positioned(bottom: 0, left: 0, child: _corner(-math.pi / 2)),
        ],
      ),
    );
  }

  Widget _corner(double rotation) {
    return Transform.rotate(
      angle: rotation,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _CornerPainter(color: color, length: length, strokeWidth: strokeWidth),
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double length;
  final double strokeWidth;

  _CornerPainter({required this.color, required this.length, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    // 左上角 L 形
    canvas.drawPath(
      Path()
        ..moveTo(0, length)
        ..lineTo(0, 0)
        ..lineTo(length, 0),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) => false;
}
