import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/core/constants/strings.dart';
import 'package:buildself/data/database/tables.dart';
import 'package:buildself/data/database/database_provider.dart';
import 'package:buildself/features/auth/providers/app_provider.dart';
import 'package:buildself/features/todo/models/todo_model.dart';
import 'package:buildself/shared/widgets/app_card.dart';
import 'package:buildself/shared/widgets/emoji_icon.dart';
import 'package:buildself/shared/widgets/nexus_background.dart';

/// 回收站页 — NEXUS 数据回收终端
class TrashScreen extends StatefulWidget {
  const TrashScreen({Key? key}) : super(key: key);

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  final _db = DatabaseProvider.instance;
  List<_TrashItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTrash();
  }

  Future<void> _loadTrash() async {
    final userId = context.read<AppProvider>().userId;
    if (userId.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    try {
      final results = <_TrashItem>[];

      // 工作记录
      final workMaps = await _db.queryAll(
        AppTables.workNotes,
        where: 'user_id = ? AND deleted_at IS NOT NULL',
        whereArgs: [userId],
        orderBy: 'deleted_at DESC',
      );
      for (final m in workMaps) {
        results.add(_TrashItem(
          id: m['id'] as String,
          title: (m['title'] as String?)?.isNotEmpty == true ? m['title'] as String : '(无标题工作记录)',
          subtitle: m['content'] as String? ?? '',
          moduleTag: 'WORK',
          moduleColor: AppColors.work,
          table: AppTables.workNotes,
          deletedAt: DateTime.parse(m['deleted_at'] as String),
        ));
      }

      // 生活记录
      final lifeMaps = await _db.queryAll(
        AppTables.lifeRecords,
        where: 'user_id = ? AND deleted_at IS NOT NULL',
        whereArgs: [userId],
        orderBy: 'deleted_at DESC',
      );
      for (final m in lifeMaps) {
        results.add(_TrashItem(
          id: m['id'] as String,
          title: (m['title'] as String?)?.isNotEmpty == true ? m['title'] as String : '(无标题生活记录)',
          subtitle: m['content'] as String? ?? '',
          moduleTag: 'LIFE',
          moduleColor: AppColors.life,
          table: AppTables.lifeRecords,
          deletedAt: DateTime.parse(m['deleted_at'] as String),
        ));
      }

      // 目标
      final goalMaps = await _db.queryAll(
        AppTables.goals,
        where: 'user_id = ? AND deleted_at IS NOT NULL',
        whereArgs: [userId],
        orderBy: 'deleted_at DESC',
      );
      for (final m in goalMaps) {
        results.add(_TrashItem(
          id: m['id'] as String,
          title: m['title'] as String? ?? '(无标题目标)',
          subtitle: m['description'] as String? ?? '',
          moduleTag: 'GOAL',
          moduleColor: AppColors.goal,
          table: AppTables.goals,
          deletedAt: DateTime.parse(m['deleted_at'] as String),
        ));
      }

      // 碎碎念
      final murmurMaps = await _db.queryAll(
        AppTables.murmurs,
        where: 'user_id = ? AND deleted_at IS NOT NULL',
        whereArgs: [userId],
        orderBy: 'deleted_at DESC',
      );
      for (final m in murmurMaps) {
        results.add(_TrashItem(
          id: m['id'] as String,
          title: m['content'] as String? ?? '',
          subtitle: '',
          moduleTag: 'MURMUR',
          moduleColor: AppColors.murmur,
          table: AppTables.murmurs,
          deletedAt: DateTime.parse(m['deleted_at'] as String),
        ));
      }

      // 待办
      final todoMaps = await _db.queryAll(
        AppTables.todos,
        where: 'user_id = ? AND deleted_at IS NOT NULL',
        whereArgs: [userId],
        orderBy: 'deleted_at DESC',
      );
      for (final m in todoMaps) {
        final catName = m['category'] as String?;
        final catLabel = TodoCategory.values
            .firstWhere((c) => c.name == catName, orElse: () => TodoCategory.work)
            .label;
        results.add(_TrashItem(
          id: m['id'] as String,
          title: m['content'] as String? ?? '',
          subtitle: catLabel,
          moduleTag: 'TODO',
          moduleColor: AppColors.todo,
          table: AppTables.todos,
          deletedAt: DateTime.parse(m['deleted_at'] as String),
        ));
      }

      // 按删除时间倒序
      results.sort((a, b) => b.deletedAt.compareTo(a.deletedAt));

      if (mounted) setState(() {
        _items = results;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _restore(_TrashItem item) async {
    await _db.restore(item.table, item.id);
    _showSnack('已恢复', AppColors.accent);
    _loadTrash();
  }

  Future<void> _permanentDelete(_TrashItem item) async {
    final confirmed = await _confirmDelete();
    if (confirmed != true) return;
    await _db.delete(item.table, where: 'id = ?', whereArgs: [item.id]);
    _showSnack('已永久删除', AppColors.error);
    _loadTrash();
  }

  Future<void> _emptyTrash() async {
    final confirmed = await _confirmDelete(isAll: true);
    if (confirmed != true) return;
    for (final item in _items) {
      await _db.delete(item.table, where: 'id = ?', whereArgs: [item.id]);
    }
    _showSnack('回收站已清空', AppColors.error);
    _loadTrash();
  }

  Future<bool?> _confirmDelete({bool isAll = false}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAll ? '清空回收站' : '永久删除'),
        content: Text(isAll ? '将永久删除回收站中的所有记录，此操作不可撤销。' : '永久删除后无法恢复，确定继续？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppStrings.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color.withOpacity(0.2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(AppStrings.trash),
        actions: [
          if (_items.isNotEmpty)
            TextButton(
              onPressed: _emptyTrash,
              child: const Text('清空', style: TextStyle(color: AppColors.error)),
            ),
        ],
      ),
      body: NexusBackground(
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.error, strokeWidth: 2))
              : _items.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      itemCount: _items.length,
                      itemBuilder: (context, i) => _buildTrashCard(_items[i]),
                    ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.error.withOpacity(0.4), width: 1),
                color: AppColors.error.withOpacity(0.06),
              ),
              child: const EmojiIcon('🗑️', size: 36),
            ),
            const SizedBox(height: 16),
            Text('回收站为空',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary(context), letterSpacing: 0.3)),
            const SizedBox(height: 6),
            Text('删除的记录将保留 30 天后自动清理',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context).withOpacity(0.6))),
          ],
        ),
      ),
    );
  }

  Widget _buildTrashCard(_TrashItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        accent: item.moduleColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: item.moduleColor.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: item.moduleColor.withOpacity(0.5), width: 0.6),
                  ),
                  child: Text(item.moduleTag,
                      style: TextStyle(
                        fontSize: 9,
                        color: item.moduleColor,
                        fontWeight: FontWeight.w700,
                      )),
                ),
                const Spacer(),
                Text(
                  '已删 ${item.deletedAt.month.toString().padLeft(2, '0')}.${item.deletedAt.day.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary(context),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (item.subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                item.subtitle,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context), height: 1.5),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _restore(item),
                    icon: const EmojiIcon('↺', size: 16),
                    label: const Text('恢复', style: TextStyle(fontSize: 13, letterSpacing: 0.5)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      side: BorderSide(color: AppColors.accent.withOpacity(0.5), width: 0.8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _permanentDelete(item),
                    icon: const EmojiIcon('🗑️', size: 16),
                    label: const Text('永久删除', style: TextStyle(fontSize: 13, letterSpacing: 0.5)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error.withOpacity(0.5), width: 0.8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrashItem {
  final String id;
  final String title;
  final String subtitle;
  final String moduleTag;
  final Color moduleColor;
  final String table;
  final DateTime deletedAt;

  _TrashItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.moduleTag,
    required this.moduleColor,
    required this.table,
    required this.deletedAt,
  });
}
