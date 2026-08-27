import 'package:buildself/data/models/reading_models.dart';

/// 书籍封面 emoji 预设池 — 书籍主题意象
///
/// 未手动指定封面 emoji 的书籍，按书名 hash 稳定分配其中一个，
/// 保证同一本书在任何页面显示一致，且不同书籍封面不千篇一律。
const List<String> bookCoverEmojis = [
  '📚',
  '📖',
  '📕',
  '📗',
  '📘',
  '📙',
  '📔',
  '📓',
  '💻',
  '🧠',
  '🚀',
  '🌱',
  '💡',
  '🎯',
  '🌍',
  '🖋️',
];

/// 解析书籍封面 emoji — 手动指定优先，否则按书名 hash 分配
String resolveCoverEmoji(Book book) =>
    resolveCoverEmojiFor(book.title, book.coverEmoji);

/// 按书名 + 手动指定值解析封面 emoji（表单实时预览用）
String resolveCoverEmojiFor(String title, String? coverEmoji) {
  if (coverEmoji != null && coverEmoji.isNotEmpty) {
    return coverEmoji;
  }
  final t = title.isEmpty ? '书' : title;
  var hash = 0;
  for (final code in t.codeUnits) {
    hash = (hash + code) & 0x7fffffff;
  }
  return bookCoverEmojis[hash % bookCoverEmojis.length];
}
