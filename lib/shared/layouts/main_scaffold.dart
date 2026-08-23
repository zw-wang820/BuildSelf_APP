import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/core/constants/strings.dart';
import 'package:buildself/features/home/screens/home_screen.dart';
import 'package:buildself/features/work/screens/work_list_screen.dart';
import 'package:buildself/features/life/screens/life_list_screen.dart';
import 'package:buildself/features/goal/screens/goal_board_screen.dart';
import 'package:buildself/features/reading/screens/bookshelf_screen.dart';

/// 主框架 — 毛玻璃底栏导航（Kimi 风格）
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

  List<_NavSpec> get _specs => [
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
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _GlassBottomNav(
        specs: _specs,
        currentIndex: _currentIndex,
        isDark: isDark,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

/// 毛玻璃底栏 — 半透明 + 背景模糊 + 选中项上移高亮
class _GlassBottomNav extends StatelessWidget {
  final List<_NavSpec> specs;
  final int currentIndex;
  final bool isDark;
  final ValueChanged<int> onTap;

  const _GlassBottomNav({
    required this.specs,
    required this.currentIndex,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = (isDark ? AppColors.surfaceDark : Colors.white).withValues(alpha: 0.82);
    final divider = isDark ? AppColors.dividerDark : AppColors.dividerLight;
    final unselectedColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            border: Border(
              top: BorderSide(color: divider.withValues(alpha: 0.6), width: 0.5),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 58,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(specs.length, (i) {
                  final spec = specs[i];
                  final selected = i == currentIndex;
                  final color = selected ? spec.color : unselectedColor;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onTap(i),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            transform: Matrix4.translationValues(0, selected ? -2.0 : 0, 0),
                            child: Icon(
                              selected ? spec.activeIcon : spec.icon,
                              size: selected ? 24 : 22,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            spec.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
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

  _NavSpec({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
  });
}

/// 底栏高度常量（供 FAB 定位用）
const double kFloatingGlassNavHeight = 80;

/// FAB 位置：底栏右上方
class FloatingAboveNavLocation extends FloatingActionButtonLocation {
  const FloatingAboveNavLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double fabX = scaffoldGeometry.scaffoldSize.width -
        scaffoldGeometry.floatingActionButtonSize.width -
        kFloatingActionButtonMargin;
    final double fabY = scaffoldGeometry.scaffoldSize.height -
        scaffoldGeometry.floatingActionButtonSize.height -
        scaffoldGeometry.minInsets.bottom -
        kFloatingGlassNavHeight -
        8;
    return Offset(fabX, fabY);
  }
}
