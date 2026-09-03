import 'package:flutter/material.dart';
import 'package:buildself/core/constants/app_constants.dart';
import 'package:buildself/core/constants/colors.dart';
import 'package:buildself/core/constants/strings.dart';
import 'package:buildself/features/review/models/review_item.dart';
import 'package:buildself/features/review/models/review_quadrant.dart';
import 'package:buildself/features/review/widgets/review_item_tile.dart';

/// 单象限卡 — 头部（emoji+中英标题+引导语+计数） + 条目列表 + 内联输入
///
/// - [focused]：是否正在输入（决定是否显示输入框与外框高亮，全页同时仅一卡为真）
/// - [requestFocus]：由父级在展开输入时置 true，触发 autofocus 并回调 [onFocused]
/// - 提交回调 [onSubmit]；[onClearFocus] 让父级收起其它卡的输入态
class ReviewQuadrantCard extends StatefulWidget {
  final ReviewQuadrant quadrant;
  final List<ReviewItem> items;
  final bool readOnly;
  final bool focused;
  final bool requestFocus;
  final VoidCallback? onAddTap;
  final ValueChanged<String> onSubmit;
  final VoidCallback? onFocusRequested;
  final ValueChanged<ReviewItem> onEditItem;
  final ValueChanged<ReviewItem> onDeleteItem;

  const ReviewQuadrantCard({
    Key? key,
    required this.quadrant,
    required this.items,
    required this.readOnly,
    this.focused = false,
    this.requestFocus = false,
    this.onAddTap,
    required this.onSubmit,
    this.onFocusRequested,
    required this.onEditItem,
    required this.onDeleteItem,
  }) : super(key: key);

  @override
  State<ReviewQuadrantCard> createState() => _ReviewQuadrantCardState();
}

class _ReviewQuadrantCardState extends State<ReviewQuadrantCard> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.requestFocus && !widget.readOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    widget.onSubmit(text);
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.quadrant;
    final color = q.color;
    final light = q.lightColor;
    final textColor = q.textColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final divider = isDark ? AppColors.dividerDark : AppColors.dividerLight;
    final surface =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.focused ? color : divider,
          width: widget.focused ? 1.5 : 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? AppColors.shadowDark : AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ===== 头部：emoji 圆底 + 标题/引导语 + 右侧计数 + 添加按钮 =====
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: light,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(q.emoji, style: const TextStyle(fontSize: 17)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                q.enLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: color,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              q.zhLabel,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          q.guideZh,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.readOnly && widget.items.isNotEmpty)
                    _countBadge(context, textColor, light)
                  else if (!widget.readOnly) ...[
                    if (widget.items.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _countBadge(context, textColor, light),
                      ),
                    GestureDetector(
                      onTap: widget.onAddTap,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: light,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.add_rounded,
                            size: 20, color: textColor),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              // ===== 条目列表 =====
              if (widget.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 3,
                        height: 14,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.readOnly
                              ? AppStrings.reviewEmpty
                              : '${AppStrings.reviewEmpty}，${AppStrings.reviewAddFirst}',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...widget.items.map(
                  (it) => ReviewItemTile(
                    item: it,
                    quadrant: q,
                    showTime: !widget.readOnly,
                    onLongPress: widget.readOnly
                        ? null
                        : () => _showItemActions(context, it),
                  ),
                ),
              // ===== 内联输入区 =====
              if (!widget.readOnly) ...[
                const SizedBox(height: 6),
                if (widget.focused)
                  Container(
                    padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
                    decoration: BoxDecoration(
                      color: light.withValues(alpha: isDark ? 0.15 : 0.45),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          autofocus: true,
                          maxLength: AppConstants.maxReviewTextLen,
                          maxLines: 3,
                          minLines: 1,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: AppColors.textPrimary(context),
                          ),
                          decoration: InputDecoration(
                            hintText: AppStrings.reviewItemHint,
                            hintStyle: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary(context),
                            ),
                            counterText: '',
                            isDense: true,
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _submit(),
                          onTapOutside: (_) => _focusNode.unfocus(),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                _controller.clear();
                                _focusNode.unfocus();
                                widget.onAddTap?.call(); // 父级负责收起聚焦态
                              },
                              child: Text(AppStrings.cancel,
                                  style: TextStyle(
                                      fontSize: 12.5, color: textColor)),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: _submit,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: const Icon(Icons.check_rounded,
                                    size: 18, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                else
                  GestureDetector(
                    onTap: widget.onAddTap,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                            color: color.withValues(alpha: 0.35), width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_rounded, size: 15, color: color),
                          const SizedBox(width: 3),
                          Text(
                            AppStrings.reviewAddFirst,
                            style: TextStyle(fontSize: 12, color: color),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _countBadge(
      BuildContext context, Color textColor, Color lightColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: lightColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${widget.items.length}',
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  /// 长按条目操作：编辑 / 删除 / 取消
  Future<void> _showItemActions(BuildContext context, ReviewItem item) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                item.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary(ctx),
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.edit_rounded, color: widget.quadrant.color),
              title: Text(AppStrings.edit,
                  style: const TextStyle(fontSize: 14.5)),
              onTap: () => Navigator.pop(ctx, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.reviewStop),
              title: const Text('删除',
                  style: TextStyle(fontSize: 14.5, color: AppColors.reviewStop)),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
            const Divider(height: 1),
            ListTile(
              title: Text(AppStrings.cancel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14.5,
                      color: AppColors.textSecondary(ctx))),
              onTap: () => Navigator.pop(ctx, 'cancel'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'edit') {
      widget.onEditItem(item);
    } else if (action == 'delete') {
      widget.onDeleteItem(item);
    }
  }
}
