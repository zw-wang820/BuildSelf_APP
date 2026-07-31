import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/core/constants/strings.dart';
import 'package:buildself/core/router/routes.dart';
import 'package:buildself/shared/widgets/app_card.dart';
import 'package:buildself/shared/widgets/nexus_background.dart';
import 'package:buildself/features/auth/providers/app_provider.dart';
import 'package:buildself/data/repositories/goal_repository.dart';
import 'package:buildself/data/repositories/reading_repository.dart';
import 'package:buildself/data/repositories/life_repository.dart';
import 'package:buildself/data/models/goal_model.dart';
import 'package:buildself/data/models/reading_models.dart';
import 'package:buildself/data/models/life_record_model.dart';

/// 首页 — NEXUS 成长指挥台
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GoalRepository _goalRepo = GoalRepository();
  final ReadingRepository _readingRepo = ReadingRepository();
  final LifeRepository _lifeRepo = LifeRepository();

  Goal? _firstGoal;
  ReadingNote? _firstChange;
  LifeRecord? _firstHistory;
  bool _loadingGoals = true;
  bool _loadingChanges = true;
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = context.read<AppProvider>().userId;
    if (userId.isEmpty) return;

    await Future.wait([
      _loadGoals(userId),
      _loadChanges(userId),
      _loadHistory(userId),
    ]);
  }

  Future<void> _loadGoals(String userId) async {
    try {
      final goals = await _goalRepo.getActiveGoals(userId);
      if (mounted) {
        setState(() {
          _firstGoal = goals.isNotEmpty ? goals.first : null;
          _loadingGoals = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingGoals = false);
    }
  }

  Future<void> _loadChanges(String userId) async {
    try {
      final changes = await _readingRepo.getAllChanges(userId);
      if (mounted) {
        setState(() {
          _firstChange = changes.isNotEmpty ? changes.first : null;
          _loadingChanges = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingChanges = false);
    }
  }

  Future<void> _loadHistory(String userId) async {
    try {
      final records = await _lifeRepo.getTodayInHistory(userId, DateTime.now());
      if (mounted) {
        setState(() {
          _firstHistory = records.isNotEmpty ? records.first : null;
          _loadingHistory = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NexusBackground(
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 22),
              _buildSystemStatus(context),
              const SizedBox(height: 22),
              _buildQuickRecords(context),
              const SizedBox(height: 24),
              _buildActiveGoals(context),
              const SizedBox(height: 20),
              _buildRecentChanges(context),
              const SizedBox(height: 20),
              _buildTodayInHistory(context),
            ],
          ),
        ),
      ),
    );
  }

  /// 顶部问候 + 操作
  Widget _buildHeader(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = AppStrings.goodMorning;
    } else if (hour < 18) {
      greeting = AppStrings.goodAfternoon;
    } else {
      greeting = AppStrings.goodEvening;
    }

    final now = DateTime.now();
    final dateStr = '${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HUD 日期行
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppColors.accent, blurRadius: 6)],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$dateStr  ·  SYSTEM ONLINE',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                      letterSpacing: 2,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '$greeting，探索者',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                  letterSpacing: 0.3,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
        _buildHeaderButton(Icons.search_outlined, () => Navigator.pushNamed(context, AppRoutes.search)),
        const SizedBox(width: 8),
        _buildHeaderButton(Icons.settings_outlined, () => Navigator.pushNamed(context, AppRoutes.settings)),
      ],
    );
  }

  Widget _buildHeaderButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.spaceHigh.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.dividerDark, width: 0.8),
        ),
        child: Icon(icon, size: 20, color: AppColors.primary),
      ),
    );
  }

  /// 系统状态卡片 — 今日成长概览 HUD
  Widget _buildSystemStatus(BuildContext context) {
    return AppCard(
      glow: true,
      accent: AppColors.primary,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              const Text(
                'GROWTH METRICS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 2,
                  fontFamily: 'monospace',
                ),
              ),
              const Spacer(),
              _buildLiveDot(),
            ],
          ),
          const SizedBox(height: 14),
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [AppColors.primaryLight, AppColors.accent],
            ).createShader(b),
            child: const Text(
              AppStrings.appSlogan,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '像建设新中国一样建设自己 — 每一次记录都是一块基石。',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondaryDark,
              height: 1.6,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveDot() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: AppColors.accent, blurRadius: 6)],
          ),
        ),
        const SizedBox(width: 5),
        const Text(
          'LIVE',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: AppColors.accent,
            letterSpacing: 1.5,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  /// 快捷记录入口 — 三色霓虹按钮
  Widget _buildQuickRecords(BuildContext context) {
    final entries = [
      _QuickEntry(icon: Icons.event_outlined, label: AppStrings.tabWork, color: AppColors.work, route: AppRoutes.workEdit),
      _QuickEntry(icon: Icons.local_cafe_outlined, label: '生活', color: AppColors.life, route: AppRoutes.lifeEdit),
      _QuickEntry(icon: Icons.auto_awesome, label: '碎碎念', color: AppColors.murmur, route: AppRoutes.murmur),
    ];

    return Row(
      children: entries.map((e) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AppCard(
              accent: e.color,
              onTap: () => Navigator.pushNamed(context, e.route),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
              child: Column(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: e.color.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: e.color.withOpacity(0.45), width: 0.8),
                      boxShadow: [BoxShadow(color: e.color.withOpacity(0.3), blurRadius: 12)],
                    ),
                    child: Icon(e.icon, color: e.color, size: 22, shadows: [
                      Shadow(color: e.color.withOpacity(0.8), blurRadius: 6),
                    ]),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    e.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: e.color,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 进行中的目标
  Widget _buildActiveGoals(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          icon: Icons.gps_fixed,
          label: AppStrings.activeGoals,
          accent: AppColors.goal,
          actionLabel: '全部',
          onAction: () => Navigator.pushNamed(context, AppRoutes.goalBoard),
        ),
        const SizedBox(height: 10),
        AppCard(
          accent: AppColors.goal,
          onTap: () => Navigator.pushNamed(context, AppRoutes.goalBoard),
          child: _buildGoalContent(),
        ),
      ],
    );
  }

  Widget _buildGoalContent() {
    if (_loadingGoals) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    final goal = _firstGoal;
    if (goal == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('暂无进行中的目标',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondaryDark, letterSpacing: 0.3)),
          const SizedBox(height: 12),
          _buildProgressBar(0, AppColors.goal),
        ],
      );
    }

    final progress = goal.calculatedProgress / 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.goal.withOpacity(0.16),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.goal.withOpacity(0.5), width: 0.6),
              ),
              child: Text('ACTIVE',
                  style: TextStyle(
                    fontSize: 9,
                    color: AppColors.goal,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    fontFamily: 'monospace',
                  )),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(goal.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        if (goal.description.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(goal.description,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark, height: 1.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
        const SizedBox(height: 14),
        _buildProgressBar(progress.clamp(0.0, 1.0), AppColors.goal),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              '${goal.calculatedProgress}%',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.goal,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            Icon(Icons.card_giftcard, size: 12, color: AppColors.textSecondaryDark),
            const SizedBox(width: 4),
            Text(goal.reward.description,
                style: TextStyle(fontSize: 11, color: AppColors.textSecondaryDark, letterSpacing: 0.2)),
          ],
        ),
      ],
    );
  }

  /// 数据条样式进度条 — 渐变填充 + 光晕
  Widget _buildProgressBar(double value, Color color) {
    final v = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 6,
        child: LayoutBuilder(
          builder: (context, c) {
            return Stack(
              fit: StackFit.expand,
              children: [
                Container(color: AppColors.dividerDark),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: c.maxWidth * v,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [color.withOpacity(0.6), color]),
                      boxShadow: [BoxShadow(color: color.withOpacity(0.6), blurRadius: 6)],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 近期改变
  Widget _buildRecentChanges(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          icon: Icons.menu_book_outlined,
          label: AppStrings.recentChanges,
          accent: AppColors.reading,
        ),
        const SizedBox(height: 10),
        AppCard(
          accent: AppColors.reading,
          onTap: () => Navigator.pushNamed(context, AppRoutes.bookshelf),
          child: _buildChangeContent(),
        ),
      ],
    );
  }

  Widget _buildChangeContent() {
    if (_loadingChanges) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    final change = _firstChange;
    if (change == null) {
      return Text('暂无阅读改变记录',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondaryDark, letterSpacing: 0.3));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.reading,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [BoxShadow(color: AppColors.reading.withOpacity(0.7), blurRadius: 4)],
              ),
            ),
            const SizedBox(width: 8),
            Text('CHANGE LOG',
                style: TextStyle(
                  fontSize: 9,
                  color: AppColors.reading,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  fontFamily: 'monospace',
                )),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          change.content,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimaryDark, height: 1.6),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (change.chapter != null) ...[
          const SizedBox(height: 6),
          Text(change.chapter!,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark, letterSpacing: 0.2)),
        ],
      ],
    );
  }

  /// 往日今日
  Widget _buildTodayInHistory(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          icon: Icons.history,
          label: AppStrings.todayInHistory,
          accent: AppColors.life,
        ),
        const SizedBox(height: 10),
        AppCard(
          accent: AppColors.life,
          onTap: () => Navigator.pushNamed(context, AppRoutes.lifeList),
          child: _buildHistoryContent(),
        ),
      ],
    );
  }

  Widget _buildHistoryContent() {
    if (_loadingHistory) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    final record = _firstHistory;
    if (record == null) {
      return Text('暂无历史记录',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondaryDark, letterSpacing: 0.3));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.life,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [BoxShadow(color: AppColors.life.withOpacity(0.7), blurRadius: 4)],
              ),
            ),
            const SizedBox(width: 8),
            Text('ARCHIVE',
                style: TextStyle(
                  fontSize: 9,
                  color: AppColors.life,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  fontFamily: 'monospace',
                )),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          record.content,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimaryDark, height: 1.6),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Text(
          '${record.createdAt.year}.${record.createdAt.month.toString().padLeft(2, '0')}.${record.createdAt.day.toString().padLeft(2, '0')}',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondaryDark,
            fontFamily: 'monospace',
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  /// 区块标题 — HUD 风格
  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color accent,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: accent.withOpacity(0.14),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: accent.withOpacity(0.45), width: 0.8),
          ),
          child: Icon(icon, size: 16, color: accent),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryDark,
            letterSpacing: 0.3,
          ),
        ),
        const Spacer(),
        if (actionLabel != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: accent.withOpacity(0.35), width: 0.6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(actionLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: accent,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      )),
                  const SizedBox(width: 2),
                  Icon(Icons.chevron_right, size: 14, color: accent),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _QuickEntry {
  final IconData icon;
  final String label;
  final Color color;
  final String route;

  _QuickEntry({required this.icon, required this.label, required this.color, required this.route});
}
