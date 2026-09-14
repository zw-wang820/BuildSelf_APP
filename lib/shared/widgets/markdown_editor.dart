import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'emoji_icon.dart';
import 'markdown_text.dart';

/// Markdown 编辑器：TextField + 底部语法工具栏 + 编辑/预览切换。
///
/// 沿用项目双模式表单惯例：编辑模式输入原文，预览模式查看渲染效果。
/// 通过传入的 [controller] 与外部表单共享内容，保存逻辑不变（存原始 Markdown）。
class MarkdownEditor extends StatefulWidget {
  final TextEditingController controller;
  final String? hint;
  final int maxLines;
  final int minLines;

  const MarkdownEditor({
    Key? key,
    required this.controller,
    this.hint,
    this.maxLines = 12,
    this.minLines = 1,
  }) : super(key: key);

  @override
  State<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor> {
  bool _preview = false;

  /// 行首插入前缀（标题 / 列表 / 引用）
  void _insertLinePrefix(String prefix) {
    final text = widget.controller.text;
    final sel = widget.controller.selection;
    final cursor = (sel.isValid && sel.start >= 0) ? sel.start : text.length;
    // 找到光标所在行的行首
    var lineStart = text.lastIndexOf('\n', cursor - 1) + 1;
    final newText = text.substring(0, lineStart) +
        prefix +
        text.substring(lineStart);
    final newCursor = cursor + prefix.length;
    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );
  }

  /// 包裹选中文字（粗体 / 斜体 / 行内代码）
  void _wrapSelection(String prefix, String suffix) {
    final text = widget.controller.text;
    final sel = widget.controller.selection;
    if (!sel.isValid || sel.start < 0) {
      // 无有效光标：追加到末尾
      final newText = text + prefix + suffix;
      widget.controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length - suffix.length),
      );
      return;
    }
    final start = sel.start;
    final end = sel.end;
    final selected = text.substring(start, end);
    final newText = text.substring(0, start) +
        prefix +
        selected +
        suffix +
        text.substring(end);
    // 有选中：光标落在包裹后的内容末尾；无选中：落在两个标记之间
    final newCursor = start + prefix.length + selected.length;
    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outline.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 编辑区 / 预览区
          if (_preview)
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 160),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                child: widget.controller.text.trim().isEmpty
                    ? Text(
                        '暂无内容，切回编辑模式输入',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      )
                    : MarkdownText(widget.controller.text),
              ),
            )
          else
            TextField(
              controller: widget.controller,
              maxLines: widget.maxLines,
              minLines: widget.minLines,
              inputFormatters: [LengthLimitingTextInputFormatter(20000)],
              decoration: InputDecoration(
                hintText: widget.hint,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          // 工具栏
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: scheme.outline.withValues(alpha: 0.3)),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _preview
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => setState(() => _preview = false),
                        icon: const EmojiIcon('✏️', size: 15),
                        label: const Text('编辑', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  )
                : Wrap(
                    spacing: 2,
                    children: [
                      _toolBtn(
                        label: 'B',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14),
                        onTap: () => _wrapSelection('**', '**'),
                      ),
                      _toolBtn(
                        label: 'I',
                        style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                            fontSize: 14),
                        onTap: () => _wrapSelection('*', '*'),
                      ),
                      _toolBtn(
                        label: 'H',
                        onTap: () => _insertLinePrefix('## '),
                      ),
                      _toolBtn(
                        label: '• —',
                        onTap: () => _insertLinePrefix('- '),
                      ),
                      _toolBtn(
                        label: '1. —',
                        onTap: () => _insertLinePrefix('1. '),
                      ),
                      _toolBtn(
                        label: '❝',
                        onTap: () => _insertLinePrefix('> '),
                      ),
                      _toolBtn(
                        label: '<>',
                        style: const TextStyle(
                            fontFamily: 'monospace', fontSize: 13),
                        onTap: () => _wrapSelection('`', '`'),
                      ),
                      const SizedBox(width: 4),
                      TextButton.icon(
                        onPressed: () => setState(() => _preview = true),
                        icon: const EmojiIcon('👁', size: 15),
                        label: const Text('预览', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _toolBtn({
    required String label,
    TextStyle? style,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Text(
          label,
          style: style ?? const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
