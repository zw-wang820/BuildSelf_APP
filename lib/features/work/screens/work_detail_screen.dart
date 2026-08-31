import 'package:flutter/material.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/core/constants/strings.dart';
import 'package:buildself/core/router/routes.dart';
import 'package:buildself/data/models/work_note_model.dart';
import 'package:buildself/data/repositories/work_repository.dart';
import 'package:buildself/shared/widgets/emoji_icon.dart';
import 'package:buildself/shared/widgets/empty_state.dart';
import 'package:buildself/shared/widgets/tag_chip.dart';

/// 工作记录详情页
class WorkDetailScreen extends StatefulWidget {
  final String? noteId;

  const WorkDetailScreen({Key? key, this.noteId}) : super(key: key);

  @override
  State<WorkDetailScreen> createState() => _WorkDetailScreenState();
}

class _WorkDetailScreenState extends State<WorkDetailScreen> {
  final WorkRepository _repo = WorkRepository();
  WorkNote? _note;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  Future<void> _loadNote() async {
    if (widget.noteId == null) {
      setState(() => _loading = false);
      return;
    }
    _note = await _repo.getById(widget.noteId!);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _delete() async {
    if (_note == null) return;
    await _repo.softDelete(_note!.id);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.deleteSuccess)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.workTitle),
        actions: [
          if (_note != null)
            IconButton(
              icon: const EmojiIcon('✏️', size: 20),
              onPressed: () async {
                await Navigator.pushNamed(context, AppRoutes.workEdit,
                    arguments: _note);
                _loadNote();
              },
            ),
          if (_note != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') _showDeleteDialog(context);
              },
              itemBuilder: (context) => [PopupMenuItem(value: 'delete', child: Text(AppStrings.delete))],
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _note == null
              ? const EmptyState(message: '记录不存在')
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final note = _note!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.work.withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text('${workTypeEmoji(note.recordType)} ${note.recordType}',
              style: const TextStyle(fontSize: 12, color: AppColors.work, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 12),
        if (note.title.isNotEmpty)
          Text(note.title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Row(children: [
          Text(_formatDate(note.createdAt), style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context))),
        ]),
        // 待学习项完成状态
        if (note.recordType == '待学习项') ...[
          const SizedBox(height: 10),
          Row(children: [
            Icon(
              note.done ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 16,
              color: note.done ? AppColors.success : AppColors.textSecondary(context),
            ),
            const SizedBox(width: 6),
            Text(
              note.done
                  ? '已完成${note.doneAt != null ? ' · ${_formatDate(note.doneAt!)}' : ''}'
                  : '未完成',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: note.done ? AppColors.success : AppColors.textSecondary(context),
              ),
            ),
          ]),
        ],
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        Text(note.content, style: const TextStyle(fontSize: 15, height: 1.8)),
        if (note.tags.isNotEmpty) ...[
          const SizedBox(height: 24),
          Wrap(spacing: 8, runSpacing: 8, children: note.tags.map((tag) => TagChip(label: tag)).toList()),
        ],
      ]),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} '
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除记录'),
        content: const Text('确定删除这条记录吗？删除后可在回收站恢复，30天后永久清除。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppStrings.cancel)),
          TextButton(
            onPressed: () { Navigator.pop(context); _delete(); },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }
}
