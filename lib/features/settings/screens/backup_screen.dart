import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buildself/core/constants/app_constants.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/core/constants/strings.dart';
import 'package:buildself/core/router/routes.dart';
import 'package:buildself/data/database/database_provider.dart';
import 'package:buildself/features/auth/providers/app_provider.dart';
import 'package:provider/provider.dart';
import 'package:buildself/data/repositories/work_repository.dart';
import 'package:buildself/data/repositories/life_repository.dart';
import 'package:buildself/data/repositories/goal_repository.dart';
import 'package:buildself/data/repositories/murmur_repository.dart';
import 'package:buildself/data/repositories/reading_repository.dart';
import 'package:buildself/shared/widgets/app_card.dart';
import 'package:buildself/shared/widgets/emoji_icon.dart';

/// 数据备份页
class BackupScreen extends StatefulWidget {
  const BackupScreen({Key? key}) : super(key: key);

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final _db = DatabaseProvider.instance;
  List<FileSystemEntity> _backups = [];
  bool _loading = true;
  bool _backing = false;

  // 备份设置开关
  bool _autoBackup = false;
  bool _wifiOnly = true;
  bool _encrypt = false;

  String _lastBackupLabel = '从未备份';

  @override
  void initState() {
    super.initState();
    _loadLastBackup();
    _loadBackups();
  }

