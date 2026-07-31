import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/core/constants/strings.dart';
import 'package:buildself/features/home/screens/home_screen.dart';
import 'package:buildself/features/work/screens/work_list_screen.dart';
import 'package:buildself/features/life/screens/life_list_screen.dart';
import 'package:buildself/features/goal/screens/goal_board_screen.dart';
import 'package:buildself/features/reading/screens/bookshelf_screen.dart';

/// 主框架 — NEXUS 浮空玻璃胶囊导航
class MainScaffold extends StatefulWidget {
  const MainScaffold({Key? key}) : super(key: key);

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    WorkListScreen(),
    LifeListScreen(),
    GoalBoardScreen(),
    BookshelfScreen(),
  ];

  // 每个模块的视觉特征：图标 / 激活图标 / 颜色 / 标签
  static const List<_NavSpec> _specs = [
    _NavSpec(icon: Icons.home_outlined, activeIcon: Icons.home, label: AppStrings.tabHome, color: AppColors.primary),
    _NavSpec(icon: Icons.event_outlined, activeIcon: Icons.event, label: AppStrings.tabWork, color: AppColors.work),
    _NavSpec(icon: Icons.local_cafe_outlined, activeIcon: Icons.local_cafe, label: AppStrings.tabLife, color: AppColors.life),
    _NavSpec(icon: Icons.gps_fixed_outlined, activeIcon: Icons.gps_fixed, label: AppStrings.tabGoal, color: AppColors.goal),
    _NavSpec(icon: Icons.menu_book_outlined, activeIcon: Icons.menu_book, label: AppStrings.tabReading, color: AppColors.reading),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      // 让内容延伸到导航下方，增强浮空感
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _FloatingGlassNav(
        specs: _specs,
        currentIndex: _currentIndex,
        isDark: isDark,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

/// 浮空玻璃胶囊导航
class _FloatingGlassNav extends StatelessWidget {
  final List<_NavSpec> specs;
  final int currentIndex;
  final bool isDark;
  final ValueChanged<int> onTap;

  const _FloatingGlassNav({
    required this.specs,
    required this.currentIndex,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: _GlassCapsule(
          isDark: isDark,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(specs.length, (i) {
                return Expanded(
                  child: _NavTab(
                    spec: specs[i],
                    selected: i == currentIndex,
                    isDark: isDark,
                    onTap: () => onTap(i),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

/// 玻璃胶囊容器 — 渐变描边 + 模糊背景 + 向上光晕
class _GlassCapsule extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const _GlassCapsule({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // 外层渐变描边
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.glassStrokeDark, AppColors.glowCyan]
              : [AppColors.dividerLight, AppColors.primary.withOpacity(0.4)],
        ),
        boxShadow: [
          // 向上的青色光晕
          BoxShadow(
            color: AppColors.glowCyan,
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
          // 向下阴影
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.5 : 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.spaceHigh.withOpacity(0.78)
                  : Colors.white.withOpacity(0.82),
              borderRadius: BorderRadius.circular(26),
              // 顶部一条细高光线，增强玻璃质感
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(isDark ? 0.18 : 0.7),
                  width: 0.8,
                ),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// 单个导航项
class _NavTab extends StatelessWidget {
  final _NavSpec spec;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _NavTab({
    required this.spec,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unselectedColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final color = selected ? spec.color : unselectedColor;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顶部激活指示条 — 选中时显现并带光晕
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              width: selected ? 22 : 6,
              height: 3,
              decoration: BoxDecoration(
                color: selected ? spec.color : (isDark ? AppColors.dividerDark : AppColors.dividerLight),
                borderRadius: BorderRadius.circular(2),
                boxShadow: selected
                    ? [BoxShadow(color: spec.color.withOpacity(0.8), blurRadius: 8, spreadRadius: 0.5)]
                    : [],
              ),
            ),
            const SizedBox(height: 6),
            // 图标 — 选中时带光晕
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: selected
                  ? BoxDecoration(
                      color: spec.color.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: spec.color.withOpacity(0.35), blurRadius: 10)],
                    )
                  : null,
              child: Icon(
                selected ? spec.activeIcon : spec.icon,
                size: 20,
                color: color,
                shadows: selected
                    ? [Shadow(color: spec.color.withOpacity(0.8), blurRadius: 6)]
                    : null,
              ),
            ),
            const SizedBox(height: 4),
            // 标签
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
                letterSpacing: 0.5,
                fontFamily: 'NotoSansSC',
              ),
              child: Text(spec.label),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavSpec {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color color;

  const _NavSpec({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
  });
}
