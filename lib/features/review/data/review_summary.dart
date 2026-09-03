import 'package:buildself/features/review/models/review_item.dart';
import 'package:buildself/features/review/models/review_quadrant.dart';

/// 生成 KISS 复盘叙事化总结（纯函数，零依赖）
///
/// 输入某日 session 的四象限条目，输出可读文本。不依赖 AppStrings 以保持
/// 模块纯净；调用方负责本地化（当前各象限文案为中文内置，与全 App 一致）。
String buildReviewSummary({
  required String dateLabel,
  required Map<ReviewQuadrant, List<ReviewItem>> byQuadrant,
}) {
  final buffer = StringBuffer('$dateLabel 复盘完成。\n\n');

  int total = 0;

  void appendQuadrant(ReviewQuadrant q) {
    final items = byQuadrant[q] ?? const [];
    total += items.length;
    if (items.isEmpty) {
      buffer.writeln('${q.emoji} ${q.enLabel} ${q.zhLabel}（0 项）\n无。\n');
      return;
    }
    buffer.writeln('${q.emoji} ${q.enLabel} ${q.zhLabel}（${items.length} 项）');
    for (final it in items) {
      final t = it.createdAt.toLocal();
      final hh = t.hour.toString().padLeft(2, '0');
      final mm = t.minute.toString().padLeft(2, '0');
      buffer.writeln('- [$hh:$mm] ${it.content}');
    }
    buffer.writeln();
  }

  appendQuadrant(ReviewQuadrant.keep);
  appendQuadrant(ReviewQuadrant.improve);
  appendQuadrant(ReviewQuadrant.start);
  appendQuadrant(ReviewQuadrant.stop);

  if (total == 0) {
    return '今日尚未记录任何复盘项。KISS 复盘建议每天留 5 分钟，'
        '从「保持一件做得好的事」开始。';
  }

  final keepCount = byQuadrant[ReviewQuadrant.keep]?.length ?? 0;
  final improveCount = byQuadrant[ReviewQuadrant.improve]?.length ?? 0;
  final startCount = byQuadrant[ReviewQuadrant.start]?.length ?? 0;
  final stopCount = byQuadrant[ReviewQuadrant.stop]?.length ?? 0;

  buffer.writeln('总计 $total 项：Keep $keepCount · Improve $improveCount · '
      'Start $startCount · Stop $stopCount。');

  // 收尾建议：依据象限构成给出轻提醒
  if (keepCount >= 2 && keepCount >= improveCount) {
    buffer.writeln('今天有不少值得保持的事，试着把它们固化为习惯。');
  } else if (startCount > 0 && stopCount > 0) {
    buffer.writeln('既有「开始」也有「停止」，先停止低价值的事，为新的开始腾出空间。');
  } else if (improveCount > 0) {
    buffer.writeln('改进项较多，建议挑最重要的一项，明天先做一次小优化。');
  } else {
    buffer.writeln('KISS 框架运转正常，明天继续。');
  }

  return buffer.toString();
}
