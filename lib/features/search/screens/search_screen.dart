import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/core/router/routes.dart';
import 'package:buildself/data/repositories/work_repository.dart';
import 'package:buildself/data/repositories/life_repository.dart';
import 'package:buildself/data/repositories/goal_repository.dart';
import 'package:buildself/data/repositories/murmur_repository.dart';
import 'package:buildself/data/repositories/reading_repository.dart';
import 'package:buildself/features/auth/providers/app_provider.dart';
import 'package:buildself/shared/widgets/app_card.dart';
import 'package:buildself/shared/widgets/nexus_background.dart';

/// 搜索范围标识
class _SearchScope {
  static const String all = 'all';
  static const String reading = 'reading';
}

/// 搜索页 — 支持全局搜索和模块内搜索
class SearchScreen extends StatefulWidget {
  final String scope;

  const SearchScreen({Key? key, this.scope = _SearchScope.all}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final WorkRepository _workRepo = WorkRepository();
  final LifeRepository _lifeRepo = LifeRepository();
  final GoalRepository _goalRepo = GoalRepository();
  final MurmurRepository _murmurRepo = MurmurRepository();
  final ReadingRepository _readingRepo = ReadingRepository();

  List<_SearchResult> _results = [];
  bool _searching = false;
  bool _hasSearched = false;
  late String _scope;

  @override
  void initState() {
    super.initState();
    _scope = widget.scope;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && args.isNotEmpty) {
      _scope = args;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _hintText {
    switch (_scope) {
      case _SearchScope.reading:
        return '搜索书籍、作者、读书笔记…';
      default:
        return '搜索工作 / 生活 / 目标 / 碎碎念…';
    }
  }

  String get _scopeLabel {
    switch (_scope) {
      case _SearchScope.reading:
        return '// LIBRARY';
      default:
        return '// SEARCH SCOPE';
    }
  }

  Color get _scopeColor {
    switch (_scope) {
      case _SearchScope.reading:
        return AppColors.reading;
      default:
        return AppColors.primary;
    }
  }

  Future<void> _doSearch(String keyword) async {
    final kw = keyword.trim();
    if (kw.isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _searching = true;
      _hasSearched = true;
    });

    final userId = context.read<AppProvider>().userId;
    if (userId.isEmpty) {
      setState(() => _searching = false);
      return;
    }

    final results = <_SearchResult>[];
    try {
      if (_scope == _SearchScope.reading) {
        // 只搜索阅读模块：书籍 + 笔记
        final books = await _readingRepo.searchBooks(userId, kw);
        final notes = await _readingRepo.searchNotes(userId, kw);

        for (final b in books) {
          final subtitleParts = <String>[];
          if (b.author?.isNotEmpty == true) subtitleParts.add('作者：${b.author}');
          subtitleParts.add('状态：${_bookStatusLabel(b.status)}');
          if (b.tags.isNotEmpty) subtitleParts.add('#${b.tags.join(' #')}');
          results.add(_SearchResult(
            title: b.title,
            subtitle: subtitleParts.join('  ·  '),
            moduleTag: 'BOOK',
            moduleColor: AppColors.reading,
            date: b.createdAt,
            onTap: () => Navigator.pushNamed(context, AppRoutes.bookDetail, arguments: b.id),
          ));
        }
        for (final n in notes) {
          final chap = n.chapter?.isNotEmpty == true ? '「${n.chapter}」 ' : '';
          results.add(_SearchResult(
            title: '$chap${n.content}',
            subtitle: '笔记类型：${_noteTypeLabel(n.noteType)}',
            moduleTag: 'NOTE',
            moduleColor: AppColors.reading.withOpacity(0.8),
            date: n.createdAt,
            onTap: () => Navigator.pushNamed(context, AppRoutes.bookDetail, arguments: n.bookId),
          ));
        }
      } else {
        // 全局搜索
        final futures = await Future.wait([
          _workRepo.search(userId, kw),
          _lifeRepo.search(userId, kw),
          _goalRepo.search(userId, kw),
          _murmurRepo.search(userId, kw),
        ]);

        for (final n in futures[0] as List) {
          results.add(_SearchResult(
            title: n.title.isNotEmpty ? n.title : '(无标题)',
            subtitle: n.content,
            moduleTag: 'WORK',
            moduleColor: AppColors.work,
            date: n.createdAt,
            onTap: () => Navigator.pushNamed(context, AppRoutes.workDetail, arguments: n.id),
          ));
        }
        for (final r in futures[1] as List) {
          results.add(_SearchResult(
            title: r.title.isNotEmpty ? r.title : '(无标题)',
            subtitle: r.content,
            moduleTag: 'LIFE',
            moduleColor: AppColors.life,
            date: r.createdAt,
            onTap: () => Navigator.pushNamed(context, AppRoutes.lifeList),
          ));
        }
        for (final g in futures[2] as List) {
          results.add(_SearchResult(
            title: g.title,
            subtitle: g.description,
            moduleTag: 'GOAL',
            moduleColor: AppColors.goal,
            date: g.createdAt,
            onTap: () => Navigator.pushNamed(context, AppRoutes.goalDetail, arguments: g.id),
          ));
        }
        for (final m in futures[3] as List) {
          results.add(_SearchResult(
            title: m.content,
            subtitle: m.tags.isNotEmpty ? '#${m.tags.join(' #')}' : '',
            moduleTag: 'MURMUR',
            moduleColor: AppColors.murmur,
            date: m.createdAt,
            onTap: () => Navigator.pushNamed(context, AppRoutes.murmur),
          ));
        }
      }

      // 按时间倒序
      results.sort((a, b) => b.date.compareTo(a.date));
    } catch (_) {
      // 忽略错误，保持空结果
    }

    if (mounted) {
      setState(() {
        _results = results;
        _searching = false;
      });
    }
  }

  String _bookStatusLabel(dynamic s) {
    switch (s.name) {
      case 'planned':
        return '待读';
      case 'reading':
        return '在读';
      case 'finished':
        return '已读完';
      case 'paused':
        return '暂停';
      default:
        return s.name;
    }
  }

  String _noteTypeLabel(dynamic t) {
    switch (t.name) {
      case 'highlight':
        return '划线';
      case 'note':
        return '笔记';
      case 'insight':
        return '想法';
      case 'change':
        return '改变';
      default:
        return t.name;
    }
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
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onSubmitted: _doSearch,
          style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 15),
          decoration: InputDecoration(
            hintText: _hintText,
            hintStyle: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 14),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondaryDark),
                    onPressed: () {
                      _controller.clear();
                      setState(() {
                        _results = [];
                        _hasSearched = false;
                      });
                    },
                  )
                : null,
          ),
          onChanged: (_) => setState(() {}),
        ),
        actions: [
          TextButton(
            onPressed: () => _doSearch(_controller.text),
            child: const Text('搜索', style: TextStyle(letterSpacing: 1)),
          ),
        ],
      ),
      body: NexusBackground(
        child: SafeArea(
          child: _searching
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
              : _hasSearched
                  ? _results.isEmpty
                      ? _buildEmpty()
                      : _buildResultList()
                  : _buildHint(),
        ),
      ),
    );
  }

  Widget _buildHint() {
    late List<_ModuleHint> modules;
    switch (_scope) {
      case _SearchScope.reading:
        modules = [
          _ModuleHint(icon: Icons.menu_book_outlined, label: '书籍（按书名 / 作者）', tag: 'BOOK', color: AppColors.reading),
          _ModuleHint(icon: Icons.edit_note_outlined, label: '读书笔记（按内容）', tag: 'NOTE', color: AppColors.reading.withOpacity(0.8)),
        ];
        break;
      default:
        modules = [
          _ModuleHint(icon: Icons.event_outlined, label: '工作记录', tag: 'WORK', color: AppColors.work),
          _ModuleHint(icon: Icons.local_cafe_outlined, label: '生活记录', tag: 'LIFE', color: AppColors.life),
          _ModuleHint(icon: Icons.gps_fixed_outlined, label: '目标', tag: 'GOAL', color: AppColors.goal),
          _ModuleHint(icon: Icons.auto_awesome, label: '碎碎念', tag: 'MURMUR', color: AppColors.murmur),
        ];
    }
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 18, height: 1.2, color: _scopeColor.withOpacity(0.6)),
              const SizedBox(width: 8),
              Text(
                _scopeLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _scopeColor,
                  letterSpacing: 2,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...modules.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  accent: m.color,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: m.color.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: m.color.withOpacity(0.4), width: 0.8),
                        ),
                        child: Icon(m.icon, color: m.color, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(m.label,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimaryDark,
                            )),
                      ),
                      Text(m.tag,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: m.color,
                            letterSpacing: 1.5,
                            fontFamily: 'monospace',
                          )),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _scopeColor.withOpacity(0.4), width: 1),
                color: _scopeColor.withOpacity(0.06),
                boxShadow: [BoxShadow(color: _scopeColor.withOpacity(0.25), blurRadius: 20)],
              ),
              child: Icon(Icons.search_off, size: 32, color: _scopeColor),
            ),
            const SizedBox(height: 16),
            const Text('未找到匹配记录',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondaryDark, letterSpacing: 0.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildResultList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: _results.length,
      itemBuilder: (context, i) {
        final r = _results[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppCard(
            accent: r.moduleColor,
            onTap: r.onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: r.moduleColor.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: r.moduleColor.withOpacity(0.5), width: 0.6),
                      ),
                      child: Text(r.moduleTag,
                          style: TextStyle(
                            fontSize: 9,
                            color: r.moduleColor,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            fontFamily: 'monospace',
                          )),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${r.date.month.toString().padLeft(2, '0')}.${r.date.day.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondaryDark,
                        fontFamily: 'monospace',
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  r.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (r.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    r.subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondaryDark,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SearchResult {
  final String title;
  final String subtitle;
  final String moduleTag;
  final Color moduleColor;
  final DateTime date;
  final VoidCallback onTap;

  _SearchResult({
    required this.title,
    required this.subtitle,
    required this.moduleTag,
    required this.moduleColor,
    required this.date,
    required this.onTap,
  });
}

class _ModuleHint {
  final IconData icon;
  final String label;
  final String tag;
  final Color color;

  _ModuleHint({required this.icon, required this.label, required this.tag, required this.color});
}
