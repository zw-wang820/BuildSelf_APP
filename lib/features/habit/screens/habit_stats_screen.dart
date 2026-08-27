import 'package:flutter/material.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/core/utils/lunar.dart';
import 'package:buildself/features/habit/data/habit_repository.dart';
import 'package:buildself/features/habit/models/habit_model.dart';
import 'package:buildself/shared/widgets/nexus_background.dart';
import 'package:buildself/shared/widgets/toast.dart';

/// 习惯打卡日历页 — 单习惯打卡记录月历 + 统计摘要
///
/// 路由参数：habitId。月历支持月份切换、点击补卡/取消（未来日期不可点）。
class HabitStatsScreen extends StatefulWidget {
  final String habitId;

  const HabitStatsScreen({Key? key, required this.habitId}) : super(key: key);

  @override
  State<HabitStatsScreen> createState() => _HabitStatsScreenState();
}

class _HabitStatsScreenState extends State<HabitStatsScreen> {
  final _repo = HabitRepository();
  Habit? _habit;
  Set<String> _dates = {};
  bool _loading = true;

  /// 当前展示的月份（年 + 月，日恒为 1）
  late DateTime _displayMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayMonth = DateTime(now.year, now.month);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final habit = await _repo.getById(widget.habitId);
      final dates = await _repo.getLogsByHabitId(widget.habitId);
      if (mounted) {
        setState(() {
          _habit = habit;
          _dates = dates;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color get _color =>
      kHabitPalette[(_habit?.colorIndex ?? 0) % kHabitPalette.length];

  // ==================== 统计 ====================

  int get _monthCount {
    final prefix = '${_displayMonth.year}-'
        '${_displayMonth.month.toString().padLeft(2, '0')}';
    return _dates.where((d) => d.startsWith(prefix)).length;
  }

  int get _totalCount => _dates.length;

  int get _streak => HabitRepository.streakOf(_dates);

  // ==================== 月份切换 ====================

  bool get _canNext {
    final now = DateTime.now();
    return DateTime(_displayMonth.year, _displayMonth.month)
        .isBefore(DateTime(now.year, now.month));
  }

  void _prevMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1);
    });
  }

  void _nextMonth() {
    if (!_canNext) return;
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1);
    });
  }

  // ==================== 日期点击：补卡 / 取消 ====================

  Future<void> _onDayTap(DateTime date) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (date.isAfter(today)) return; // 未来日期不可点

    final ds = HabitRepository.fmtDate(date);
    final checked = _dates.contains(ds);

    if (checked) {
      // 取消打卡 — 二次确认
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('取消打卡'),
          content: Text('确定取消 ${date.month}月${date.day}日 的打卡吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('再想想'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('取消打卡'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
      await _repo.toggle(widget.habitId, date);
      if (!mounted) return;
      ToastHelper.show(context, '已取消 ${date.month}月${date.day}日 打卡');
    } else {
      // 直接补卡
      await _repo.toggle(widget.habitId, date);
      if (!mounted) return;
      ToastHelper.show(context, '✅ 已补上 ${date.month}月${date.day}日');
    }
    await _loadData();
  }

  // ==================== UI ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_habit?.icon ?? ''} ${_habit?.name ?? '打卡日历'}'),
      ),
      body: NexusBackground(
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    _buildStats(context),
                    const SizedBox(height: 20),
                    _buildCalendar(context),
                    const SizedBox(height: 14),
                    Text(
                      '● 已打卡 · 格子下方为农历 · 点击日期可补卡/取消 · 未来不可选',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  /// 统计摘要三卡 — 本月打卡 / 连续打卡 / 累计打卡
  Widget _buildStats(BuildContext context) {
    final color = _color;
    return Row(
      children: [
        _buildStatCard(context, Icons.calendar_month_outlined, '$_monthCount',
            '本月打卡', color),
        const SizedBox(width: 10),
        _buildStatCard(context, Icons.local_fire_department, '$_streak',
            '连续打卡', AppColors.goalShort),
        const SizedBox(width: 10),
        _buildStatCard(context, Icons.done_all, '$_totalCount', '累计打卡',
            AppColors.todo),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// 月历 — 月份切换 + 周表头 + 7 列网格
  Widget _buildCalendar(BuildContext context) {
    final daysInMonth =
        DateTime(_displayMonth.year, _displayMonth.month + 1, 0).day;
    final firstWeekday =
        DateTime(_displayMonth.year, _displayMonth.month, 1).weekday; // 1=周一
    final leadingBlanks = firstWeekday - 1;
    final totalCells = ((leadingBlanks + daysInMonth) / 7).ceil() * 7;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Column(
      children: [
        // 月份切换头部
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: _prevMonth,
              icon: const Icon(Icons.chevron_left),
              color: AppColors.textPrimary(context),
            ),
            SizedBox(
              width: 110,
              child: Text(
                '${_displayMonth.year}年${_displayMonth.month}月',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ),
            IconButton(
              onPressed: _canNext ? _nextMonth : null,
              icon: const Icon(Icons.chevron_right),
              color: AppColors.textPrimary(context),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // 周表头
        Row(
          children: ['一', '二', '三', '四', '五', '六', '日'].map((w) {
            return Expanded(
              child: Center(
                child: Text(
                  w,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        // 日期网格
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
          ),
          itemCount: totalCells,
          itemBuilder: (context, i) {
            final day = i - leadingBlanks + 1;
            if (day < 1 || day > daysInMonth) {
              return const SizedBox.shrink();
            }
            final date =
                DateTime(_displayMonth.year, _displayMonth.month, day);
            final ds = HabitRepository.fmtDate(date);
            final checked = _dates.contains(ds);
            final isToday = date == today;
            final isFuture = date.isAfter(today);
            return _buildDayCell(
                context, date, day, checked, isToday, isFuture);
          },
        ),
      ],
    );
  }

  /// 日期格 — 阳历数字 + 农历小字；打卡日习惯色圆底
  Widget _buildDayCell(
    BuildContext context,
    DateTime date,
    int day,
    bool checked,
    bool isToday,
    bool isFuture,
  ) {
    final color = _color;
    final lunarLabel = lunarDayLabel(date);
    final baseColor = isFuture
        ? AppColors.textSecondary(context).withValues(alpha: 0.4)
        : AppColors.textPrimary(context);
    return GestureDetector(
      onTap: isFuture ? null : () => _onDayTap(date),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: checked
              ? color
              : (isToday ? color.withValues(alpha: 0.12) : Colors.transparent),
          border: isToday ? Border.all(color: color, width: 1.4) : null,
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1,
                color: checked ? Colors.white : baseColor,
              ),
            ),
            if (lunarLabel != null) ...[
              const SizedBox(height: 2),
              Text(
                lunarLabel,
                style: TextStyle(
                  fontSize: 8.5,
                  height: 1,
                  color: checked
                      ? Colors.white.withValues(alpha: 0.85)
                      : AppColors.textSecondary(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
