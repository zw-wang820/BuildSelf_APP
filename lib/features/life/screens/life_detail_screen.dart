import 'package:flutter/material.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/core/constants/strings.dart';
import 'package:buildself/core/router/routes.dart';
import 'package:buildself/data/models/life_record_model.dart';
import 'package:buildself/data/repositories/life_repository.dart';
import 'package:buildself/shared/widgets/emoji_icon.dart';
import 'package:buildself/shared/widgets/empty_state.dart';
import 'package:buildself/shared/widgets/markdown_text.dart';

/// 生活记录详情页
class LifeDetailScreen extends StatefulWidget {
  final String? recordId;

  const LifeDetailScreen({Key? key, this.recordId}) : super(key: key);

  @override
  State<LifeDetailScreen> createState() => _LifeDetailScreenState();
}

class _LifeDetailScreenState extends State<LifeDetailScreen> {
  final LifeRepository _repo = LifeRepository();
  LifeRecord? _record;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRecord();
  }

  Future<void> _loadRecord() async {
    if (widget.recordId == null) {
      setState(() => _loading = false);
      return;
    }
    _record = await _repo.getById(widget.recordId!);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _delete() async {
    if (_record == null) return;
    await _repo.softDelete(_record!.id);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AppStrings.deleteSuccess)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.lifeTitle),
        actions: [
          if (_record != null)
            IconButton(
              icon: const EmojiIcon('✏️', size: 20),
              onPressed: () async {
                await Navigator.pushNamed(context, AppRoutes.lifeEdit,
                    arguments: _record);
                _loadRecord();
              },
            ),
          if (_record != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') _showDeleteDialog(context);
              },
              itemBuilder: (context) =>
                  [PopupMenuItem(value: 'delete', child: Text(AppStrings.delete))],
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _record == null
              ? const EmptyState(message: '记录不存在')
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final record = _record!;
    const color = AppColors.life;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 类型标签 + 日期
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: color.withValues(alpha: 0.5), width: 0.6),
              ),
              child: Text(
                record.recordType,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.life,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Spacer(),
            Text(
              _formatFullDate(record.createdAt),
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary(context),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 标题
        if (record.title.isNotEmpty) ...[
          Text(
            record.title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary(context),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
        ],

        // 内容（Markdown 渲染）
        MarkdownText(
          record.content,
          baseStyle: TextStyle(
            fontSize: 15,
            color: AppColors.textPrimary(context),
            height: 1.6,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 16),

        // 元信息（心情 / 地点）
        if (record.mood != null ||
            (record.location != null && record.location!.isNotEmpty)) ...[
          const Divider(),
          const SizedBox(height: 8),
          Row(
            children: [
              if (record.mood != null) ...[
                Text('${record.mood!.emoji} ${record.mood!.label}',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary(context))),
                const SizedBox(width: 16),
              ],
              if (record.location != null && record.location!.isNotEmpty) ...[
                Icon(Icons.location_on_outlined,
                    size: 14, color: color.withValues(alpha: 0.7)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(record.location!,
                      style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary(context)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ],
          ),
        ],
      ]),
    );
  }

  String _formatFullDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除记录'),
        content: const Text('确定删除这条记录吗？删除后可在回收站恢复，30天后永久清除。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppStrings.cancel)),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _delete();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }
}
