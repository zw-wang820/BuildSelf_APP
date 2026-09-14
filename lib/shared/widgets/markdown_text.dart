import 'package:flutter/material.dart';

import '../../core/utils/markdown_parser.dart';

/// Markdown 渲染组件（只读）。
///
/// 将 parseMarkdown 输出的块级模型映射为 Flutter Widget，
/// 供预览模式、详情页、列表页直接使用。
/// 颜色取自 Theme.colorScheme，自动适配明暗主题。
class MarkdownText extends StatelessWidget {
  final String data;

  /// 基础文字样式（缺省取 textTheme.bodyMedium）
  final TextStyle? baseStyle;

  const MarkdownText(this.data, {Key? key, this.baseStyle}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final blocks = parseMarkdown(data);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks.map((b) => _buildBlock(context, b)).toList(),
    );
  }

  /// 基础样式：以主题 bodyMedium（含明暗自适应颜色）为底，
  /// 外部 baseStyle 仅覆盖字号/行高等属性。
  /// RichText 不继承 DefaultTextStyle，这里必须显式保证有 color，
  /// 否则浅色模式下会按渲染默认色（白）显示。
  TextStyle _base(BuildContext context) {
    final s = Theme.of(context).textTheme.bodyMedium!;
    return baseStyle == null ? s : s.merge(baseStyle);
  }

  Widget _buildBlock(BuildContext context, MarkdownBlock block) {
    final scheme = Theme.of(context).colorScheme;
    if (block is HeadingBlock) {
      final sizes = [22.0, 19.0, 17.0, 16.0, 15.0, 14.0];
      return Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        child: RichText(
          text: _spans(context, block.spans,
              base: _base(context).copyWith(
                fontSize: sizes[block.level - 1],
                fontWeight: FontWeight.w700,
                height: 1.4,
              )),
        ),
      );
    }
    if (block is ParagraphBlock) {
      return Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 2),
        child: RichText(
          text: _spans(context, block.spans,
              base: _base(context).copyWith(height: 1.5)),
        ),
      );
    }
    if (block is ListBlock) {
      return Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: block.items.map((item) {
            final indent = 16.0 * item.level;
            return Padding(
              padding: EdgeInsets.only(left: indent, top: 2, bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(
                      item.number != null ? '${item.number}.' : '•',
                      style: _base(context)
                          .copyWith(fontWeight: FontWeight.w600, height: 1.5),
                    ),
                  ),
                  Expanded(
                    child: RichText(
                      text: _spans(context, item.spans,
                          base: _base(context).copyWith(height: 1.5)),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      );
    }
    if (block is QuoteBlock) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.06),
            border: Border(
              left: BorderSide(width: 3, color: scheme.primary.withValues(alpha: 0.5)),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: block.lines
                .map((spans) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: RichText(
                        text: _spans(context, spans,
                            base: _base(context)
                                .copyWith(height: 1.5, fontStyle: FontStyle.italic)),
                      ),
                    ))
                .toList(),
          ),
        ),
      );
    }
    if (block is CodeBlock) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(10),
          child: Text(
            block.code,
            style: _base(context).copyWith(
              fontFamily: 'monospace',
              fontSize: (_base(context).fontSize ?? 14) - 1,
              height: 1.5,
            ),
          ),
        ),
      );
    }
    if (block is DividerBlock) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Divider(height: 1, color: scheme.outline.withValues(alpha: 0.4)),
      );
    }
    return const SizedBox.shrink();
  }

  /// 将行内模型转为 TextSpan；行内代码用 WidgetSpan 加底色
  TextSpan _spans(BuildContext context, List<MarkdownSpan> spans,
      {required TextStyle base}) {
    final scheme = Theme.of(context).colorScheme;
    return TextSpan(
      children: spans.map((s) {
        var style = base.copyWith(
          fontWeight: s.bold ? FontWeight.w700 : base.fontWeight,
          fontStyle: s.italic ? FontStyle.italic : base.fontStyle,
        );
        if (s.isLink) {
          style = style.copyWith(
            color: scheme.primary,
            decoration: TextDecoration.underline,
          );
        }
        if (s.code) {
          return WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              child: Text(
                s.text,
                style: base.copyWith(
                  fontFamily: 'monospace',
                  fontSize: (base.fontSize ?? 14) - 1,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }
        return TextSpan(text: s.text, style: style);
      }).toList(),
    );
  }
}
