/// 轻量 Markdown 解析器（方案 B：自研，零三方依赖）
///
/// V1 支持子集：标题(1-6)、粗体、斜体、无序/有序列表（一层嵌套）、
/// 引用、行内代码、代码块、分隔线、链接（仅展示不跳转）。
/// 纯 Dart 实现，无 Flutter 依赖，输出 block/span 模型供渲染层消费。

// ---------- 行内模型 ----------

/// 行内片段：一段带样式的文本
class MarkdownSpan {
  final String text;
  final bool bold;
  final bool italic;
  final bool code;
  final String? linkUrl;

  const MarkdownSpan(
    this.text, {
    this.bold = false,
    this.italic = false,
    this.code = false,
    this.linkUrl,
  });

  bool get isLink => linkUrl != null;
}

// ---------- 块级模型 ----------

/// 块级元素基类
abstract class MarkdownBlock {
  const MarkdownBlock();
}

/// 标题，level 1-6
class HeadingBlock extends MarkdownBlock {
  final int level;
  final List<MarkdownSpan> spans;
  const HeadingBlock(this.level, this.spans);
}

/// 普通段落
class ParagraphBlock extends MarkdownBlock {
  final List<MarkdownSpan> spans;
  const ParagraphBlock(this.spans);
}

/// 列表项
class MarkdownListItem {
  /// 缩进层级：0 顶层，1 嵌套
  final int level;
  final List<MarkdownSpan> spans;

  /// 有序列表的原始序号（如 '3'），无序为 null
  final String? number;
  const MarkdownListItem(this.spans, {this.level = 0, this.number});
}

/// 列表（无序/有序混合分组）
class ListBlock extends MarkdownBlock {
  final List<MarkdownListItem> items;
  const ListBlock(this.items);
}

/// 引用（连续 `>` 行合并为一个块，行间以 \n 分隔）
class QuoteBlock extends MarkdownBlock {
  final List<List<MarkdownSpan>> lines;
  const QuoteBlock(this.lines);
}

/// 代码块
class CodeBlock extends MarkdownBlock {
  final String code;
  const CodeBlock(this.code);
}

/// 分隔线
class DividerBlock extends MarkdownBlock {
  const DividerBlock();
}

// ---------- 解析 ----------

final RegExp _inlineRe = RegExp(
  r'(`[^`\n]+`)|(\*\*[^*\n]+\*\*)|(\*[^*\n]+\*)|(\[[^\]\n]+\]\([^)\n]+\))',
);
final RegExp _linkRe = RegExp(r'^\[([^\]]+)\]\(([^)]+)\)$');
final RegExp _headingRe = RegExp(r'^(#{1,6})\s+(.*)$');
final RegExp _dividerRe = RegExp(r'^\s*([-*_])\s*(?:\1\s*){2,}$');
final RegExp _dividerReMultiline =
    RegExp(r'^\s*([-*_])\s*(?:\1\s*){2,}$', multiLine: true);
final RegExp _bulletRe = RegExp(r'^(\s*)[-*]\s+(.*)$');
final RegExp _orderedRe = RegExp(r'^(\s*)(\d{1,3})[.、]\s+(.*)$');
final RegExp _quoteRe = RegExp(r'^\s*>\s?(.*)$');
final RegExp _fenceRe = RegExp(r'^\s*```');

