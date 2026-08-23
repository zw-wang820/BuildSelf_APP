import 'package:flutter/material.dart';

/// Emoji 图标 — 用文本字形替代 Material Icon。
///
/// - 自带彩色字形，`color` 仅对可着色的字形生效（多数 emoji 忽略）；
///   强调/选中态建议通过 `size`/圆底/加粗体现。
/// - 内部使用固定尺寸的占位框 + FittedBox 居中，保证在任意父容器中
///   都垂直/水平居中（替代 Material Icon 的 glyph 居中行为）。
class EmojiIcon extends StatelessWidget {
  final String emoji;
  final double size;
  final Color? color;
  final FontWeight? weight;

  const EmojiIcon(
    this.emoji, {
    Key? key,
    this.size = 22,
    this.color,
    this.weight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.2,
      height: size * 1.1,
      child: FittedBox(
        fit: BoxFit.contain,
        alignment: Alignment.center,
        child: Text(
          emoji,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: size,
            height: 1.0,
            color: color,
            fontWeight: weight,
          ),
        ),
      ),
    );
  }
}
