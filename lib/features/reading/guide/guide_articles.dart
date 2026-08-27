import 'package:buildself/data/models/enums.dart';

/// 阅读指南区块类型
enum GuideBlockType {
  /// 普通段落
  paragraph,

  /// 金句（强调引用）
  quote,

  /// 圆点要点列表（title 为可选分组标题）
  points,

  /// 编号步骤列表（title 为步骤名）
  steps,

  /// 底部行动引导按钮
  action,
}

/// 阅读指南单个内容区块
class GuideBlock {
  final GuideBlockType type;
  final String? title;
  final String text;
  final List<String> items;

  const GuideBlock.paragraph(this.text)
      : type = GuideBlockType.paragraph,
        title = null,
        items = const [];

  const GuideBlock.quote(this.text)
      : type = GuideBlockType.quote,
        title = null,
        items = const [];

  const GuideBlock.points({this.title, required this.items})
      : type = GuideBlockType.points,
        text = '';

  const GuideBlock.steps({required this.title, required this.items})
      : type = GuideBlockType.steps,
        text = '';

  const GuideBlock.action(this.text)
      : type = GuideBlockType.action,
        title = null,
        items = const [];
}

/// 阅读指南文章
class GuideArticle {
  final String emoji;
  final String title;
  final String summary;
  final List<GuideBlock> blocks;

  const GuideArticle({
    required this.emoji,
    required this.title,
    required this.summary,
    required this.blocks,
  });
}

/// 阅读指南文章列表（顺序即列表页展示顺序）
const List<GuideArticle> guideArticles = [
  GuideArticle(
    emoji: '📖',
    title: '为什么阅读',
    summary: '阅读的本质不是输入，是改变',
    blocks: [
      GuideBlock.quote('阅读 ≠ 输入信息；阅读 = 从「知道」到「做到」的桥梁。'),
      GuideBlock.points(
        title: '读 → 思 → 行 → 变',
        items: [
          '读：接收信息',
          '思：理解内化',
          '行：付诸行动',
          '变：形成改变',
        ],
      ),
      GuideBlock.paragraph(
          '只在「读」和「思」停留，知识只是库存；走到「行」和「变」，知识才成为能力。'),
      GuideBlock.paragraph(
          'App 里每本书的「改变」类笔记，就是为「行」与「变」预留的位置。读完一本书，先问自己：我要改变什么？'),
    ],
  ),
  GuideArticle(
    emoji: '🎯',
    title: '如何选书',
    summary: '选对书，阅读成功一半',
    blocks: [
      GuideBlock.points(
        title: '四步筛选',
        items: [
          '定目的：想解决什么问题？目标相关七成，其他领域三成',
          '快评估：5-10 分钟检视——书名、目录、索引、试读一章',
          '看验证：经典优先（经时间检验）、可信推荐、好书延伸（参考文献）',
          '定主题：围绕一个主题读 5-10 本，对照互证',
        ],
      ),
      GuideBlock.points(
        title: '三问测试',
        items: [
          '能解决我当前哪个具体问题？',
          '有至少 3 个能直接应用的方法吗？',
          '是否颠覆我的旧认知？（有冲突才可能成长）',
        ],
      ),
      GuideBlock.quote('别为「读完」选书，为「改变」选书。'),
    ],
  ),
  GuideArticle(
    emoji: '📚',
    title: '如何阅读',
    summary: '读深、读透、读成体系',
    blocks: [
      GuideBlock.points(
        title: '阅读四层次（由浅入深）',
        items: [
          '基础阅读：识字即可',
          '检视阅读：30 分钟摸清一本书——书名/序/目录/索引/相关篇章/快速翻读，判断值不值得深读',
          '分析阅读：完整消化——先找结构（谈什么）、再诠释（关键词/主旨/论证）、最后理性评论',
          '主题阅读：同主题读多本，解构重组，形成自己的知识体系',
        ],
      ),
      GuideBlock.points(
        title: 'SQ3R 五步法',
        items: [
          '浏览：先看目录搭框架',
          '提问：把标题变成问题',
          '阅读：带着问题读',
          '复述：合上书，用自己的话讲',
          '复盘：梳理逻辑链条',
        ],
      ),
      GuideBlock.points(
        title: '主动阅读四问',
        items: [
          '这本书整体在谈什么？',
          '细节是怎么展开的？',
          '说得有道理吗？',
          '跟我有什么关系？',
        ],
      ),
    ],
  ),
  GuideArticle(
    emoji: '🚀',
    title: '如何落地',
    summary: '把书变成行动，阅读才算完成',
    blocks: [
      GuideBlock.steps(
        title: 'RIA 便签法',
        items: [
          'R 读一段原文：划出打动你的片段',
          'I 用自己的话重述：检验是否真懂',
          'A1 联想自身经历：这和我哪段经历相关？',
          'A2 写下下一步行动：具体、有时限——"下次遇到 X，我要做 Y"',
        ],
      ),
      GuideBlock.points(
        title: '费曼输出',
        items: [
          '合上书，用最简单的话讲给别人听',
          '讲不清的地方 = 没读透，回头补',
        ],
      ),
      GuideBlock.points(
        title: '三色标注',
        items: [
          '黑 = 事实与定义',
          '蓝 = 可立即操作的方法',
          '红 = 颠覆认知的观点（最值得转化为行动）',
        ],
      ),
      GuideBlock.action('把这本书的方法变成行动'),
    ],
  ),
];

/// 行动引导对应的笔记类型预设
const NoteType guideActionNoteType = NoteType.change;
