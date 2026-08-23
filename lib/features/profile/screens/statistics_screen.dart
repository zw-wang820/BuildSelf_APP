import 'dart:math';
import 'package:flutter/material.dart';
import 'package:buildself/core/constants/colors.dart';

/// 数据统计页
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  // 本周专注时长（小时）
  static const List<double> _week = [2.0, 3.5, 1.5, 4.0, 2.5, 5.0, 3.0];
  static const List<String> _weekLabels = ['一', '二', '三', '四', '五', '六', '日'];

  // 时间分配
  static final List<_Slice> _allocation = [
    _Slice('工作', 35, AppColors.work),
    _Slice('生活', 25, AppColors.life),
    _Slice('阅读', 20, AppColors.reading),
    _Slice('目标', 12, AppColors.goalMid),
    _Slice('碎碎念', 8, AppColors.murmur),
  ];

  // 四项成长趋势
  static final List<_Trend> _trends = [
    _Trend('工作', AppColors.work, [3, 4, 3.5, 5, 4, 6, 5.5], '+18%'),
    _Trend('生活', AppColors.life, [2, 2.5, 3, 2, 3.5, 4, 3.8], '+12%'),
    _Trend('阅读', AppColors.reading, [1, 1.5, 2, 1.8, 2.5, 2.2, 3], '+25%'),
    _Trend('目标', AppColors.goalMid, [4, 4.5, 5, 5.5, 6, 6.5, 7], '+9%'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('数据统计')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 累计专注时长 Hero 卡片
            Container(
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(22),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined,
                      color: Colors.white, size: 30),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('累计专注时长',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 4),
                        RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: '64.5',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              TextSpan(
                                text: ' 小时',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text('本周已专注 27.5 小时 · 较上周 +15%',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),

            // 本周柱状图
            _sectionLabel('本周专注时长（小时）', context),
            const SizedBox(height: 10),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: CustomPaint(
                size: Size.infinite,
                painter: _BarChartPainter(
                  values: _week,
                  labels: _weekLabels,
                  color: AppColors.primary,
                  labelColor: AppColors.textSecondary(context),
                ),
              ),
            ),
            const SizedBox(height: 26),

            // 时间分配饼图
            _sectionLabel('时间分配', context),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    height: 180,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: Size.infinite,
                          painter: _PiePainter(slices: _allocation),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('128',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary(context),
                                )),
                            Text('总记录',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary(context),
                                )),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  ..._allocation.map((s) => _legendRow(s, context)).toList(),
                ],
              ),
            ),
            const SizedBox(height: 26),

            // 四项成长趋势
            _sectionLabel('四项成长趋势', context),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(8),
              child: Column(
                children: _trends.map((t) => _trendRow(t, context)).toList(),
              ),
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

  Widget _legendRow(_Slice s, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: s.color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 10),
          Text(s.label, style: TextStyle(fontSize: 13, color: AppColors.textPrimary(context))),
          const Spacer(),
          Text('${s.value}%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary(context))),
        ],
      ),
    );
  }

  Widget _trendRow(_Trend t, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: t.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_trendIcon(t.label), color: t.color, size: 18),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 44,
            child: Text(t.label,
                style: TextStyle(fontSize: 13, color: AppColors.textPrimary(context))),
          ),
          Expanded(
            child: SizedBox(
              height: 36,
              child: CustomPaint(
                size: Size.infinite,
                painter: _SparkPainter(values: t.values, color: t.color),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(t.change,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.success,
              )),
        ],
      ),
    );
  }

  IconData _trendIcon(String label) {
    switch (label) {
      case '工作':
        return Icons.work_outline;
      case '生活':
        return Icons.local_cafe_outlined;
      case '阅读':
        return Icons.menu_book_outlined;
      default:
        return Icons.flag_outlined;
    }
  }
}

class _Slice {
  final String label;
  final double value;
  final Color color;
  _Slice(this.label, this.value, this.color);
}

class _Trend {
  final String label;
  final Color color;
  final List<double> values;
  final String change;
  _Trend(this.label, this.color, this.values, this.change);
}

/// 柱状图
class _BarChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final Color color;
  final Color labelColor;

  _BarChartPainter({
    required this.values,
    required this.labels,
    required this.color,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final maxV = values.reduce((a, b) => a > b ? a : b);
    const top = 20.0;
    const bottom = 20.0;
    final plotH = size.height - top - bottom;
    final n = values.length;
    const gap = 12.0;
    final barW = (size.width - gap * (n - 1)) / n;
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < n; i++) {
      final x = i * (barW + gap);
      final h = maxV == 0 ? 0.0 : (values[i] / maxV) * plotH;
      final y = top + (plotH - h);
      paint.color = color;
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barW, h), Radius.circular(barW / 2),
      );
      canvas.drawRRect(r, paint);

      // 数值
      final tp = TextPainter(
        text: TextSpan(
          text: values[i].toStringAsFixed(1),
          style: TextStyle(fontSize: 10, color: labelColor),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x + barW / 2 - tp.width / 2, y - 13));

      // 标签
      final tl = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(fontSize: 11, color: labelColor),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tl.paint(canvas, Offset(x + barW / 2 - tl.width / 2, size.height - 15));
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter old) => false;
}

/// 环形饼图
class _PiePainter extends CustomPainter {
  final List<_Slice> slices;

  _PiePainter({required this.slices});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = min(cx, cy);
    final inner = r * 0.62;
    final total = slices.fold(0.0, (double s, _Slice e) => s + e.value);
    double start = -pi / 2;

    for (final s in slices) {
      final sweep = (s.value / total) * 2 * pi;
      final path = Path();
      path.arcTo(Rect.fromCircle(center: Offset(cx, cy), radius: r), start, sweep, false);
      path.arcTo(Rect.fromCircle(center: Offset(cx, cy), radius: inner), start + sweep, -sweep, false);
      path.close();
      canvas.drawPath(path, Paint()..color = s.color);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _PiePainter old) => false;
}

/// 迷你趋势线
class _SparkPainter extends CustomPainter {
  final List<double> values;
  final Color color;

  _SparkPainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final minV = values.reduce((a, b) => a < b ? a : b);
    final span = (maxV - minV) == 0 ? 1.0 : (maxV - minV);
    final n = values.length;
    final step = size.width / (n - 1);
    final pts = <Offset>[];
    for (int i = 0; i < n; i++) {
      final x = i * step;
      final y = size.height - ((values[i] - minV) / span) * (size.height - 6) - 3;
      pts.add(Offset(x, y));
    }

    // 填充
    final fill = Path()..moveTo(0, size.height);
    for (final p in pts) fill.lineTo(p.dx, p.dy);
    fill.lineTo(size.width, size.height);
    fill.close();
    final grad = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.0)],
    );
    canvas.drawPath(fill, Paint()..shader = grad.createShader(Offset.zero & size));

    // 线
    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) line.lineTo(p.dx, p.dy);
    canvas.drawPath(line, Paint()..color = color..strokeWidth = 2..style = PaintingStyle.stroke);

    // 端点
    canvas.drawCircle(pts.last, 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) => false;
}
