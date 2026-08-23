/// 数据库表结构定义
class AppTables {
  AppTables._();

  // 表名
  static const String users = 'users';
  static const String workNotes = 'work_notes';
  static const String lifeRecords = 'life_records';
  static const String goals = 'goals';
  static const String goalLogs = 'goal_logs';
  static const String books = 'books';
  static const String readingNotes = 'reading_notes';
  static const String murmurs = 'murmurs';
  static const String tags = 'tags';
  static const String trashItems = 'trash_items';
  static const String todos = 'todos';
}

/// 建表 SQL
class AppSql {
  AppSql._();

  static const String createUsers = '''
    CREATE TABLE IF NOT EXISTS ${AppTables.users} (
      user_id TEXT PRIMARY KEY,
      login_type TEXT NOT NULL,
      phone TEXT,
      wechat_open_id TEXT,
      nickname TEXT NOT NULL,
      avatar_path TEXT,
      created_at TEXT NOT NULL,
      last_login_at TEXT NOT NULL
    )
  ''';

  static const String createWorkNotes = '''
    CREATE TABLE IF NOT EXISTS ${AppTables.workNotes} (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      title TEXT DEFAULT '',
      content TEXT NOT NULL,
      record_type TEXT NOT NULL,
      tags TEXT DEFAULT '[]',
      mood TEXT,
      attachments TEXT DEFAULT '[]',
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      deleted_at TEXT,
      FOREIGN KEY (user_id) REFERENCES ${AppTables.users}(user_id)
    )
  ''';

  static const String createLifeRecords = '''
    CREATE TABLE IF NOT EXISTS ${AppTables.lifeRecords} (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      title TEXT DEFAULT '',
      content TEXT NOT NULL,
      record_type TEXT NOT NULL,
      mood TEXT,
      weather TEXT,
      location TEXT,
      images TEXT DEFAULT '[]',
      tags TEXT DEFAULT '[]',
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      deleted_at TEXT,
      FOREIGN KEY (user_id) REFERENCES ${AppTables.users}(user_id)
    )
  ''';

  static const String createGoals = '''
    CREATE TABLE IF NOT EXISTS ${AppTables.goals} (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      title TEXT NOT NULL,
      description TEXT DEFAULT '',
      goal_type TEXT NOT NULL,
      category TEXT,
      start_date TEXT NOT NULL,
      target_date TEXT,
      progress_type TEXT NOT NULL,
      progress INTEGER DEFAULT 0,
      milestones TEXT DEFAULT '[]',
      checklist TEXT DEFAULT '[]',
      reward TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'active',
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      completed_at TEXT,
      deleted_at TEXT,
      FOREIGN KEY (user_id) REFERENCES ${AppTables.users}(user_id)
    )
  ''';

  static const String createGoalLogs = '''
    CREATE TABLE IF NOT EXISTS ${AppTables.goalLogs} (
      id TEXT PRIMARY KEY,
      goal_id TEXT NOT NULL,
      progress_before INTEGER NOT NULL,
      progress_after INTEGER NOT NULL,
      note TEXT,
      created_at TEXT NOT NULL,
      FOREIGN KEY (goal_id) REFERENCES ${AppTables.goals}(id) ON DELETE CASCADE
    )
  ''';

  static const String createBooks = '''
    CREATE TABLE IF NOT EXISTS ${AppTables.books} (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      title TEXT NOT NULL,
      author TEXT,
      cover_image TEXT,
      status TEXT NOT NULL DEFAULT 'planned',
      start_date TEXT,
      finish_date TEXT,
      rating INTEGER,
      tags TEXT DEFAULT '[]',
      current_page INTEGER NOT NULL DEFAULT 0,
      total_pages INTEGER NOT NULL DEFAULT 0,
      cover_color INTEGER,
      last_read_at TEXT,
      created_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES ${AppTables.users}(user_id)
    )
  ''';

  static const String createReadingNotes = '''
    CREATE TABLE IF NOT EXISTS ${AppTables.readingNotes} (
      id TEXT PRIMARY KEY,
      book_id TEXT NOT NULL,
      note_type TEXT NOT NULL,
      chapter TEXT,
      content TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (book_id) REFERENCES ${AppTables.books}(id) ON DELETE CASCADE
    )
  ''';

  static const String createMurmurs = '''
    CREATE TABLE IF NOT EXISTS ${AppTables.murmurs} (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      content TEXT NOT NULL,
      mood TEXT,
      tags TEXT DEFAULT '[]',
      images TEXT DEFAULT '[]',
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      deleted_at TEXT,
      FOREIGN KEY (user_id) REFERENCES ${AppTables.users}(user_id)
    )
  ''';

  static const String createTags = '''
    CREATE TABLE IF NOT EXISTS ${AppTables.tags} (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      module TEXT NOT NULL,
      color TEXT,
      usage_count INTEGER DEFAULT 0
    )
  ''';

  static const String createTrashItems = '''
    CREATE TABLE IF NOT EXISTS ${AppTables.trashItems} (
      id TEXT PRIMARY KEY,
      module_type TEXT NOT NULL,
      record_data TEXT NOT NULL,
      deleted_at TEXT NOT NULL,
      auto_purge_at TEXT NOT NULL
    )
  ''';

  static const String createTodos = '''
    CREATE TABLE IF NOT EXISTS ${AppTables.todos} (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      content TEXT NOT NULL,
      note TEXT DEFAULT '',
      category TEXT NOT NULL,
      priority TEXT NOT NULL,
      due_type TEXT NOT NULL,
      due_date TEXT,
      is_completed INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      completed_at TEXT,
      FOREIGN KEY (user_id) REFERENCES ${AppTables.users}(user_id)
    )
  ''';

  /// 所有建表语句
  static const List<String> allCreateStatements = [
    createUsers,
    createWorkNotes,
    createLifeRecords,
    createGoals,
    createGoalLogs,
    createBooks,
    createReadingNotes,
    createMurmurs,
    createTags,
    createTrashItems,
    createTodos,
  ];

  /// 索引创建语句
  static const List<String> indexStatements = [
    'CREATE INDEX IF NOT EXISTS idx_work_notes_user ON ${AppTables.workNotes}(user_id)',
    'CREATE INDEX IF NOT EXISTS idx_work_notes_deleted ON ${AppTables.workNotes}(deleted_at)',
    'CREATE INDEX IF NOT EXISTS idx_life_records_user ON ${AppTables.lifeRecords}(user_id)',
    'CREATE INDEX IF NOT EXISTS idx_life_records_deleted ON ${AppTables.lifeRecords}(deleted_at)',
    'CREATE INDEX IF NOT EXISTS idx_goals_user ON ${AppTables.goals}(user_id)',
    'CREATE INDEX IF NOT EXISTS idx_goals_status ON ${AppTables.goals}(status)',
    'CREATE INDEX IF NOT EXISTS idx_goal_logs_goal ON ${AppTables.goalLogs}(goal_id)',
    'CREATE INDEX IF NOT EXISTS idx_books_user ON ${AppTables.books}(user_id)',
    'CREATE INDEX IF NOT EXISTS idx_reading_notes_book ON ${AppTables.readingNotes}(book_id)',
    'CREATE INDEX IF NOT EXISTS idx_murmurs_user ON ${AppTables.murmurs}(user_id)',
    'CREATE INDEX IF NOT EXISTS idx_murmurs_deleted ON ${AppTables.murmurs}(deleted_at)',
    'CREATE INDEX IF NOT EXISTS idx_todos_user ON ${AppTables.todos}(user_id)',
  ];
}
