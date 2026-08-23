import 'dart:math';
import 'package:flutter/material.dart';
import 'package:buildself/core/constants/colors.dart';

/// 全屏庆祝动效 — 粒子 burst + 火焰浮动，约 1.6 秒后自动消失。
/// 用法：CelebrationOverlay.show(context, color: AppColors.habit);
class CelebrationOverlay {
  CelebrationOverlay._();

  static void show(BuildContext context, {Color? color}) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _CelebrationOverlay(
        accent: color ?? AppColors.habit,
        onDone: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

/// 单个放射粒子
class _Particle {
  final double angle; // 放射方向（弧度）
  final double speed; // 0.35 ~ 1.0
  final double size; // 半径
  final Color color;
  final double delay; // 0 ~ 0.18 出场相位

  _Particle(this.angle, this.speed, this.size, this.color, this.delay);

  factory _Particle.random(Random r, List<Color> pool) => _Particle(
        r.nextDouble() * 2 * pi,
        0.35 + r.nextDouble() * 0.65,
        3 + r.nextDouble() * 5,
        pool[r.nextInt(pool.length)],
        r.nextDouble() * 0.18,
      );
}

/// 单个浮动火焰
class _Flame {
  final double xRatio; // 水平位置比例
  final double size; // emoji 字号
  final double phase; // 相位（摇摆/闪烁偏移）

  _Flame(this.xRatio, this.size, this.phase);

  factory _Flame.random(Random r) => _Flame(
        0.08 + r.nextDouble() * 0.84,
        24 + r.nextDouble() * 20,
        r.nextDouble() * 2 * pi,
      );
}

class _CelebrationOverlay extends StatefulWidget {
  final Color accent;
  final VoidCallback onDone;

  const _CelebrationOverlay({required this.accent, required this.onDone});

  @override
  State<_CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<_CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Particle> _particles;
  late final List<_Flame> _flames;
  late final List<Color> _pool;
  final _rand = Random(20260823);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _pool = [
      const Color(0xFFFBBF24), // amber
      const Color(0xFFF97316), // orange
      const Color(0xFFF43F5E), // rose
      const Color(0xFFFFF8E1), // 暖白
      widget.accent,
    ];
    _particles = List.generate(44, (_) => _Particle.random(_rand, _pool));
    _flames = List.generate(10, (_) => _Flame.random(_rand));
    _ctrl.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          return Stack(
            fit: StackFit.expand,
            children: [
              // 轻微暗化背景，突出动效（随动画渐隐）
              FadeTransition(
                opacity: Tween<double>(begin: 0.32, end: 0.0)
                    .animate(CurvedAnimation(
                  parent: _ctrl,
                  curve: const Interval(0, 0.85),
                )),
                child: Container(color: Colors.black),
              ),
              // 粒子 burst — 从屏幕中上部向四周放射
              AnimatedBuilder(
                animation: _ctrl,
                builder: (context, _) => CustomPaint(
                  painter: _ParticlePainter(
                    particles: _particles,
                    progress: _ctrl.value,
                  ),
                ),
              ),
              // 火焰浮动 — 从底部上升
              AnimatedBuilder(
                animation: _ctrl,
                builder: (context, _) {
                  final t = _ctrl.value;
                  return Stack(
                    children: [
                      for (final f in _flames)
                        Positioned(
                          left: w * f.xRatio +
                              sin(t * pi * 2 + f.phase) * 14,
                          top: (h + 40) -
                              (h + 40 - h * 0.34) * Curves.easeOut.transform(t),
                          child: Opacity(
                            opacity: _flameAlpha(t, f.phase),
                            child: Transform.scale(
                              scale: 0.85 + 0.3 * sin(t * pi + f.phase),
                              child: Text('🔥', style: TextStyle(fontSize: f.size)),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  /// 火焰透明度：前段渐显、后段渐隐
  double _flameAlpha(double t, double phase) {
    final base = t < 0.12 ? t / 0.12 : 1.0;
    final fadeOut = t > 0.7 ? (1 - (t - 0.7) / 0.3) : 1.0;
    final flicker = 0.82 + 0.18 * sin(t * 12 + phase);
    return (base * fadeOut * flicker).clamp(0.0, 1.0);
  }
}

/// 粒子放射绘制器
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.44);
    final maxR = size.shortestSide * 0.46;
    for (final p in particles) {
      final local = (progress - p.delay) / (1 - p.delay);
      if (local <= 0 || local >= 1) continue;
      final t = Curves.easeOutCubic.transform(local);
      final pos = center + Offset(cos(p.angle), sin(p.angle)) * (maxR * p.speed * t);
      final fade = local < 0.62 ? 1.0 : (1 - (local - 0.62) / 0.38);
      final radius = p.size * (1 - local * 0.45);
      canvas.drawCircle(
        pos,
        radius,
        Paint()..color = p.color.withValues(alpha: fade.clamp(0.0, 1.0)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) =>
      old.progress != progress;
}
