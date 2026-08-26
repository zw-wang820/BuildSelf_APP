import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/features/auth/providers/app_provider.dart';
import 'package:buildself/features/todo/data/todo_repository.dart';
import 'package:buildself/features/todo/models/todo_category_info.dart';
import 'package:buildself/features/todo/models/todo_model.dart';
import 'package:buildself/features/todo/widgets/add_todo_sheet.dart';
import 'package:buildself/shared/widgets/app_card.dart';
import 'package:buildself/shared/widgets/emoji_icon.dart';
import 'package:buildself/shared/widgets/nexus_background.dart';
import 'package:buildself/shared/widgets/toast.dart';

/// 分类管理页 — 内置四类只读；自定义分类可新增/重命名/删除
class CategoryManageScreen extends StatefulWidget {
  const CategoryManageScreen({Key? key}) : super(key: key);

  @override
  State<CategoryManageScreen> createState() => _CategoryManageScreenState();
}

class _CategoryManageScreenState extends State<CategoryManageScreen> {
  final TodoRepository _repo = TodoRepository();
  List<TodoCategoryInfo> _customCategories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = context.read<AppProvider>().userId;
    if (userId.isEmpty) return;
    final list = await _repo.getCustomCategories(userId);
    if (mounted) {
      setState(() {
        _customCategories = list;
        _loading = false;
      });
    }
  }

  Future<void> _addCategory() async {
    final userId = context.read<AppProvider>().userId;
    if (userId.isEmpty) return;
    await showAddCategorySheet(
      context,
      userId: userId,
      repository: _repo,
      onCreated: (_) {
        ToastHelper.show(context, '✅ 分类已创建');
        _load();
      },
    );
  }

  /// 重命名 — 同步更新该分类下全部待办
  Future<void> _rename(TodoCategoryInfo c) async {
    final userId = context.read<AppProvider>().userId;
    if (userId.isEmpty) return;
    final nameCtrl = TextEditingController(text: c.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重命名分类'),
        content: TextField(
          controller: nameCtrl,
          maxLength: 6,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '分类名称',
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, nameCtrl.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty || newName == c.name) return;
    final ok = await _repo.renameCustomCategory(
      userId,
      id: c.id!,
      oldName: c.name,
      newName: newName,
    );
    if (!mounted) return;
    if (!ok) {
      ToastHelper.show(context, '该分类已存在', icon: Icons.error_outline);
      return;
    }
    ToastHelper.show(context, '✅ 已重命名');
    _load();
  }

  /// 删除 — 该分类下待办归入「工作」
  Future<void> _delete(TodoCategoryInfo c) async {
    final userId = context.read<AppProvider>().userId;
    if (userId.isEmpty) return;
    // 查询该分类下（不含回收站）待办数，用于确认文案
    final count = (await _repo.getAll(userId, category: c.name)).length;
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除分类'),
        content: Text(
          '将删除分类「${c.label}」，其中 $count 条待办将归入「工作」。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repo.deleteCustomCategory(userId, id: c.id!, name: c.name);
    if (!mounted) return;
    ToastHelper.show(context, '🗑️ 分类已删除');
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('分类管理')),
      body: NexusBackground(
        child: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.todo, strokeWidth: 2),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionLabel('内置分类'),
                      const SizedBox(height: 10),
                      _buildBuiltinGrid(),
                      const SizedBox(height: 24),
                      _buildSectionLabel('我的分类'),
                      const SizedBox(height: 10),
                      if (_customCategories.isEmpty)
                        AppCard(
                          accent: AppColors.todo,
                          onTap: null,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            child: Center(
                              child: Text(
                                '还没有自定义分类，点击下方按钮新建',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary(context),
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        AppCard(
                          accent: AppColors.todo,
                          onTap: null,
                          child: Column(
                            children: List.generate(
                                _customCategories.length, (i) {
                              final c = _customCategories[i];
                              final isLast =
                                  i == _customCategories.length - 1;
                              return Padding(
                                padding: EdgeInsets.only(
                                    bottom: isLast ? 0 : 10),
                                child: _buildCustomRow(c),
                              );
                            }),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Center(
                        child: OutlinedButton.icon(
                          onPressed: _addCategory,
                          icon: const EmojiIcon('➕', size: 16),
                          label: const Text('新建分类',
                              style: TextStyle(fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(
                                color:
                                    AppColors.primary.withValues(alpha: 0.5)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
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

  /// 内置四类只读展示
  Widget _buildBuiltinGrid() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: TodoCategory.values.map((c) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: c.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: c.color.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(c.emoji, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 5),
              Text(
                c.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: c.color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// 自定义分类行 — emoji + 名称 + 重命名 / 删除
  Widget _buildCustomRow(TodoCategoryInfo c) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: c.color.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Center(child: EmojiIcon(c.emoji, size: 16)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            c.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(context),
            ),
          ),
        ),
        _buildIconAction('✏️', () => _rename(c)),
        const SizedBox(width: 4),
        _buildIconAction('🗑️', () => _delete(c)),
      ],
    );
  }

  Widget _buildIconAction(String emoji, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.textSecondary(context).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(child: EmojiIcon(emoji, size: 15)),
      ),
    );
  }
}
