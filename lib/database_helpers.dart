import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

// database table and column names
final String tableSpending = 'spending';
final String tableSubscriptions = 'tableSubscriptions';

final String columnId = '_id';
final String columnTimeStamp = 'timestamp';
final String columnDay = 'day';
final String columnAmount = 'amount';
final String columnContent = 'content';

final String columnCycle = 'cycle';

// data model class
class SpendingEntry {

  // Five items per spending entry
  int id, timestamp, day;
  String content;
  double amount;

  SpendingEntry();

  // convenience constructor to create a Word object
  SpendingEntry.fromMap(Map<String, dynamic> map) {
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

  @override
  String toString() {
    return "{id: $id, day: $day, amount: $amount, content: $content}";
  }
}

class SubscriptionEntry {

  // Five items per spending entry
  int id, cycle, day;
  String content;
  double amount;

  SubscriptionEntry();

  // convenience constructor to create a Word object
  SubscriptionEntry.fromMap(Map<String, dynamic> map) {
    id = map[columnId];
    day = map[columnDay];
    amount = map[columnAmount];
    content = map[columnContent];
    cycle = map[columnCycle];
  }

  // convenience method to create a Map from this object
  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      columnDay: day,
      columnAmount: amount,
      columnContent: content,
      columnCycle: cycle,
    };
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  @override
  String toString() {
    return "{id: $id, cycle: $cycle, day: $day, amount: $amount, content: $content}";
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
                $columnDay INTEGER NOT NULL,
                $columnAmount REAL NOT NULL,
                $columnContent TEXT NOT NULL
              )
              ''');

    await db.execute('''
              CREATE TABLE $tableSubscriptions (
                $columnId INTEGER PRIMARY KEY,
                $columnDay INTEGER NOT NULL,
                $columnAmount REAL NOT NULL,
                $columnContent TEXT NOT NULL,
                $columnCycle INTEGER NOT NULL
              )
              ''');
  }

  // Database helper methods:

  Future<int> insertSubscription(SubscriptionEntry entry) async {
    Database db = await database;
    int id = await db.insert(tableSubscriptions, entry.toMap());
    return id;
  }

  Future<List<SubscriptionEntry>> queryAllSubscriptions() async {
    Database db = await database;
    List<Map> maps = await db.rawQuery('SELECT * FROM $tableSubscriptions');
    List<SubscriptionEntry> result = new List<SubscriptionEntry>();
    if (maps.length > 0) {
      for(Map i in maps){
        result.add(SubscriptionEntry.fromMap(i));
      }
      return result;
    }
    return new List<SubscriptionEntry>();
  }

  Future<int> deleteSubscription(int id) async {
    Database db = await database;
    return await db.delete(tableSubscriptions, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<int> updateSubscription(SubscriptionEntry entry) async {
    Database db = await database;
    return await db.update(tableSubscriptions, entry.toMap(),
        where: '$columnId = ?', whereArgs: [entry.id]);
  }

  Future<int> insertSpending(SpendingEntry entry) async {
    Database db = await database;
    int id = await db.insert(tableSpending, entry.toMap());
    return id;
  }

  Future<SpendingEntry> querySpending(int id) async {
    Database db = await database;
    List<Map> maps = await db.query(tableSpending,
        columns: [columnId, columnTimeStamp, columnDay, columnAmount, columnContent],
        where: '$columnId = ?',
        whereArgs: [id]);
    if (maps.length > 0) {
      return SpendingEntry.fromMap(maps.first);
    }
    return null;
  }

  // Get all items from today
  Future<List<SpendingEntry>> queryDay(num day) async {
    Database db = await database;
    List<Map> maps = await db.query(tableSpending,
        columns: [columnId, columnTimeStamp, columnDay, columnAmount, columnContent],
        where: '$columnDay = ?',
        whereArgs: [day]);
    List<SpendingEntry> result = new List<SpendingEntry>();
    if (maps.length > 0) {
      for(Map i in maps){
        result.add(SpendingEntry.fromMap(i));
      }
      return result;
    }
    return new List<SpendingEntry>();
  }

  Future<int> deleteSingleEntry(int id) async {
    Database db = await database;
    return await db.delete(tableSpending, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<int> updateSingleEntry(SpendingEntry entry) async {
    Database db = await database;
    return await db.update(tableSpending, entry.toMap(),
        where: '$columnId = ?', whereArgs: [entry.id]);
  }

  Future<List<SpendingEntry>> queryAllSpending() async {
    Database db = await database;
    List<Map> maps = await db.rawQuery('SELECT * FROM $tableSpending');
    List<SpendingEntry> result = new List<SpendingEntry>();
    if (maps.length > 0) {
      for(Map i in maps){
        result.add(SpendingEntry.fromMap(i));
      }
      return result;
    }
    return new List<SpendingEntry>();
  }

  Future<int> clearSpendingTable() async{
    Database db = await database;
    return await db.delete(tableSpending);
  }

  Future<int> clearSubscriptionTable() async{
    Database db = await database;
    return await db.delete(tableSubscriptions);
  }
}