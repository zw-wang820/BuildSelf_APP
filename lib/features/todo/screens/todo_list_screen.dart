import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/core/router/routes.dart';
import 'package:buildself/features/auth/providers/app_provider.dart';
import 'package:buildself/features/todo/data/todo_repository.dart';
import 'package:buildself/features/todo/models/todo_model.dart';
import 'package:buildself/features/todo/widgets/add_todo_sheet.dart';
import 'package:buildself/features/todo/widgets/todo_item_card.dart';
import 'package:buildself/shared/widgets/emoji_icon.dart';
import 'package:buildself/shared/widgets/nexus_background.dart';
import 'package:buildself/shared/widgets/toast.dart';

/// 待办列表页 — 筛选标签 + 列表 + 右下角「+」新建
class TodoListScreen extends StatefulWidget {
  const TodoListScreen({Key? key}) : super(key: key);

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

enum _TodoFilter { all, work, life, reading, completed }

extension _TodoFilterX on _TodoFilter {
  String get label {
    switch (this) {
      case _TodoFilter.all:
        return '全部';
      case _TodoFilter.work:
        return '工作';
      case _TodoFilter.life:
        return '生活';
      case _TodoFilter.reading:
        return '阅读';
      case _TodoFilter.completed:
        return '已完成';
    }
  }

  TodoCategory? get category {
    switch (this) {
      case _TodoFilter.work:
        return TodoCategory.work;
      case _TodoFilter.life:
        return TodoCategory.life;
      case _TodoFilter.reading:
        return TodoCategory.reading;
      default:
        return null;
    }
  }

  // 全部/分类标签展示该范围的全部（含已完成）；仅「已完成」限定为已完成
  bool? get completed => this == _TodoFilter.completed ? true : null;

  Color get accent {
    switch (this) {
      case _TodoFilter.all:
        return AppColors.todo;
      case _TodoFilter.work:
        return AppColors.work;
      case _TodoFilter.life:
        return AppColors.life;
      case _TodoFilter.reading:
        return AppColors.reading;
      case _TodoFilter.completed:
        return AppColors.success;
    }
  }
}

class _TodoListScreenState extends State<TodoListScreen> {
  final TodoRepository _repo = TodoRepository();
  _TodoFilter _filter = _TodoFilter.all;
  List<Todo> _todos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = context.read<AppProvider>().userId;
    if (userId.isEmpty) return;
    setState(() => _loading = true);
    // 先惰性补建到期重复实例，再加载列表
    await _repo.ensureDueInstances(userId);
    final list = await _repo.getAll(
      userId,
      category: _filter.category,
      completed: _filter.completed,
    );
    if (mounted) setState(() {
      _todos = list;
      _loading = false;
    });
  }

  void _changeFilter(_TodoFilter f) {
    if (_filter == f) {
      return;
    }
    setState(() => _filter = f);
    _loadData();
  }

  Future<void> _openAddSheet() async {
    final userId = context.read<AppProvider>().userId;
    if (userId.isEmpty) return;
    await showAddTodoSheet(
      context,
      userId: userId,
      repository: _repo,
      onCreated: (_) {
        _loadData();
        ToastHelper.show(
          context,
          '✅ 待办创建成功！',
          icon: Icons.check_circle,
          color: AppColors.success,
        );
      },
    );
  }

  /// 点击卡片编辑待办
  Future<void> _openEditSheet(Todo todo) async {
    await showEditTodoSheet(
      context,
      repository: _repo,
      todo: todo,
      onUpdated: (_) {
        _loadData();
        ToastHelper.show(
          context,
          '✅ 待办已更新',
          icon: Icons.check_circle,
          color: AppColors.success,
        );
      },
    );
  }

  /// 标记完成 / 恢复 — 先乐观更新（弹簧动画可见），持久化后再移除条目
  Future<void> _toggleTodo(Todo todo) async {
    final nowCompleted = !todo.isCompleted;
    setState(() {
      final idx = _todos.indexWhere((t) => t.id == todo.id);
      if (idx != -1) {
        _todos[idx] = todo.copyWith(
          isCompleted: nowCompleted,
          completedAt: nowCompleted ? DateTime.now() : null,
        );
      }
    });
    if (nowCompleted) {
      await _repo.markCompleted(todo.id);
    } else {
      await _repo.markActive(todo.id);
    }
    if (!mounted) return;
    ToastHelper.show(
      context,
      nowCompleted ? '✅ 已完成' : '已恢复为待办',
      icon: nowCompleted ? Icons.check_circle : Icons.undo,
      color: nowCompleted ? AppColors.success : AppColors.info,
    );
    // 等待弹簧动画播完再刷新，让勾选动效可见
    await Future.delayed(const Duration(milliseconds: 420));
    if (mounted) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('待办清单'),
        actions: [
          IconButton(
            icon: const EmojiIcon('📊', size: 21),
            tooltip: '统计',
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.todoStats),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: NexusBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildFilterBar(),
              const SizedBox(height: 4),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddSheet,
        backgroundColor: AppColors.todo,
        foregroundColor: Colors.white,
        child: const EmojiIcon('➕', size: 22),
      ),
    );
  }

  Widget _buildFilterBar() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _TodoFilter.values.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final f = _TodoFilter.values[i];
          final selected = _filter == f;
          return GestureDetector(
            onTap: () => _changeFilter(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? f.accent.withValues(alpha: 0.16)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? f.accent : Theme.of(context).dividerColor,
                  width: selected ? 1.4 : 1,
                ),
              ),
              child: Text(
                f.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? f.accent : AppColors.textSecondary(context),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(
          color: _filter.accent,
          strokeWidth: 2,
        ),
      );
    }
    if (_todos.isEmpty) {
      return _buildEmpty();
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: _todos.length,
      itemBuilder: (context, i) {
        final todo = _todos[i];
        return Dismissible(
          key: ValueKey(todo.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => _deleteTodo(todo),
          background: _buildDeleteBackground(context),
          child: TodoItemCard(
            todo: todo,
            onToggle: _toggleTodo,
            onTap: () => _openEditSheet(todo),
          ),
        );
      },
    );
  }

  /// 左滑露出的删除背景（红色 + 🗑️）
  Widget _buildDeleteBackground(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.only(right: 24),
      alignment: Alignment.centerRight,
      child: const EmojiIcon('🗑️', size: 22),
    );
  }

  /// 左滑删除待办
  Future<void> _deleteTodo(Todo todo) async {
    setState(() => _todos.removeWhere((t) => t.id == todo.id));
    await _repo.delete(todo.id);
    if (!mounted) return;
    ToastHelper.show(context, '🗑️ 待办已删除');
  }

  Widget _buildEmpty() {
    final isCompleted = _filter == _TodoFilter.completed;
    final accent = _filter.accent;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: EmojiIcon(isCompleted ? '✅' : '📋', size: 30),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isCompleted ? '还没有已完成的待办' : '还没有待办',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isCompleted ? '完成一条待办后会出现在这里' : '点击右下角 + 新建一条',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}
