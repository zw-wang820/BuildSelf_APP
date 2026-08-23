import 'package:flutter/material.dart';
import 'package:buildself/core/constants/colors.dart';

/// 极简背景 — 纯色底，无网格无光晕
///
/// 保持类名兼容旧代码，但实现已简化为纯 Container
class NexusBackground extends StatelessWidget {
  final Widget child;
  final bool showGlow;

  const NexusBackground({
    Key? key,
    required this.child,
    this.showGlow = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

/// HUD 角标 — 极简版，不再绘制装饰角标
class HudCorners extends StatelessWidget {
  final Widget child;
  final Color? color;

  const HudCorners({
    Key? key,
    required this.child,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
