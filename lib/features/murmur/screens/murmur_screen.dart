import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/core/constants/strings.dart';
import 'package:buildself/data/models/enums.dart';
import 'package:buildself/data/models/murmur_model.dart';
import 'package:buildself/data/repositories/murmur_repository.dart';
import 'package:buildself/features/auth/providers/app_provider.dart';
import 'package:buildself/shared/widgets/app_card.dart';
import 'package:buildself/shared/widgets/empty_state.dart';
import 'package:buildself/shared/widgets/mood_selector.dart';
import 'package:buildself/shared/widgets/nexus_background.dart';

/// 碎碎念页 — 时间线 + 快速记录
class MurmurScreen extends StatefulWidget {
  const MurmurScreen({Key? key}) : super(key: key);

  @override
  State<MurmurScreen> createState() => _MurmurScreenState();
}

class _MurmurScreenState extends State<MurmurScreen> {
  final MurmurRepository _repo = MurmurRepository();
  final _contentController = TextEditingController();
  Mood? _mood;
  bool _isExpanded = false;
  List<Murmur> _murmurs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final userId = context.read<AppProvider>().userId;
    if (userId.isEmpty) return;
    setState(() => _loading = true);
    _murmurs = await _repo.getAll(userId);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (_contentController.text.trim().isEmpty) return;

    final userId = context.read<AppProvider>().userId;
    if (userId.isEmpty) return;

    try {
      await _repo.create(
        userId: userId,
        content: _contentController.text.trim(),
        mood: _mood,
      );
      _contentController.clear();
      setState(() {
        _mood = null;
        _isExpanded = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已记下'),
            duration: Duration(milliseconds: 800),
          ),
        );
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }

  Future<void> _deleteMurmur(Murmur murmur) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条碎碎念吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(AppStrings.delete, style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _repo.softDelete(murmur.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppStrings.deleteSuccess),
              duration: Duration(seconds: 1),
            ),
          );
        }
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败: $e')),
          );
        }
      }
    }
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
                color: AppColors.murmur,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.murmur, blurRadius: 6)],
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '// MURMUR',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.murmur,
                letterSpacing: 2,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                AppStrings.murmurTitle,
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
      ),
      body: NexusBackground(
        child: SafeArea(
          child: Column(
            children: [
              // 快速记录区
              _buildQuickInput(),
              // 时间线
              Expanded(child: _buildTimeline()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.spaceHigh.withOpacity(0.9),
        border: Border(
          bottom: BorderSide(color: AppColors.dividerDark, width: 0.8),
        ),
      ),
      child: Column(
        children: [
          TextField(
            controller: _contentController,
            maxLines: _isExpanded ? 5 : 2,
            style: const TextStyle(
              color: AppColors.textPrimaryDark,
              fontSize: 14,
              height: 1.5,
              letterSpacing: 0.3,
            ),
            decoration: InputDecoration(
              hintText: AppStrings.murmurHint,
              hintStyle: const TextStyle(color: AppColors.textSecondaryDark),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.dividerDark),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.dividerDark),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.murmur.withOpacity(0.6), width: 1),
              ),
            ),
            onTap: () => setState(() => _isExpanded = true),
          ),
          if (_isExpanded) ...[
            const SizedBox(height: 8),
            MoodSelector(
              selected: _mood,
              onChanged: (mood) => setState(() => _mood = mood),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_isExpanded)
                TextButton(
                  onPressed: () => setState(() {
                    _isExpanded = false;
                    _mood = null;
                  }),
                  child: const Text(AppStrings.cancel),
                ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.murmur,
                  foregroundColor: AppColors.spaceDeep,
                  elevation: 4,
                  shadowColor: AppColors.murmur,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(AppStrings.murmurSave),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.murmur, strokeWidth: 2),
      );
    }
    if (_murmurs.isEmpty) {
      return EmptyState(
        icon: Icons.auto_awesome,
        message: '还没有碎碎念\n写下此刻的想法吧',
      );
    }

    // 按日期分组
    final grouped = <String, List<Murmur>>{};
    for (final m in _murmurs) {
      final key = _dateKey(m.createdAt);
      grouped.putIfAbsent(key, () => []).add(m);
    }
    final keys = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final key = keys[index];
        final list = grouped[key]!;
        return _buildDateGroup(key, list);
      },
    );
  }

  Widget _buildDateGroup(String dateKey, List<Murmur> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              width: 3,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.murmur,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(color: AppColors.murmur.withOpacity(0.7), blurRadius: 4),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              dateKey,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.murmur,
                fontFamily: 'monospace',
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...list.map((m) => _buildMurmurCard(m)),
      ],
    );
  }

  Widget _buildMurmurCard(Murmur murmur) {
    return GestureDetector(
      onLongPress: () => _deleteMurmur(murmur),
      child: AppCard(
        accent: AppColors.murmur,
        margin: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              murmur.content,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimaryDark,
                height: 1.5,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (murmur.mood != null) ...[
                  Text(
                    '${murmur.mood!.emoji} ${murmur.mood!.label}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                const Spacer(),
                Text(
                  _formatTime(murmur.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondaryDark,
                    fontFamily: 'monospace',
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _dateKey(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  String _formatTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
