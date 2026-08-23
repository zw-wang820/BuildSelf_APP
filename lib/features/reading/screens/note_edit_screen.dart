import 'package:flutter/material.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/core/constants/strings.dart';
import 'package:buildself/data/models/enums.dart';
import 'package:buildself/data/models/reading_models.dart';
import 'package:buildself/data/repositories/reading_repository.dart';

/// 读书笔记编辑参数
class NoteEditArgs {
  final String bookId;
  final ReadingNote? note;

  NoteEditArgs({required this.bookId, this.note});
}

/// 读书笔记编辑/新建页
class NoteEditScreen extends StatefulWidget {
  final NoteEditArgs? args;

  const NoteEditScreen({Key? key, this.args}) : super(key: key);

  @override
  State<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  final _repo = ReadingRepository();
  late NoteType _noteType;
  final _chapterController = TextEditingController();
  final _contentController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final note = widget.args?.note;
    _noteType = note?.noteType ?? NoteType.excerpt;
    if (note != null) {
      _chapterController.text = note.chapter ?? '';
      _contentController.text = note.content;
    }
  }

  @override
  void dispose() {
    _chapterController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入内容')));
      return;
    }

    final bookId = widget.args?.bookId;
    if (bookId == null || bookId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('缺少书籍信息')));
      return;
    }

    setState(() => _saving = true);
    try {
      final note = widget.args?.note;
      final chapter = _chapterController.text.trim().isEmpty ? null : _chapterController.text.trim();

      if (note != null) {
        // 编辑已有笔记
        note.noteType = _noteType;
        note.chapter = chapter;
        note.content = _contentController.text.trim();
        await _repo.updateNote(note);
      } else {
        // 新建笔记
        await _repo.createNote(
          bookId: bookId,
          noteType: _noteType,
          chapter: chapter,
          content: _contentController.text.trim(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.saveSuccess), duration: Duration(seconds: 1)),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存失败，请重试')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppStrings.cancel),
        ),
        title: Text(AppStrings.newReadingNote),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(AppStrings.save, style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 笔记类型选择
            Wrap(
              spacing: 8,
              children: NoteType.values.map((type) {
                final isSelected = _noteType == type;
                return FilterChip(
                  label: Text(type.label),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _noteType = type),
                  selectedColor: AppColors.reading.withOpacity(0.15),
                  checkmarkColor: AppColors.reading,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.reading : AppColors.textSecondary(context),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // 章节
            TextField(
              controller: _chapterController,
              decoration: const InputDecoration(
                hintText: '章节/页码（选填）',
                prefixIcon: Icon(Icons.bookmark_outline),
              ),
            ),
            const SizedBox(height: 16),

            // 内容
            TextField(
              controller: _contentController,
              maxLines: 15,
              decoration: InputDecoration(
                hintText: _getHintByType(_noteType),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getHintByType(NoteType type) {
    switch (type) {
      case NoteType.excerpt:
        return '摘录书中的精华原文...';
      case NoteType.insight:
        return '写下你对书中内容的理解和感悟...';
      case NoteType.thought:
        return '记录由书中内容引发的延伸思考...';
      case NoteType.change:
        return '因为这本书，你决定做出什么改变？';
    }
  }
}
