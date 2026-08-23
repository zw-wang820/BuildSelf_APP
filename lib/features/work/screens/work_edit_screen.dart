import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/core/constants/strings.dart';
import 'package:buildself/data/models/enums.dart';
import 'package:buildself/data/models/work_note_model.dart';
import 'package:buildself/data/repositories/work_repository.dart';
import 'package:buildself/features/auth/providers/app_provider.dart';
import 'package:buildself/shared/widgets/emoji_icon.dart';
import 'package:buildself/shared/widgets/mood_selector.dart';
import 'package:buildself/shared/widgets/tag_chip.dart';

/// 工作记录编辑/新建页
class WorkEditScreen extends StatefulWidget {
  final WorkNote? note;

  const WorkEditScreen({Key? key, this.note}) : super(key: key);

  @override
  State<WorkEditScreen> createState() => _WorkEditScreenState();
}

class _WorkEditScreenState extends State<WorkEditScreen> {
  final WorkRepository _repo = WorkRepository();
  late String _recordType;
  List<String> _categories = [];
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();
  List<String> _tags = [];
  Mood? _mood;
  bool _saving = false;

  bool get _isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    final note = widget.note;
    _recordType = note?.recordType ?? '心得';
    if (note != null) {
      _titleController.text = note.title;
      _contentController.text = note.content;
      _tags = List.from(note.tags);
      _mood = note.mood;
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final userId = context.read<AppProvider>().userId;
    if (userId.isEmpty) return;
    final cats = await _repo.getCategories(userId);
    if (mounted) setState(() => _categories = cats);
  }

  void _showAddCategoryDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新增分类'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '输入分类名称'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.cancel)),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              final userId = context.read<AppProvider>().userId;
              await _repo.addCategory(userId, name);
              if (mounted) {
                setState(() {
                  _categories.add(name);
                  _recordType = name;
                });
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(AppStrings.confirm),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入内容')));
      return;
    }
    setState(() => _saving = true);

    try {
      final userId = context.read<AppProvider>().userId;
      if (_isEditing) {
        final note = widget.note!;
        note.title = _titleController.text.trim();
        note.content = _contentController.text.trim();
        note.recordType = _recordType;
        note.tags = _tags;
        note.mood = _mood;
        await _repo.update(note);
      } else {
        await _repo.create(
          userId: userId,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          recordType: _recordType,
          tags: _tags,
          mood: _mood,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.saveSuccess), duration: Duration(seconds: 1)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败：$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: TextButton(onPressed: () => Navigator.pop(context), child: Text(AppStrings.cancel)),
        title: Text(_isEditing ? AppStrings.edit : AppStrings.newWorkRecord),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(AppStrings.save, style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(
            spacing: 8,
            children: [
              ..._categories.map((type) {
                return FilterChip(
                  label: Text(type),
                  selected: _recordType == type,
                  onSelected: (_) => setState(() => _recordType = type),
                  selectedColor: AppColors.work.withOpacity(0.15),
                  checkmarkColor: AppColors.work,
                );
              }),
              ActionChip(
                label: const Text('+ 新增'),
                onPressed: _showAddCategoryDialog,
                backgroundColor: AppColors.spaceHigh,
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(controller: _titleController, decoration: InputDecoration(hintText: AppStrings.titleOptional)),
          const SizedBox(height: 16),
          TextField(
            controller: _contentController,
            maxLines: 12,
            decoration: const InputDecoration(hintText: '记录你的经验、心得或反思...'),
          ),
          const SizedBox(height: 16),
          Text(AppStrings.mood, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          MoodSelector(selected: _mood, onChanged: (mood) => setState(() => _mood = mood)),
          const SizedBox(height: 16),
          Text(AppStrings.tags, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_tags.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags.map((tag) => TagChip(label: tag, onDeleted: () => setState(() => _tags.remove(tag)))).toList(),
            ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _tagController,
                decoration: const InputDecoration(hintText: '输入标签', isDense: true),
                onSubmitted: (_) => _addTag(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(icon: const EmojiIcon('➕', size: 20), onPressed: _addTag),
          ]),
        ]),
      ),
    );
  }
}
