import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/core/constants/strings.dart';
import 'package:buildself/core/router/routes.dart';
import 'package:buildself/data/models/life_record_model.dart';
import 'package:buildself/data/repositories/life_repository.dart';
import 'package:buildself/features/auth/providers/app_provider.dart';
import 'package:buildself/shared/layouts/main_scaffold.dart';
import 'package:buildself/shared/widgets/app_card.dart';
import 'package:buildself/shared/widgets/empty_state.dart';
import 'package:buildself/shared/widgets/nexus_background.dart';

/// 生活记录列表页
class LifeListScreen extends StatefulWidget {
  const LifeListScreen({Key? key}) : super(key: key);

  @override
  State<LifeListScreen> createState() => _LifeListScreenState();
}

class _LifeListScreenState extends State<LifeListScreen> {
  final LifeRepository _repo = LifeRepository();
  String? _filterType;
  List<String> _categories = [];
  List<LifeRecord> _records = [];
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
    _records = await _repo.getAll(userId, type: _filterType);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.lifeTitle),
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
                          color: AppColors.life,
                          strokeWidth: 2,
                        ),
                      )
                    : _buildListView(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, AppRoutes.lifeEdit);
          _loadCategories();
          _loadData();
        },
        backgroundColor: AppColors.life,
        foregroundColor: AppColors.spaceDeep,
        child: const Icon(Icons.add),
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
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _filterType = isSelected ? null : type);
        _loadData();
      },
      selectedColor: AppColors.life.withOpacity(0.18),
      checkmarkColor: AppColors.life,
      backgroundColor: AppColors.spaceHigh,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.life : AppColors.textSecondary(context),
        fontSize: 13,
      ),
      side: BorderSide(
        color: AppColors.life.withOpacity(isSelected ? 0.6 : 0.3),
        width: 0.8,
      ),
      shape: const StadiumBorder(),
    );
  }

  Widget _buildListView() {
    if (_records.isEmpty) {
      return EmptyState(
        icon: Icons.local_cafe_outlined,
        message: '还没有生活记录\n记录下生活中的美好瞬间',
        onAction: () async {
          await Navigator.pushNamed(context, AppRoutes.lifeEdit);
          _loadCategories();
          _loadData();
        },
        actionLabel: '新建记录',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _records.length,
      itemBuilder: (context, index) => _buildRecordCard(_records[index]),
    );
  }

  Widget _buildRecordCard(LifeRecord record) {
    final color = AppColors.life;

    return AppCard(
      accent: color,
      margin: const EdgeInsets.only(bottom: 10),
      onTap: () => _showDetailSheet(record),
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
                  record.recordType,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (record.mood != null) ...[
                const SizedBox(width: 8),
                Text(record.mood!.emoji, style: const TextStyle(fontSize: 14)),
              ],
              if (record.weather != null) ...[
                const SizedBox(width: 4),
                Text(record.weather!.emoji, style: const TextStyle(fontSize: 14)),
              ],
              const Spacer(),
              Text(
                _formatDate(record.createdAt),
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary(context),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          if (record.title.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              record.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary(context),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            record.content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary(context),
              height: 1.5,
              letterSpacing: 0.3,
            ),
          ),
          if (record.location != null && record.location!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 14, color: color.withOpacity(0.7)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    record.location!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary(context),
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showDetailSheet(LifeRecord record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return _LifeDetailSheet(record: record);
          },
        );
      },
    );
  }

  String _formatDate(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  void _showSearch(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('搜索生活记录'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '输入关键词'),
          onSubmitted: (value) async {
            Navigator.pop(ctx);
            if (value.trim().isNotEmpty) {
              final userId = this.context.read<AppProvider>().userId;
              final results = await _repo.search(userId, value.trim());
              if (!mounted) return;
              setState(() {
                _filterType = null;
                _records = results;
              });
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _loadData();
            },
            child: const Text('清除搜索'),
          ),
        ],
      ),
    );
  }
}

/// 生活记录详情 BottomSheet
class _LifeDetailSheet extends StatelessWidget {
  final LifeRecord record;

  const _LifeDetailSheet({Key? key, required this.record}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = AppColors.life;

    return SingleChildScrollView(
      controller: PrimaryScrollController.of(context),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 拖动条
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary(context).withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 类型标签
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: color.withOpacity(0.5), width: 0.6),
                ),
                child: Text(
                  record.recordType,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
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

          // 内容
          Text(
            record.content,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary(context),
              height: 1.6,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 16),

          // 元信息
          if (record.mood != null || record.weather != null || (record.location != null && record.location!.isNotEmpty)) ...[
            Divider(color: AppColors.dividerDark, height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                if (record.mood != null) ...[
                  Text('${record.mood!.emoji} ${record.mood!.label}',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary(context))),
                  const SizedBox(width: 16),
                ],
                if (record.weather != null) ...[
                  Text('${record.weather!.emoji} ${record.weather!.label}',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary(context))),
                  const SizedBox(width: 16),
                ],
                if (record.location != null && record.location!.isNotEmpty) ...[
                  Icon(Icons.location_on_outlined, size: 14, color: color.withOpacity(0.7)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(record.location!,
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary(context)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  String _formatFullDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
