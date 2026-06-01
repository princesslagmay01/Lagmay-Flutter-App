import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDbService {
  static final LocalDbService _instance = LocalDbService._internal();
  factory LocalDbService() => _instance;
  LocalDbService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'lagmay_offline.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Offline users table (for signup and caching)
        await db.execute('''
          CREATE TABLE offline_users(
            id TEXT PRIMARY KEY,
            email TEXT,
            password TEXT,
            name TEXT,
            id_number TEXT,
            section TEXT,
            avatar_id TEXT,
            created_at INTEGER,
            sync_status TEXT -- 'synced', 'pending_create'
          )
        ''');

        // Tasks table
        await db.execute('''
          CREATE TABLE tasks(
            id TEXT PRIMARY KEY,
            user_id TEXT,
            title TEXT,
            description TEXT,
            is_done INTEGER,
            created_at INTEGER,
            priority TEXT,
            due_date INTEGER,
            category TEXT,
            is_deleted INTEGER,
            sync_status TEXT -- 'synced', 'pending_create', 'pending_update', 'pending_delete'
          )
        ''');
      },
    );
  }

  // --- USER OPERATIONS ---
  
  Future<void> insertUser(Map<String, dynamic> userMap) async {
    final db = await database;
    await db.insert(
      'offline_users',
      userMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getUser(String email, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'offline_users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    if (maps.isNotEmpty) return maps.first;
    return null;
  }

  Future<List<Map<String, dynamic>>> getPendingUsers() async {
    final db = await database;
    return await db.query('offline_users', where: 'sync_status = ?', whereArgs: ['pending_create']);
  }

  Future<void> updateSyncStatus(String table, String id, String status) async {
    final db = await database;
    await db.update(
      table,
      {'sync_status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- TASK OPERATIONS ---

  Future<void> insertTask(Map<String, dynamic> taskMap) async {
    final db = await database;
    await db.insert('tasks', taskMap, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateTask(Map<String, dynamic> taskMap) async {
    final db = await database;
    await db.update('tasks', taskMap, where: 'id = ?', whereArgs: [taskMap['id']]);
  }

  Future<List<Map<String, dynamic>>> getTasksForUser(String userId) async {
    final db = await database;
    return await db.query('tasks', where: 'user_id = ? AND is_deleted = 0', whereArgs: [userId]);
  }

  Future<List<Map<String, dynamic>>> getPendingTasks() async {
    final db = await database;
    return await db.query('tasks', where: 'sync_status != ?', whereArgs: ['synced']);
  }

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('offline_users');
    await db.delete('tasks');
  }
}
