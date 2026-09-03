import 'package:flutter/material.dart';
import 'package:buildself/core/constants/colors.dart';

/// KISS 复盘四象限
///
/// 每个象限独立管理：独立颜色语义、独立引导问题（中文/英文双语文案在
/// 各调用处经 AppStrings 获取，此处仅存图标与默认引导语）。
enum ReviewQuadrant {
  keep('keep', '✅', 'Keep', '保持', '哪些做得好？如何固化？'),
  improve('improve', '🔄', 'Improve', '改进', '哪些不够好？如何优化？'),
  start('start', '➕', 'Start', '开始', '哪些该做但没做？何时启动？'),
  stop('stop', '🚫', 'Stop', '停止', '哪些无效甚至有害？如何断舍离？');

  const ReviewQuadrant(this.storage, this.emoji, this.enLabel, this.zhLabel,
      this.guideZh);

  /// 数据库存储值（英文单数小写，向后兼容稳定）
  final String storage;
  final String emoji;
  final String enLabel;
  final String zhLabel;
  final String guideZh;

  /// 展示名：当前 App 语言为中文时显示「保持」，否则「Keep」
  String get label => enLabel;

  /// 主题色
  Color get color {
    switch (this) {
      case ReviewQuadrant.keep:
        return AppColors.reviewKeep;
      case ReviewQuadrant.improve:
        return AppColors.reviewImprove;
      case ReviewQuadrant.start:
        return AppColors.reviewStart;
      case ReviewQuadrant.stop:
        return AppColors.reviewStop;
    }
  }

  /// 浅色底
  Color get lightColor {
    switch (this) {
      case ReviewQuadrant.keep:
        return AppColors.reviewKeepLight;
      case ReviewQuadrant.improve:
        return AppColors.reviewImproveLight;
      case ReviewQuadrant.start:
        return AppColors.reviewStartLight;
      case ReviewQuadrant.stop:
        return AppColors.reviewStopLight;
    }
  }

  /// 深色文字（浅底上）
  Color get textColor {
    switch (this) {
      case ReviewQuadrant.keep:
        return AppColors.reviewKeepText;
      case ReviewQuadrant.improve:
        return AppColors.reviewImproveText;
      case ReviewQuadrant.start:
        return AppColors.reviewStartText;
      case ReviewQuadrant.stop:
        return AppColors.reviewStopText;
    }
  }

  /// 由存储值反解；未知值回落 keep（数据层防御）
  static ReviewQuadrant fromStorage(String? raw) {
    for (final q in ReviewQuadrant.values) {
      if (q.storage == raw) return q;
    }
    return ReviewQuadrant.keep;
  }
}
