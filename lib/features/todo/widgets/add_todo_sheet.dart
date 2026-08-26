import 'package:flutter/material.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/features/todo/data/todo_repository.dart';
import 'package:buildself/features/todo/models/todo_category_info.dart';
import 'package:buildself/features/todo/models/todo_model.dart';
import 'package:buildself/shared/widgets/gradient_button.dart';
import 'package:buildself/shared/widgets/toast.dart';

/// 新建分类候选 emoji
const List<String> categoryEmojis = [
  '💼', '🌿', '📖', '📚', '🏃', '💪', '📌', '⭐', '🎯', '✈️', '💻', '🎨',
];

/// 弹出「新建分类」底部表单 — 名称 + emoji 选择，颜色自动分配
/// 创建成功调用 [onCreated] 并关闭；重名时 Toast 提示
Future<void> showAddCategorySheet(
  BuildContext context, {
  required String userId,
  required TodoRepository repository,
  required ValueChanged<TodoCategoryInfo> onCreated,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddCategorySheet(
      userId: userId,
      repository: repository,
      onCreated: onCreated,
    ),
  );
}

/// 新建分类表单
class _AddCategorySheet extends StatefulWidget {
  final String userId;
  final TodoRepository repository;
  final ValueChanged<TodoCategoryInfo> onCreated;

  const _AddCategorySheet({
    required this.userId,
    required this.repository,
    required this.onCreated,
  });

  @override
  State<_AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<_AddCategorySheet> {
  final _nameCtrl = TextEditingController();
  String _emoji = categoryEmojis.first;
  bool _creating = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ToastHelper.show(context, '请输入分类名称', icon: Icons.info_outline);
      return;
    }
    if (_creating) return;
    setState(() => _creating = true);
    final info = await widget.repository
        .addCustomCategory(widget.userId, name: name, emoji: _emoji);
    if (!mounted) return;
    if (info == null) {
      ToastHelper.show(context, '该分类已存在', icon: Icons.error_outline);
      setState(() => _creating = false);
      return;
    }
    widget.onCreated(info);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final divider = isDark ? AppColors.dividerDark : AppColors.dividerLight;
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '新建分类',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _nameCtrl,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: '分类名称',
                hintText: '如：健身、重要',
                counterText: '',
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _create(),
            ),
            const SizedBox(height: 14),
            Text(
              '选择图标',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary(context),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: categoryEmojis.map((e) {
                final selected = _emoji == e;
                return GestureDetector(
                  onTap: () => setState(() => _emoji = e),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.14)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? AppColors.primary : divider,
                        width: selected ? 1.4 : 1,
                      ),
                    ),
                    child: Text(e, style: const TextStyle(fontSize: 18)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            GradientButton(
              label: _creating ? '创建中…' : '创建分类',
              icon: Icons.add,
              onPressed: _creating ? null : _create,
            ),
          ],
        ),
      ),
    );
  }
}

/// 弹出「新建待办」底部表单
///
/// 创建成功后调用 [onCreated] 并关闭表单
Future<void> showAddTodoSheet(
  BuildContext context, {
  required String userId,
  required TodoRepository repository,
  required ValueChanged<Todo> onCreated,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddTodoSheet(
      userId: userId,
      repository: repository,
      onCreated: onCreated,
    ),
  );
}

/// 弹出「编辑待办」底部表单
///
/// 保存成功后调用 [onUpdated] 并关闭表单
Future<void> showEditTodoSheet(
  BuildContext context, {
  required TodoRepository repository,
  required Todo todo,
  required ValueChanged<Todo> onUpdated,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddTodoSheet(
      repository: repository,
      todo: todo,
      onUpdated: onUpdated,
    ),
  );
}

class _AddTodoSheet extends StatefulWidget {
  final String userId;
  final TodoRepository repository;
  final ValueChanged<Todo>? onCreated;
  final Todo? todo; // 非空 = 编辑模式
  final ValueChanged<Todo>? onUpdated;