/// 解析 Markdown 源文本为块级模型列表。
/// 输入为纯文本（无任何语法标记）时，整体输出为单个段落，天然向后兼容。
List<MarkdownBlock> parseMarkdown(String src) {
  final blocks = <MarkdownBlock>[];
  final lines = src.split('\n');
  final paragraphBuf = <String>[];
  final listBuf = <MarkdownListItem>[];
  final quoteBuf = <String>[];

  void flushParagraph() {
    if (paragraphBuf.isNotEmpty) {
      blocks.add(ParagraphBlock(parseInline(paragraphBuf.join('\n'))));
      paragraphBuf.clear();
    }
  }

  void flushList() {
    if (listBuf.isNotEmpty) {
      blocks.add(ListBlock(List.of(listBuf)));
      listBuf.clear();
    }
  }

  void flushQuote() {
    if (quoteBuf.isNotEmpty) {
      blocks.add(QuoteBlock(
        quoteBuf.map((l) => parseInline(l)).toList(),
      ));
      quoteBuf.clear();
    }
  }

  void flushAll() {
    flushParagraph();
    flushList();
    flushQuote();
  }

  var inCodeFence = false;
  final codeBuf = <String>[];

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];

    // 代码块围栏
    if (_fenceRe.hasMatch(line)) {
      if (inCodeFence) {
        blocks.add(CodeBlock(codeBuf.join('\n')));
        codeBuf.clear();
        inCodeFence = false;
      } else {
        flushAll();
        inCodeFence = true;
      }
      continue;
    }
    if (inCodeFence) {
      codeBuf.add(line);
      continue;
    }

    // 空行：结束段落
    if (line.trim().isEmpty) {
      flushParagraph();
      continue;
    }

    // 标题
    final h = _headingRe.firstMatch(line);
    if (h != null) {
      flushAll();
      blocks.add(HeadingBlock(h.group(1)!.length, parseInline(h.group(2)!)));
      continue;
    }

    // 分隔线
    if (_dividerRe.hasMatch(line)) {
      flushAll();
      blocks.add(const DividerBlock());
      continue;
    }

    // 引用（连续行合并）
    final q = _quoteRe.firstMatch(line);
    if (q != null) {
      flushParagraph();
      flushList();
      quoteBuf.add(q.group(1)!);
      continue;
    }

    // 无序列表
    final b = _bulletRe.firstMatch(line);
    if (b != null) {
      flushParagraph();
      flushQuote();
      listBuf.add(MarkdownListItem(
        parseInline(b.group(2)!),
        level: (b.group(1)!.length / 2).floor().clamp(0, 1),
      ));
      continue;
    }

    // 有序列表
    final o = _orderedRe.firstMatch(line);
    if (o != null) {
      flushParagraph();
      flushQuote();
      listBuf.add(MarkdownListItem(
        parseInline(o.group(3)!),
        level: (o.group(1)!.length / 2).floor().clamp(0, 1),
        number: o.group(2),
      ));
      continue;
    }

    // 普通文本行：进入段落
    flushList();
    flushQuote();
    paragraphBuf.add(line);
  }

  if (inCodeFence && codeBuf.isNotEmpty) {
    // 未闭合的代码块：剩余内容按代码块输出
    blocks.add(CodeBlock(codeBuf.join('\n')));
  }
  flushAll();

  return blocks;
}

/// 行内解析：递归处理 `code`、**bold**、*italic*、[text](url)
List<MarkdownSpan> parseInline(String input,
    {bool bold = false, bool italic = false}) {
  final spans = <MarkdownSpan>[];
  var last = 0;

  for (final m in _inlineRe.allMatches(input)) {
    if (m.start > last) {
      spans.add(MarkdownSpan(input.substring(last, m.start),
          bold: bold, italic: italic));
    }
    final token = m.group(0)!;
    if (token.startsWith('`')) {
      spans.add(MarkdownSpan(token.substring(1, token.length - 1),
          code: true, bold: bold, italic: italic));
    } else if (token.startsWith('**')) {
      spans.addAll(parseInline(token.substring(2, token.length - 2),
          bold: true, italic: italic));
    } else if (token.startsWith('[')) {
      final link = _linkRe.firstMatch(token)!;
      spans.add(MarkdownSpan(link.group(1)!,
          linkUrl: link.group(2), bold: bold, italic: italic));
    } else {
      spans.addAll(parseInline(token.substring(1, token.length - 1),
          bold: bold, italic: true));
    }
    last = m.end;
  }

  if (last < input.length) {
    spans.add(MarkdownSpan(input.substring(last), bold: bold, italic: italic));
  }
  return spans;
}

/// 剥离 Markdown 语法标记，用于列表页纯文本摘要。
/// 注意：涉及捕获组回填必须用 replaceAllMapped —— Dart 的 replaceAll
/// 不支持 `$1` 分组插值（会把 `$1` 当字面量输出）。
String stripMarkdown(String src) {
  var s = src.replaceAll(RegExp(r'```[\s\S]*?```'), ' ');
  s = s.replaceAllMapped(RegExp(r'`([^`]*)`'), (m) => m.group(1)!);
  s = s.replaceAllMapped(
      RegExp(r'\[([^\]\n]+)\]\(([^)\n]+)\)'), (m) => m.group(1)!);
  s = s.replaceAll(RegExp(r'^\s{0,3}#{1,6}\s+', multiLine: true), '');
  s = s.replaceAll(RegExp(r'^\s{0,3}>\s?', multiLine: true), '');
  s = s.replaceAll(RegExp(r'^\s{0,3}[-*]\s+', multiLine: true), '• ');
  s = s.replaceAll(_dividerReMultiline, '———');
  s = s.replaceAllMapped(RegExp(r'\*\*([^*]+)\*\*'), (m) => m.group(1)!);
  s = s.replaceAllMapped(RegExp(r'\*([^*]+)\*'), (m) => m.group(1)!);
  return s.trim();
}
