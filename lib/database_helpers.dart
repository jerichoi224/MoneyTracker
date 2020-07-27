import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

// database table and column names
final String tableSpending = 'spendings';
final String columnId = '_id';
final String columnTimeStamp = 'timestamp';
final String columnDay = 'day';
final String columnAmount = 'amount';
final String columnContent = 'content';

// data model class
class Entry {

  int id;
  int timestamp;
  String day;
  double amount;
  String content;

  Entry();

  // convenience constructor to create a Word object
  Entry.fromMap(Map<String, dynamic> map) {
    id = map[columnId];
    timestamp = map[columnTimeStamp];
    day = map[columnDay];
    amount = map[columnAmount];
    content = map[columnContent];
  }

  // convenience method to create a Map from this object
  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      columnTimeStamp: timestamp,
      columnDay: day,
      columnAmount: amount,
      columnContent: content,
    };
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }
}

// singleton class to manage the database
class DatabaseHelper {

  // This is the actual database filename that is saved in the docs directory.
  static final _databaseName = "SpendingDatabase.db";
  // Increment this version when you need to change the schema.
  static final _databaseVersion = 1;

  // Make this a singleton class.
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // Only allow a single open connection to the database.
  static Database _database;
  Future<Database> get database async {
    if (_database != null) return _database;
    _database = await _initDatabase();
    return _database;
  }

  // open the database
  _initDatabase() async {
    // The path_provider plugin gets the right directory for Android or iOS.
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    // Open the database. Can also add an onUpdate callback parameter.
    return await openDatabase(path,
        version: _databaseVersion,
        onCreate: _onCreate);
  }

  // SQL string to create the database
  Future _onCreate(Database db, int version) async {
    await db.execute('''
              CREATE TABLE $tableSpending (
                $columnId INTEGER PRIMARY KEY,
                $columnTimeStamp INTEGER NOT NULL,
                $columnDay TEXT NOT NULL,
                $columnAmount REAL NOT NULL,
                $columnContent TEXT NOT NULL
              )
              ''');
  }

  // Database helper methods:

  Future<int> insert(Entry entry) async {
    Database db = await database;
    int id = await db.insert(tableSpending, entry.toMap());
    return id;
  }

  Future<Entry> querySpending(int id) async {
    Database db = await database;
    List<Map> maps = await db.query(tableSpending,
        columns: [columnId, columnTimeStamp, columnDay, columnAmount, columnContent],
        where: '$columnId = ?',
        whereArgs: [id]);
    if (maps.length > 0) {
      return Entry.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Entry>> queryDay(String day) async {
    Database db = await database;
    List<Map> maps = await db.query(tableSpending,
        columns: [columnId, columnTimeStamp, columnDay, columnAmount, columnContent],
        where: '$columnDay = ?',
        whereArgs: [day]);
    List<Entry> result = new List<Entry>();
    if (maps.length > 0) {
      for(Map i in maps){
        result.add(Entry.fromMap(i));
      }
      return result;
    }
    return new List<Entry>();
  }

  Future<int> delete(int id) async {
    Database db = await database;
    return await db.delete(tableSpending, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<int> update(Entry entry) async {
    Database db = await database;
    return await db.update(tableSpending, entry.toMap(),
        where: '$columnId = ?', whereArgs: [entry.id]);
  }

}