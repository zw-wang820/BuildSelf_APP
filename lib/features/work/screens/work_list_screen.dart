import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/core/constants/strings.dart';
import 'package:buildself/core/router/routes.dart';
import 'package:buildself/data/models/enums.dart';
import 'package:buildself/data/models/work_note_model.dart';
import 'package:buildself/data/repositories/work_repository.dart';
import 'package:buildself/features/auth/providers/app_provider.dart';
import 'package:buildself/shared/widgets/app_card.dart';
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.work,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.work, blurRadius: 6)],
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '// WORK LOG',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.work,
                letterSpacing: 2,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                AppStrings.workTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryDark,
                  letterSpacing: 0.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
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
                    ? Center(
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
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.work.withOpacity(0.5),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          elevation: 0,
          onPressed: () async {
            await Navigator.pushNamed(context, AppRoutes.workEdit);
            _loadCategories();
            _loadData();
          },
          backgroundColor: AppColors.work,
          foregroundColor: AppColors.spaceDeep,
          child: const Icon(Icons.add),
        ),
      ),
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
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _filterType = isSelected ? null : type);
        _loadData();
      },
      selectedColor: AppColors.work.withOpacity(0.18),
      checkmarkColor: AppColors.work,
      backgroundColor: AppColors.spaceHigh,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.work : AppColors.textSecondaryDark,
        fontSize: 13,
      ),
      side: BorderSide(
        color: AppColors.work.withOpacity(isSelected ? 0.6 : 0.3),
        width: 0.8,
      ),
      shape: const StadiumBorder(),
    );
  }

  Widget _buildList() {
    if (_notes.isEmpty) {
      return EmptyState(
        icon: Icons.event_outlined,
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
    final color = AppColors.work;

    return AppCard(
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: color.withOpacity(0.5), width: 0.6),
                ),
                child: Text(
                  note.recordType,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              if (note.mood != null) ...[
                const SizedBox(width: 8),
                Text(note.mood!.emoji, style: const TextStyle(fontSize: 14)),
              ],
              const Spacer(),
              Text(
                _formatDate(note.createdAt),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondaryDark,
                  fontFamily: 'monospace',
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          if (note.title.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              note.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryDark,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            note.content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondaryDark,
              height: 1.5,
              letterSpacing: 0.3,
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
