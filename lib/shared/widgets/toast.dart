import 'package:flutter/material.dart';
import 'package:buildself/core/constants/colors.dart';

/// 轻量 Toast — 基于 Overlay 的淡入淡出提示
class ToastHelper {
  ToastHelper._();

  /// 在屏幕底部上方弹出一条 Toast，自动消失
  static void show(
    BuildContext context,
    String message, {
    IconData? icon,
    Color? color,
    Duration duration = const Duration(milliseconds: 1600),
  }) {
    final overlay = Overlay.of(context);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastOverlay(
        message: message,
        icon: icon,
        color: color,
        duration: duration,
        onDone: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

class _ToastOverlay extends StatefulWidget {
  final String message;
  final IconData? icon;
  final Color? color;
  final Duration duration;
  final VoidCallback onDone;

  const _ToastOverlay({
    required this.message,
    this.icon,
    this.color,
    required this.duration,
    required this.onDone,
  });

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<double> _translate;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _translate = Tween<double>(begin: 10, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _ctrl.forward();
    Future.delayed(widget.duration, () async {
      if (!mounted) return;
      await _ctrl.reverse();
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight;
    final fg = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Positioned(
      left: 24,
      right: 24,
      bottom: 96,
      child: IgnorePointer(
        child: Center(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) => Opacity(
              opacity: _opacity.value,
              child: Transform.translate(
                offset: Offset(0, _translate.value),
                child: child,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon,
                        color: widget.color ?? AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: fg,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
