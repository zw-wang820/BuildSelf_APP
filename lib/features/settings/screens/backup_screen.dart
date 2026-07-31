import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:buildself/core/constants/app_constants.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/core/constants/strings.dart';
import 'package:buildself/data/database/database_provider.dart';
import 'package:buildself/shared/widgets/app_card.dart';
import 'package:buildself/shared/widgets/nexus_background.dart';

/// 备份与恢复页 — NEXUS 数据保险库
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

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<Directory> _backupDir() async {
    final docDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docDir.path, 'backups'));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  Future<void> _loadBackups() async {
    try {
      final dir = await _backupDir();
      final files = dir.listSync().where((f) => f.path.endsWith('.db')).toList();
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      if (mounted) setState(() {
        _backups = files;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createBackup() async {
    setState(() => _backing = true);
    try {
      // 关闭数据库连接，确保数据写入磁盘
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

      _showSnack('备份成功', AppColors.accent);
      _loadBackups();
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(AppStrings.cancel)),
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(AppStrings.cancel)),
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

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color.withOpacity(0.2)),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.primary, blurRadius: 6)],
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '// VAULT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 2,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(width: 10),
            const Text('备份与恢复'),
          ],
        ),
      ),
      body: NexusBackground(
        child: SafeArea(
          child: _backing
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 备份操作卡
                      AppCard(
                        glow: true,
                        accent: AppColors.primary,
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.cloud_upload_outlined, size: 20, color: AppColors.primary),
                                const SizedBox(width: 8),
                                const Text(
                                  'CREATE BACKUP',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                    letterSpacing: 2,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              '将当前所有数据保存为备份文件，可用于日后恢复',
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondaryDark, height: 1.5),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _createBackup,
                                icon: const Icon(Icons.backup_outlined, size: 18),
                                label: const Text('立即备份', style: TextStyle(letterSpacing: 1)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 备份列表标题
                      Row(
                        children: [
                          const Text(
                            'BACKUP ARCHIVES',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondaryDark,
                              letterSpacing: 2,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const Spacer(),
                          Text('${_backups.length} 个',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondaryDark,
                                fontFamily: 'monospace',
                              )),
                        ],
                      ),
                      const SizedBox(height: 10),

                      if (_loading)
                        const Center(child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                        ))
                      else if (_backups.isEmpty)
                        _buildEmptyArchive()
                      else
                        ..._backups.map((f) => _buildBackupItem(f)),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyArchive() {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.folder_open_outlined, size: 40, color: AppColors.textSecondaryDark.withOpacity(0.5)),
          const SizedBox(height: 12),
          const Text('暂无备份记录',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondaryDark, letterSpacing: 0.3)),
        ],
      ),
    );
  }

  Widget _buildBackupItem(FileSystemEntity f) {
    final modified = f.statSync().modified;
    final name = p.basename(f.path);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        accent: AppColors.primary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 0.8),
                  ),
                  child: const Icon(Icons.storage, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimaryDark,
                            fontFamily: 'monospace',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Text(
                        '${_formatDate(modified)}  ·  ${_fileSize(f)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondaryDark,
                          fontFamily: 'monospace',
                          letterSpacing: 0.3,
                        ),
                      ),
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
                    icon: const Icon(Icons.restore, size: 16),
                    label: const Text('恢复', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      side: BorderSide(color: AppColors.accent.withOpacity(0.5), width: 0.8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 7),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteBackup(f),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('删除', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error.withOpacity(0.5), width: 0.8),
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