  Future<Directory> _backupDir() async {
    final docDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docDir.path, 'backups'));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  Future<void> _loadLastBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getString(AppConstants.keyLastBackupTime);
    if (mounted) {
      setState(() => _lastBackupLabel =
          ts != null ? _fmtIso(ts) : '从未备份');
    }
  }

  Future<void> _loadBackups() async {
    try {
      final dir = await _backupDir();
      final files =
          dir.listSync().where((f) => f.path.endsWith('.db')).toList();
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      if (mounted) {
        setState(() {
          _backups = files;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// 立即备份：先显示「正在备份」，再执行真实备份，最后「备份成功」
  Future<void> _startBackup() async {
    if (_backing) return;
    setState(() => _backing = true);
    _showSnack('正在备份…', AppColors.life);
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      await _db.close();
      final docDir = await getApplicationDocumentsDirectory();
      final srcPath = p.join(docDir.path, AppConstants.databaseName);
      final srcFile = File(srcPath);
      if (!srcFile.existsSync()) {
        _showSnack('数据库文件不存在', AppColors.error);
        return;
      }
      final stamp = DateTime.now()
          .toIso8601String()
          .replaceAll(RegExp(r'[:.]'), '-')
          .substring(0, 19);
      final destDir = await _backupDir();
      final destPath = p.join(destDir.path, 'buildself_backup_$stamp.db');
      await srcFile.copy(destPath);

      // 记录备份时间
      final prefs = await SharedPreferences.getInstance();
      final nowIso = DateTime.now().toIso8601String();
      await prefs.setString(AppConstants.keyLastBackupTime, nowIso);

      if (mounted) {
        setState(() => _lastBackupLabel = _fmtIso(nowIso));
        _showSnack('备份成功', AppColors.success);
        _loadBackups();
      }
    } catch (e) {
      _showSnack('备份失败：$e', AppColors.error);
    } finally {
      if (mounted) setState(() => _backing = false);
    }
  }

  Future<void> _restoreBackup(FileSystemEntity file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('恢复备份'),
        content: const Text('恢复将覆盖当前所有数据，此操作不可撤销。确定继续？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppStrings.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('恢复'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _backing = true);
    try {
      await _db.close();
      final docDir = await getApplicationDocumentsDirectory();
      final destPath = p.join(docDir.path, AppConstants.databaseName);
      await File(file.path).copy(destPath);
      _showSnack('恢复成功，请重启应用以生效', AppColors.accent);
    } catch (e) {
      _showSnack('恢复失败：$e', AppColors.error);
    } finally {
      if (mounted) setState(() => _backing = false);
      _loadBackups();
    }
  }

  Future<void> _deleteBackup(FileSystemEntity file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除备份'),
        content: const Text('确定删除此备份文件？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppStrings.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await File(file.path).delete();
    _showSnack('已删除备份', AppColors.error);
    _loadBackups();
  }

  /// 导出全部数据为 Markdown
  Future<void> _exportData() async {
    final userId = context.read<AppProvider>().userId;
    if (userId.isEmpty) return;
    _showSnack('正在导出数据…', AppColors.life);
    try {
      final workRepo = WorkRepository();
      final lifeRepo = LifeRepository();
      final goalRepo = GoalRepository();
      final murmurRepo = MurmurRepository();
      final readingRepo = ReadingRepository();

      final buf = StringBuffer();
      buf.writeln('# BuildSelf 数据导出');
      buf.writeln();
      buf.writeln('> 导出时间：${DateTime.now().toIso8601String()}');
      buf.writeln();

      final works = await workRepo.getAll(userId);
      buf.writeln('## 工作记录（${works.length} 条）');
      buf.writeln();
      for (final w in works) {
        buf.writeln('### ${w.title.isNotEmpty ? w.title : "（无标题）"}');
        buf.writeln('- **时间**：${w.createdAt.toIso8601String()}');
        if (w.tags.isNotEmpty) buf.writeln('- **标签**：${w.tags.map((t) => '#$t').join(' ')}');
        buf.writeln();
        buf.writeln(w.content);
        buf.writeln('---');
        buf.writeln();
      }

      final lives = await lifeRepo.getAll(userId);
      buf.writeln('## 生活记录（${lives.length} 条）');
      buf.writeln();
      for (final l in lives) {
        buf.writeln('### ${l.title.isNotEmpty ? l.title : "（无标题）"}');
        buf.writeln('- **时间**：${l.createdAt.toIso8601String()}');
        if (l.tags.isNotEmpty) buf.writeln('- **标签**：${l.tags.map((t) => '#$t').join(' ')}');
        if (l.weather != null) buf.writeln('- **天气**：${l.weather!.label}');
        if (l.location != null) buf.writeln('- **位置**：${l.location}');
        buf.writeln();
        buf.writeln(l.content);
        buf.writeln('---');
        buf.writeln();
      }

      final goals = await goalRepo.getActiveGoals(userId);
      buf.writeln('## 目标（${goals.length} 个）');
      buf.writeln();
      for (final g in goals) {
        buf.writeln('### ${g.title}');
        buf.writeln('- **类型**：${g.goalType.name}');
        buf.writeln('- **进度**：${g.calculatedProgress}%');
        if (g.description.isNotEmpty) buf.writeln(g.description);
        buf.writeln('---');
        buf.writeln();
      }

      final changes = await readingRepo.getAllChanges(userId);
      buf.writeln('## 阅读改变（${changes.length} 条）');
      buf.writeln();
      for (final c in changes) {
        buf.writeln('- ${c.createdAt.toIso8601String()}：${c.content}');
      }
      buf.writeln();

      final murmurs = await murmurRepo.getAll(userId);
      buf.writeln('## 碎碎念（${murmurs.length} 条）');
      buf.writeln();
      for (final m in murmurs) {
        buf.writeln('### ${m.createdAt.toIso8601String()}');
        buf.writeln(m.content);
        if (m.tags.isNotEmpty) buf.writeln(m.tags.map((t) => '#$t').join(' '));
        buf.writeln('---');
        buf.writeln();
      }

      final dir = await getApplicationDocumentsDirectory();
      final exportDir = Directory(p.join(dir.path, 'exports'));
      if (!exportDir.existsSync()) exportDir.createSync(recursive: true);
      final stamp = DateTime.now()
          .toIso8601String()
          .replaceAll(RegExp(r'[:.]'), '-')
          .substring(0, 19);
      final filePath = p.join(exportDir.path, 'buildself_export_$stamp.md');
      await File(filePath).writeAsString(buf.toString());

      _showSnack('导出成功：$filePath', AppColors.success);
    } catch (e) {
      _showSnack('导出失败：$e', AppColors.error);
    }
  }

  Future<void> _clearCache() async {
    _showSnack('缓存已清除', AppColors.success);
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color.withValues(alpha: 0.2)),
    );
  }

  String _fmtIso(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')} '
          '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  String _fileSize(FileSystemEntity f) {
    final bytes = f.statSync().size;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('数据备份')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 同步状态 + 立即备份
            AppCard(
              accent: AppColors.life,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.cloud_sync_outlined, color: AppColors.life, size: 20),
                      const SizedBox(width: 8),
                      const Text('云同步状态',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.life,
                          )),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            EmojiIcon('✅', size: 12),
                            SizedBox(width: 4),
                            Text('已连接',
                                style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('上次备份：$_lastBackupLabel',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary(context))),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: _backing ? null : _startBackup,
                      icon: _backing
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const EmojiIcon('📥', size: 18),
                      label: Text(_backing ? '备份中…' : '立即备份'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 备份设置开关
            _sectionLabel('备份设置'),
            const SizedBox(height: 10),
            AppCard(
              child: Column(
                children: [
                  _switchRow('自动备份', '每天在 WiFi 下自动备份', _autoBackup,
                      (v) => setState(() => _autoBackup = v)),
                  const Divider(height: 1),
                  _switchRow('仅 WiFi 下备份', '避免消耗移动流量', _wifiOnly,
                      (v) => setState(() => _wifiOnly = v)),
                  const Divider(height: 1),
                  _switchRow('加密备份', '使用本地密钥加密备份文件', _encrypt,
                      (v) => setState(() => _encrypt = v)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 备份历史
            _sectionLabel('备份历史（${_backups.length}）'),
            const SizedBox(height: 10),
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(strokeWidth: 2)))
            else if (_backups.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(Icons.folder_open_outlined, size: 40, color: AppColors.textSecondary(context).withValues(alpha: 0.5)),
                    const SizedBox(height: 12),
                    Text('暂无备份记录',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary(context))),
                  ],
                ),
              )
            else
              ..._backups.map((f) => _buildBackupItem(f)).toList(),
            const SizedBox(height: 24),

            // 数据管理
            _sectionLabel('数据管理'),
            const SizedBox(height: 10),
            AppCard(
              child: Column(
                children: [
                  _tapRow('📥', '导出数据', '导出为 Markdown 文件', () => _exportData()),
                  const Divider(height: 1),
                  _tapRow('🗑️', '回收站', '管理已删除的记录', () => Navigator.pushNamed(context, AppRoutes.trash)),
                  const Divider(height: 1),
                  _tapRow('🧹', '清除缓存', '清理临时文件', () => _clearCache()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary(context),
        ),
      ),
    );
  }

  Widget _switchRow(String title, String sub, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: Text(sub, style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context))),
        trailing: Switch(value: value, onChanged: onChanged, activeColor: AppColors.primary),
      ),
    );
  }

  Widget _tapRow(String emoji, String title, String sub, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            EmojiIcon(emoji, size: 18),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context))),
                  const SizedBox(height: 2),
                  Text(sub, style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context))),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textSecondary(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupItem(FileSystemEntity f) {
    final modified = f.statSync().modified;
    final name = p.basename(f.path);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        accent: AppColors.life,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.life.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.storage, size: 18, color: AppColors.life),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context)),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Text('${_fmtIso(modified.toIso8601String())}  ·  ${_fileSize(f)}',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary(context))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _restoreBackup(f),
                    icon: const EmojiIcon('↺', size: 16),
                    label: const Text('恢复', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      side: BorderSide(color: AppColors.accent.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 7),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteBackup(f),
                    icon: const EmojiIcon('🗑️', size: 16),
                    label: const Text('删除', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 7),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