  const _AddTodoSheet({
    this.userId = '',
    required this.repository,
    this.onCreated,
    this.todo,
    this.onUpdated,
  });

  bool get isEdit => todo != null;

  @override
  State<_AddTodoSheet> createState() => _AddTodoSheetState();
}

class _AddTodoSheetState extends State<_AddTodoSheet> {
  final _contentCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  /// 当前分类名（内置枚举名 或 自定义分类名）
  String _category = TodoCategory.work.name;
  TodoPriority _priority = TodoPriority.medium;
  TodoDueType _dueType = TodoDueType.today;
  DateTime? _customDueDate;
  bool _creating = false;

  // 自定义分类
  List<TodoCategoryInfo> _customCategories = [];

  // 重复设置
  TodoRepeatType _repeatType = TodoRepeatType.none;
  int _repeatInterval = 1;
  Set<int> _repeatWeekdays = {DateTime.now().weekday};
  bool _repeatEndByCount = false; // 终止方式：按次数
  int _repeatCountValue = 5;
  bool _repeatEndByDate = false; // 终止方式：按日期
  DateTime? _repeatEndDate;

  /// 当前用户 id（新建传参；编辑取待办自身的 userId）
  String get _userId =>
      widget.userId.isNotEmpty ? widget.userId : (widget.todo?.userId ?? '');

  bool get _isRepeat => _repeatType != TodoRepeatType.none;

  /// 加载自定义分类；编辑时若当前分类已不存在（被删）则回退「工作」
  Future<void> _loadCustomCategories() async {
    final uid = _userId;
    if (uid.isEmpty) return;
    final list = await widget.repository.getCustomCategories(uid);
    if (!mounted) return;
    setState(() {
      _customCategories = list;
      if (widget.todo != null &&
          !_isValidCategory(_category) &&
          !list.any((c) => c.name == _category)) {
        _category = TodoCategory.work.name;
      }
    });
  }

  bool _isValidCategory(String name) =>
      TodoCategory.values.any((c) => c.name == name);

  /// 依据表单组装重复规则（不重复返回 null）
  TodoRepeat? _buildRepeat() {
    if (!_isRepeat) return null;
    return TodoRepeat(
      type: _repeatType,
      interval: _repeatInterval,
      weekdays:
          _repeatType == TodoRepeatType.weekly ? _repeatWeekdays : const {},
      maxCount: _repeatEndByCount ? _repeatCountValue : null,
      endDate: _repeatEndByDate ? _repeatEndDate : null,
    );
  }

