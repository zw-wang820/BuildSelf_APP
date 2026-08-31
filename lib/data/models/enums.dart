/// 登录方式
enum LoginType { wechat, phone }

/// 心情
enum Mood {
  happy('😊', '开心'),
  neutral('😐', '平静'),
  angry('😤', '烦躁'),
  sad('😢', '难过'),
  think('🤔', '思考');

  const Mood(this.emoji, this.label);
  final String emoji;
  final String label;
}

/// 天气
enum Weather {
  sunny('☀️', '晴'),
  cloudy('☁️', '多云'),
  rainy('🌧️', '雨'),
  snowy('❄️', '雪'),
  foggy('🌫️', '雾');

  const Weather(this.emoji, this.label);
  final String emoji;
  final String label;
}

/// 工作记录类型
enum WorkRecordType {
  insight('心得', '💡'),
  thought('思考', '🤔'),
  journal('工作日志', '📝'),
  learning('待学习项', '📚');

  const WorkRecordType(this.label, this.emoji);
  final String label;
  final String emoji;
}

/// 生活记录类型
enum LifeRecordType {
  beauty('美好'),
  insight('感悟'),
  reflection('反思');

  const LifeRecordType(this.label);
  final String label;
}

/// 目标类型
enum GoalType {
  shortTerm('短期目标'),
  midTerm('中期目标'),
  longTerm('长期目标');

  const GoalType(this.label);
  final String label;
}

/// 目标类别
enum GoalCategory {
  health('健康'),
  career('事业'),
  learning('学习'),
  life('生活'),
  finance('财务'),
  other('其他');

  const GoalCategory(this.label);
  final String label;
}

/// 目标进度模式
enum ProgressType {
  manual('手动百分比'),
  milestone('里程碑'),
  checklist('清单');

  const ProgressType(this.label);
  final String label;
}

/// 目标状态
enum GoalStatus {
  active('进行中'),
  completed('已完成'),
  abandoned('已放弃');

  const GoalStatus(this.label);
  final String label;
}

/// 奖励类型
enum RewardType {
  food('美食'),
  travel('旅行'),
  shopping('购物'),
  experience('体验'),
  other('其他');

  const RewardType(this.label);
  final String label;
}

/// 书籍阅读状态
enum BookStatus {
  reading('在读'),
  finished('已读'),
  paused('暂停'),
  planned('想读');

  const BookStatus(this.label);
  final String label;
}

/// 读书笔记类型
enum NoteType {
  excerpt('摘抄'),
  insight('心得'),
  thought('思考'),
  change('改变');

  const NoteType(this.label);
  final String label;
}
