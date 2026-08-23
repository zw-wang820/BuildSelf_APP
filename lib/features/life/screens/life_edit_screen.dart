import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/core/constants/strings.dart';
import 'package:buildself/data/models/enums.dart';
import 'package:buildself/data/repositories/life_repository.dart';
import 'package:buildself/features/auth/providers/app_provider.dart';
import 'package:buildself/shared/widgets/mood_selector.dart';

/// 生活记录编辑/新建页
class LifeEditScreen extends StatefulWidget {
  const LifeEditScreen({Key? key}) : super(key: key);

  @override
  State<LifeEditScreen> createState() => _LifeEditScreenState();
}

class _LifeEditScreenState extends State<LifeEditScreen> {
  final LifeRepository _repo = LifeRepository();
  late String _recordType;
  List<String> _categories = [];
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  Mood? _mood;
  Weather? _weather;
  final _locationController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _recordType = '美好';
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
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入内容')),
      );
      return;
    }

    final userId = context.read<AppProvider>().userId;
    if (userId.isEmpty) return;

    setState(() => _saving = true);

    try {
      await _repo.create(
        userId: userId,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        recordType: _recordType,
        mood: _mood,
        weather: _weather,
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.saveSuccess),
            duration: Duration(seconds: 1),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(AppStrings.cancel),
        ),
        title: Text(AppStrings.newLifeRecord),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    AppStrings.save,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 类型选择
            Wrap(
              spacing: 8,
              children: [
                ..._categories.map((type) {
                  return FilterChip(
                    label: Text(type),
                    selected: _recordType == type,
                    onSelected: (_) => setState(() => _recordType = type),
                    selectedColor: AppColors.life.withOpacity(0.15),
                    checkmarkColor: AppColors.life,
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
            TextField(
              controller: _titleController,
              decoration: InputDecoration(hintText: AppStrings.titleOptional),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              maxLines: 10,
              decoration: const InputDecoration(hintText: '记录生活中的美好与感悟...'),
            ),
            const SizedBox(height: 16),

            // 图片添加
            _buildImagePicker(),
            const SizedBox(height: 16),

            // 天气
            Text(AppStrings.weather, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: Weather.values.map((w) {
                return FilterChip(
                  label: Text('${w.emoji} ${w.label}'),
                  selected: _weather == w,
                  onSelected: (_) =>
                      setState(() => _weather = _weather == w ? null : w),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // 心情
            Text(AppStrings.mood, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            MoodSelector(
              selected: _mood,
              onChanged: (mood) => setState(() => _mood = mood),
            ),
            const SizedBox(height: 16),

            // 地点
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: AppStrings.location,
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: () {
        // TODO: 调用 image_picker 选择图片
      },
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.dividerDark, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_outlined, size: 32, color: AppColors.textSecondary(context)),
              const SizedBox(height: 4),
              Text(
                '添加照片（最多9张）',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