  Future<void> _pickRepeatEndDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _repeatEndDate ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 3650)),
      helpText: '选择重复结束日期',
    );
    if (picked == null) return;
    if (mounted) {
      setState(() {
        _repeatEndByDate = true;
        _repeatEndDate = picked;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    final t = widget.todo;
    if (t != null) {
      _contentCtrl.text = t.content;
      _noteCtrl.text = t.note;
      _category = t.category;
      _priority = t.priority;
      _dueType = t.dueType;
      _customDueDate = t.dueDate;
      // 相对截止（今天/明天/后天）已不再匹配当前日期时，回退为"自定义"原日期，
      // 避免保存时被 _resolveDueDate 按今天重算导致截止日期被篡改
      final d = t.dueDate;
      if (d != null && t.dueType != TodoDueType.custom) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final dueDay = DateTime(d.year, d.month, d.day);
        final diff = dueDay.difference(today).inDays;
        if (diff < 0 || diff > 2) {
          _dueType = TodoDueType.custom;
        }
      }
      final r = t.repeat;
      if (r != null && !r.isNone) {
        _repeatType = r.type;
        _repeatInterval = r.interval;
        if (r.weekdays.isNotEmpty) _repeatWeekdays = {...r.weekdays};
        if (r.maxCount != null) {
          _repeatEndByCount = true;
          _repeatCountValue = r.maxCount!;
        } else if (r.endDate != null) {
          _repeatEndByDate = true;
          _repeatEndDate = r.endDate;
        }
      }
    }
    _loadCustomCategories();
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  /// 依据所选类型计算截止日期（今天/明天/后天取当日零点，自定义取所选日期）
  DateTime? _resolveDueDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_dueType) {
      case TodoDueType.today:
        return today;
      case TodoDueType.tomorrow:
        return today.add(const Duration(days: 1));
      case TodoDueType.dayAfter:
        return today.add(const Duration(days: 2));
      case TodoDueType.custom:
        return _customDueDate;
    }
  }

  /// 创建时间展示文案：今天/昨天 HH:mm；同年 MM/DD HH:mm；跨年 YYYY/MM/DD HH:mm
  String _formatCreated(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(t.year, t.month, t.day);
    final diff = day.difference(today).inDays;
    final hm =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    if (diff == 0) return '今天 $hm';
    if (diff == -1) return '昨天 $hm';
    if (t.year == now.year) {
      return '${t.month.toString().padLeft(2, '0')}/${t.day.toString().padLeft(2, '0')} $hm';
    }
    return '${t.year}/${t.month.toString().padLeft(2, '0')}/${t.day.toString().padLeft(2, '0')} $hm';
  }

  Future<void> _pickCustomDate() async {    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _customDueDate ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 3650)),
      helpText: '选择截止日期',
    );
    if (picked == null) return;
    if (mounted) {
      setState(() {
        _dueType = TodoDueType.custom;
        _customDueDate = picked;
      });
    }
  }

  Future<void> _create() async {
    final content = _contentCtrl.text.trim();
    if (content.isEmpty) {
      ToastHelper.show(context, '请输入待办内容', icon: Icons.info_outline);
      return;
    }
    if (_creating) return;
    setState(() => _creating = true);
    try {
      if (widget.isEdit) {
        final t = widget.todo!;
        final updated = Todo(
          id: t.id,
          userId: t.userId,
          content: content,
          note: _noteCtrl.text.trim(),
          category: _category,
          priority: _priority,
          dueType: _dueType,
          dueDate: _resolveDueDate(),
          isCompleted: t.isCompleted,
          createdAt: t.createdAt,
          completedAt: t.completedAt,
          repeat: _buildRepeat(),
          repeatOriginId: t.repeatOriginId,
        );
        await widget.repository.update(updated);
        if (mounted) {
          widget.onUpdated?.call(updated);
          Navigator.of(context).pop();
        }
        return;
      }
      final todo = await widget.repository.create(
        userId: widget.userId,
        content: content,
        note: _noteCtrl.text.trim(),
        category: _category,
        priority: _priority,
        dueType: _dueType,
        dueDate: _resolveDueDate(),
        repeat: _buildRepeat(),
      );
      if (mounted) {
        widget.onCreated?.call(todo);
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        ToastHelper.show(context, '保存失败，请重试', icon: Icons.error_outline);
        setState(() => _creating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final divider = isDark ? AppColors.dividerDark : AppColors.dividerLight;
    final labelStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary(context),
    );

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.isEdit ? '编辑待办' : '新建待办',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary(context),
                ),
              ),
              if (widget.isEdit) ...[
                const SizedBox(height: 6),
                Text(
                  '🕐 创建于 ${_formatCreated(widget.todo!.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              // 待办内容
              TextField(
                controller: _contentCtrl,
                autofocus: false,
                maxLength: 60,
                decoration: const InputDecoration(
                  labelText: '待办内容',
                  hintText: '今天要做什么？',
                  counterText: '',
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              // 备注
              TextField(
                controller: _noteCtrl,
                maxLines: 3,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: '备注',
                  hintText: '补充说明（选填）',
                  counterText: '',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 18),
              // 分类标签
              Text('分类标签', style: labelStyle),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ...TodoCategory.values.map((cat) => _buildCategoryChip(
                        name: cat.name,
                        label: cat.label,
                        emoji: cat.emoji,
                        color: cat.color,
                      )),
                  ..._customCategories.map((c) => _buildCategoryChip(
                        name: c.name,
                        label: c.label,
                        emoji: c.emoji,
                        color: c.color,
                      )),
                  _buildNewCategoryChip(),
                ],
              ),
              const SizedBox(height: 18),
              // 优先级
              Text('优先级', style: labelStyle),
              const SizedBox(height: 10),
              Row(
                children: TodoPriority.values.map((pri) {
                  final selected = _priority == pri;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _priority = pri),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: EdgeInsets.only(
                          right: pri == TodoPriority.values.last ? 0 : 10,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selected
                              ? pri.color.withValues(alpha: 0.14)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? pri.color : divider,
                            width: selected ? 1.6 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: pri.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${pri.label}优先级',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? pri.color
                                    : AppColors.textPrimary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              // 截止时间
              Text('截止时间', style: labelStyle),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ...TodoDueType.values
                      .where((t) => t != TodoDueType.custom)
                      .map((t) => _buildDueChip(t, t == _dueType)),
                  _buildDueChip(
                    TodoDueType.custom,
                    _dueType == TodoDueType.custom,
                    trailing: _customDueDate == null
                        ? null
                        : '${_customDueDate!.month}/${_customDueDate!.day}',
                    onTap: _pickCustomDate,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // 重复
              Text('重复', style: labelStyle),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: TodoRepeatType.values.map((t) {
                  final selected = _repeatType == t;
                  return GestureDetector(
                    onTap: () => setState(() => _repeatType = t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.14)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? AppColors.primary : divider,
                          width: selected ? 1.4 : 1,
                        ),
                      ),
                      child: Text(
                        _repeatTypeLabel(t),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textPrimary(context),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_isRepeat) ...[
                // 每周几多选
                if (_repeatType == TodoRepeatType.weekly) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 1; i <= 7; i++)
                        _buildWeekdayChip(i),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                // 间隔
                Row(
                  children: [
                    Text('每', style: labelStyle),
                    const SizedBox(width: 8),
                    _buildStepButton(Icons.remove, () {
                      setState(() {
                        if (_repeatInterval > 1) _repeatInterval--;
                      });
                    }),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '$_repeatInterval',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                    ),
                    _buildStepButton(Icons.add, () {
                      setState(() {
                        if (_repeatInterval < 99) _repeatInterval++;
                      });
                    }),
                    const SizedBox(width: 10),
                    Text(_repeatUnitLabel, style: labelStyle),
                  ],
                ),
                const SizedBox(height: 14),
                // 终止条件
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildEndChip('永不结束', !_repeatEndByCount && !_repeatEndByDate,
                        () => setState(() {
                          _repeatEndByCount = false;
                          _repeatEndByDate = false;
                        })),
                    _buildEndChip('按次数', _repeatEndByCount, () =>
                        setState(() {
                          _repeatEndByCount = true;
                          _repeatEndByDate = false;
                        })),
                    _buildEndChip('按日期', _repeatEndByDate, () =>
                        setState(() {
                          _repeatEndByDate = true;
                          _repeatEndByCount = false;
                        })),
                  ],
                ),
                if (_repeatEndByCount) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text('共', style: labelStyle),
                      const SizedBox(width: 8),
                      _buildStepButton(Icons.remove, () {
                        setState(() {
                          if (_repeatCountValue > 2) _repeatCountValue--;
                        });
                      }),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '$_repeatCountValue',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                      ),
                      _buildStepButton(Icons.add, () {
                        setState(() {
                          if (_repeatCountValue < 99) _repeatCountValue++;
                        });
                      }),
                      const SizedBox(width: 10),
                      Text('次（含本条）', style: labelStyle),
                    ],
                  ),
                ],
                if (_repeatEndByDate) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _pickRepeatEndDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        _repeatEndDate == null
                            ? '选择结束日期'
                            : '至 ${_repeatEndDate!.year}-${_repeatEndDate!.month.toString().padLeft(2, '0')}-${_repeatEndDate!.day.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Builder(builder: (ctx) {
                  final r = _buildRepeat();
                  final due = _resolveDueDate();
                  final endText = r?.maxCount != null
                      ? '共生成 ${r!.maxCount} 次'
                      : (r?.endDate != null
                          ? '至 ${_repeatEndDate!.month}/${_repeatEndDate!.day} 结束'
                          : '永不结束');
                  return Text(
                    '🔁 将${r?.label(due: due) ?? ''}自动创建，$endText',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary(context),
                    ),
                  );
                }),
              ],
              const SizedBox(height: 24),
              // 创建按钮
              GradientButton(
                label: _creating
                    ? '保存中…'
                    : (widget.isEdit ? '保存修改' : '创建待办'),
                icon: Icons.add_task,
                onPressed: _creating ? null : _create,
              ),            ],
          ),
        ),
      ),
    );
  }

  /// 分类 chip（内置 / 自定义共用）
  Widget _buildCategoryChip({
    required String name,
    required String label,
    required String emoji,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark ? AppColors.dividerDark : AppColors.dividerLight;
    final selected = _category == name;
    return GestureDetector(
      onTap: () => setState(() => _category = name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.16) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : dividerColor,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? color : AppColors.textPrimary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 「＋ 新建分类」chip
  Widget _buildNewCategoryChip() {
    return GestureDetector(
      onTap: _showAddCategory,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('➕', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              '新建分类',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 新建分类 — 复用公共弹窗，成功后加入列表并自动选中
  Future<void> _showAddCategory() async {
    final uid = _userId;
    if (uid.isEmpty) return;
    await showAddCategorySheet(
      context,
      userId: uid,
      repository: widget.repository,
      onCreated: (info) {
        setState(() {
          _customCategories = [..._customCategories, info];
          _category = info.name;
        });
      },
    );
  }

  Widget _buildDueChip(
    TodoDueType type,
    bool selected, {
    String? trailing,
    VoidCallback? onTap,
  }) {
    final divider = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dividerDark
        : AppColors.dividerLight;
    final accent = selected ? AppColors.primary : AppColors.textSecondary(context);
    return GestureDetector(
      onTap: onTap ?? () => setState(() => _dueType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : divider,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              trailing ?? type.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: accent,
              ),
            ),
            if (type == TodoDueType.custom) ...[
              const SizedBox(width: 2),
              Icon(Icons.calendar_today, size: 12, color: accent),
            ],
          ],
        ),
      ),
    );
  }

  // ==================== 重复设置辅助 ====================

  String _repeatTypeLabel(TodoRepeatType t) {
    switch (t) {
      case TodoRepeatType.none:
        return '不重复';
      case TodoRepeatType.daily:
        return '每天';
      case TodoRepeatType.weekly:
        return '每周';
      case TodoRepeatType.monthly:
        return '每月';
      case TodoRepeatType.yearly:
        return '每年';
    }
  }

  String get _repeatUnitLabel {
    switch (_repeatType) {
      case TodoRepeatType.daily:
        return '天';
      case TodoRepeatType.weekly:
        return '周';
      case TodoRepeatType.monthly:
        return '个月';
      case TodoRepeatType.yearly:
        return '年';
      case TodoRepeatType.none:
        return '';
    }
  }

  Widget _buildWeekdayChip(int weekday) {
    final selected = _repeatWeekdays.contains(weekday);
    final name = TodoRepeat.weekdayNames[weekday - 1];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark ? AppColors.dividerDark : AppColors.dividerLight;
    return GestureDetector(
      onTap: () => setState(() {
        if (selected) {
          _repeatWeekdays.remove(weekday);
        } else {
          _repeatWeekdays.add(weekday);
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : dividerColor,
            width: selected ? 1.3 : 1,
          ),
        ),
        child: Text(
          name,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected
                ? AppColors.primary
                : AppColors.textSecondary(context),
          ),
        ),
      ),
    );
  }

  Widget _buildStepButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
    );
  }

  Widget _buildEndChip(String label, bool selected, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark ? AppColors.dividerDark : AppColors.dividerLight;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : dividerColor,
            width: selected ? 1.3 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected
                ? AppColors.primary
                : AppColors.textSecondary(context),
          ),
        ),
      ),
    );
  }
}
