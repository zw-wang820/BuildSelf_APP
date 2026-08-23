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
import 'package:buildself/data/repositories/work_repository.dart';
import 'package:buildself/data/repositories/murmur_repository.dart';
import 'package:buildself/data/models/goal_model.dart';
import 'package:buildself/data/models/reading_models.dart';
import 'package:buildself/data/models/enums.dart';
import 'package:buildself/features/todo/data/todo_repository.dart';
import 'package:buildself/features/todo/models/todo_model.dart';
import 'package:buildself/features/todo/widgets/todo_checkbox.dart';
import 'package:buildself/shared/widgets/toast.dart';

/// 首页 — 成长日报
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GoalRepository _goalRepo = GoalRepository();
  final ReadingRepository _readingRepo = ReadingRepository();
  final LifeRepository _lifeRepo = LifeRepository();
  final WorkRepository _workRepo = WorkRepository();
  final MurmurRepository _murmurRepo = MurmurRepository();

  // 进行中目标 — 列表（最多展示 3 条）
  List<Goal> _activeGoals = [];
  int _activeGoalCount = 0;
  bool _loadingGoals = true;

  // 待办 — 真实数据：_todos 为首页预览（最多 3 条），_todoCount 为未完成总数
  final TodoRepository _todoRepo = TodoRepository();
  List<Todo> _todos = [];
  bool _loadingTodos = true;
  int _todoCount = 0;
  // 习惯打卡 功能尚未实现，先以 0 占位。
  int _habitCount = 0;

  // 正在阅读（status = reading 的书籍，最多 3 条）
  List<Book> _readingBooks = [];
  bool _loadingReading = true;

  int _growthIndex = 0;
  int _streakDays = 0;
  int _weeklyActive = 0;
  bool _loadingIndex = true;

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
      _loadReading(userId),
      _loadGrowth(userId),
      _loadTodos(userId),
    ]);
  }

  Future<void> _loadGoals(String userId) async {
    try {
      final goals = await _goalRepo.getActiveGoals(userId);
      if (mounted) {
        setState(() {
          _activeGoals = goals;
          _activeGoalCount = goals.length;
          _loadingGoals = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingGoals = false);
    }
  }

  Future<void> _loadReading(String userId) async {
    try {
      final books =
          await _readingRepo.getAllBooks(userId, status: BookStatus.reading);
      if (mounted) {
        setState(() {
          _readingBooks = books.take(3).toList();
          _loadingReading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingReading = false);
    }
  }

  /// 加载首页待办预览（最多 3 条未完成）与未完成总数
  Future<void> _loadTodos(String userId) async {
    try {
      final todos = await _todoRepo.getAll(userId, completed: false, limit: 3);
      final count = await _todoRepo.getActiveCount(userId);
      if (mounted) {
        setState(() {
          _todos = todos;
          _todoCount = count;
          _loadingTodos = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingTodos = false);
    }
  }

  /// 打开待办列表页，返回后刷新预览与计数
  Future<void> _openTodoList() async {
    await Navigator.pushNamed(context, AppRoutes.todoList);
    if (mounted) {
      final userId = context.read<AppProvider>().userId;
      if (userId.isNotEmpty) _loadTodos(userId);
    }
  }

  /// 打开目标列表页，返回后刷新目标列表、数量与成长指数
  Future<void> _openGoalBoard() async {
    await Navigator.pushNamed(context, AppRoutes.goalBoard);
    if (mounted) {
      final userId = context.read<AppProvider>().userId;
      if (userId.isNotEmpty) {
        await _loadGoals(userId);
        await _loadGrowth(userId);
      }
    }
  }

  /// 打开书架，返回后刷新「正在阅读」预览
  Future<void> _openBookshelf() async {
    await Navigator.pushNamed(context, AppRoutes.bookshelf);
    if (mounted) {
      final userId = context.read<AppProvider>().userId;
      if (userId.isNotEmpty) _loadReading(userId);
    }
  }

  /// 首页勾选完成 — 落库后从预览移除并 Toast 反馈
  Future<void> _toggleTodoAtHome(Todo todo) async {
    final nowCompleted = !todo.isCompleted;
    if (nowCompleted) {
      await _todoRepo.markCompleted(todo.id);
    } else {
      await _todoRepo.markActive(todo.id);
    }
    if (!mounted) return;
    ToastHelper.show(
      context,
      nowCompleted ? '✅ 已完成' : '已恢复为待办',
      icon: nowCompleted ? Icons.check_circle : Icons.undo,
      color: nowCompleted ? AppColors.success : AppColors.info,
    );
    setState(() {
      _todos.removeWhere((t) => t.id == todo.id);
      final updated = _todoCount + (nowCompleted ? -1 : 1);
      _todoCount = updated < 0 ? 0 : updated;
    });
  }

  /// 成长指数 = 目标平均进度×0.4 + 周活跃度×0.4 + 连续天数×0.2（三者均归一 0-100）
  Future<void> _loadGrowth(String userId) async {
    try {
      final now = DateTime.now();
      final since = now.subtract(const Duration(days: 30));
      final results = await Future.wait<List<String>>([
        _goalRepo.getActiveDateStamps(userId, since),
        _readingRepo.getActiveDateStamps(userId, since),
        _workRepo.getActiveDateStamps(userId, since),
        _lifeRepo.getActiveDateStamps(userId, since),
        _murmurRepo.getActiveDateStamps(userId, since),
      ]);

      final daySet = <DateTime>{};
      for (final list in results) {
        for (final stamp in list) {
          daySet.add(DateTime.parse(stamp));
        }
      }

      final today = DateTime(now.year, now.month, now.day);
      // 连续天数：从今天往前数连续有记录的天数（今天无记录则从昨天起算）
      int streak = 0;
      var cursor = today;
      if (!daySet.contains(cursor)) {
        cursor = cursor.subtract(const Duration(days: 1));
      }
      while (daySet.contains(cursor)) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      }

      // 近 7 天活跃天数
      final weekStart = today.subtract(const Duration(days: 6));
      final weeklyActive =
          daySet.where((d) => !d.isBefore(weekStart)).length;

      // 进行中目标平均进度
      final goals = await _goalRepo.getActiveGoals(userId);
      final goalProgress = goals.isEmpty
          ? 0.0
          : goals.map((g) => g.calculatedProgress).reduce((a, b) => a + b) /
              goals.length;

      final weeklyNorm = (weeklyActive.clamp(0, 7) / 7) * 100;
      final streakNorm = (streak.clamp(0, 30) / 30) * 100;
      final index =
          (goalProgress * 0.4 + weeklyNorm * 0.4 + streakNorm * 0.2).round();

      if (mounted) {
        setState(() {
          _growthIndex = index;
          _streakDays = streak;
          _weeklyActive = weeklyActive;
          _loadingIndex = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingIndex = false);
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
              const SizedBox(height: 20),
              _buildHero(context),
              const SizedBox(height: 16),
              _buildDataStrip(context),
              const SizedBox(height: 20),
              _buildQuickRecords(context),
              const SizedBox(height: 24),
              _buildTodos(context),
              const SizedBox(height: 20),
              _buildActiveGoals(context),
              const SizedBox(height: 20),
              _buildReading(context),
              const SizedBox(height: 20),
              _buildReview(context),
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
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final dateStr =
        '${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')} '
        '${weekdays[now.weekday - 1]}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting，${AppStrings.explorer}',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary(context),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.search_outlined, size: 22),
              color: AppColors.primary,
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.search),
            ),
            const SizedBox(width: 4),
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.profileCenter),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/avatar.jpg',
                      fit: BoxFit.cover,
                      width: 40,
                      height: 40,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          AppStrings.appSlogan,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(context),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  /// 成长指数 hero 卡
  Widget _buildHero(BuildContext context) {
    final value = _growthIndex.clamp(0, 100) / 100;
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('今日成长指数',
              style: TextStyle(fontSize: 13, color: Colors.white70)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_loadingIndex)
                const SizedBox(
                  width: 64,
                  height: 34,
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              else
                Text('$_growthIndex',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1,
                    )),
              if (!_loadingIndex) ...[
                const SizedBox(width: 6),
                const Padding(
                  padding: EdgeInsets.only(bottom: 5),
                  child: Text('/ 100',
                      style: TextStyle(fontSize: 13, color: Colors.white60)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _loadingIndex
                ? '正在计算你的成长…'
                : '近7天活跃 $_weeklyActive 天 · 进行中 $_activeGoalCount 个 · 连续 $_streakDays 天',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  /// 成长数据条 — hero 下方三张数据卡
  /// 待办已接入真实数据；习惯打卡暂以 0 占位
  Widget _buildDataStrip(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.checklist_outlined,
            label: '待办',
            value: _todoCount,
            color: AppColors.todo,
            onTap: _openTodoList,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.gps_fixed,
            label: '进行中目标',
            value: _activeGoalCount,
            color: AppColors.goal,
            onTap: _openGoalBoard,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.repeat_outlined,
            label: '习惯打卡',
            value: _habitCount,
            color: AppColors.habit,
          ),
        ),
      ],
    );
  }

  /// 单张数据卡 — 图标 + 大数字 + 标签
  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return AppCard(
      accent: color,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 快捷记录入口 — 四模块场景色
  Widget _buildQuickRecords(BuildContext context) {
    final entries = [
      _QuickEntry(
          icon: Icons.event_outlined,
          label: AppStrings.tabWork,
          color: AppColors.work,
          route: AppRoutes.workEdit),
      _QuickEntry(
          icon: Icons.local_cafe_outlined,
          label: AppStrings.tabLife,
          color: AppColors.life,
          route: AppRoutes.lifeEdit),
      _QuickEntry(
          icon: Icons.menu_book_outlined,
          label: AppStrings.tabReading,
          color: AppColors.reading,
          route: AppRoutes.bookshelf),
      _QuickEntry(
          icon: Icons.auto_awesome,
          label: AppStrings.murmurTitle,
          color: AppColors.murmur,
          route: AppRoutes.murmur),
    ];

    return Row(
      children: entries.map((e) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AppCard(
              accent: e.color,
              onTap: () => Navigator.pushNamed(context, e.route),
              padding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: e.color.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(e.icon, color: e.color, size: 22),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    e.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: e.color,
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

  /// 今日待办
  Widget _buildTodos(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          icon: Icons.checklist_outlined,
          label: '今日待办',
          accent: AppColors.todo,
          actionLabel: '查看全部',
          onAction: _openTodoList,
        ),
        const SizedBox(height: 10),
        AppCard(
          accent: AppColors.todo,
          onTap: null,
          child: _buildTodoContent(),
        ),
      ],
    );
  }

  /// 今日待办内容 — 预览进行中的待办（最多 3 条），点击复选框可直接勾选完成
  Widget _buildTodoContent() {
    if (_loadingTodos) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
            child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    if (_todos.isEmpty) {
      return _buildEmptyState(
        icon: Icons.checklist_outlined,
        color: AppColors.todo,
        text: '今日还没有待办',
        hint: '去待办清单添加，开始清空列表',
      );
    }
    return Column(
      children: List.generate(_todos.length, (i) {
        final todo = _todos[i];
        final isLast = i == _todos.length - 1;
        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
          child: _buildTodoRow(todo),
        );
      }),
    );
  }

  /// 首页待办单行 — 优先级色条 + 圆形复选框 + 内容 + 截止
  Widget _buildTodoRow(Todo todo) {
    final priColor = todo.priority.color;
    return Row(
      children: [
        Container(
          width: 3,
          height: 26,
          decoration: BoxDecoration(
            color: priColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        TodoCheckbox(
          value: todo.isCompleted,
          activeColor: priColor,
          size: 22,
          onChanged: (_) => _toggleTodoAtHome(todo),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            todo.content,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary(context),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          todo.dueLabel,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary(context),
          ),
        ),
      ],
    );
  }

  /// 进行中的目标 — 列表（最多 3 条）
  Widget _buildActiveGoals(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          icon: Icons.gps_fixed,
          label: AppStrings.activeGoals,
          accent: AppColors.goal,
          actionLabel: '全部目标',
          onAction: _openGoalBoard,
        ),
        const SizedBox(height: 10),
        AppCard(
          accent: AppColors.goal,
          onTap: _openGoalBoard,
          child: _buildGoalContent(),
        ),
      ],
    );
  }

  Widget _buildGoalContent() {
    if (_loadingGoals) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
            child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    if (_activeGoals.isEmpty) {
      return _buildEmptyState(
        icon: Icons.gps_fixed,
        color: AppColors.goal,
        text: '还没有进行中的目标',
        hint: '添加目标，开始你的成长之旅',
      );
    }

    final shown = _activeGoals.take(3).toList();
    return Column(
      children: List.generate(shown.length, (i) {
        final goal = shown[i];
        final isLast = i == shown.length - 1;
        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
          child: _buildGoalRow(goal),
        );
      }),
    );
  }

  Widget _buildGoalRow(Goal goal) {
    final progress = (goal.calculatedProgress / 100).clamp(0.0, 1.0);
    final typeColor = goal.goalType == GoalType.shortTerm
        ? AppColors.goalShort
        : goal.goalType == GoalType.midTerm
            ? AppColors.goalMid
            : AppColors.goalLong;
    final typeLabel = goal.goalType.label;
    final days = goal.targetDate == null
        ? '—'
        : goal.targetDate!
            .difference(DateTime.now())
            .inDays
            .toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                goal.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$typeLabel · 剩余$days天',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildProgressBar(progress, typeColor),
      ],
    );
  }

  /// 进度条 — 简洁填充
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
                    decoration: BoxDecoration(color: color),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 正在阅读
  Widget _buildReading(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          icon: Icons.menu_book_outlined,
          label: '正在阅读',
          accent: AppColors.reading,
          actionLabel: '查看全部',
          onAction: _openBookshelf,
        ),
        const SizedBox(height: 10),
        AppCard(
          accent: AppColors.reading,
          onTap: _openBookshelf,
          child: _buildReadingContent(),
        ),
      ],
    );
  }

  Widget _buildReadingContent() {
    if (_loadingReading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
            child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    if (_readingBooks.isEmpty) {
      return _buildEmptyState(
        icon: Icons.menu_book_outlined,
        color: AppColors.reading,
        text: '还没有在读的书',
        hint: '去书架添加一本正在读的书',
      );
    }

    return Column(
      children: List.generate(_readingBooks.length, (i) {
        final book = _readingBooks[i];
        final isLast = i == _readingBooks.length - 1;
        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
          child: _buildBookRow(book, i),
        );
      }),
    );
  }

  Widget _buildBookRow(Book book, int index) {
    final gradient =
        AppColors.bookCovers[index % AppColors.bookCovers.length];
    return Row(
      children: [
        Container(
          width: 36,
          height: 50,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.menu_book, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                book.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                book.author ?? '佚名',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 今日复盘
  Widget _buildReview(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          icon: Icons.auto_awesome,
          label: '今日复盘',
          accent: AppColors.accent,
          actionLabel: '开始复盘',
          onAction: () {},
        ),
        const SizedBox(height: 10),
        AppCard(
          accent: AppColors.accent,
          onTap: null,
          child: _buildReviewContent(),
        ),
      ],
    );
  }

  /// 今日复盘内容 — 数据模型未建，先以空态呈现
  Widget _buildReviewContent() {
    return _buildEmptyState(
      icon: Icons.auto_awesome,
      color: AppColors.accent,
      text: '今日还没有复盘',
      hint: '回顾今天的成长与反思',
    );
  }

  /// 通用空态 — 图标 + 标题 + 提示
  Widget _buildEmptyState({
    required IconData icon,
    required Color color,
    required String text,
    required String hint,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hint,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 区块标题
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
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: accent),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary(context),
          ),
        ),
        const Spacer(),
        if (actionLabel != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(actionLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: accent,
                        fontWeight: FontWeight.w600,
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

  _QuickEntry(
      {required this.icon,
      required this.label,
      required this.color,
      required this.route});
}
