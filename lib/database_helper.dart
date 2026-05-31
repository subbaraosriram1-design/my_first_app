import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('auth.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);
      debugPrint('Initializing SQLite database at: $path');

      return await openDatabase(
        path,
        version: 4,
        onCreate: _createDB,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      debugPrint('SQLite Initialization Error: $e');
      if (e.toString().contains('sqlite_c_ffi_not_found')) {
        debugPrint('MAC/LINUX DESKTOP ERROR: You need sqflite_common_ffi and databaseFactory initialization in main.dart');
      }
      rethrow;
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      )
    ''');

    await _createResumeTable(db);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createResumeTable(db);
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE resumes ADD COLUMN skills TEXT');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE resumes RENAME COLUMN experience TO projects');
    }
  }

  Future _createResumeTable(Database db) async {
    await db.execute('''
      CREATE TABLE resumes (
        username TEXT PRIMARY KEY,
        fullName TEXT,
        email TEXT,
        education TEXT,
        projects TEXT,
        skills TEXT,
        fileNames TEXT,
        FOREIGN KEY (username) REFERENCES users (username)
      )
    ''');
  }

  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<int> registerUser(String username, String password) async {
    final db = await instance.database;
    final hashedPassword = _hashPassword(password);
    
    try {
      return await db.insert('users', {
        'username': username,
        'password': hashedPassword,
      });
    } catch (e) {
      return -1;
    }
  }

  Future<bool> loginUser(String username, String password) async {
    final db = await instance.database;
    final hashedPassword = _hashPassword(password);

    final maps = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, hashedPassword],
    );

    return maps.isNotEmpty;
  }

  Future<int> saveResume(String username, Map<String, dynamic> data) async {
    final db = await instance.database;
    data['username'] = username;
    
    return await db.insert(
      'resumes',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getResume(String username) async {
    final db = await instance.database;
    final maps = await db.query(
      'resumes',
      where: 'username = ?',
      whereArgs: [username],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }
}
