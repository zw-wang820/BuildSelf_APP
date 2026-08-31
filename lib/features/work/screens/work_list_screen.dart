import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/core/constants/strings.dart';
import 'package:buildself/core/router/routes.dart';
import 'package:buildself/data/models/enums.dart';
import 'package:buildself/data/models/work_note_model.dart';
import 'package:buildself/data/repositories/work_repository.dart';
import 'package:buildself/features/auth/providers/app_provider.dart';
import 'package:buildself/shared/layouts/main_scaffold.dart';
import 'package:buildself/shared/widgets/app_card.dart';
import 'package:buildself/shared/widgets/emoji_icon.dart';
import 'package:buildself/shared/widgets/empty_state.dart';
import 'package:buildself/shared/widgets/nexus_background.dart';
import 'package:buildself/shared/widgets/tag_chip.dart';

/// 工作记录列表页
class WorkListScreen extends StatefulWidget {
  const WorkListScreen({Key? key}) : super(key: key);

  @override
  State<WorkListScreen> createState() => _WorkListScreenState();
}

class _WorkListScreenState extends State<WorkListScreen> {
  final WorkRepository _repo = WorkRepository();
  String? _filterType;
  List<String> _categories = [];
  List<WorkNote> _notes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadData();
  }

  Future<void> _loadCategories() async {
    final userId = context.read<AppProvider>().userId;
    if (userId.isEmpty) return;
    final cats = await _repo.getCategories(userId);
    if (mounted) setState(() => _categories = cats);
  }

  Future<void> _loadData() async {
    final userId = context.read<AppProvider>().userId;
    if (userId.isEmpty) return;
    setState(() => _loading = true);
    _notes = await _repo.getAll(userId, type: _filterType);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.workTitle),
        actions: [
          IconButton(
            icon: const EmojiIcon('🔍', size: 21),
            onPressed: () => _showSearch(context),
          ),
        ],
      ),
      body: NexusBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildFilterBar(),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.work,
                          strokeWidth: 2,
                        ),
                      )
                    : _buildList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, AppRoutes.workEdit);
          _loadCategories();
          _loadData();
        },
        backgroundColor: AppColors.work,
        foregroundColor: AppColors.spaceDeep,
        child: const EmojiIcon('➕', size: 22),
      ),
      floatingActionButtonLocation: const FloatingAboveNavLocation(),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: [
          _buildFilterChip(null, '全部'),
          ..._categories.map((type) => _buildFilterChip(type, type)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String? type, String label) {
    final isSelected = _filterType == type;
    final display = type == null ? label : '${workTypeEmoji(type)} $label';
    final accent = type == null ? AppColors.work : workTypeColor(type);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FilterChip(
      label: Text(display),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _filterType = isSelected ? null : type);
        _loadData();
      },
      selectedColor: accent.withValues(alpha: 0.15),
      checkmarkColor: accent,
      backgroundColor: Colors.transparent,
      labelStyle: TextStyle(
        color: isSelected ? accent : AppColors.textSecondary(context),
        fontSize: 13,
      ),
      side: BorderSide(
        color: isSelected
            ? accent
            : (isDark ? AppColors.dividerDark : AppColors.dividerLight),
        width: 0.8,
      ),
      shape: const StadiumBorder(),
    );
  }

  Widget _buildList() {
    if (_notes.isEmpty) {
      return EmptyState(
        emoji: '💼',
        message: '还没有工作记录\n点击右下角 + 开始记录',
        onAction: () async {
          await Navigator.pushNamed(context, AppRoutes.workEdit);
          _loadCategories();
          _loadData();
        },
        actionLabel: '新建记录',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _notes.length,
      itemBuilder: (context, index) => _buildNoteCard(_notes[index]),
    );
  }

  Widget _buildNoteCard(WorkNote note) {
    const color = AppColors.work;
    final isLearning = note.recordType == '待学习项';
    final done = note.done;

    // 外层 GestureDetector 仅接管长按（删除），点击仍走 AppCard 的 onTap（进详情）
    return GestureDetector(
      onLongPress: () => _confirmDelete(note),
      child: AppCard(
        accent: color,
        margin: const EdgeInsets.only(bottom: 10),
        onTap: () async {
          await Navigator.pushNamed(context, AppRoutes.workDetail, arguments: note.id);
          _loadData();
        },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 待学习项：完成勾选框（列表内直接勾选）
              if (isLearning)
                SizedBox(
                  height: 32,
                  child: Checkbox(
                    value: done,
                    activeColor: AppColors.success,
                    visualDensity: VisualDensity.compact,
                    onChanged: (v) => _toggleDone(note, v ?? false),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: color.withOpacity(0.5), width: 0.6),
                ),
                child: Text(
                  '${workTypeEmoji(note.recordType)} ${note.recordType}',
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(note.createdAt),
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary(context),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          if (note.title.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              note.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary(context),
                decoration: done ? TextDecoration.lineThrough : null,
                decorationColor: AppColors.textSecondary(context),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            note.content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: done
                  ? AppColors.textSecondary(context).withValues(alpha: 0.6)
                  : AppColors.textSecondary(context),
              height: 1.5,
              letterSpacing: 0.3,
              decoration: done ? TextDecoration.lineThrough : null,
              decorationColor: AppColors.textSecondary(context),
            ),
          ),
          if (note.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: note.tags.map((t) => TagChip(label: t)).toList(),
            ),
          ],
        ],
      ),
      ),
    );
  }

  /// 待学习项完成/取消（列表内直接勾选）
  Future<void> _toggleDone(WorkNote note, bool done) async {
    await _repo.toggleDone(note, done);
    if (mounted) _loadData();
  }

  /// 长按删除 — 二次确认后移入回收站
  Future<void> _confirmDelete(WorkNote note) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除记录'),
        content: const Text('确定删除这条记录吗？删除后可在回收站恢复，30天后永久清除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(AppStrings.delete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _repo.softDelete(note.id);
    if (!mounted) return;
    _loadData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.deleteSuccess)),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  void _showSearch(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('搜索工作记录'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '输入关键词'),
          onSubmitted: (value) async {
            Navigator.pop(context);
            if (value.trim().isNotEmpty) {
              final userId = this.context.read<AppProvider>().userId;
              final results = await _repo.search(userId, value.trim());
              if (!mounted) return;
              setState(() => _notes = results);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadData();
            },
            child: const Text('清除搜索'),
          ),
        ],
      ),
    );
  }
}
