// Contents of database_helper.dart
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  // Singleton pattern
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // Database information
  static final _dbName = "healthhub.db";
  static final _dbVersion = 1;
  static final _tableName = "user_info";

  // Field strings
  static final columnId = "_id";
  static final columnName = "username";
  static final columnPassword = "password";

  // Database instance
  static Database? _database;
  Future<Database> get database async => _database ??= await _initDatabase();

  // Initialize database
  _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, _dbName);
    return await openDatabase(path, version: _dbVersion, onCreate: _onCreate);
  }

  // Create database table
  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        $columnId INTEGER PRIMARY KEY,
        $columnName TEXT NOT NULL,
        $columnPassword TEXT NOT NULL
      )
    ''');
  }

// Database helper methods (insert, query, update, delete)...
  Future<int> insertUser(String username, String password) async {
    Database db = await instance.database;
    return await db.insert(_tableName, {
      columnName: username,
      columnPassword: password
    });
  }
  Future<int> updateUser(String username, double weight, double height) async {
    Database db = await instance.database;
    return await db.update(
      _tableName,
      {
        'weight': weight,
        'height': height,
      },
      where: '$columnName = ?',
      whereArgs: [username],
    );
  }

}
