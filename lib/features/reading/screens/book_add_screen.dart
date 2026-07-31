import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/core/constants/strings.dart';
import 'package:buildself/data/models/enums.dart';
import 'package:buildself/data/repositories/reading_repository.dart';
import 'package:buildself/features/auth/providers/app_provider.dart';

/// 添加书籍页
class BookAddScreen extends StatefulWidget {
  const BookAddScreen({Key? key}) : super(key: key);

  @override
  State<BookAddScreen> createState() => _BookAddScreenState();
}

class _BookAddScreenState extends State<BookAddScreen> {
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _repo = ReadingRepository();
  BookStatus _status = BookStatus.planned;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入书名')));
      return;
    }
    setState(() => _saving = true);
    try {
      final userId = context.read<AppProvider>().userId;
      await _repo.createBook(
        userId: userId,
        title: _titleController.text.trim(),
        author: _authorController.text.trim().isEmpty ? null : _authorController.text.trim(),
        status: _status,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.saveSuccess), duration: Duration(seconds: 1)),
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
          child: const Text(AppStrings.cancel),
        ),
        title: const Text(AppStrings.addBook),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text(AppStrings.save, style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 封面占位
            Center(
              child: GestureDetector(
                onTap: () {
                  // TODO: 选择封面图片
                },
                child: Container(
                  width: 120,
                  height: 160,
                  decoration: BoxDecoration(
                    color: AppColors.reading.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, size: 36, color: AppColors.reading),
                      SizedBox(height: 8),
                      Text('添加封面', style: TextStyle(fontSize: 12, color: AppColors.reading)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: '书名',
                prefixIcon: Icon(Icons.menu_book_outlined),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _authorController,
              decoration: const InputDecoration(
                hintText: '作者（选填）',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),

            const Text('阅读状态', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: BookStatus.values.map((status) {
                return FilterChip(
                  label: Text(status.label),
                  selected: _status == status,
                  onSelected: (_) => setState(() => _status = status),
                  selectedColor: AppColors.reading.withOpacity(0.15),
                  checkmarkColor: AppColors.reading,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
